defmodule Medcamp.Procurement.ShipmentItem do
  use Ecto.Schema
  import Ecto.Changeset

  @temperature_requirements ~w(ambient cold_chain)

  schema "shipment_items" do
    field :position, :integer
    field :description, :string
    field :unit, :string
    field :quantity_shipped, :decimal
    field :batch_number, :string
    field :expiry_date, :date
    field :temperature_requirement, :string, default: "ambient"

    belongs_to :shipment_advice, Medcamp.Procurement.ShipmentAdvice
    belongs_to :purchase_order_item, Medcamp.Procurement.PurchaseOrderItem
    belongs_to :inventory_received, Medcamp.InventoriesReceived.InventoryReceived

    timestamps(type: :utc_datetime)
  end

  def temperature_requirements, do: @temperature_requirements

  def changeset(item, attrs) do
    item
    |> cast(attrs, [
      :shipment_advice_id,
      :purchase_order_item_id,
      :position,
      :description,
      :unit,
      :quantity_shipped,
      :batch_number,
      :expiry_date,
      :temperature_requirement,
      :inventory_received_id
    ])
    |> validate_required([:shipment_advice_id, :description])
    |> validate_inclusion(:temperature_requirement, @temperature_requirements)
    |> foreign_key_constraint(:shipment_advice_id)
    |> foreign_key_constraint(:inventory_received_id)
  end
end
