defmodule BadMammaJamma.JamChannel do
  use BadMammaJamma.Web, :channel

  def join("jam:room", _message, socket) do
    :timer.send_interval(333, :metronome_tick)
    {:ok, socket}
  end

  def handle_info(:metronome_tick, socket) do
    tick = socket.assigns[:tick] || 1
    push socket, "metronome_tick", %{tick: tick}

    {:noreply, assign(socket, :tick, tick + 1)}
  end
end
