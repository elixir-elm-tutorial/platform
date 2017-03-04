defmodule Platform.Players.Player do
  use Ecto.Schema
  
  schema "players_players" do
    field :username, :string
    field :score, :integer

    timestamps()
  end
end
