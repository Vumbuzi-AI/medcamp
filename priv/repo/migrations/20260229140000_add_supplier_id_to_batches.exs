defmodule Medcamp.Repo.Migrations.AddSupplierIdToBatches do
  use Ecto.Migration

  def change do
    alter table(:batches) do
      add :supplier_id, references(:suppliers, on_delete: :nilify_all)
    end

    create index(:batches, [:supplier_id])
  end
end
