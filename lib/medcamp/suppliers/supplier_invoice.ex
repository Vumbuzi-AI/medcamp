defmodule Medcamp.Suppliers.SupplierInvoice do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(submitted approved rejected paid)
  @currencies ~w(KES USD EUR GBP)

  schema "supplier_invoices" do
    field :invoice_number, :string
    field :invoice_date, :date
    field :due_date, :date
    field :amount, :decimal
    field :currency, :string, default: "KES"
    field :status, :string, default: "submitted"
    field :notes, :string
    field :file_path, :string
    field :original_filename, :string
    belongs_to :supplier, Medcamp.Suppliers.Supplier

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses
  def currencies, do: @currencies

  def status_label("submitted"), do: "Submitted"
  def status_label("approved"), do: "Approved"
  def status_label("rejected"), do: "Rejected"
  def status_label("paid"), do: "Paid"
  def status_label(_), do: "Unknown"

  def status_color("submitted"), do: "bg-blue-100 text-blue-800"
  def status_color("approved"), do: "bg-emerald-100 text-emerald-800"
  def status_color("rejected"), do: "bg-rose-100 text-rose-800"
  def status_color("paid"), do: "bg-purple-100 text-purple-800"
  def status_color(_), do: "bg-gray-100 text-gray-800"

  @doc false
  def changeset(invoice, attrs) do
    invoice
    |> cast(attrs, [
      :invoice_number,
      :invoice_date,
      :due_date,
      :amount,
      :currency,
      :status,
      :notes,
      :file_path,
      :original_filename,
      :supplier_id
    ])
    |> validate_required([:invoice_number, :supplier_id])
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:currency, @currencies)
    |> foreign_key_constraint(:supplier_id)
  end
end
