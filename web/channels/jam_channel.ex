defmodule BadMammaJamma.JamChannel do
  use Phoenix.Channel

  def join("jam:room", message, socket) do
    {:ok, socket}
  end
end
