module Track exposing (Track, init, defaultTracks)

import Cell exposing (Cell)

type alias Track =
  { id : Int
  , name : String
  , sample_file : String
  , cells : List Cell }

init : Int -> List Cell -> String -> String -> Track
init id cells name sample_file =
  { id = id
  , name = name
  , sample_file = sample_file
  , cells = cells }

defaultTracks : List Int ->  List Track
defaultTracks total_cells =
  [
    (init
       1
       (List.map (\cell_id -> Cell.init cell_id 1) total_cells)
       "Kick"
       "samples/kick.wav"
    ),
    (init
       2
       (List.map (\cell_id -> Cell.init cell_id 2) total_cells)
       "Snare"
       "samples/snare.wav"
    ),
    (init
       3
       (List.map (\cell_id -> Cell.init cell_id 3) total_cells)
       "HH Closed"
       "samples/hh-closed.wav"
    ),
    (init
       4
       (List.map (\cell_id -> Cell.init cell_id 4) total_cells)
       "HH Open"
       "samples/hh-open.wav"
    )
  ]

