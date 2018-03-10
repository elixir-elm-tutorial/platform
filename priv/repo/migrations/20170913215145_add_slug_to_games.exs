defmodule Platform.Repo.Migrations.AddSlugToGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add(:slug, :string)
    end

    create(unique_index(:games, [:slug]))
  end
end
