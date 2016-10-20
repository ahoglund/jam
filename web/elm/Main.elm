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

type alias Model =
  { tracks : List Track
  , total_beats : Int
  , current_beat : Maybe Int
  , is_playing : Bool
  , bpm : Int }

initModel : List Track -> Model
initModel tracks =
  { tracks = tracks
  , total_beats = List.length beatCount
  , bpm = 120
  , is_playing = False
  , current_beat = Nothing }

beatCount : List Int
beatCount =
  [1..16]

type Msg = SetCurrentBeat Time
  | UpdateBpm Int
  | PlaySound String
  | ToggleCell Track Cell
  | Play
  | Stop

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    UpdateBpm bpm ->
      ({ model | bpm = bpm }, Cmd.none)
    PlaySound file ->
      (model, Cmds.playSound(file))
    ToggleCell track beat ->
      let
        tracks = model.tracks
        |> List.map (\t ->
          let
            new_cells = List.map (\b -> toggleCell t b beat) t.cells
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
toggleCell track cell1 cell2 =
  if track.id == cell2.track_id && cell1.id == cell2.id  then
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
    |> List.map (\beat -> stepEditorCell model track beat)
    |> List.append [preview_cell]
    |> tr []

stepEditorCell : Model -> Track -> Cell -> Html Msg
stepEditorCell model track beat =
  td [ id ("track-" ++ (toString track.id) ++ "-cell-" ++ (toString beat.id))
     , class ((setActiveClass beat.id model.current_beat) ++ " " ++ (setActiveCell track beat))
     , onClick (ToggleCell track beat)] []

setActiveCell : Track -> Cell -> String
setActiveCell track beat =
  if beat.is_active == True && beat.track_id == track.id then
    "success"
  else
    ""

setActiveClass : Int -> Maybe Int -> String
setActiveClass beat_id current_beat =
  case current_beat of
    Nothing ->
      "inactive"
    Just beat ->
      if beat_id == beat then
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
    button [ class "btn btn-default"] [ text (toString model.bpm)],
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
      Time.every (Time.minute * (interval model)) SetCurrentBeat
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

