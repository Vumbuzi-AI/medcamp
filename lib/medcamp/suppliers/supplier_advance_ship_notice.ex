defmodule Medcamp.Suppliers.SupplierAdvanceShipNotice do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(submitted received cancelled)

  schema "supplier_advance_ship_notices" do
    field :asn_number, :string
    field :ship_date, :date
    field :expected_delivery_date, :date
    field :status, :string, default: "submitted"
    field :notes, :string
    field :file_path, :string
    field :original_filename, :string
    belongs_to :supplier, Medcamp.Suppliers.Supplier

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses

  def status_label("submitted"), do: "Submitted"
  def status_label("received"), do: "Received"
  def status_label("cancelled"), do: "Cancelled"
  def status_label(_), do: "Unknown"

  def status_color("submitted"), do: "bg-blue-100 text-blue-800"
  def status_color("received"), do: "bg-emerald-100 text-emerald-800"
  def status_color("cancelled"), do: "bg-gray-100 text-gray-800"
  def status_color(_), do: "bg-gray-100 text-gray-800"

  @doc false
  def changeset(asn, attrs) do
    asn
    |> cast(attrs, [
      :asn_number,
      :ship_date,
      :expected_delivery_date,
      :status,
      :notes,
      :file_path,
      :original_filename,
      :supplier_id
    ])
    |> validate_required([:asn_number, :supplier_id])
    |> validate_inclusion(:status, @statuses)
    |> foreign_key_constraint(:supplier_id)
  end
end
