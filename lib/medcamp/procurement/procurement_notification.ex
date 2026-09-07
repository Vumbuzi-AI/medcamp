defmodule Medcamp.Procurement.ProcurementNotification do
  use Ecto.Schema
  import Ecto.Changeset

  @types ~w(
    rfq_issued quote_received po_issued invoice_submitted
    invoice_approved invoice_rejected shipment_submitted
    grn_finalised registration_approved registration_rejected deadline_reminder
  )

  schema "procurement_notifications" do
    field :type, :string
    field :title, :string
    field :body, :string
    field :resource_type, :string
    field :resource_id, :integer
    field :read, :boolean, default: false
    field :read_at, :utc_datetime

    belongs_to :user, Medcamp.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def types, do: @types

  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [
      :user_id,
      :type,
      :title,
      :body,
      :resource_type,
      :resource_id,
      :read,
      :read_at
    ])
    |> validate_required([:user_id, :type])
    |> validate_inclusion(:type, @types)
    |> foreign_key_constraint(:user_id)
  end
end
