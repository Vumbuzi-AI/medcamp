defmodule Medcamp.Repo.Migrations.CreateDoctorNotes do
  use Ecto.Migration

  def change do
    create table(:doctor_notes) do
      add :date, :date
      add :reason_for_consulatation, :text
      add :symptoms, :text
      add :prescribed_medication, :text
      add :lifestyle_recommendations, :text
      add :lab_imaging_request, :string
      add :doctor_id, references(:users, on_delete: :nothing)
      add :patient_id, references(:patients, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:doctor_notes, [:doctor_id])
    create index(:doctor_notes, [:patient_id])
  end
end
