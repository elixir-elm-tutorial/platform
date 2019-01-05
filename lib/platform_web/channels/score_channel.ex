defmodule PlatformWeb.ScoreChannel do
  use PlatformWeb, :channel

  def join("score:" <> game_slug, _payload, socket) do
    game = Platform.Products.get_game_by_slug!(game_slug)
    socket = assign(socket, :game_id, game.id)
    {:ok, socket}
  end

  # Broadcast for authenticated players
  def handle_in(
        "broadcast_score",
        %{"player_score" => player_score} = payload,
        %{assigns: %{game_id: game_id, player_id: player_id}} = socket
      ) do
    payload = %{
      game_id: game_id,
      player_id: player_id,
      player_score: player_score
    }

    IO.inspect(payload, label: "Broadcasting the score payload over the channel")
    broadcast(socket, "broadcast_score", payload)
    {:noreply, socket}
  end

  # Broadcast for anonymous players
  def handle_in("broadcast_score", payload, socket) do
    broadcast(socket, "broadcast_score", payload)
    {:noreply, socket}
  end

  # Save scores for authenticated players
  def handle_in(
        "save_score",
        %{"player_score" => player_score} = payload,
        %{assigns: %{game_id: game_id, player_id: player_id}} = socket
      ) do
    payload = %{
      game_id: game_id,
      player_id: player_id,
      player_score: player_score
    }

    IO.inspect(payload, label: "Saving the score payload to the database")
    Platform.Products.create_gameplay(payload)
    {:noreply, socket}
  end
end
