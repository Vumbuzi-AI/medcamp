defmodule Medcamp.Repo.Migrations.AddDiagnosisIcdCodeToDoctorNotes do
  use Ecto.Migration

  def change do
    alter table(:doctor_notes) do
      add :diagnosis_icd_code, :string
    end
  end
end
