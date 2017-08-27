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
      title: game.title,
      description: game.description,
      thumbnail: game.thumbnail,
      featured: game.featured}
  end
end
