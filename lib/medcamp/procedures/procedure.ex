defmodule Medcamp.Procedures.Procedure do
  use Ecto.Schema
  import Ecto.Changeset

  schema "procedure" do
    field :name, :string
    field :description, :string
    field :price, :integer
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(procedure, attrs) do
    procedure
    |> cast(attrs, [:name, :price, :description])
    |> validate_required([:name, :price, :description])
  end
end
