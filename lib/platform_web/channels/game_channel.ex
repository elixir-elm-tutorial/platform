defmodule PlatformWeb.GameChannel do
  use PlatformWeb, :channel

  alias Platform.Products

  def join("game:" <> game_slug, _payload, socket) do
    game = Products.get_game_by_slug!(game_slug)
    socket = assign(socket, :game_id, game.id)
    {:ok, socket}
  end

  def handle_in("ball:position_x", %{"ball_position_x" => ball_position_x}, socket) do
    payload = %{ball_position_x: ball_position_x}
    broadcast(socket, "ball:position_x", payload)
    {:noreply, socket}
  end

  def handle_in("paddle:position_y", %{"paddle_position_y" => paddle_position_y}, socket) do
    payload = %{paddle_position_y: paddle_position_y}
    broadcast(socket, "paddle:position_y", payload)
    {:noreply, socket}
  end
end
