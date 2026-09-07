defmodule Medcamp.Repo.Migrations.AddSupplierIdToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :supplier_id, references(:suppliers, on_delete: :nilify_all)
    end

    create index(:users, [:supplier_id])
  end
end
