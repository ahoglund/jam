import {BasicSynth} from "./basic_synth"
import elmApp from "./elm_app"
const basic_synth = new BasicSynth();

elmApp.ports.playSynth.subscribe(function (file) {
  basic_synth.play_frequency(220.0);
});
