defmodule Platform.Repo.Migrations.CreateGameplays do
  use Ecto.Migration

  def change do
    create index(:gameplays, [:game_id])
    create index(:gameplays, [:player_id])
  end
end
