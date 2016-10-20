import {BasicSynth} from "./basic_synth"

const basic_synth = new BasicSynth()

$(".playpad").click(event => { basic_synth.play_frequency(220.0) });
