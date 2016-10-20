port module Cmds exposing (..)

port playRawSound : String -> Cmd msg

playSound : String -> Cmd msg

playSound file =
  playRawSound file

