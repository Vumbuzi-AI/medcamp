defmodule Medcamp.Repo.Migrations.AddPatientVisitIdToDoctorNotes do
  use Ecto.Migration

  def change do
    alter table(:doctor_notes) do
      add :patient_visit_id, references(:patient_visits, on_delete: :nilify_all)
    end

    create unique_index(:doctor_notes, [:patient_visit_id], where: "patient_visit_id IS NOT NULL")
  end
end
