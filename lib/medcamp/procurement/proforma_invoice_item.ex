defmodule Medcamp.Procurement.ProformaInvoiceItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "proforma_invoice_items" do
    field :position, :integer
    field :description, :string
    field :unit, :string
    field :quantity, :decimal
    field :unit_price, :decimal
    field :discount_percent, :decimal, default: Decimal.new(0)
    field :discount_amount, :decimal, default: Decimal.new(0)
    field :total, :decimal

    belongs_to :proforma_invoice, Medcamp.Procurement.ProformaInvoice
    belongs_to :rfq_item, Medcamp.Procurement.RfqItem
    belongs_to :inventory_received, Medcamp.InventoriesReceived.InventoryReceived

    timestamps(type: :utc_datetime)
  end

  def changeset(item, attrs) do
    item
    |> cast(attrs, [
      :proforma_invoice_id,
      :rfq_item_id,
      :position,
      :description,
      :unit,
      :quantity,
      :unit_price,
      :discount_percent,
      :discount_amount,
      :total,
      :inventory_received_id
    ])
    |> validate_required([:proforma_invoice_id, :description])
    |> foreign_key_constraint(:proforma_invoice_id)
    |> foreign_key_constraint(:inventory_received_id)
  end
end
