defmodule Medcamp.Repo.Migrations.CreateProcedure do
  use Ecto.Migration

  def change do
    create table(:procedure) do
      add :name, :string
      add :price, :integer
      add :description, :text
      add :user_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:procedure, [:user_id])
  end
end
