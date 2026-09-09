defmodule Medcamp.DrugBatches.DrugBatch do
  use Ecto.Schema
  use Medcamp.Tenancy.Schema
  use Medcamp.Camps.Schema
  import Ecto.Changeset

  schema "drug_batches" do
    tenant_field()
    camp_field()

    field :remaining_quantity, :integer
    belongs_to :drug, Medcamp.Drugs.Drug
    belongs_to :batch, Medcamp.Batches.Batch
    # Kept for backwards-compatible data, but batches are confirmed on intake.
    field :is_confirmed, :boolean, default: true
    field :is_active, :boolean, default: true
    belongs_to :confirmed_by_user, Medcamp.Accounts.User, foreign_key: :confirmed_by
    belongs_to :inventory_received, Medcamp.InventoriesReceived.InventoryReceived
    belongs_to :inventory_manager, Medcamp.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(drug_batch, attrs) do
    drug_batch
    |> cast(attrs, [
      :drug_id,
      :batch_id,
      :is_confirmed,
      :is_active,
      :confirmed_by,
      :inventory_manager_id,
      :inventory_received_id,
      :remaining_quantity
    ])
    |> validate_required([
      :drug_id,
      :batch_id,
      :remaining_quantity,
      :inventory_manager_id,
      :inventory_received_id
    ])
    |> put_org_id()
    |> put_camp_id()
  end
end
