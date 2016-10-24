defmodule BadMammaJamma.Metronome do
  use GenServer

  def start_link(jam_id) do
    GenServer.start_link(__MODULE__, %{jam_id: jam_id, tick: 1}, name: {:global, "jam_#{jam_id}_metronome"} )
  end

  def init(%{jam_id: jam_id, tick: tick}) do
    Process.send_after(self, :tick, 333)
    {:ok, %{jam_id: jam_id, tick: tick + 1}}
  end

  def handle_info(:tick, %{jam_id: jam_id, tick: tick}) do
    Process.send_after(self, :tick, 333)
    BadMammaJamma.Endpoint.broadcast_from! self(), "jam:room:#{jam_id}",
      "metronome_tick", %{jam_id: jam_id, tick: tick}
    {:noreply, %{jam_id: jam_id, tick: tick + 1}}
  end
end
