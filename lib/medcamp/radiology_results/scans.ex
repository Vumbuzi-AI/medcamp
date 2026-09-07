defmodule Medcamp.RadiologyResults.Scans do
  use Ecto.Schema

  embedded_schema do
    field :name, :string
    field :price, :integer
  end

  def changeset(lab_test, attrs) do
    lab_test
    |> Ecto.Changeset.cast(attrs, [:name, :price])
    |> Ecto.Changeset.validate_required([:name, :price])
  end
end
