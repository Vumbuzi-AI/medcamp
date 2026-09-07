defmodule Medcamp.Batches.Batch do
  use Ecto.Schema
  import Ecto.Changeset

  schema "batches" do
    field :serial, :string
    field :gtin, :string
    field :batch, :string
    field :expiry, :string
    field :manufacturer, :string
    field :cost_per_unit, :integer
    field :uom, :string
    field :weight, :float
    field :received_date, :date, default: Date.utc_today()
    field :remaining_quantity, :integer
    field :quantity, :integer
    field :price_per_unit, :integer
    field :has_been_issued, :boolean, default: false
    belongs_to :inventory_received, Medcamp.InventoriesReceived.InventoryReceived
    belongs_to :supplier, Medcamp.Suppliers.Supplier
    field :inventory_manager_id, :id
    field :manufacture_date, :date

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(batch, attrs) do
    batch
    |> cast(attrs, [
      :gtin,
      :batch,
      :expiry,
      :price_per_unit,
      :received_date,
      :cost_per_unit,
      :manufacturer,
      :has_been_issued,
      :serial,
      :uom,
      :weight,
      :quantity,
      :remaining_quantity,
      :manufacture_date,
      :inventory_received_id,
      :inventory_manager_id,
      :supplier_id
    ])
    |> validate_required([:gtin, :batch, :quantity])
  end
end
