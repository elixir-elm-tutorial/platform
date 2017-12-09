defmodule PlatformWeb.ScoreChannel do
  use PlatformWeb, :channel

  alias Platform.Products

  def join("score:" <> game_slug, payload, socket) do
    if authorized?(payload) do
      Products.get_game_by_slug!(game_slug)
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # Save score to the database as Gameplay record.
  def handle_in("save_score", %{"player_score" => player_score} = payload, socket) do
    Products.create_gameplay(%{player_id: socket.assigns.player_id, game_id: socket.assigns.game_id, player_score: player_score})
    broadcast(socket, "sync_score", payload)
    {:noreply, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (score:lobby).
  def handle_in("shout", payload, socket) do
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
