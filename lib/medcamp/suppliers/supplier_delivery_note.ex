defmodule Medcamp.Suppliers.SupplierDeliveryNote do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(submitted acknowledged disputed)

  schema "supplier_delivery_notes" do
    field :delivery_note_number, :string
    field :delivery_date, :date
    field :status, :string, default: "submitted"
    field :notes, :string
    field :file_path, :string
    field :original_filename, :string
    belongs_to :supplier, Medcamp.Suppliers.Supplier

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses

  def status_label("submitted"), do: "Submitted"
  def status_label("acknowledged"), do: "Acknowledged"
  def status_label("disputed"), do: "Disputed"
  def status_label(_), do: "Unknown"

  def status_color("submitted"), do: "bg-blue-100 text-blue-800"
  def status_color("acknowledged"), do: "bg-emerald-100 text-emerald-800"
  def status_color("disputed"), do: "bg-amber-100 text-amber-800"
  def status_color(_), do: "bg-gray-100 text-gray-800"

  @doc false
  def changeset(delivery_note, attrs) do
    delivery_note
    |> cast(attrs, [
      :delivery_note_number,
      :delivery_date,
      :status,
      :notes,
      :file_path,
      :original_filename,
      :supplier_id
    ])
    |> validate_required([:delivery_note_number, :supplier_id])
    |> validate_inclusion(:status, @statuses)
    |> foreign_key_constraint(:supplier_id)
  end
end
