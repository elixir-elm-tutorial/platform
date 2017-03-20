defmodule Platform.Games.Game do
  use Ecto.Schema
  
  schema "games_games" do
    field :title, :string
    field :description, :string
    field :author_id, :integer

    timestamps()
  end
end
