import {BasicSynth} from "./basic_synth"
import elmApp from "./elm_app"
const basic_synth = new BasicSynth();

elmApp.ports.playRawSynth.subscribe(function (freq) {
  basic_synth.play_frequency(freq);
});

elmApp.ports.stopRawSynth.subscribe(function () {
  basic_synth.note_off();
});
