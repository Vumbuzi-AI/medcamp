defmodule Medcamp.Repo.Migrations.AddGeneralInventoryItemIdToRequisitions do
  use Ecto.Migration

  def change do
    alter table(:requisitions) do
      add :general_inventory_item_id,
          references(:general_inventory_items, on_delete: :nilify_all)
    end

    create index(:requisitions, [:general_inventory_item_id])
  end
end
