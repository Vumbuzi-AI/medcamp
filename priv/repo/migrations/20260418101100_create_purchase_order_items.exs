defmodule Medcamp.Repo.Migrations.CreatePurchaseOrderItems do
  use Ecto.Migration

  def change do
    create table(:purchase_order_items) do
      add :purchase_order_id, references(:purchase_orders, on_delete: :delete_all), null: false
      add :rfq_item_id, references(:rfq_items, on_delete: :nilify_all)
      add :position, :integer
      add :description, :text
      add :unit, :string
      add :quantity, :decimal, precision: 15, scale: 3
      add :unit_price, :decimal, precision: 15, scale: 2
      add :total, :decimal, precision: 15, scale: 2

      timestamps(type: :utc_datetime)
    end

    create index(:purchase_order_items, [:purchase_order_id])
  end
end
