defmodule Medcamp.Procurement.ProformaInvoice do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(draft submitted accepted rejected)

  schema "proforma_invoices" do
    field :reference, :string
    field :pi_date, :date
    field :valid_until, :date
    field :currency, :string, default: "KES"
    field :bill_to, :string
    field :ship_to, :string
    field :payment_instructions, :string
    field :subtotal, :decimal
    field :discount_amount, :decimal, default: Decimal.new(0)
    field :vat_amount, :decimal
    field :total, :decimal
    field :status, :string, default: "draft"

    belongs_to :quote, Medcamp.Procurement.Quote
    belongs_to :supplier, Medcamp.Suppliers.Supplier

    has_many :items, Medcamp.Procurement.ProformaInvoiceItem

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses

  def changeset(pi, attrs) do
    pi
    |> cast(attrs, [
      :reference,
      :quote_id,
      :supplier_id,
      :pi_date,
      :valid_until,
      :currency,
      :bill_to,
      :ship_to,
      :payment_instructions,
      :subtotal,
      :discount_amount,
      :vat_amount,
      :total,
      :status
    ])
    |> validate_required([:reference, :quote_id, :supplier_id, :status])
    |> validate_inclusion(:status, @statuses)
    |> unique_constraint(:reference)
    |> foreign_key_constraint(:quote_id)
    |> foreign_key_constraint(:supplier_id)
  end
end
