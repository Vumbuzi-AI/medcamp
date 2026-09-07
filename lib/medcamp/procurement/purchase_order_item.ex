defmodule Medcamp.Procurement.PurchaseOrderItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "purchase_order_items" do
    field :position, :integer
    field :description, :string
    field :unit, :string
    field :quantity, :decimal
    field :unit_price, :decimal
    field :total, :decimal

    belongs_to :purchase_order, Medcamp.Procurement.PurchaseOrder
    belongs_to :rfq_item, Medcamp.Procurement.RfqItem
    belongs_to :inventory_received, Medcamp.InventoriesReceived.InventoryReceived

    timestamps(type: :utc_datetime)
  end

  def changeset(item, attrs) do
    item
    |> cast(attrs, [
      :purchase_order_id,
      :rfq_item_id,
      :position,
      :description,
      :unit,
      :quantity,
      :unit_price,
      :total,
      :inventory_received_id
    ])
    |> validate_required([:purchase_order_id, :description])
    |> foreign_key_constraint(:purchase_order_id)
    |> foreign_key_constraint(:inventory_received_id)
  end
end
