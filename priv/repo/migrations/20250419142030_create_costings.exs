defmodule Medcamp.Repo.Migrations.CreateCostings do
  use Ecto.Migration

  def change do
    create table(:costings) do
      add :type, :string
      add :price, :integer
      add :user_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:costings, [:user_id])
  end
end
