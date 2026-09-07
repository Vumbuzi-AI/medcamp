defmodule Medcamp.Procurement.RfqItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rfq_items" do
    field :position, :integer
    field :description, :string
    field :category, :string
    field :unit, :string
    field :quantity_required, :decimal
    field :estimated_unit_price, :decimal

    belongs_to :rfq, Medcamp.Procurement.Rfq
    belongs_to :inventory_received, Medcamp.InventoriesReceived.InventoryReceived

    timestamps(type: :utc_datetime)
  end

  def changeset(item, attrs) do
    item
    |> cast(attrs, [
      :rfq_id,
      :position,
      :description,
      :category,
      :unit,
      :quantity_required,
      :estimated_unit_price,
      :inventory_received_id
    ])
    |> validate_required([:description, :quantity_required])
    |> validate_number(:quantity_required, greater_than: 0)
    |> foreign_key_constraint(:rfq_id)
    |> foreign_key_constraint(:inventory_received_id)
  end
end
