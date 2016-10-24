defmodule BadMammaJamma.JamChannel do
  use BadMammaJamma.Web, :channel

  def join("jam:room:" <> jam_id, _message, socket) do
    BadMammaJamma.Metronome.start_link(jam_id)
    {:ok, assign(socket, :jam_id, String.to_integer(jam_id))}
  end

  def handle_in("update_cell", %{"track_id" => track_id, "is_active" => is_active, "id" => id}, socket) do
    broadcast! socket, "update_cell", %{id: id, track_id: track_id, is_active: is_active}
    {:noreply, socket}
  end

  def handle_in("update_bpm", %{"bpm" => bpm}, socket) do
    GenServer.cast({:global, "jam_#{socket.assigns[:jam_id]}_metronome"}, {:set_bpm, bpm})
    broadcast! socket, "update_bpm", %{bpm: bpm}
    {:noreply, socket}
  end
end
