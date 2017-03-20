defmodule Platform.Repo.Migrations.CreatePlatform.Games.Game do
  use Ecto.Migration

  def change do
    create table(:games_games) do
      add :title, :string
      add :description, :string
      add :author_id, :integer

      timestamps()
    end

  end
end
