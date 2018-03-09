defmodule PlatformWeb.PlayerApiView do
  use PlatformWeb, :view
  alias PlatformWeb.PlayerApiView

  def render("index.json", %{players: players}) do
    %{data: render_many(players, PlayerApiView, "player.json")}
  end

  def render("show.json", %{player: player}) do
    %{data: render_one(player, PlayerApiView, "player.json")}
  end

  def render("player.json", %{player_api: player_api}) do
    %{
      id: player_api.id,
      username: player_api.username,
      display_name: player_api.display_name,
      score: player_api.score
    }
  end
end
