defmodule Medcamp.Procurement.GoodsReceivedNote do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(draft pending_review finalised flagged)
  @conditions ~w(good minor_damage significant_damage)
  @discrepancy_actions ~w(back_delivery credit_note accept_as_is)

  schema "goods_received_notes" do
    field :reference, :string
    field :received_date, :date
    field :received_time, :time
    field :overall_condition, :string
    field :delivery_remarks, :string
    field :discrepancy_description, :string
    field :discrepancy_action, :string
    field :resolution_deadline, :date
    field :status, :string, default: "draft"
    field :finalised_at, :utc_datetime
    field :packages_received, :integer

    belongs_to :purchase_order, Medcamp.Procurement.PurchaseOrder
    belongs_to :invoice, Medcamp.Procurement.Invoice
    belongs_to :shipment_advice, Medcamp.Procurement.ShipmentAdvice
    belongs_to :supplier, Medcamp.Suppliers.Supplier
    belongs_to :received_by, Medcamp.Accounts.User, foreign_key: :received_by_id
    belongs_to :finalised_by, Medcamp.Accounts.User, foreign_key: :finalised_by_id

    has_many :items, Medcamp.Procurement.GrnItem, foreign_key: :grn_id

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses
  def conditions, do: @conditions
  def discrepancy_actions, do: @discrepancy_actions

  def changeset(grn, attrs) do
    grn
    |> cast(attrs, [
      :reference,
      :purchase_order_id,
      :invoice_id,
      :shipment_advice_id,
      :supplier_id,
      :received_date,
      :received_time,
      :received_by_id,
      :overall_condition,
      :delivery_remarks,
      :discrepancy_description,
      :discrepancy_action,
      :resolution_deadline,
      :status,
      :finalised_by_id,
      :finalised_at,
      :packages_received
    ])
    |> validate_required([
      :reference,
      :purchase_order_id,
      :invoice_id,
      :shipment_advice_id,
      :supplier_id,
      :status
    ])
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:overall_condition, @conditions ++ [nil])
    |> validate_inclusion(:discrepancy_action, @discrepancy_actions ++ [nil])
    |> unique_constraint(:reference)
  end
end
