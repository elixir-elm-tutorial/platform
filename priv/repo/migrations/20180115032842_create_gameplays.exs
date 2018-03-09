defmodule Platform.Repo.Migrations.CreateGameplays do
  use Ecto.Migration

  def change do
    create table(:gameplays) do
      add(:player_score, :integer)
      add(:game_id, references(:games, on_delete: :nothing))
      add(:player_id, references(:players, on_delete: :nothing))

      timestamps()
    end

    create(index(:gameplays, [:game_id]))
    create(index(:gameplays, [:player_id]))
  end
end
