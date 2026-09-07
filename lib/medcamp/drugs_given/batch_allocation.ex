defmodule Medcamp.DrugsGiven.BatchAllocation do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :quantity, :integer
    field :unit_price, :integer
    field :batch_id, :id
    field :drug_batch_id, :id
    field :is_verified, :boolean, default: false

    belongs_to :batch, Medcamp.Batches.Batch, define_field: false, foreign_key: :batch_id
  end

  def changeset(batch_allocation, attrs) do
    batch_allocation
    |> cast(attrs, [:quantity, :unit_price, :batch_id, :drug_batch_id, :is_verified])
    |> validate_required([:quantity, :unit_price, :batch_id, :drug_batch_id, :is_verified])
  end
end
