defmodule Medcamp.Inventories.GeneralInventoryItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "general_inventory_items" do
    field :name, :string
    field :category, :string
    field :unit_of_measure, :string
    field :current_quantity, :decimal
    field :reorder_level, :decimal
    field :unit_cost, :decimal
    field :supplier, :string
    field :notes, :string
    field :gtin, :string
    field :room_id, :id
    field :manufacturer, :string
    field :date_received, :date

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(general_inventory_item, attrs) do
    general_inventory_item
    |> cast(attrs, [
      :name,
      :category,
      :date_received,
      :unit_of_measure,
      :manufacturer,
      :current_quantity,
      :gtin,
      :reorder_level,
      :unit_cost,
      :supplier,
      :notes
    ])
    |> validate_required([
      :name,
      :category,
      :date_received,
      :unit_of_measure,
      :manufacturer,
      :current_quantity,
      :gtin,
      :reorder_level,
      :unit_cost,
      :supplier
    ])
  end
end
