defmodule Platform.Products.Gameplay do
  use Ecto.Schema
  import Ecto.Changeset
  alias Platform.Products.Gameplay
  alias Platform.Products.Game
  alias Platform.Accounts.Player

  schema "gameplays" do
    belongs_to :game, Game
    belongs_to :player, Player

    field :player_score, :integer, default: 0

    timestamps()
  end

  @doc false
  def changeset(%Gameplay{} = gameplay, attrs) do
    gameplay
    |> cast(attrs, [:game_id, :player_id, :player_score])
    |> validate_required([:game_id, :player_id, :player_score])
  end
end
