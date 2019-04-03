# Jam

To start:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.create && mix ecto.migrate`
  * Install Node.js dependencies with `npm install`
  * Start Phoenix endpoint with `mix phoenix.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

# TODO
  * Multiple Instruments
    * Sampler (pads)
      * Record Mode (into a clip)
      * Play Mode (from a clip)
      * Pads to trigger samples
      * drag and drop sample wav/mp3 files to the pads
      * mapulate play back speed of the sample
      * trigger repeat of the sample
      * record audio live into the sampler
    * Synth (multiple per room)
      * Record Mode (into a clip)
      * Play Mode (from a clip)
      * Different Modes (Bass, Lead, Pads)
      * Filter Controls
      * Waveform Controls
      * ASDR
  * Clips
    * Each instrument can create 'clips' of music (various lengths)
    * A clip can be saved into some sort of bin for dynamic triggering
    * You can apply swing to a clip (or maybe this should be global?)
    * Clips can be played together and loop at their various lengths independant of other clips
  * Effects
    * Wire instruments into them
    * Reverb
    * Delay
    * Compression
  * Transport
    * Global (per room) controls or play/stop/bpm (top of page)
  * The amount of instruments is fixed and are assigned to a person (the chose)

# Technical Concerns
  * Getting the global BPM rock solid taking network latency into consideration
  * Doing rendering with svg rather than html dom elements. is this faster?
