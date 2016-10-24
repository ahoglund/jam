defmodule BadMammaJamma.JamChannel do
  use BadMammaJamma.Web, :channel

  def join("jam:room:" <> jam_id, _message, socket) do
    BadMammaJamma.Metronome.start_link(jam_id)
    {:ok, assign(socket, :jam_id, String.to_integer(jam_id))}
  end
end
