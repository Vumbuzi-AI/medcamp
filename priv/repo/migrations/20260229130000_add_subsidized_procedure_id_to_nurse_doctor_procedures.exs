defmodule Medcamp.Repo.Migrations.AddSubsidizedProcedureIdToNurseDoctorProcedures do
  use Ecto.Migration

  def change do
    alter table(:nurse_procedures) do
      add :subsidized_procedure_id, references(:subsidized_procedures, on_delete: :nothing)
    end

    alter table(:doctor_procedures) do
      add :subsidized_procedure_id, references(:subsidized_procedures, on_delete: :nothing)
    end

    create index(:nurse_procedures, [:subsidized_procedure_id])
    create index(:doctor_procedures, [:subsidized_procedure_id])
  end
end
