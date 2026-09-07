defmodule Medcamp.Costings.Costing do
  use Ecto.Schema
  import Ecto.Changeset

  schema "costings" do
    field :type, :string
    field :price, :integer
    belongs_to :user, Medcamp.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(costing, attrs) do
    costing
    |> cast(attrs, [:type, :price, :user_id])
    |> validate_required([:type, :price, :user_id])
    |> unique_constraint(:type, message: "Type must be unique")
  end
end
