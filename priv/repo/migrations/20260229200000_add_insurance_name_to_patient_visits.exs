defmodule Medcamp.Repo.Migrations.AddInsuranceNameToPatientVisits do
  use Ecto.Migration

  def change do
    alter table(:patient_visits) do
      add :insurance_name, :string
    end
  end
end
