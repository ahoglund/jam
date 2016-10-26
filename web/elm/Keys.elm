module Keys exposing (toFrequency, fromKeyCode, Key)

import Dict exposing (Dict)
import Keyboard exposing (KeyCode)
import Maybe exposing (Maybe)

type Key
  = C3 | CS3 | D3 | DS3 | E3 | F3 | FS3 | G3 | GS3 | A3 | AS3 | B3
  | C4 | CS4 | D4

keyCodeToKey : Dict KeyCode Key
keyCodeToKey =
  Dict.fromList
    [ (65, C3)
    , (87, CS3)
    , (83, D3)
    , (69, DS3)
    , (68, E3)
    , (70, F3)
    , (84, FS3)
    , (71, G3)
    , (89, GS3)
    , (72, A3)
    , (85, AS3)
    , (74, B3)
    , (75, C4)
    , (79, CS4)
    , (76, D4)
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
        C3 -> 130.81 / 3
        CS3 -> 138.59 / 3
        D3 -> 146.83 / 3
        DS3 -> 155.56 / 3
        E3 -> 164.81 / 3
        F3 -> 174.61 / 3
        FS3 -> 185.0 / 3
        G3 -> 196.0 / 3
        GS3 -> 207.65 / 3
        A3 -> 220.0 / 3
        AS3 -> 233.08 / 3
        B3 -> 246.94 / 3
        C4 -> 261.63 / 3
        CS4 -> 277.18 / 3
        D4 -> 293.67 / 3
