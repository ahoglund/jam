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
import Json.Encode as JE
import Json.Decode as JD exposing ((:=))
import Dict
import Keyboard
import Char

type alias Model =
  { tracks : List Track
  , total_beats : Int
  , current_beat : Maybe Int
  , is_playing : Bool
  , phxSocket : Phoenix.Socket.Socket Msg
  , bpm : Int }

socketServer : String
socketServer =
  "ws://localhost:4000/socket/websocket"

initPhxSocket : Phoenix.Socket.Socket Msg
initPhxSocket =
  Phoenix.Socket.init socketServer
    |> Phoenix.Socket.withDebug
    |> Phoenix.Socket.on "update_tracks" jamChannelName ReceiveCellUpdate

initModel : List Track -> Model
initModel tracks =
  { tracks = tracks
  , total_beats = List.length beatCount
  , bpm = 120
  , is_playing = False
  , phxSocket = initPhxSocket
  , current_beat = Nothing }

jamChannelName : String
jamChannelName =
  "jam:room"

beatCount : List Int
beatCount =
  [1..16]

type alias CellUpdate =
  { cell_id : Int
  , track_id : Int
  , is_active : Bool
  }

decodeCellUpdate : JD.Decoder CellUpdate
decodeCellUpdate =
  JD.object3 CellUpdate
    ("cell_id" := JD.int)
    ("track_id" := JD.int)
    ("is_active" := JD.bool)

type Msg
  = SetCurrentBeat Time
  | UpdateBpm Int
  | PlaySound String
  | ToggleCell Cell
  | Play
  | Stop
  | PhoenixMsg (Phoenix.Socket.Msg Msg)
  | ReceiveCellUpdate JE.Value
  | SendCellUpdate Int Int Bool
  | PlaySynth String

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
    SendCellUpdate cell_id track_id is_active ->
      let
        payload = (JE.object [
          ("cell_id", JE.int cell_id)
        , ("track_id", JE.int track_id)
        , ("is_active", JE.bool is_active) ])

        push' =
          Phoenix.Push.init "update_tracks" jamChannelName
            |> Phoenix.Push.withPayload payload
        (phxSocket, phxCmd) = Phoenix.Socket.push push' model.phxSocket
      in
        ( { model | phxSocket = phxSocket }
        , Cmd.map PhoenixMsg phxCmd
        )
    ReceiveCellUpdate raw ->
      case JD.decodeValue decodeCellUpdate raw of
        Ok tracks ->
          ( { model | tracks = tracks }
          , Cmd.none
          )
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
    SetCurrentBeat time ->
      case model.current_beat of
        Nothing ->
          ({ model | current_beat = (Just 1) }, Cmd.batch (playSounds model ((Just 1))))
        Just beat ->
          if beat == model.total_beats then
            ({ model | current_beat = (Just 1) }, Cmd.batch (playSounds model ((Just 1))))
          else
            ({ model | current_beat = Just (beat + 1) }, Cmd.batch (playSounds model (Just (beat + 1))))
    Play ->
      if model.is_playing == True then
        ({ model | current_beat = Just 1 }, Cmd.batch (playSounds model (Just 1)) )
      else
        ({ model | is_playing = True }, Cmd.batch (playSounds model (model.current_beat)) )
    Stop ->
      if model.is_playing == False then
        ({ model | current_beat = Nothing, is_playing = False }, Cmd.none )
      else
        ({ model | is_playing = False }, Cmd.none )

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
  div [ class "page-header" ]
    [ stepEditorHeader,
      stepEditor model ]

stepEditorHeader : Html Msg
stepEditorHeader =
  h3 [] [ text ("Drum Sequence Editor") ]

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

stepEditorTrack : Model -> Track -> Html Msg
stepEditorTrack model track =
  let
  preview_cell =
    td [ class "sample"]
      [
       button [ class "btn", onClick (PlaySound track.sample_file)]
         [
           span [ class "glyphicon glyphicon-play" ] []
         ],
       text track.name
      ]
  in
    track.cells
    |> List.map (\cell -> stepEditorCell model track cell)
    |> List.append [preview_cell]
    |> tr []

stepEditorCell : Model -> Track -> Cell -> Html Msg
stepEditorCell model track cell =
  td [ id ("track-" ++ (toString track.id) ++ "-cell-" ++ (toString cell.id))
     , class ((setActiveClass cell.id model.current_beat) ++ " " ++ (setActiveCell track cell))
     , onClick (ToggleCell cell)] []

setActiveCell : Track -> Cell -> String
setActiveCell track beat =
  if beat.is_active == True && beat.track_id == track.id then
    "success"
  else
    ""

setActiveClass : Int -> Maybe Int -> String
setActiveClass cell_id current_beat =
  case current_beat of
    Nothing ->
      "inactive"
    Just beat ->
      if cell_id == beat then
        "active"
      else
        "inactive"

buttons : Model -> Html Msg
buttons model =
  div []
  [
    button [ class "btn btn-success" , onClick Play ]
      [ span [ class "glyphicon glyphicon-play" ] [] ],
    button [ class "btn btn-danger" , onClick Stop ]
      [ span [ class "glyphicon glyphicon-stop" ] [] ],
    input [ disabled True, class "btn btn-default"] [ text (toString model.bpm)],
    button [ class "btn btn-default" , onClick (UpdateBpm (model.bpm + 1))]
      [ span [ class "glyphicon glyphicon-arrow-up" ] [] ],
    button [ class "btn btn-default" , onClick (UpdateBpm (model.bpm - 1))]
      [ span [ class "glyphicon glyphicon-arrow-down" ] [] ]
  ]

view : Model -> Html Msg
view model =
    div [ class "container" ]
        [ stepEditorSection model,
          buttons model ]

subscriptions : Model -> Sub Msg
subscriptions model =
  case model.is_playing of
    True ->
      Sub.batch [
        Time.every (Time.minute * (interval model)) SetCurrentBeat,
        Phoenix.Socket.listen model.phxSocket PhoenixMsg
      ]
    False ->
      Sub.none

interval : Model -> Float
interval model =
    0.5 / (toFloat model.bpm)

init =
  let
    model = initModel (defaultTracks beatCount)
  in
    (model, Cmd.none)

main : Program Never
main =
  App.program
    { init          = init
    , subscriptions = subscriptions
    , update        = update
    , view          = view
    }

