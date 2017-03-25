defmodule Platform.Players.Player do
  @moduledoc """
  Schema for player data.
  """
  use Ecto.Schema

  schema "players_players" do
    field :display_name, :string
    field :username, :string
    field :score, :integer
    field :password, :string, virtual: true
    field :password_hash, :string

    timestamps()
  end
end
