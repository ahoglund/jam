import {BasicSynth} from "./basic_synth"
import elmApp from "./elm_app"
const basic_synth = new BasicSynth();

elmApp.ports.playRawSynth.subscribe(function (freq) {
  basic_synth.play_frequency(freq);
  console.log("PLAY PLAY PLAY PLAY");
});

elmApp.ports.stopRawSynth.subscribe(function () {
  basic_synth.note_off();
  console.log("STOP STOP STOP STOP STOP STOP");
});
