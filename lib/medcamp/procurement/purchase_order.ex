defmodule Medcamp.Procurement.PurchaseOrder do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(draft pending_approval approved sent acknowledged delivered cancelled)

  @checklist_fields ~w(
    checklist_prices_confirmed
    checklist_vendor_approved
    checklist_delivery_verified
    checklist_budget_approved
    checklist_hod_signoff
  )a

  schema "purchase_orders" do
    field :reference, :string
    field :po_date, :date
    field :expected_delivery_date, :date
    field :currency, :string, default: "KES"
    field :payment_terms, :string
    field :delivery_address, :string
    field :subtotal, :decimal
    field :vat_amount, :decimal
    field :total, :decimal
    field :status, :string, default: "draft"
    field :approved_at, :utc_datetime
    field :acknowledged_at, :utc_datetime
    field :checklist_prices_confirmed, :boolean, default: false
    field :checklist_vendor_approved, :boolean, default: false
    field :checklist_delivery_verified, :boolean, default: false
    field :checklist_budget_approved, :boolean, default: false
    field :checklist_hod_signoff, :boolean, default: false

    belongs_to :rfq, Medcamp.Procurement.Rfq
    belongs_to :proforma_invoice, Medcamp.Procurement.ProformaInvoice
    belongs_to :supplier, Medcamp.Suppliers.Supplier
    belongs_to :approved_by, Medcamp.Accounts.User, foreign_key: :approved_by_id
    belongs_to :created_by, Medcamp.Accounts.User, foreign_key: :created_by_id

    has_many :items, Medcamp.Procurement.PurchaseOrderItem

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses
  def checklist_fields, do: @checklist_fields

  def changeset(po, attrs) do
    po
    |> cast(attrs, [
      :reference,
      :rfq_id,
      :proforma_invoice_id,
      :supplier_id,
      :po_date,
      :expected_delivery_date,
      :currency,
      :payment_terms,
      :delivery_address,
      :subtotal,
      :vat_amount,
      :total,
      :status,
      :approved_by_id,
      :approved_at,
      :acknowledged_at,
      :created_by_id | @checklist_fields
    ])
    |> validate_required([:reference, :supplier_id, :status])
    |> validate_inclusion(:status, @statuses)
    |> unique_constraint(:reference)
    |> foreign_key_constraint(:supplier_id)
  end
end
