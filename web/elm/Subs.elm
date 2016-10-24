module Subs exposing (..)

import Keys exposing (Key)
import Keyboard

downs : Maybe Key -> Sub Msg
downs maybeKey =
  let
    onKeyDown currentKey keyCode =
      if Keys.fromKeyCode keyCode == currentKey then
        NoOp
      else
        keyCode |> Keys.fromKeyCode |> KeyChange
  in
    Keyboard.downs (onKeyDown maybeKey)

ups : Maybe Key -> Sub Msg
ups maybeKey =
  let
    onKeyUp currentKeyCode keyCode =
      if Keys.fromKeyCode keyCode == Just currentKeyCode then
        KeyChange Nothing
      else
        NoOp
  in
    case maybeKey of
      Nothing ->
        Sub.none
      Just key ->
        Keyboard.ups (onKeyUp key)
