defmodule Medcamp.NursingAllocations.NursingAllocation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "nursing_allocations" do
    field :allocated_quantity, :integer
    field :remaining_quantity, :integer
    field :uom, :string
    field :expiry_date, :date
    field :total_consumed, :integer, virtual: true, default: 0

    belongs_to :inventory_issued, Medcamp.InventoriesIssues.InventoryIssued
    belongs_to :inventory_received, Medcamp.InventoriesReceived.InventoryReceived
    belongs_to :batch, Medcamp.Batches.Batch
    belongs_to :allocated_by_user, Medcamp.Accounts.User, foreign_key: :allocated_by
    belongs_to :allocated_to_user, Medcamp.Accounts.User, foreign_key: :allocated_to
    has_many :nursing_consumables, Medcamp.NursingConsumables.NursingConsumable

    timestamps(type: :utc_datetime)
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [
      :allocated_quantity,
      :remaining_quantity,
      :uom,
      :expiry_date,
      :inventory_issued_id,
      :inventory_received_id,
      :batch_id,
      :allocated_by,
      :allocated_to
    ])
    |> validate_required([:allocated_quantity, :remaining_quantity])
  end
end
