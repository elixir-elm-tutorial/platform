defmodule Platform.Repo.Migrations.AddFieldsToPlayers do
  use Ecto.Migration

  def change do
    alter table(:players_players) do
      add :display_name, :string
      add :password, :string
      add :password_hash, :string
    end

    create unique_index(:players_players, [:username])
  end
end
