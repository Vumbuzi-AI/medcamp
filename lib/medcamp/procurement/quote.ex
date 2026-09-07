defmodule Medcamp.Procurement.Quote do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(submitted under_review accepted rejected)

  schema "quotes" do
    field :reference, :string
    field :quote_date, :date
    field :valid_until, :date
    field :lead_time_days, :integer
    field :delivery_terms, :string
    field :general_remarks, :string
    field :subtotal, :decimal
    field :vat_amount, :decimal
    field :vat_rate, :decimal, default: Decimal.new("0.16")
    field :total, :decimal
    field :status, :string, default: "submitted"
    field :compliance_score, :integer

    belongs_to :rfq, Medcamp.Procurement.Rfq
    belongs_to :supplier, Medcamp.Suppliers.Supplier

    has_many :items, Medcamp.Procurement.QuoteItem

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses

  def changeset(quote, attrs) do
    quote
    |> cast(attrs, [
      :reference,
      :rfq_id,
      :supplier_id,
      :quote_date,
      :valid_until,
      :lead_time_days,
      :delivery_terms,
      :general_remarks,
      :subtotal,
      :vat_amount,
      :vat_rate,
      :total,
      :status,
      :compliance_score
    ])
    |> validate_required([:reference, :rfq_id, :supplier_id, :status])
    |> validate_inclusion(:status, @statuses)
    |> unique_constraint(:reference)
    |> unique_constraint([:rfq_id, :supplier_id], name: :quotes_rfq_id_supplier_id_index)
    |> foreign_key_constraint(:rfq_id)
    |> foreign_key_constraint(:supplier_id)
  end
end
