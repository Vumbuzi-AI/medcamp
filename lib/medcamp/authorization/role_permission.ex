defmodule Medcamp.Authorization.RolePermission do
  use Ecto.Schema
  import Ecto.Changeset

  alias Medcamp.Accounts.User

  schema "role_permissions" do
    field :role, :string
    field :granted_at, :utc_datetime

    belongs_to :permission, Medcamp.Authorization.Permission
    belongs_to :granted_by, Medcamp.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(role_permission, attrs) do
    role_permission
    |> cast(attrs, [:role, :permission_id, :granted_by_id, :granted_at])
    |> validate_required([:role, :permission_id, :granted_at])
    |> validate_inclusion(:role, User.roles())
    |> foreign_key_constraint(:permission_id)
    |> foreign_key_constraint(:granted_by_id)
    |> unique_constraint([:role, :permission_id])
  end
end
