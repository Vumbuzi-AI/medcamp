defmodule Medcamp.Repo.Migrations.CreatePharmacyLogs do
  use Ecto.Migration

  def change do
    create table(:pharmacy_logs) do
      add :log_type, :string, null: false
      add :month, :integer, null: false
      add :year, :integer, null: false
      add :daily_entries, :map, default: %{}
      add :created_by_id, references(:users, on_delete: :nothing), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:pharmacy_logs, [:created_by_id])

    create unique_index(:pharmacy_logs, [:log_type, :month, :year],
             name: :unique_pharmacy_log_per_month
           )
  end
end
