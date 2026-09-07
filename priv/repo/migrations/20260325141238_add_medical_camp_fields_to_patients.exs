defmodule Medcamp.Repo.Migrations.AddMedicalCampFieldsToPatients do
  use Ecto.Migration

  def change do
    alter table(:patients) do
      add :is_for_medical_camp, :boolean, default: false, null: false
      add :medical_camp_name, :string
    end
  end
end
