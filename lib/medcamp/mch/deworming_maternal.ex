defmodule Medcamp.Mch.DewormingMaternal do
  use Ecto.Schema
  import Ecto.Changeset

  schema "mch_deworming_maternal" do
    belongs_to :pregnancy, Medcamp.Mch.Pregnancy
    field :date_given, :date
    field :medication, :string, default: "Mebendazole 500mg"

    timestamps(type: :utc_datetime)
  end

  def changeset(deworming, attrs) do
    deworming
    |> cast(attrs, [:pregnancy_id, :date_given, :medication])
    |> validate_required([:pregnancy_id])
    |> foreign_key_constraint(:pregnancy_id)
  end
end
