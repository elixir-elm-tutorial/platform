defmodule Platform.Web.Router do
  use Platform.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Platform.Web.PlayerAuthController, repo: Platform.Repo
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Platform.Web do
    pipe_through :browser

    get "/", PageController, :index
    resources "/players", PlayerController
    resources "/sessions", PlayerSessionController, only: [:new, :create, :delete]
  end

  scope "/api", Platform.Web do
    pipe_through :api

    resources "/games", GameController, except: [:new, :edit]
  end
end
