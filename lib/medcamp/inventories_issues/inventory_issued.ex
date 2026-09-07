defmodule Medcamp.InventoriesIssues.InventoryIssued do
  use Ecto.Schema
  import Ecto.Changeset
  alias Medcamp.Batches

  schema "inventories_issued" do
    field :description, :string
    field :location, :string, default: "Pharmacy"
    field :gtin, :string
    field :quantity, :integer
    belongs_to :batch, Medcamp.Batches.Batch
    field :type, :string, default: "solid", virtual: true
    belongs_to :inventory_manager, Medcamp.Accounts.User
    belongs_to :assigned_to, Medcamp.Accounts.User, foreign_key: :assigned_to_id
    belongs_to :inventory_received, Medcamp.InventoriesReceived.InventoryReceived
    belongs_to :requisition, Medcamp.Requisitions.Requisition

    timestamps(type: :utc_datetime)
  end

  def changeset(inventory_issued, attrs) do
    inventory_issued
    |> cast(attrs, [
      :gtin,
      :quantity,
      :type,
      :description,
      :location,
      :batch_id,
      :inventory_received_id,
      :requisition_id,
      :assigned_to_id,
      :inventory_manager_id
    ])
    |> validate_required([
      :quantity,
      :location,
      :inventory_received_id,
      :assigned_to_id,
      :batch_id,
      :inventory_manager_id
    ])
    |> validate_batch_quantity()
  end

  defp validate_batch_quantity(changeset) do
    batch_id = get_field(changeset, :batch_id)
    quantity = get_field(changeset, :quantity)

    if batch_id && quantity do
      case Batches.get_batch!(batch_id) do
        nil ->
          add_error(changeset, :batch_id, "batch not found")

        batch ->
          available =
            (batch.remaining_quantity || 0) + previously_issued_quantity(changeset, batch_id)

          if quantity > available do
            add_error(
              changeset,
              :quantity,
              "must not exceed the batch's remaining quantity (#{available})"
            )
          else
            changeset
          end
      end
    else
      changeset
    end
  end

  defp previously_issued_quantity(
         %Ecto.Changeset{data: %{id: id, batch_id: batch_id, quantity: quantity}},
         batch_id
       )
       when not is_nil(id) do
    quantity || 0
  end

  defp previously_issued_quantity(_changeset, _batch_id), do: 0
end
