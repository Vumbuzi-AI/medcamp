defmodule Medcamp.SubsidizedProcedures.SubsidizedProcedure do
  use Ecto.Schema
  import Ecto.Changeset

  schema "subsidized_procedures" do
    field :name, :string
    field :description, :string
    field :price, :integer
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(subsidized_procedure, attrs) do
    subsidized_procedure
    |> cast(attrs, [:name, :price, :description])
    |> validate_required([:name, :price])
  end
end
