defmodule Medcamp.StockTakes.StockTakeEntry do
  use Ecto.Schema
  import Ecto.Changeset

  schema "stock_take_entries" do
    # entity_type: "drug_batch" | "lab_allocation" | "nursing_allocation" | "inventory_received"
    field :entity_type, :string
    field :entity_id, :integer
    field :entity_name, :string
    field :category, :string
    field :previous_quantity, :integer
    field :counted_quantity, :integer
    field :counted_allocated_quantity, :integer
    field :difference, :integer
    field :uom, :string
    field :notes, :string
    field :has_been_applied, :boolean, default: false

    belongs_to :stock_take, Medcamp.StockTakes.StockTake

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [
      :entity_type,
      :entity_id,
      :entity_name,
      :category,
      :previous_quantity,
      :counted_quantity,
      :counted_allocated_quantity,
      :difference,
      :uom,
      :notes,
      :has_been_applied,
      :stock_take_id
    ])
    |> validate_required([
      :entity_type,
      :entity_id,
      :entity_name,
      :previous_quantity,
      :stock_take_id
    ])
    |> validate_inclusion(:entity_type, [
      "drug_batch",
      "lab_allocation",
      "nursing_allocation",
      "inventory_received"
    ])
    |> compute_difference()
  end

  defp compute_difference(changeset) do
    counted = get_field(changeset, :counted_quantity)
    previous = get_field(changeset, :previous_quantity)

    if counted != nil and previous != nil do
      put_change(changeset, :difference, counted - previous)
    else
      changeset
    end
  end
end
