defmodule BadMammaJamma.Metronome do
  use GenServer

  def set_bpm(pid, bpm), do: GenServer.cast(pid, {:set_bpm, bpm})

  def get_bpm(pid), do: GenServer.call(pid, :get_bpm)

  def start_link(jam_id) do
    GenServer.start_link(__MODULE__, %{jam_id: jam_id, tick: 1, bpm: 120}, name: {:global, "jam_#{jam_id}_metronome"} )
  end

  def init(%{jam_id: jam_id, tick: tick, bpm: bpm}) do
    Process.send_after(self, :tick, calculate(tick,bpm))
    {:ok, %{jam_id: jam_id, tick: tick + 1, bpm: bpm}}
  end

  def handle_info(:tick, %{jam_id: jam_id, tick: tick, bpm: bpm}) do
    Process.send_after(self, :tick, calculate(tick,bpm))
    BadMammaJamma.Endpoint.broadcast_from! self(), "jam:room:#{jam_id}",
      "metronome_tick", %{jam_id: jam_id, tick: tick, bpm: bpm}
    {:noreply, %{jam_id: jam_id, tick: tick + 1, bpm: bpm}}
  end

  def handle_cast({:set_bpm, bpm}, state) do
    {:noreply, %{ state | bpm: bpm }}
  end

  def handle_call(:get_bpm, _from, state) do
    {:reply, state, state}
  end

  defp calculate(_tick, bpm) do
    div(div(60_000, bpm), 4)
  end
end
