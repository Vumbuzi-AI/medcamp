defmodule Medcamp.LabAllocations.LabAllocation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "lab_allocations" do
    field :allocated_quantity, :integer
    field :remaining_quantity, :integer
    field :uom, :string
    field :expiry_date, :date
    belongs_to :inventory_issued, Medcamp.InventoriesIssues.InventoryIssued
    belongs_to :allocated_by_user, Medcamp.Accounts.User, foreign_key: :allocated_by
    belongs_to :allocated_to_user, Medcamp.Accounts.User, foreign_key: :allocated_to

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(lab_allocation, attrs) do
    lab_allocation
    |> cast(attrs, [
      :allocated_quantity,
      :remaining_quantity,
      :uom,
      :expiry_date,
      :inventory_issued_id,
      :allocated_by,
      :allocated_to
    ])
    |> validate_required([:allocated_quantity, :remaining_quantity])
  end
end
