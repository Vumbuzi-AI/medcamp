defmodule Medcamp.InventoryDisposals.InventoryDisposalItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "inventory_disposal_items" do
    field :entity_type, :string
    field :entity_id, :integer
    field :entity_name, :string
    field :category, :string
    field :available_quantity, :integer
    field :quantity, :integer
    field :uom, :string
    field :notes, :string
    field :has_been_applied, :boolean, default: false

    belongs_to :inventory_disposal, Medcamp.InventoryDisposals.InventoryDisposal

    timestamps(type: :utc_datetime)
  end

  def changeset(item, attrs) do
    item
    |> cast(attrs, [
      :entity_type,
      :entity_id,
      :entity_name,
      :category,
      :available_quantity,
      :quantity,
      :uom,
      :notes,
      :has_been_applied,
      :inventory_disposal_id
    ])
    |> validate_required([
      :entity_type,
      :entity_id,
      :entity_name,
      :available_quantity,
      :quantity,
      :inventory_disposal_id
    ])
    |> validate_inclusion(:entity_type, [
      "drug_batch",
      "lab_allocation",
      "nursing_allocation",
      "inventory_received"
    ])
    |> validate_number(:quantity, greater_than: 0)
    |> validate_requested_quantity()
    |> unique_constraint([:inventory_disposal_id, :entity_type, :entity_id],
      name: :inventory_disposal_items_unique_source,
      message: "has already been added to this request"
    )
  end

  defp validate_requested_quantity(changeset) do
    quantity = get_field(changeset, :quantity)
    available = get_field(changeset, :available_quantity)

    if is_integer(quantity) and is_integer(available) and quantity > available do
      add_error(changeset, :quantity, "cannot exceed the available quantity of #{available}")
    else
      changeset
    end
  end
end
