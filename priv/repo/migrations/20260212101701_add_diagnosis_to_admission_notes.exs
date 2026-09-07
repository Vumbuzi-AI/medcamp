defmodule Medcamp.Repo.Migrations.AddDiagnosisToAdmissionNotes do
  use Ecto.Migration

  def change do
    alter table(:admission_notes) do
      add :diagnosis, :string
      add :diagnosis_icd_code, :string
    end
  end
end
