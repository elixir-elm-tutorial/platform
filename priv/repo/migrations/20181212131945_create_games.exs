defmodule Platform.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table(:games) do
      add :description, :string
      add :featured, :boolean, default: false, null: false
      add :thumbnail, :string
      add :title, :string

      timestamps()
    end

  end
end
