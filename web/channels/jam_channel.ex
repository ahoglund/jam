defmodule BadMammaJamma.JamChannel do
  use Phoenix.Channel

  def join("jam:open", message, socket) do
    {:ok, socket}
  end
end
