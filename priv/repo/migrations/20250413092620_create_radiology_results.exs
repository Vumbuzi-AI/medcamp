defmodule Medcamp.Repo.Migrations.CreateRadiologyResults do
  use Ecto.Migration

  def change do
    create table(:radiology_results) do
      add :description, :text
      add :payment_type, :string
      add :total_amount_paid, :integer
      add :has_paid, :boolean, default: false, null: false
      add :findings, :text
      add :radiology_report, :text
      add :scans, :jsonb, default: "[]"
      add :report_complete, :boolean, default: false, null: false
      add :doctor_id, references(:users, on_delete: :nothing)
      add :doctor_note_id, references(:doctor_notes, on_delete: :nothing)
      add :radiologist_id, references(:users, on_delete: :nothing)
      add :patient_id, references(:patients, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:radiology_results, [:doctor_id])
    create index(:radiology_results, [:doctor_note_id])
    create index(:radiology_results, [:radiologist_id])
  end
end
