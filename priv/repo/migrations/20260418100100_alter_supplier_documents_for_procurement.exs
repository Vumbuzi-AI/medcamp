defmodule Medcamp.Repo.Migrations.AlterSupplierDocumentsForProcurement do
  use Ecto.Migration

  def change do
    alter table(:supplier_documents) do
      add :reference_number, :string
      add :file_name, :string
      add :file_size, :integer
      add :verified, :boolean, default: false, null: false
      add :verified_by_id, references(:users, on_delete: :nilify_all)
    end

    create unique_index(:supplier_documents, [:supplier_id, :document_type])
    create index(:supplier_documents, [:verified_by_id])
  end
end
