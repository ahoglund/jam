import mixer from "./mixer"

export class FourBandEq {
  constructor() {
    this.low_pass = mixer.createBiquadFilter()
    this.low_pass.type = "lowpass"
    this.low_pass.frequency.value = 15000

    this.band_pass_one = mixer.createBiquadFilter()
    this.band_pass_one.type = "bandpass"
    this.band_pass_one.frequency.value = 3000

    this.band_pass_two = mixer.createBiquadFilter()
    this.band_pass_two.type = "bandpass"
    this.band_pass_two.frequency.value = 7000

    this.high_pass = mixer.createBiquadFilter()
    this.high_pass.type = "highpass"
    this.high_pass.frequency.value = 30

    this.low_pass.connect(this.band_pass_one)
    this.band_pass_one.connect(this.band_pass_two)
    this.band_pass_two.connect(this.high_pass)
  }

  input() {
    return this.low_pass
  }

  output() {
    return this.high_pass
  }
}

