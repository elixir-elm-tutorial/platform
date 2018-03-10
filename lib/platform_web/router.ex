defmodule PlatformWeb.Router do
  use PlatformWeb, :router
  use Plug.ErrorHandler

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(PlatformWeb.PlayerAuthController, repo: Platform.Repo)
    plug(:put_user_token)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", PlatformWeb do
    pipe_through(:browser)

    get("/", PageController, :index)
    get("/games/:slug", GameController, :play)
    resources("/players", PlayerController)
    resources("/sessions", PlayerSessionController, only: [:new, :create, :delete])
  end

  scope "/api", PlatformWeb do
    pipe_through(:api)

    resources("/players", PlayerApiController, except: [:new, :edit])
    resources("/games", GameController, except: [:new, :edit])
    resources("/gameplays", GameplayController, except: [:new, :edit])
  end

  defp handle_errors(conn, %{kind: kind, reason: reason, stack: stacktrace}) do
    Rollbax.report(kind, reason, stacktrace, %{params: conn.params})
  end

  defp put_user_token(conn, _) do
    if current_user = conn.assigns[:current_user] do
      token = Phoenix.Token.sign(conn, "user socket", current_user.id)
      assign(conn, :user_token, token)
    else
      conn
    end
  end
end
