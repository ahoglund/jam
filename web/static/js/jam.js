import {BasicSynth} from "./basic_synth"
import elmApp from "./elm_app"
const basic_synth = new BasicSynth();

elmApp.ports.playRawSynth.subscribe(function (freq) {
  basic_synth.play_frequency(880.0);
});
