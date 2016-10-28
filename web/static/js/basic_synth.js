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
    this.osc_2  = new Osc("sine", 220.0)

    this.eq.low_pass.frequency.value      = 5000
    this.eq.band_pass_one.frequency.value = 400
    this.eq.band_pass_two.frequency.value = 300
    this.eq.high_pass.frequency.value     = 40

    this.osc.output().connect(this.eq.input())
    this.osc_2.output().connect(this.eq.input())
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

  note_on(freq) {
    this.osc.frequency(freq);
    this.osc_2.frequency(freq);
    this.volume_on()
  }

  note_off() {
    this.volume_off()
  }

  volume_off() {
    this.volume.value = 0
  }

  volume_on() {
    this.volume.value = 3
  }
}
