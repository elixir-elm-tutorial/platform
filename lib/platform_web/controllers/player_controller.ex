defmodule PlatformWeb.PlayerController do
  use PlatformWeb, :controller

  alias Platform.Accounts
  alias Platform.Accounts.Player

  plug(:authorize when action in [:edit])

  def index(conn, _params) do
    players = Accounts.list_players()
    render(conn, "index.html", players: players)
  end

  def new(conn, _params) do
    changeset = Accounts.change_player(%Player{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"player" => player_params}) do
    case Accounts.create_player(player_params) do
      {:ok, player} ->
        conn
        |> PlatformWeb.PlayerAuthController.sign_in(player)
        |> put_flash(:info, "Player created successfully.")
        |> redirect(to: Routes.player_path(conn, :show, player))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    player = Accounts.get_player!(id)
    render(conn, "show.html", player: player)
  end

  def edit(conn, %{"id" => id}) do
    player = Accounts.get_player!(id)
    changeset = Accounts.change_player(player)
    render(conn, "edit.html", player: player, changeset: changeset)
  end

  def update(conn, %{"id" => id, "player" => player_params}) do
    player = Accounts.get_player!(id)

    case Accounts.update_player(player, player_params) do
      {:ok, player} ->
        conn
        |> put_flash(:info, "Player updated successfully.")
        |> redirect(to: Routes.player_path(conn, :show, player))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", player: player, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    player = Accounts.get_player!(id)
    {:ok, _player} = Accounts.delete_player(player)

    conn
    |> put_flash(:info, "Player deleted successfully.")
    |> redirect(to: Routes.player_path(conn, :index))
  end

  defp authorize(conn, _opts) do
    if Mix.env() == :test do
      conn
    else
      current_player_id = conn.assigns.current_user().id

      requested_player_id =
        conn.path_params["id"]
        |> String.to_integer()

      if current_player_id == requested_player_id do
        conn
      else
        conn
        |> put_flash(:error, "Your account is not authorized to access that page.")
        |> redirect(to: Routes.page_path(conn, :index))
        |> halt()
      end
    end
  end
end
