defmodule Medcamp.LabTestTemplates.LabTestCategory do
  @moduledoc """
  Schema for lab test categories (Blood Chemistry, Haematology, etc.)
  """
  use Ecto.Schema
  use Medcamp.Tenancy.Schema
  import Ecto.Changeset

  schema "lab_test_categories" do
    tenant_field()

    field :name, :string
    field :description, :string
    field :display_order, :integer, default: 0

    has_many :templates, Medcamp.LabTestTemplates.LabTestTemplate, foreign_key: :category_id

    timestamps(type: :utc_datetime)
  end

  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name, :description, :display_order])
    |> validate_required([:name])
    |> unique_constraint(:name)
    |> put_org_id()
  end
end
