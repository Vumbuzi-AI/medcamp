defmodule Medcamp.Procurement.Invoice do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(draft submitted pending_grn grn_confirmed approved rejected)

  schema "invoices" do
    field :reference, :string
    field :invoice_date, :date
    field :due_date, :date
    field :currency, :string, default: "KES"
    field :supplier_pin, :string
    field :bill_to, :string
    field :subtotal, :decimal
    field :vat_amount, :decimal
    field :total, :decimal
    field :invoice_document_path, :string
    field :status, :string, default: "draft"
    field :approved_at, :utc_datetime

    belongs_to :purchase_order, Medcamp.Procurement.PurchaseOrder
    belongs_to :supplier, Medcamp.Suppliers.Supplier
    belongs_to :approved_by, Medcamp.Accounts.User, foreign_key: :approved_by_id

    has_many :items, Medcamp.Procurement.InvoiceItem

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses

  def changeset(invoice, attrs) do
    invoice
    |> cast(attrs, [
      :reference,
      :purchase_order_id,
      :supplier_id,
      :invoice_date,
      :due_date,
      :currency,
      :supplier_pin,
      :bill_to,
      :subtotal,
      :vat_amount,
      :total,
      :invoice_document_path,
      :status,
      :approved_by_id,
      :approved_at
    ])
    |> validate_required([:reference, :purchase_order_id, :supplier_id, :status])
    |> validate_inclusion(:status, @statuses)
    |> unique_constraint(:reference)
    |> foreign_key_constraint(:purchase_order_id)
    |> foreign_key_constraint(:supplier_id)
  end
end
