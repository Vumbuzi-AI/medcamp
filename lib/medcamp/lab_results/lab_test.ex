defmodule Medcamp.LabResults.LabTest do
  use Ecto.Schema

  embedded_schema do
    field :name, :string
    field :price, :integer
    field :serial, :string
    field :result, :string
  end

  def changeset(lab_test, attrs) do
    lab_test
    |> Ecto.Changeset.cast(attrs, [:name, :price, :serial, :result])
    |> Ecto.Changeset.validate_required([:name, :price])
    |> generate_serial()
  end

  defp generate_serial(changeset) do
    case Ecto.Changeset.get_field(changeset, :serial) do
      nil ->
        serial = generate_unique_serial()
        Ecto.Changeset.put_change(changeset, :serial, serial)

      _existing ->
        changeset
    end
  end

  defp generate_unique_serial do
    (:rand.uniform(90_000_000) + 10_000_000 - 1) |> Integer.to_string()
  end
end
