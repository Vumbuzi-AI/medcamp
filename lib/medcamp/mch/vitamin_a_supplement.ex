defmodule Medcamp.Mch.VitaminASupplement do
  use Ecto.Schema
  import Ecto.Changeset

  schema "mch_vitamin_a_supplements" do
    belongs_to :child, Medcamp.Mch.Child
    field :dose_iu, :integer
    field :age_months, :integer
    field :date_given, :date

    timestamps(type: :utc_datetime)
  end

  def changeset(supplement, attrs) do
    supplement
    |> cast(attrs, [:child_id, :dose_iu, :age_months, :date_given])
    |> validate_required([:child_id])
    |> foreign_key_constraint(:child_id)
  end
end
