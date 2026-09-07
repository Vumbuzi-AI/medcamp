defmodule Medcamp.AssignedTags.AssignedTag do
  use Ecto.Schema
  import Ecto.Changeset

  schema "assigned_tags" do
    field :date, :date
    field :number, :integer
    field :remaining_number, :integer
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(assigned_tag, attrs) do
    assigned_tag
    |> cast(attrs, [:number, :date, :remaining_number])
    |> validate_required([:number, :date, :remaining_number])
  end
end
