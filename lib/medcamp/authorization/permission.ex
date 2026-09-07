defmodule Medcamp.Authorization.Permission do
  use Ecto.Schema
  import Ecto.Changeset

  schema "permissions" do
    field :slug, :string
    field :description, :string
    field :resource_area, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(permission, attrs) do
    permission
    |> cast(attrs, [:slug, :description, :resource_area])
    |> validate_required([:slug])
    |> unique_constraint(:slug)
  end
end
