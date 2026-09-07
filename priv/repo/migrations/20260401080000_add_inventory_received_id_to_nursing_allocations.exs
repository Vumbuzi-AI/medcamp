defmodule Medcamp.Repo.Migrations.AddInventoryReceivedIdToNursingAllocations do
  use Ecto.Migration

  def change do
    alter table(:nursing_allocations) do
      add :inventory_received_id, references(:inventories_received, on_delete: :nothing),
        null: true
    end

    create index(:nursing_allocations, [:allocated_to, :inventory_received_id])
  end
end
