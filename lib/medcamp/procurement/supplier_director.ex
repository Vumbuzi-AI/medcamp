defmodule Medcamp.Procurement.SupplierDirector do
  use Ecto.Schema
  import Ecto.Changeset

  schema "supplier_directors" do
    field :first_name, :string
    field :last_name, :string
    field :middle_name, :string
    field :id_number, :string
    field :telephone, :string
    field :email, :string
    field :id_document_path, :string

    belongs_to :supplier, Medcamp.Suppliers.Supplier

    timestamps(type: :utc_datetime)
  end

  @required [:supplier_id, :first_name, :last_name, :id_number]
  @optional [:middle_name, :telephone, :email, :id_document_path]

  def changeset(director, attrs) do
    director
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> foreign_key_constraint(:supplier_id)
  end
end
