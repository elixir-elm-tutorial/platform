defmodule Platform.Products.Game do
  @moduledoc """
  This module allows for creating game metadata and records on the
  platform's back-end, but all game development actually occurs in
  the Elm front-end.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Platform.Products.Game
  alias Platform.Products.Gameplay
  alias Platform.Accounts.Player

  schema "games" do
    many_to_many(:players, Player, join_through: Gameplay)

    field(:description, :string)
    field(:featured, :boolean, default: false)
    field(:slug, :string, unique: true)
    field(:thumbnail, :string)
    field(:title, :string)

    timestamps()
  end

  @doc false
  def changeset(%Game{} = game, attrs) do
    game
    |> cast(attrs, [:description, :featured, :slug, :thumbnail, :title])
    |> validate_required([:description, :featured, :slug, :thumbnail, :title])
    |> unique_constraint(:slug)
  end
end
