defmodule Medcamp.Repo.Migrations.CreateLabConsumables do
  use Ecto.Migration

  def change do
    create table(:lab_consumables) do
      add :consumed_quantity, :string
      add :date, :string
      add :purpose, :string
      add :patient_id, references(:patients, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:lab_consumables, [:patient_id])
  end
end
