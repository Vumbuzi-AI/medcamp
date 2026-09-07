defmodule Medcamp.Procurement.QuoteItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "quote_items" do
    field :position, :integer
    field :unit, :string
    field :quantity_available, :decimal
    field :unit_price, :decimal
    field :total, :decimal
    field :batch_number, :string
    field :brand_origin, :string
    field :expiry_date, :date

    belongs_to :quote, Medcamp.Procurement.Quote
    belongs_to :rfq_item, Medcamp.Procurement.RfqItem
    belongs_to :inventory_received, Medcamp.InventoriesReceived.InventoryReceived

    timestamps(type: :utc_datetime)
  end

  def changeset(item, attrs) do
    item
    |> cast(attrs, [
      :quote_id,
      :rfq_item_id,
      :position,
      :unit,
      :quantity_available,
      :unit_price,
      :total,
      :batch_number,
      :brand_origin,
      :expiry_date,
      :inventory_received_id
    ])
    |> validate_required([:quote_id, :rfq_item_id])
    |> foreign_key_constraint(:quote_id)
    |> foreign_key_constraint(:rfq_item_id)
    |> foreign_key_constraint(:inventory_received_id)
  end
end
