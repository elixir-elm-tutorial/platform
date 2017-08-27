defmodule PlatformWeb.PlayerApiView do
  use PlatformWeb, :view
  alias PlatformWeb.PlayerApiView

  def render("index.json", %{players: players}) do
    %{data: render_many(players, PlayerApiView, "player.json")}
  end

  def render("show.json", %{player: player}) do
    %{data: render_one(player, PlayerApiView, "player.json")}
  end

  def render("player.json", %{player: player}) do
    %{id: player.id,
      username: player.username,
      display_name: player.display_name,
      score: player.score}
  end
end
