defmodule BadMammaJamma.Metronome do
  use GenServer

  def inc(pid), do: GenServer.cast(pid, :inc)

  def dec(pid), do: GenServer.cast(pid, :dec)

  def val(pid) do
    GenServer.call(pid, :val)
  end

  def start_link(bpm) do
    GenServer.start_link(__MODULE__, bpm)
  end

  def init(bpm) do
    start_clock(bpm)
    {:ok, bpm}
  end

  def handle_info(:tick, val) when val <= 0, do: raise "boom!"

  def handle_info(:tick, val) do
    IO.puts "tick #{val}"
    Process.send_after(self, :tick, 1000)
    {:noreply, val - 1}
  end

  def handle_cast(:inc, val) do
    {:noreply, val + 1}
  end

  def handle_cast(:dec, val) do
    {:noreply, val - 1}
  end

  def handle_call(:val, _from, val) do
    {:reply, val, val}
  end

  defp start_clock(bpm) do
    :timer.send_interval(bpm, :metronome_tick)
  end
end
