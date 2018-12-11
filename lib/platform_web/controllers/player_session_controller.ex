defmodule PlatformWeb.PlayerSessionController do
  use PlatformWeb, :controller

  def new(conn, _) do
    render(conn, "new.html")
  end

  def create(conn, %{"session" => %{"username" => user, "password" => pass}}) do
    case PlatformWeb.PlayerAuthController.sign_in_with_username_and_password(
           conn,
           user,
           pass,
           repo: Platform.Repo
         ) do
      {:ok, conn} ->
        conn
        |> put_flash(:info, "Welcome back!")
        |> redirect(to: Routes.page_path(conn, :index))

      {:error, _reason, conn} ->
        conn
        |> put_flash(:error, "Invalid username/password combination.")
        |> render("new.html")
    end
  end

  def delete(conn, _) do
    conn
    |> PlatformWeb.PlayerAuthController.sign_out()
    |> redirect(to: Routes.player_session_path(conn, :new))
  end
end
