defmodule Medcamp.Authorization.PermissionReview do
  use Ecto.Schema
  import Ecto.Changeset

  alias Medcamp.Accounts.User

  schema "permission_reviews" do
    field :role, :string
    field :reviewed_at, :utc_datetime
    field :notes, :string

    belongs_to :reviewer, Medcamp.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(permission_review, attrs) do
    permission_review
    |> cast(attrs, [:role, :reviewer_id, :reviewed_at, :notes])
    |> validate_required([:role, :reviewed_at])
    |> validate_inclusion(:role, User.roles())
    |> foreign_key_constraint(:reviewer_id)
  end
end
