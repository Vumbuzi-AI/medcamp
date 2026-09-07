defmodule Medcamp.Repo.Migrations.ChangeReferencesForPatients do
  use Ecto.Migration

  def change do
    alter table(:drug_allocations) do
      modify :patient_id, :id, null: false
    end

    execute "ALTER TABLE drug_allocations DROP CONSTRAINT IF EXISTS drug_allocations_patient_id_fkey"

    alter table(:drug_allocations) do
      modify :patient_id, references(:patients, on_delete: :delete_all)
    end
  end
end
