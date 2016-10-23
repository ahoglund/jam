defmodule BadMammaJamma.JamChannel do
  use BadMammaJamma.Web, :channel

  def join("jam:room:" <> jam_id, _message, socket) do
    {:ok, assign(socket, :jam_id, String.to_integer(jam_id))}
  end

  def handle_info(:metronome_tick, socket) do
    tick = socket.assigns[:tick] || 1
    push socket, "metronome_tick", %{tick: tick}

    {:noreply, assign(socket, :tick, tick + 1)}
  end

  def handle_in("metronome_tick", params, socket) do
    broadcast! socket, "metronome_tick", %{
      tick: params["tick"]
    }

    {:reply, :ok, socket}
  end
end
