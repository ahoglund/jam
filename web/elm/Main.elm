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
import Char

type alias Model =
  { tracks : List Track
  , total_beats : Int
  , current_beat : Maybe Int
  , is_playing : Bool
  , phxSocket : Phoenix.Socket.Socket Msg
  , jam_id : String
  , bpm : Int }

socketServer : String
socketServer =
  "ws://localhost:4000/socket/websocket"

initPhxSocket : Phoenix.Socket.Socket Msg
initPhxSocket =
  Phoenix.Socket.init socketServer
    |> Phoenix.Socket.withDebug
    |> Phoenix.Socket.on "metronome_tick" jamChannelName ReceiveMetronomeTick

initModel : JamFlags -> List Track -> Model
initModel jamFlags tracks =
  { tracks = tracks
  , total_beats = List.length beatCount
  , bpm = 120
  , is_playing = False
  , phxSocket = initPhxSocket
  , jam_id = jamFlags.jam_id
  , current_beat = Nothing }

jamChannelName : String
jamChannelName =
  "jam:room:"

beatCount : List Int
beatCount =
  [1..16]

type alias CellUpdate =
  { cell_id : Int
  , track_id : Int
  , is_active : Bool
  }

type alias Metronome =
  { tick : Int }

decodeMetronomeTick : JD.Decoder Metronome
decodeMetronomeTick =
  JD.object1 Metronome
    ("tick" := JD.int)

decodeCellUpdate : JD.Decoder CellUpdate
decodeCellUpdate =
  JD.object3 CellUpdate
    ("cell_id" := JD.int)
    ("track_id" := JD.int)
    ("is_active" := JD.bool)

type Msg
  = UpdateBpm Int
  | PlaySound String
  | ToggleCell Cell
  | Play
  | Stop
  | PlaySynth String
  | PhoenixMsg (Phoenix.Socket.Msg Msg)
  | LeaveChannel
  | ReceiveMetronomeTick JE.Value

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    PhoenixMsg msg ->
      let
        ( phxSocket, phxCmd ) = Phoenix.Socket.update msg model.phxSocket
      in
        ( { model | phxSocket = phxSocket }
        , Cmd.map PhoenixMsg phxCmd
        )
    ReceiveMetronomeTick raw ->
      case JD.decodeValue decodeMetronomeTick raw of
        Ok metronome ->
          let
            current_beat = setCurrentBeat model
          in
          ({ model | current_beat = current_beat }, Cmd.batch (playSounds model current_beat))
        Err err ->
          (model, Cmd.none)
    UpdateBpm bpm ->
      ({ model | bpm = bpm }, Cmd.none)
    PlaySound file ->
      (model, Cmds.playSound(file))
    PlaySynth key ->
      (model, Cmds.playSynth(440.0))
    ToggleCell cell ->
      let
        tracks = model.tracks
        |> List.map (\t ->
          let
            new_cells = List.map (\c -> toggleCell t c cell) t.cells
          in
          ({ t | cells = new_cells })
        )
      in
        ({ model | tracks = tracks }, Cmd.none)
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

toggleCell : Track -> Cell -> Cell -> Cell
toggleCell track cell1 toggled_cell =
  if track.id == toggled_cell.track_id && cell1.id == toggled_cell.id  then
    if cell1.is_active == True then
      ({ cell1 | is_active = False })
    else
      ({ cell1 | is_active = True })
  else
    (cell1)

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
     , onClick (ToggleCell cell)] []

setActiveCell : Track -> Cell -> String
setActiveCell track beat =
  if beat.is_active == True && beat.track_id == track.id then
    "success"
  else
    ""

setActiveClass : Int -> Model -> String
setActiveClass cell_id model =
  case model.current_beat of
    Nothing ->
      "inactive"
    Just beat ->
      if model.is_playing == True && cell_id == beat then
        "active"
      else
        "inactive"

buttons : Model -> Html Msg
buttons model =
  div []
  [
    button [ class "btn btn-success", onClick Play ]
      [ span [ class "glyphicon glyphicon-play" ] [] ],
    button [ class "btn btn-danger", onClick Stop ]
      [ span [ class "glyphicon glyphicon-stop" ] [] ],
    p [ class "btn btn-default", onClick(UpdateBpm 120)] [ text ( "BPM: " ++ toString model.bpm)],
    button [ class "btn btn-default", onClick (UpdateBpm (model.bpm + 1))]
      [ span [ class "glyphicon glyphicon-arrow-up" ] [] ],
    button [ class "btn btn-default", onClick (UpdateBpm (model.bpm - 1))]
      [ span [ class "glyphicon glyphicon-arrow-down" ] [] ],
    button [ class "btn btn-default", onClick LeaveChannel ] [ text "Leave channel" ],
    p [] [ text (toString model) ]
  ]

view : Model -> Html Msg
view model =
    div [ class "container" ]
        [ stepEditorSection model,
          buttons model ]

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch [
    Phoenix.Socket.listen model.phxSocket PhoenixMsg
  ]

interval : Model -> Float
interval model =
    0.5 / (toFloat model.bpm)

init : JamFlags -> (Model, Cmd Msg)
init jamFlags =
  let
    model = initModel jamFlags (defaultTracks beatCount)
    channel = Phoenix.Channel.init (jamChannelName ++ model.jam_id)
    (phxSocket, phxCmd) = Phoenix.Socket.join channel model.phxSocket
  in
    ({ model | phxSocket = phxSocket } , Cmd.map PhoenixMsg phxCmd)

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

