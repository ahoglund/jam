defmodule BadMammaJamma.JamChannel do
  use BadMammaJamma.Web, :channel

  def join("jam:room", message, socket) do
    init_metronome
    {:ok, socket}
  end

  def handle_info(:metronome_click, socket) do
    push socket, "metronome_click", %{count: 1}
  end

  defp init_metronome do
    :timer.send_interval(1_000, :metronome_tick)
  end
end
