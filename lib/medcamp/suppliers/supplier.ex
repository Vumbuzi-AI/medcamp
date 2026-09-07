defmodule Medcamp.Suppliers.Supplier do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(pending under_review approved rejected)

  schema "suppliers" do
    field :name, :string
    field :description, :string
    field :location, :string
    field :email, :string
    field :contact, :string
    field :gln, :string
    field :inventory_manager_id, :id

    field :reference, :string
    field :legal_name, :string
    field :nature_of_business, :string
    field :years_in_operation, :integer
    field :country, :string
    field :product_categories, {:array, :string}, default: []
    field :street_address, :string
    field :city, :string
    field :county, :string
    field :po_box, :string
    field :contact_first_name, :string
    field :contact_last_name, :string
    field :contact_designation, :string
    field :contact_email, :string
    field :contact_telephone, :string
    field :alternate_contact_name, :string
    field :alternate_contact_email, :string
    field :alternate_contact_telephone, :string
    field :account_name, :string
    field :account_number, :string
    field :bank_name, :string
    field :bank_branch, :string
    field :swift_code, :string
    field :currency, :string, default: "KES"
    field :payment_terms, :string, default: ""
    field :kra_pin, :string
    field :status, :string, default: "pending"
    field :compliance_score, :integer
    field :approved_at, :utc_datetime
    field :rejection_reason, :string

    belongs_to :approved_by, Medcamp.Accounts.User, foreign_key: :approved_by_id

    has_many :supplier_documents, Medcamp.Suppliers.SupplierDocument
    has_many :supplier_invoices, Medcamp.Suppliers.SupplierInvoice
    has_many :supplier_quotes, Medcamp.Suppliers.SupplierQuote
    has_many :supplier_delivery_notes, Medcamp.Suppliers.SupplierDeliveryNote
    has_many :supplier_advance_ship_notices, Medcamp.Suppliers.SupplierAdvanceShipNotice
    has_many :supplier_recalls, Medcamp.Suppliers.SupplierRecall

    has_many :directors, Medcamp.Procurement.SupplierDirector
    has_many :rfq_invitations, Medcamp.Procurement.RfqInvitation
    has_many :quotes, Medcamp.Procurement.Quote
    has_many :purchase_orders, Medcamp.Procurement.PurchaseOrder

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses

  @doc false
  def changeset(supplier, attrs) do
    supplier
    |> cast(attrs, [:name, :description, :email, :contact, :location, :gln])
    |> validate_required([:name, :email, :contact])
  end

  @doc """
  Changeset for the procurement registration flow. Covers spec columns and keeps legacy
  `name` / `email` / `contact` / `location` required so existing inventory flows keep working.
  """
  def registration_changeset(supplier, attrs) do
    supplier
    |> cast(attrs, [
      :name,
      :description,
      :email,
      :contact,
      :location,
      :gln,
      :reference,
      :legal_name,
      :nature_of_business,
      :years_in_operation,
      :country,
      :product_categories,
      :street_address,
      :city,
      :county,
      :po_box,
      :contact_first_name,
      :contact_last_name,
      :contact_designation,
      :contact_email,
      :contact_telephone,
      :alternate_contact_name,
      :alternate_contact_email,
      :alternate_contact_telephone,
      :account_name,
      :account_number,
      :bank_name,
      :bank_branch,
      :swift_code,
      :currency,
      :payment_terms,
      :kra_pin,
      :status,
      :compliance_score,
      :approved_by_id,
      :approved_at,
      :rejection_reason
    ])
    |> validate_inclusion(:status, @statuses)
    |> validate_number(:compliance_score, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    |> unique_constraint(:reference)
    |> foreign_key_constraint(:approved_by_id)
  end
end
