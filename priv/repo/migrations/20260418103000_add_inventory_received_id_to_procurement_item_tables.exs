defmodule Medcamp.Repo.Migrations.AddInventoryReceivedIdToProcurementItemTables do
  use Ecto.Migration

  def change do
    alter table(:rfq_items) do
      add :inventory_received_id, references(:inventories_received, on_delete: :nilify_all)
    end

    alter table(:quote_items) do
      add :inventory_received_id, references(:inventories_received, on_delete: :nilify_all)
    end

    alter table(:proforma_invoice_items) do
      add :inventory_received_id, references(:inventories_received, on_delete: :nilify_all)
    end

    alter table(:purchase_order_items) do
      add :inventory_received_id, references(:inventories_received, on_delete: :nilify_all)
    end

    alter table(:invoice_items) do
      add :inventory_received_id, references(:inventories_received, on_delete: :nilify_all)
    end

    alter table(:shipment_items) do
      add :inventory_received_id, references(:inventories_received, on_delete: :nilify_all)
    end

    alter table(:grn_items) do
      add :inventory_received_id, references(:inventories_received, on_delete: :nilify_all)
    end

    create index(:rfq_items, [:inventory_received_id])
    create index(:quote_items, [:inventory_received_id])
    create index(:proforma_invoice_items, [:inventory_received_id])
    create index(:purchase_order_items, [:inventory_received_id])
    create index(:invoice_items, [:inventory_received_id])
    create index(:shipment_items, [:inventory_received_id])
    create index(:grn_items, [:inventory_received_id])
  end
end
