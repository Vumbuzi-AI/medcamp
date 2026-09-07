defmodule Medcamp.Suppliers.SupplierDocument do
  use Ecto.Schema
  import Ecto.Changeset

  @legacy_document_types ~w(cr12 letter_of_incorporation license_certificate other)
  @procurement_document_types ~w(registration_cert pin_cert trade_licence)
  @document_types @legacy_document_types ++ @procurement_document_types

  schema "supplier_documents" do
    field :document_type, :string
    field :file_path, :string
    field :original_filename, :string
    field :reference_number, :string
    field :file_name, :string
    field :file_size, :integer
    field :verified, :boolean, default: false

    belongs_to :supplier, Medcamp.Suppliers.Supplier
    belongs_to :verified_by, Medcamp.Accounts.User, foreign_key: :verified_by_id

    timestamps(type: :utc_datetime)
  end

  def document_types, do: @document_types
  def procurement_document_types, do: @procurement_document_types

  def document_type_label("cr12"), do: "CR12"
  def document_type_label("letter_of_incorporation"), do: "Letter of Incorporation"
  def document_type_label("license_certificate"), do: "License Certificate"
  def document_type_label("other"), do: "Other"
  def document_type_label("registration_cert"), do: "Certificate of Registration"
  def document_type_label("pin_cert"), do: "KRA PIN Certificate"
  def document_type_label("trade_licence"), do: "Trade Licence"
  def document_type_label(_), do: "Document"

  @doc false
  def changeset(supplier_document, attrs) do
    supplier_document
    |> cast(attrs, [
      :document_type,
      :file_path,
      :original_filename,
      :supplier_id,
      :reference_number,
      :file_name,
      :file_size,
      :verified,
      :verified_by_id
    ])
    |> validate_required([:document_type, :file_path, :supplier_id])
    |> validate_inclusion(:document_type, @document_types)
    |> foreign_key_constraint(:supplier_id)
    |> foreign_key_constraint(:verified_by_id)
    |> unique_constraint([:supplier_id, :document_type],
      name: :supplier_documents_supplier_id_document_type_index
    )
  end
end
