defmodule Medcamp.Repo.Migrations.CreateSupplierDocuments do
  use Ecto.Migration

  def change do
    create table(:supplier_documents) do
      add :document_type, :string, null: false
      add :file_path, :string, null: false
      add :original_filename, :string
      add :supplier_id, references(:suppliers, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:supplier_documents, [:supplier_id])
  end
end
