defmodule PlatformWeb.GameController do
  use PlatformWeb, :controller

  alias Platform.Products
  alias Platform.Products.Game

  action_fallback PlatformWeb.FallbackController

  def index(conn, _params) do
    games = Products.list_games()
    render(conn, "index.json", games: games)
  end

  def create(conn, %{"game" => game_params}) do
    with {:ok, %Game{} = game} <- Products.create_game(game_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", game_path(conn, :show, game))
      |> render("show.json", game: game)
    end
  end

  def show(conn, %{"id" => id}) do
    game = Products.get_game!(id)
    render(conn, "show.json", game: game)
  end

  def update(conn, %{"id" => id, "game" => game_params}) do
    game = Products.get_game!(id)

    with {:ok, %Game{} = game} <- Products.update_game(game, game_params) do
      render(conn, "show.json", game: game)
    end
  end

  def delete(conn, %{"id" => id}) do
    game = Products.get_game!(id)
    with {:ok, %Game{}} <- Products.delete_game(game) do
      send_resp(conn, :no_content, "")
    end
  end
end
