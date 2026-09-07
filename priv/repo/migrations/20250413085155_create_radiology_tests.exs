defmodule Medcamp.Repo.Migrations.CreateRadiologyTests do
  use Ecto.Migration

  def change do
    create table(:radiology_tests) do
      add :name, :string
      add :description, :text
      add :price, :integer
      add :creator_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:radiology_tests, [:creator_id])
  end
end
