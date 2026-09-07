defmodule Medcamp.Procurement.GrnItem do
  use Ecto.Schema
  import Ecto.Changeset

  @conditions ~w(accepted partial rejected)

  schema "grn_items" do
    field :position, :integer
    field :description, :string
    field :po_quantity, :decimal
    field :quantity_received, :decimal
    field :variance, :decimal
    field :batch_number, :string
    field :expiry_date, :date
    field :condition, :string, default: "accepted"

    belongs_to :grn, Medcamp.Procurement.GoodsReceivedNote
    belongs_to :purchase_order_item, Medcamp.Procurement.PurchaseOrderItem
    belongs_to :inventory_received, Medcamp.InventoriesReceived.InventoryReceived

    timestamps(type: :utc_datetime)
  end

  def conditions, do: @conditions

  def changeset(item, attrs) do
    item
    |> cast(attrs, [
      :grn_id,
      :purchase_order_item_id,
      :position,
      :description,
      :po_quantity,
      :quantity_received,
      :variance,
      :batch_number,
      :expiry_date,
      :condition,
      :inventory_received_id
    ])
    |> validate_required([:grn_id, :purchase_order_item_id, :condition])
    |> validate_inclusion(:condition, @conditions)
    |> compute_variance()
    |> foreign_key_constraint(:grn_id)
    |> foreign_key_constraint(:inventory_received_id)
  end

  defp compute_variance(changeset) do
    po_qty = get_field(changeset, :po_quantity)
    received = get_field(changeset, :quantity_received)

    if is_struct(po_qty, Decimal) and is_struct(received, Decimal) do
      put_change(changeset, :variance, Decimal.sub(po_qty, received))
    else
      changeset
    end
  end
end
