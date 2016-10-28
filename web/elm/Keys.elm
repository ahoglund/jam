module Keys exposing (toFrequency, fromKeyCode, Key)

import Dict exposing (Dict)
import Keyboard exposing (KeyCode)
import Maybe exposing (Maybe)

type Key
  = C2 | CS2 | D2 | DS2 | E2 | F2 | FS2 | G2 | GS2 | A2 | AS2 | B2
  | C3

keyCodeToKey : Dict KeyCode Key
keyCodeToKey =
  Dict.fromList
    [ (65, C2)
    , (87, CS2)
    , (83, D2)
    , (69, DS2)
    , (68, E2)
    , (70, F2)
    , (84, FS2)
    , (71, G2)
    , (89, GS2)
    , (72, A2)
    , (85, AS2)
    , (74, B2)
    , (75, C3)
    ]

fromKeyCode : KeyCode -> Maybe Key
fromKeyCode keyCode =
  Dict.get keyCode keyCodeToKey


toFrequency : Maybe Key -> Float
toFrequency maybeKey =
  case maybeKey of
    Nothing ->
      0.0
    Just key ->
      case key of
        C2 -> 65.41
        CS2 -> 69.30
        D2 -> 73.42
        DS2 -> 77.78
        E2 -> 82.41
        F2 -> 87.31
        FS2 -> 92.50
        G2 -> 98.00
        GS2 -> 103.83
        A2 -> 110.00
        AS2 -> 116.54
        B2 -> 123.47
        C3 -> 130.81
