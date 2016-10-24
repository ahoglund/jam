defmodule BadMammaJamma.UserSocket do
  use Phoenix.Socket

  ## Channels
  channel "jam:room:*", BadMammaJamma.JamChannel

  ## Transports
  transport :websocket, Phoenix.Transports.WebSocket
  # transport :longpoll, Phoenix.Transports.LongPoll

  def connect(_params, socket) do
    {:ok, socket}
  end

  def id(_socket), do: nil
end
