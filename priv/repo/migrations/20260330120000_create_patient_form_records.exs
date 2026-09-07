defmodule Medcamp.Repo.Migrations.CreatePatientFormRecords do
  use Ecto.Migration

  def change do
    create table(:patient_form_records) do
      add :patient_id, references(:patients, on_delete: :delete_all), null: false
      add :form_type, :string, null: false
      add :form_data, :map, null: false
      add :created_by_id, references(:users, on_delete: :nilify_all)
      add :updated_by_id, references(:users, on_delete: :nilify_all)
      timestamps()
    end

    create index(:patient_form_records, [:patient_id])
    create index(:patient_form_records, [:form_type])
  end
end
