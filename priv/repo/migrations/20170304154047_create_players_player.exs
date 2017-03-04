defmodule Platform.Repo.Migrations.CreatePlatform.Players.Player do
  use Ecto.Migration

  def change do
    create table(:players_players) do
      add :username, :string
      add :score, :integer

      timestamps()
    end

  end
end
