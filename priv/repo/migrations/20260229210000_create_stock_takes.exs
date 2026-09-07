defmodule Medcamp.Repo.Migrations.CreateStockTakes do
  use Ecto.Migration

  def change do
    create table(:stock_takes) do
      add :date, :date, null: false
      add :notes, :text
      add :status, :string, null: false, default: "draft"
      add :admin_id, references(:users, on_delete: :nothing), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:stock_takes, [:admin_id])
    create index(:stock_takes, [:status])
  end
end
