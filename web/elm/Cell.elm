module Cell exposing (Cell, init)

type alias Cell =
  { is_active : Bool
  , track_id : Int
  , id: Int }

init : Int -> Int -> Cell
init id track_id =
  { id = id
  , track_id = track_id
  , is_active = False }



