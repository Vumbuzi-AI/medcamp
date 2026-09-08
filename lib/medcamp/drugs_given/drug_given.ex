defmodule Medcamp.DrugsGiven.DrugGiven do
  use Ecto.Schema
  use Medcamp.Tenancy.Schema
  use Medcamp.Camps.Schema
  import Ecto.Changeset
  alias Medcamp.DrugBatches
  alias Medcamp.DrugsGiven.BatchAllocation

  schema "drugs_given" do
    tenant_field()
    camp_field()

    field :quantity, :integer
    field :price, :integer
    belongs_to :drug, Medcamp.Drugs.Drug
    embeds_many :batch_allocations, BatchAllocation
    belongs_to :drug_allocation, Medcamp.DrugAllocations.DrugAllocation
    belongs_to :pharmacist, Medcamp.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(drug_given, attrs) do
    drug_given
    |> cast(attrs, [
      :quantity,
      :price,
      :drug_id,
      :drug_allocation_id,
      :pharmacist_id
    ])
    |> validate_required([:quantity, :price, :drug_id, :drug_allocation_id, :pharmacist_id])
    |> validate_drug_batch_quantity()
    |> cast_embed(:batch_allocations)
    |> put_org_id()
    |> put_camp_id()
  end

  defp validate_drug_batch_quantity(changeset) do
    # Only proceed with validation if quantity and drug_batch_id are present
    with quantity when not is_nil(quantity) <- get_field(changeset, :quantity),
         drug_batch_id when not is_nil(drug_batch_id) <- get_field(changeset, :drug_batch_id) do
      # Fetch the selected drug batch to get its remaining quantity
      case DrugBatches.get_drug_batch!(drug_batch_id) do
        nil ->
          add_error(changeset, :drug_batch_id, "selected drug batch does not exist")

        drug_batch ->
          if quantity > drug_batch.remaining_quantity do
            add_error(
              changeset,
              :quantity,
              "must not exceed the remaining quantity (#{drug_batch.remaining_quantity}) in the selected batch"
            )
          else
            changeset
          end
      end
    else
      # Return the original changeset if any of the conditions in with aren't met
      _ -> changeset
    end
  end
end
