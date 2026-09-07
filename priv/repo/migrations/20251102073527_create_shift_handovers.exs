defmodule Medcamp.Repo.Migrations.CreateShiftHandovers do
  use Ecto.Migration

  def change do
    create table(:shift_handovers) do
      add :shift_date, :date
      add :shift_type, :string
      add :department, :string
      add :handover_from, :string
      add :handover_to, :string
      add :patient_count, :integer
      add :admissions, :integer
      add :discharges, :integer
      add :patient_updates, :text
      add :pending_tasks, :text
      add :equipment_issues, :text
      add :incidents, :text
      add :notes, :text
      add :status, :string
      add :submitted_at, :utc_datetime
      add :acknowledged_at, :utc_datetime
      add :submitted_by_id, references(:users, on_delete: :nothing)
      add :acknowledged_by_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:shift_handovers, [:submitted_by_id])
    create index(:shift_handovers, [:acknowledged_by_id])
  end
end
