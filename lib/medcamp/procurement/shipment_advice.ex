defmodule Medcamp.Procurement.ShipmentAdvice do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(submitted received grn_created)

  schema "shipment_advices" do
    field :reference, :string
    field :dispatch_date, :date
    field :estimated_delivery_date, :date
    field :carrier, :string
    field :waybill_number, :string
    field :number_of_packages, :integer
    field :total_weight_kg, :decimal
    field :delivery_instructions, :string
    field :status, :string, default: "submitted"

    belongs_to :purchase_order, Medcamp.Procurement.PurchaseOrder
    belongs_to :invoice, Medcamp.Procurement.Invoice
    belongs_to :supplier, Medcamp.Suppliers.Supplier

    has_many :items, Medcamp.Procurement.ShipmentItem

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses

  def changeset(sa, attrs) do
    sa
    |> cast(attrs, [
      :reference,
      :purchase_order_id,
      :invoice_id,
      :supplier_id,
      :dispatch_date,
      :estimated_delivery_date,
      :carrier,
      :waybill_number,
      :number_of_packages,
      :total_weight_kg,
      :delivery_instructions,
      :status
    ])
    |> validate_required([:reference, :purchase_order_id, :invoice_id, :supplier_id, :status])
    |> validate_inclusion(:status, @statuses)
    |> unique_constraint(:reference)
  end
end
