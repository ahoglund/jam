module Cell exposing (Cell, init)

type alias Cell =
  { track_id : Int
  , is_active : Bool
  , id: Int }

init : Int -> Int -> Cell
init id track_id =
  { id = id
  , track_id = track_id
  , is_active = False }

