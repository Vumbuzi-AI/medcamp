defmodule Medcamp.Batches.Batch do
  use Ecto.Schema
  use Medcamp.Tenancy.Schema
  import Ecto.Changeset

  schema "batches" do
    tenant_field()

    field :serial, :string
    field :gtin, :string
    field :batch, :string
    field :expiry, :string
    field :manufacturer, :string
    field :uom, :string
    field :weight, :float
    field :received_date, :date, default: Date.utc_today()
    field :remaining_quantity, :integer
    field :quantity, :integer
    field :price_per_unit, :integer, default: 0
    belongs_to :inventory_received, Medcamp.InventoriesReceived.InventoryReceived
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
      :received_date,
      :manufacturer,
      :serial,
      :uom,
      :weight,
      :quantity,
      :remaining_quantity,
      :price_per_unit,
      :manufacture_date,
      :inventory_received_id,
      :inventory_manager_id
    ])
    |> validate_required([:gtin, :batch, :quantity])
    |> put_org_id()
  end
end
