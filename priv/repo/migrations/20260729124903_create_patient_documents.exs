defmodule Medcamp.Repo.Migrations.CreatePatientDocuments do
  use Ecto.Migration

  def change do
    create table(:patient_documents) do
      add :document_name, :string
      add :document_type, :string
      add :file_path, :string
      add :content_type, :string

      add :patient_id,
          references(:patients, on_delete: :delete_all),
          null: false

      timestamps(type: :utc_datetime)
    end

    create index(:patient_documents, [:patient_id])
  end
end
