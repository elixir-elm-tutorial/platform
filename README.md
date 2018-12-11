# Platform

This repository contains the source code for
[elixir-elm-tutorial.herokuapp.com](https://elixir-elm-tutorial.herokuapp.com),
which is the demo application from the
[Elixir and Elm Tutorial](https://leanpub.com/elixir-elm-tutorial).

## Requirements

- Elixir 1.7
- Phoenix 1.4
- Elm 0.19

## Setup

1. `git clone https://github.com/elixir-and-elm-tutorial/platform.git`
2. `mix deps.get` to install Phoenix dependencies.
3. `config/dev.exs` and `config/test.exs` to configure local database.
4. `mix ecto.setup` to create, migrate, and seed the database.
5. `cd assets && npm install` to install Node dependencies.
6. `mix phx.server` to start Phoenix server.
7. `localhost:4000` to see application!

## Need Help?

- Open a [GitHub Issue](https://github.com/elixir-elm-tutorial/platform/issues).
- Email me at `bijanbwb@gmail.com`.
