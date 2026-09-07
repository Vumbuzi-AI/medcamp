defmodule Medcamp.Repo.Migrations.CreateDepartments do
  use Ecto.Migration

  def change do
    create table(:departments) do
      add :name, :string, null: false
      add :code, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:departments, [:code])
  end
end
