defmodule Medcamp.AuditLog do
  use Ecto.Schema
  use Medcamp.Tenancy.Schema
  import Ecto.Changeset

  schema "audit_logs" do
    tenant_field()

    belongs_to :user, Medcamp.Accounts.User
    field :action, :string
    field :table_name, :string
    field :record_id, :integer
    field :previous_state, :map
    field :new_state, :map
    field :changed_fields, {:array, :string}

    timestamps(updated_at: false)
  end

  def changeset(audit_log, attrs) do
    audit_log
    |> cast(attrs, [
      :user_id,
      :action,
      :table_name,
      :record_id,
      :previous_state,
      :new_state,
      :changed_fields
    ])
    |> validate_required([:action, :table_name, :record_id])
    |> put_org_id()
  end
end
