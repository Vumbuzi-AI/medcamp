defmodule Medcamp.Mch.ChildDeworming do
  use Ecto.Schema
  import Ecto.Changeset

  schema "mch_child_deworming" do
    belongs_to :child, Medcamp.Mch.Child
    field :age_months, :integer
    field :medication, :string
    field :dosage_mg, :integer
    field :date_given, :date

    timestamps(type: :utc_datetime)
  end

  def changeset(deworming, attrs) do
    deworming
    |> cast(attrs, [:child_id, :age_months, :medication, :dosage_mg, :date_given])
    |> validate_required([:child_id])
    |> foreign_key_constraint(:child_id)
  end
end
