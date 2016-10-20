port module Cmds exposing (..)

port playRawSound : String -> Cmd msg
port playRawSynth : Float -> Cmd msg

playSound : String -> Cmd msg
playSound file =
  playRawSound file

playSynth : Float -> Cmd msg
playSynth freq =
  playRawSynth freq
