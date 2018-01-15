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
  end
end
