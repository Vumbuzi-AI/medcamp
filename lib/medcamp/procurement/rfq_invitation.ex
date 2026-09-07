defmodule Medcamp.Procurement.RfqInvitation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rfq_invitations" do
    field :sent_at, :utc_datetime
    field :viewed_at, :utc_datetime

    belongs_to :rfq, Medcamp.Procurement.Rfq
    belongs_to :supplier, Medcamp.Suppliers.Supplier

    timestamps(type: :utc_datetime)
  end

  def changeset(invitation, attrs) do
    invitation
    |> cast(attrs, [:rfq_id, :supplier_id, :sent_at, :viewed_at])
    |> validate_required([:rfq_id, :supplier_id])
    |> foreign_key_constraint(:rfq_id)
    |> foreign_key_constraint(:supplier_id)
    |> unique_constraint([:rfq_id, :supplier_id],
      name: :rfq_invitations_rfq_id_supplier_id_index
    )
  end
end
