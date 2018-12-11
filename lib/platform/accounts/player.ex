defmodule Platform.Accounts.Player do
  use Ecto.Schema
  import Ecto.Changeset


  schema "players" do
    field :display_name, :string
    field :password, :string, virtual: true
    field :password_digest, :string
    field :score, :integer, default: 0
    field :username, :string, unique: true

    timestamps()
  end

  @doc false
  def changeset(player, attrs) do
    player
    |> cast(attrs, [:display_name, :password, :score, :username])
    |> validate_required([:username])
    |> unique_constraint(:username)
  end
end
