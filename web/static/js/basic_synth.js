import mixer from './mixer'
import {Osc} from "./osc"
import {FourBandEq} from "./four_band_eq"

export class BasicSynth {
  constructor() {
    this.gain   = mixer.createGain()
    this.dest   = mixer.destination
    this.volume = this.gain.gain
    this.eq     = new FourBandEq()
    this.osc    = new Osc("triangle", 220.0)

    this.osc.output().connect(this.eq.input())
    this.eq.output().connect(this.input())
    this.input().connect(this.output())
    this.volume_off()
  }

  input() {
    return this.gain
  }

  output() {
    return this.dest
  }

  play_frequency(freq) {
    this.osc.frequency(freq);
    this.note_on();
  }

  note_on() {
    this.volume_on()
  }

  note_off() {
    this.volume_off()
  }

  volume_off() {
    this.volume.value = 0
  }

  volume_on() {
    this.volume.value = 1
  }
}
