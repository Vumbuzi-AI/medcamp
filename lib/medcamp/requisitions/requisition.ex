defmodule Medcamp.Requisitions.Requisition do
  use Ecto.Schema
  import Ecto.Changeset

  schema "requisitions" do
    field :title, :string
    field :description, :string
    field :status, :string, default: "pending"
    field :notes, :string
    field :quantity, :integer
    field :requested_at, :utc_datetime
    field :responded_at, :utc_datetime
    field :urgency, :string, default: "normal"
    field :needs_reorder, :boolean, default: false
    field :rejection_reason, :string
    belongs_to :requested_by, Medcamp.Accounts.User, foreign_key: :requested_by_id
    belongs_to :requested_from, Medcamp.Accounts.User, foreign_key: :requested_from_id
    belongs_to :to_department, Medcamp.Departments.Department, foreign_key: :to_department_id
    belongs_to :inventory_received, Medcamp.InventoriesReceived.InventoryReceived
    belongs_to :general_inventory_item, Medcamp.Inventories.GeneralInventoryItem

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(requisition, attrs) do
    requisition
    |> cast(attrs, [
      :title,
      :description,
      :status,
      :notes,
      :quantity,
      :requested_at,
      :responded_at,
      :requested_by_id,
      :requested_from_id,
      :to_department_id,
      :inventory_received_id,
      :general_inventory_item_id,
      :urgency,
      :needs_reorder,
      :rejection_reason
    ])
    |> validate_required([:requested_by_id])
    |> validate_required_to_department_or_user()
    |> validate_required_if_inventory_received([:title, :description])
    |> validate_inclusion(:status, ["pending", "approved", "rejected"])
    |> validate_inclusion(:urgency, ["normal", "urgent", "critical"])
    |> validate_rejection_reason_if_rejected()
    |> foreign_key_constraint(:inventory_received_id)
    |> foreign_key_constraint(:general_inventory_item_id)
    |> foreign_key_constraint(:to_department_id)
  end

  # Requisition must be sent to a department (or legacy: to a user)
  defp validate_required_to_department_or_user(changeset) do
    to_dept = get_field(changeset, :to_department_id)
    to_user = get_field(changeset, :requested_from_id)

    if to_dept || to_user do
      changeset
    else
      add_error(changeset, :to_department_id, "must select a department to request from")
    end
  end

  defp validate_required_if_inventory_received(changeset, _fields) do
    if get_field(changeset, :inventory_received_id) ||
         get_field(changeset, :general_inventory_item_id) do
      changeset
      |> validate_required([:title, :quantity])
    else
      changeset
      |> validate_required([:title, :description])
    end
  end

  defp validate_rejection_reason_if_rejected(changeset) do
    if get_field(changeset, :status) == "rejected" do
      changeset
      |> update_change(:rejection_reason, fn
        nil -> nil
        value when is_binary(value) -> String.trim(value)
      end)
      |> then(fn changeset ->
        if get_field(changeset, :rejection_reason) in [nil, ""] do
          add_error(changeset, :rejection_reason, "is required when rejecting a requisition")
        else
          changeset
        end
      end)
    else
      changeset
    end
  end
end
