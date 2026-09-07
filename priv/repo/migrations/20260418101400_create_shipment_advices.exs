defmodule Medcamp.Repo.Migrations.CreateShipmentAdvices do
  use Ecto.Migration

  def change do
    create table(:shipment_advices) do
      add :reference, :string, null: false
      add :purchase_order_id, references(:purchase_orders, on_delete: :restrict), null: false
      add :invoice_id, references(:invoices, on_delete: :restrict), null: false
      add :supplier_id, references(:suppliers, on_delete: :restrict), null: false
      add :dispatch_date, :date
      add :estimated_delivery_date, :date
      add :carrier, :string
      add :waybill_number, :string
      add :number_of_packages, :integer
      add :total_weight_kg, :decimal, precision: 10, scale: 2
      add :delivery_instructions, :text
      add :status, :string, default: "submitted", null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:shipment_advices, [:reference])
    create index(:shipment_advices, [:purchase_order_id])
    create index(:shipment_advices, [:invoice_id])
    create index(:shipment_advices, [:supplier_id])
    create index(:shipment_advices, [:status])
  end
end
