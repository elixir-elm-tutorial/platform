defmodule Platform.Products.Game do
  use Ecto.Schema
  import Ecto.Changeset

  alias Platform.Products.Gameplay
  alias Platform.Accounts.Player

  schema "games" do
    many_to_many :players, Player, join_through: Gameplay

    field :description, :string
    field :featured, :boolean, default: false
    field :thumbnail, :string
    field :title, :string

    timestamps()
  end

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, [:description, :featured, :thumbnail, :title])
    |> validate_required([:description, :featured, :thumbnail, :title])
  end
end
