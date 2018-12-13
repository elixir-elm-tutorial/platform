defmodule PlatformWeb.Router do
  use PlatformWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug PlatformWeb.PlayerAuthController, repo: Platform.Repo
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PlatformWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/games/:id", GameController, :play
    resources "/players", PlayerController
    resources "/sessions", PlayerSessionController, only: [:new, :create, :delete]
  end

  scope "/api", PlatformWeb do
    pipe_through :api

    resources "/games", GameController, except: [:new, :edit]
    resources "/gameplays", GameplayController, except: [:new, :edit]
    resources "/players", PlayerApiController, except: [:new, :edit]
  end
end
