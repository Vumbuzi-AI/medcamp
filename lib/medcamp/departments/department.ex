defmodule Medcamp.Departments.Department do
  use Ecto.Schema
  import Ecto.Changeset

  schema "departments" do
    field :name, :string
    field :code, :string

    has_many :users, Medcamp.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(department, attrs) do
    department
    |> cast(attrs, [:name, :code])
    |> validate_required([:name])
    |> unique_constraint(:code)
  end
end
