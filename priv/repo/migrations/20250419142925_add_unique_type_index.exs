defmodule Medcamp.Repo.Migrations.AddUniqueTypeIndex do
  use Ecto.Migration

  def change do
    create unique_index(:costings, [:type])
  end
end
