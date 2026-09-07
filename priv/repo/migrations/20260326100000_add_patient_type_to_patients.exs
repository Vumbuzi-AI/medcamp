defmodule Medcamp.Repo.Migrations.AddPatientTypeToPatients do
  use Ecto.Migration

  def change do
    alter table(:patients) do
      add :patient_type, :string
    end
  end
end
