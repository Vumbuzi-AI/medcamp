defmodule Medcamp.InventoryDisposals.InventoryDisposal do
  use Ecto.Schema
  import Ecto.Changeset

  schema "inventory_disposals" do
    field :kind, :string
    field :date, :date
    field :reason, :string
    field :status, :string, default: "draft"
    field :supporting_document_path, :string
    field :supporting_document_name, :string
    field :approved_at, :utc_datetime

    belongs_to :requested_by, Medcamp.Accounts.User
    belongs_to :approved_by, Medcamp.Accounts.User

    has_many :items, Medcamp.InventoryDisposals.InventoryDisposalItem, on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  def changeset(disposal, attrs) do
    disposal
    |> cast(attrs, [
      :kind,
      :date,
      :reason,
      :status,
      :supporting_document_path,
      :supporting_document_name,
      :requested_by_id,
      :approved_by_id,
      :approved_at
    ])
    |> validate_required([:kind, :date, :requested_by_id])
    |> validate_inclusion(:kind, ["donation", "expiry"])
    |> validate_inclusion(:status, ["draft", "pending", "approved", "rejected"])
  end
end
