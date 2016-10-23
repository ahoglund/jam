defmodule BadMammaJamma.Metronome do

  defp init do
    :timer.send_interval(333, :metronome_tick)
  end
end
