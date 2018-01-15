defmodule Platform.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table(:games) do
      add :title, :string
      add :description, :string
      add :thumbnail, :string
      add :featured, :boolean, default: false, null: false

      timestamps()
    end

    create table(:gameplays) do
      add :game_id, references(:games, on_delete: :nothing), null: false
      add :player_id, references(:players, on_delete: :nothing), null: false
      add :player_score, :integer

      timestamps()
    end
  end
end
