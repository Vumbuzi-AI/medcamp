defmodule Medcamp.Repo.Migrations.CreateSubsidizedProcedures do
  use Ecto.Migration

  def change do
    create table(:subsidized_procedures) do
      add :name, :string
      add :description, :string
      add :price, :integer
      add :user_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:subsidized_procedures, [:user_id])
  end
end
