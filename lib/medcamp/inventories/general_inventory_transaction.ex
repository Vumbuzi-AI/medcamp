defmodule Medcamp.Inventories.GeneralInventoryTransaction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "general_inventory_transactions" do
    field :reason, :string
    field :transaction_type, :string
    field :quantity, :decimal
    field :notes, :string
    field :recorded_by, :string
    field :transaction_date, :date
    belongs_to :general_inventory_item, Medcamp.Inventories.GeneralInventoryItem
    belongs_to :user, Medcamp.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(general_inventory_transaction, attrs) do
    general_inventory_transaction
    |> cast(attrs, [
      :transaction_type,
      :quantity,
      :reason,
      :notes,
      :recorded_by,
      :transaction_date,
      :general_inventory_item_id,
      :user_id
    ])
    |> validate_required([
      :transaction_type,
      :quantity,
      :reason,
      :notes,
      :recorded_by,
      :transaction_date,
      :general_inventory_item_id
    ])
    |> validate_inclusion(:transaction_type, ["received", "adjustment", "used", "destroyed"])
  end
end
