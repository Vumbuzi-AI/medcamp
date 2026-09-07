defmodule Medcamp.Repo.Migrations.CreateLabResults do
  use Ecto.Migration

  def change do
    create table(:lab_results) do
      add :name, :string
      add :tests, :jsonb, default: "[]"
      add :description, :text
      add :date_of_test, :date
      add :urgency, :string
      add :lab_report, :text
      add :test_findings, :text
      add :sample_collection_date, :date
      add :payment_type, :string
      add :total_amount_paid, :integer
      add :has_paid, :boolean, default: false
      add :sample_collection_description, :text
      add :technician_name, :string
      add :report_complete, :boolean, default: false, null: false
      add :doctor_note_id, references(:doctor_notes, on_delete: :nothing)
      add :patient_id, references(:patients, on_delete: :nothing)
      add :doctor_id, references(:users, on_delete: :nothing)
      add :lab_technician_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:lab_results, [:doctor_note_id])
    create index(:lab_results, [:patient_id])
    create index(:lab_results, [:doctor_id])
    create index(:lab_results, [:lab_technician_id])
  end
end
