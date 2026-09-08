defmodule Medcamp.DrugAllocations.DrugAssigned do
  use Ecto.Schema

  embedded_schema do
    field :brand_name, :string
    field :generic_name, :string
    field :quantity, :integer
    field :unit_of_measurement, :string
    field :frequency, :string
    field :duration_in_days, :integer
    field :price, :integer
    field :strength, :string
    field :prescription_note, :string
    field :pharmacist_note, :string
    field :route_of_administration, :string
    field :inventory_received_id, :integer
    field :has_been_given, :boolean, default: false
  end

  def changeset(drug_allocation, attrs, opts \\ []) do
    drug_allocation
    |> Ecto.Changeset.cast(attrs, [
      :brand_name,
      :generic_name,
      :inventory_received_id,
      :strength,
      :pharmacist_note,
      :prescription_note,
      :quantity,
      :has_been_given,
      :price,
      :unit_of_measurement,
      :frequency,
      :duration_in_days,
      :route_of_administration
    ])
    |> Ecto.Changeset.validate_required([
      :brand_name,
      :generic_name,
      :inventory_received_id,
      :quantity,
      :frequency,
      :duration_in_days,
      :route_of_administration
    ])
    |> maybe_validate_available_quantity(opts)
  end

  defp maybe_validate_available_quantity(changeset, opts) do
    if Keyword.get(opts, :validate_available_quantity, true) do
      validate_available_quantity(changeset)
    else
      changeset
    end
  end

  defp validate_available_quantity(changeset) do
    inventory_received_id = Ecto.Changeset.get_field(changeset, :inventory_received_id)
    requested_quantity = Ecto.Changeset.get_field(changeset, :quantity)

    if inventory_received_id && requested_quantity do
      # Get available quantity
      available_quantity = Medcamp.DrugBatches.check_available_quantity(inventory_received_id)

      # Validate requested quantity against available quantity
      if requested_quantity > available_quantity do
        Ecto.Changeset.add_error(
          changeset,
          :quantity,
          "exceeds available quantity. Only #{available_quantity} units available."
        )
      else
        changeset
      end
    else
      changeset
    end
  end
end
