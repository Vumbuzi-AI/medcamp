defmodule Medcamp.Authorization.UserPermission do
  use Ecto.Schema
  import Ecto.Changeset

  @effects ~w(grant deny)

  schema "user_permissions" do
    field :effect, :string
    field :granted_at, :utc_datetime

    belongs_to :user, Medcamp.Accounts.User
    belongs_to :permission, Medcamp.Authorization.Permission
    belongs_to :granted_by, Medcamp.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def effects, do: @effects

  @doc false
  def changeset(user_permission, attrs) do
    user_permission
    |> cast(attrs, [:user_id, :permission_id, :effect, :granted_by_id, :granted_at])
    |> validate_required([:user_id, :permission_id, :effect, :granted_at])
    |> validate_inclusion(:effect, @effects)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:permission_id)
    |> foreign_key_constraint(:granted_by_id)
    |> unique_constraint([:user_id, :permission_id])
  end
end
