defmodule Medcamp.Suppliers.SupplierQuote do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(submitted approved rejected)
  @currencies ~w(KES USD EUR GBP)

  schema "supplier_quotes" do
    field :quote_number, :string
    field :quote_date, :date
    field :expiry_date, :date
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
  def status_label(_), do: "Unknown"

  def status_color("submitted"), do: "bg-blue-100 text-blue-800"
  def status_color("approved"), do: "bg-emerald-100 text-emerald-800"
  def status_color("rejected"), do: "bg-rose-100 text-rose-800"
  def status_color(_), do: "bg-gray-100 text-gray-800"

  @doc false
  def changeset(quote, attrs) do
    quote
    |> cast(attrs, [
      :quote_number,
      :quote_date,
      :expiry_date,
      :amount,
      :currency,
      :status,
      :notes,
      :file_path,
      :original_filename,
      :supplier_id
    ])
    |> validate_required([:quote_number, :supplier_id])
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:currency, @currencies)
    |> foreign_key_constraint(:supplier_id)
  end
end
