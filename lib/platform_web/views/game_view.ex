defmodule PlatformWeb.GameView do
  use PlatformWeb, :view
  alias PlatformWeb.GameView

  def render("index.json", %{games: games}) do
    %{data: render_many(games, GameView, "game.json")}
  end

  def render("show.json", %{game: game}) do
    %{data: render_one(game, GameView, "game.json")}
  end

  def render("game.json", %{game: game}) do
    %{id: game.id,
      description: game.description,
      featured: game.featured,
      thumbnail: game.thumbnail,
      title: game.title}
  end
end
