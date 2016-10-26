port module Cmds exposing (..)

port playRawSound : String -> Cmd msg
port playRawSynth : Float -> Cmd msg
port stopRawSynth : String -> Cmd msg

playSound : String -> Cmd msg
playSound file =
  playRawSound file

playSynth : Float -> Cmd msg
playSynth freq =
  playRawSynth freq

stopSynth : String -> Cmd msg
stopSynth a =
  stopRawSynth a
