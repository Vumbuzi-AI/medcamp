defmodule Medcamp.Repo.Migrations.CreateTriages do
  use Ecto.Migration

  def change do
    create table(:triages) do
      add :temperature, :float
      add :blood_pressure, :float
      add :pulse_rate, :float
      add :oxygen_saturation, :float
      add :height, :float
      add :weight, :float
      add :date, :date
      add :triage_notes, :text
      add :patient_id, references(:patients, on_delete: :nothing)
      add :creator_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:triages, [:patient_id])
    create index(:triages, [:creator_id])
  end
end
