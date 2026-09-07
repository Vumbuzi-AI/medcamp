defmodule Medcamp.RadiologyTests.RadiologyTest do
  use Ecto.Schema
  import Ecto.Changeset

  schema "radiology_tests" do
    field :name, :string
    field :description, :string
    field :price, :integer
    belongs_to :creator, Medcamp.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(radiology_test, attrs) do
    radiology_test
    |> cast(attrs, [:name, :description, :price, :creator_id])
    |> validate_required([:name, :description, :price, :creator_id])
  end
end
