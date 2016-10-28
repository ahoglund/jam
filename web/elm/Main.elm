module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.App as App
import Time exposing (Time, second)
import String
import Track exposing (..)
import Cell exposing (..)
import Cmds exposing (..)
import Phoenix.Socket
import Phoenix.Channel
import Phoenix.Push
import Json.Encode as JE exposing (..)
import Json.Decode as JD exposing (..)
import Dict
import Keys
import Keys exposing (Key)
import Keyboard
import Char

type alias JamFlags =
  { jam_id : String }

main : Program JamFlags
main =
  App.programWithFlags
    { init          = init
    , subscriptions = subscriptions
    , update        = update
    , view          = view
    }

type alias Model =
  { tracks : List Track
  , total_beats : Int
  , current_beat : Maybe Int
  , current_key : Maybe Key
  , is_playing : Bool
  , phxSocket : Phoenix.Socket.Socket Msg
  , bpm : Int
  , jam_id : String }

socketServer : String
socketServer =
  "ws://localhost:4000/socket/websocket"

initPhxSocket : String -> Phoenix.Socket.Socket Msg
initPhxSocket jam_id =
  Phoenix.Socket.init socketServer
    |> Phoenix.Socket.withDebug
    |> Phoenix.Socket.on "metronome_tick" (jamChannelName ++ jam_id) ReceiveMetronomeTick
    |> Phoenix.Socket.on "update_cell" (jamChannelName ++ jam_id) ReceiveUpdatedCell
    |> Phoenix.Socket.on "update_bpm" (jamChannelName ++ jam_id) ReceiveUpdatedBpm

initModel : JamFlags -> List Track -> Model
initModel jamFlags tracks =
  { tracks = tracks
  , total_beats = List.length beatCount
  , is_playing = False
  , phxSocket = (initPhxSocket jamFlags.jam_id)
  , jam_id = jamFlags.jam_id
  , bpm = 120
  , current_key = Nothing
  , current_beat = Nothing }

jamChannelName : String
jamChannelName =
  "jam:room:"

beatCount : List Int
beatCount =
  [1..16]

type alias Metronome =
  { tick : Int }

decodeMetronomeTick : JD.Decoder Metronome
decodeMetronomeTick =
  JD.object1 Metronome
    ("tick" := JD.int)

decodeBpm : JD.Decoder Int
decodeBpm =
  ("bpm" := JD.int)

decodeCell : JD.Decoder Cell
decodeCell =
  JD.object3 Cell
    ("track_id" := JD.int)
    ("is_active" := JD.bool)
    ("id" := JD.int)

type Msg
  = PlaySound String
  | NoOp
  | Play
  | Stop
  | PlaySynth (Maybe Key)
  | PhoenixMsg (Phoenix.Socket.Msg Msg)
  | LeaveChannel
  | ReceiveMetronomeTick JE.Value
  | ReceiveUpdatedCell JE.Value
  | SendUpdatedCell Cell
  | ReceiveUpdatedBpm JE.Value
  | SendBpmUpdate Int

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    NoOp ->
      (model, Cmd.none)
    PhoenixMsg msg ->
      let
        ( phxSocket, phxCmd ) = Phoenix.Socket.update msg model.phxSocket
      in
        ( { model | phxSocket = phxSocket }
        , Cmd.map PhoenixMsg phxCmd
        )
    ReceiveUpdatedCell raw ->
      case JD.decodeValue decodeCell raw of
        Ok updated_cell ->
          let
            tracks = (toggleCells model.tracks updated_cell)
          in
          ({ model | tracks = tracks }, Cmd.none)
        Err err ->
          (model, Cmd.none)
    ReceiveUpdatedBpm raw ->
      case JD.decodeValue decodeBpm raw of
        Ok bpm ->
          ({ model | bpm = bpm }, Cmd.none)
        Err err ->
          (model, Cmd.none)
    SendUpdatedCell updated_cell ->
      let
        payload = (JE.object
          [ ("track_id",  JE.int updated_cell.track_id)
          , ("is_active", JE.bool updated_cell.is_active)
          , ("id",        JE.int updated_cell.id)])

        push' =
          Phoenix.Push.init "update_cell" (jamChannelName ++ model.jam_id)
          |> Phoenix.Push.withPayload payload
        tracks = (toggleCells model.tracks updated_cell)
        (phxSocket, phxCmd) = Phoenix.Socket.push push' model.phxSocket
      in
        ({ model | tracks = tracks, phxSocket = phxSocket }, Cmd.map PhoenixMsg phxCmd)
    ReceiveMetronomeTick raw ->
      case JD.decodeValue decodeMetronomeTick raw of
        Ok metronome ->
          let
            current_beat = setCurrentBeat model
          in
          ({ model | current_beat = current_beat }, Cmd.batch (playSounds model current_beat))
        Err err ->
          (model, Cmd.none)
    SendBpmUpdate bpm ->
      let
        payload = (JE.object [ ("bpm",  JE.int bpm)])
        push' =
          Phoenix.Push.init "update_bpm" (jamChannelName ++ model.jam_id)
          |> Phoenix.Push.withPayload payload
        (phxSocket, phxCmd) = Phoenix.Socket.push push' model.phxSocket
      in
        ({ model | phxSocket = phxSocket }, Cmd.map PhoenixMsg phxCmd)
    PlaySound file ->
      (model, Cmds.playSound(file))
    PlaySynth maybeKey ->
      case maybeKey of
        Nothing ->
          ({model | current_key = maybeKey}, Cmds.stopSynth("stop"))
        Just key ->
          ({model | current_key = maybeKey}, Cmds.playSynth(Keys.toFrequency maybeKey))
    LeaveChannel ->
      let
        (phxSocket, phxCmd) = Phoenix.Socket.leave (jamChannelName ++ model.jam_id) model.phxSocket
      in
        ({ model | phxSocket = phxSocket }
        , Cmd.map PhoenixMsg phxCmd
        )
    Play ->
      let
        current_beat = setCurrentBeat model
      in
        if model.is_playing == True then
          ({ model | current_beat = current_beat }, Cmd.batch (playSounds model current_beat) )
        else
          ({ model | is_playing = True }, Cmd.batch (playSounds model current_beat) )
    Stop ->
      ({ model | current_beat = Nothing, is_playing = False }, Cmd.none )

setCurrentBeat : Model -> Maybe Int
setCurrentBeat model =
  case model.current_beat of
    Nothing ->
      if model.is_playing == True then
        (Just 1)
      else
        (Nothing)
    Just beat ->
      if model.is_playing == True then
        if beat == model.total_beats then
          (Just 1)
        else
          (Just (beat + 1))
      else
        (Nothing)

playSounds : Model -> Maybe Int -> List (Cmd msg)
playSounds model current_beat =
  case current_beat of
    Nothing ->
      [(Cmd.none)]
    Just beat ->
      model.tracks
      |> List.map (\track ->
        track.cells
        |> List.map (\cell ->
          if cell.is_active && beat == cell.id then
            (Cmds.playSound(track.sample_file))
          else
            (Cmd.none)
        )
      )
      |> List.concat

toggleCells : List Track -> Cell -> List Track
toggleCells tracks updated_cell =
    tracks
      |> List.map (\track ->
        let
          new_cells = List.map (\cell -> toggleCell track cell updated_cell) track.cells
        in
        ({ track | cells = new_cells })
      )

toggleCell : Track -> Cell -> Cell -> Cell
toggleCell current_track current_cell updated_cell =
  if current_track.id == updated_cell.track_id && current_cell.id == updated_cell.id  then
    if updated_cell.is_active == True then
      ({ current_cell | is_active = False })
    else
      ({ current_cell | is_active = True })
  else
    (current_cell)

stepEditorSection : Model -> Html Msg
stepEditorSection model =
  div [ class "sequencer" ]
     [ stepEditorHeader
     , stepEditor model]

stepEditorHeader : Html Msg
stepEditorHeader =
  h3 [] [ text ("Sequencer") ]

stepEditor : Model -> Html Msg
stepEditor model =
  table [ class "table table-hover table-bordered" ]
  [ stepEditorTableHeader model
  , stepEditorTracks model ]

stepEditorTableHeader : Model -> Html Msg
stepEditorTableHeader model =
  [1..model.total_beats]
  |> List.map (\beat_id -> th [] [ text (toString beat_id) ])
  |> List.append [th [] []]
  |> tr []

stepEditorTracks : Model -> Html Msg
stepEditorTracks model =
  model.tracks
  |> List.map (\track -> stepEditorTrack model track)
  |> tbody []

pads : Track -> Html Msg
pads track =
  td []
    [
     button [ class "btn", onClick (PlaySound track.sample_file)]
       [
         span [ class "glyphicon glyphicon-play" ] []
       ],
     text track.name
    ]

stepEditorTrack : Model -> Track -> Html Msg
stepEditorTrack model track =
  track.cells
    |> List.map (\cell -> stepEditorCell model track cell)
    |> List.append [ td [class "sample"] [ span [] [text track.name ]]]
    |> tr []

stepEditorCell : Model -> Track -> Cell -> Html Msg
stepEditorCell model track cell =
  td [ id ("track-" ++ (toString track.id) ++ "-cell-" ++ (toString cell.id))
     , class ((setActiveClass cell.id model) ++ " " ++ (setActiveCell track cell))
     , onClick (SendUpdatedCell (Cell track.id cell.is_active cell.id))] []

setActiveCell : Track -> Cell -> String
setActiveCell track beat =
  if beat.is_active == True && beat.track_id == track.id then
    "selected"
  else
    "deselected"

setActiveClass : Int -> Model -> String
setActiveClass cell_id model =
  case model.current_beat of
    Nothing ->
      "inactive"
    Just beat ->
      if model.is_playing == True && cell_id == beat then
        "activated"
      else
        "deactivated"

buttons : Model -> Html Msg
buttons model =
  div []
  [
    button [ class "btn btn-success", onClick Play ]
      [ span [ class "glyphicon glyphicon-play" ] [] ],
    button [ class "btn btn-danger", onClick Stop ]
      [ span [ class "glyphicon glyphicon-stop" ] [] ],
    p [ class "btn btn-default", onClick(SendBpmUpdate 120)] [ text ( "BPM: " ++ toString model.bpm)],
    button [ class "btn btn-default", onClick (SendBpmUpdate (model.bpm + 1))]
      [ span [ class "glyphicon glyphicon-arrow-up" ] [] ],
    button [ class "btn btn-default", onClick (SendBpmUpdate (model.bpm - 1))]
      [ span [ class "glyphicon glyphicon-arrow-down" ] [] ],
    button [ class "btn btn-warning", onClick (PlaySound "/samples/its_alive.wav")]
      [ text "!!!" ]
  ]

view : Model -> Html Msg
view model =
    div [ class "container" ]
        [ stepEditorSection model
        , buttons model ]

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch [
    Phoenix.Socket.listen model.phxSocket PhoenixMsg,
    bass_key_down model.current_key,
    base_key_up model.current_key
  ]

bass_key_down : Maybe Key -> Sub Msg
bass_key_down maybeKey =
  let
    onKeyDown currentKey keyCode =
      if Keys.fromKeyCode keyCode == currentKey then
        NoOp
      else
        keyCode |> Keys.fromKeyCode |> PlaySynth
  in
    Keyboard.downs (onKeyDown maybeKey)

base_key_up : Maybe Key -> Sub Msg
base_key_up maybeKey =
  let
    onKeyUp currentKeyCode keyCode =
      if Keys.fromKeyCode keyCode == Just currentKeyCode then
        PlaySynth Nothing
      else
        NoOp
  in
    case maybeKey of
      Nothing ->
        Sub.none
      Just key ->
        Keyboard.ups (onKeyUp key)
init : JamFlags -> (Model, Cmd Msg)
init jamFlags =
  let
    model = initModel jamFlags (defaultTracks beatCount)
    channel = Phoenix.Channel.init (jamChannelName ++ model.jam_id)
    (phxSocket, phxCmd) = Phoenix.Socket.join channel model.phxSocket
  in
    ({ model | phxSocket = phxSocket } , Cmd.map PhoenixMsg phxCmd)

