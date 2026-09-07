defmodule Medcamp.Repo.Migrations.CreateDrugs do
  use Ecto.Migration

  def change do
    create table(:drugs) do
      add :inventory_manager_id, references(:users, on_delete: :nothing)
      timestamps(type: :utc_datetime)
    end
  end
end
