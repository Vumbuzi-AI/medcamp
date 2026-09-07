defmodule Medcamp.Procurement.InvoiceItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "invoice_items" do
    field :position, :integer
    field :description, :string
    field :unit, :string
    field :quantity_delivered, :decimal
    field :unit_price, :decimal
    field :vat_rate, :decimal, default: Decimal.new("0.16")
    field :vat_amount, :decimal
    field :total, :decimal

    belongs_to :invoice, Medcamp.Procurement.Invoice
    belongs_to :purchase_order_item, Medcamp.Procurement.PurchaseOrderItem
    belongs_to :inventory_received, Medcamp.InventoriesReceived.InventoryReceived

    timestamps(type: :utc_datetime)
  end

  def changeset(item, attrs) do
    item
    |> cast(attrs, [
      :invoice_id,
      :purchase_order_item_id,
      :position,
      :description,
      :unit,
      :quantity_delivered,
      :unit_price,
      :vat_rate,
      :vat_amount,
      :total,
      :inventory_received_id
    ])
    |> validate_required([:invoice_id, :description])
    |> foreign_key_constraint(:invoice_id)
    |> foreign_key_constraint(:inventory_received_id)
  end
end
