defmodule Medcamp.Repo.Migrations.AddInventoryReceivedIdAndQuantityToRequisitions do
  use Ecto.Migration

  def change do
    alter table(:requisitions) do
      add :inventory_received_id, references(:inventories_received, on_delete: :nilify_all)
      add :quantity, :integer
    end

    create index(:requisitions, [:inventory_received_id])
  end
end
