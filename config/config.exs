# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :platform,
  ecto_repos: [Platform.Repo]

# Configures the endpoint
config :platform, PlatformWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "/G9FWwO7YY3ToHR3udWaPFICtaTB5S4qMHFcdWOd0UxzY13quCgI3hvEWQnIXb2e",
  render_errors: [view: PlatformWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Platform.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
