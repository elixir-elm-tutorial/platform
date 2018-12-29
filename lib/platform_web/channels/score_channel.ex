defmodule PlatformWeb.ScoreChannel do
  use PlatformWeb, :channel

  def join("score:platformer", _payload, socket) do
    {:ok, socket}
  end

  def handle_in("broadcast_score", payload, socket) do
    broadcast(socket, "broadcast_score", payload)
    {:noreply, socket}
  end
end
