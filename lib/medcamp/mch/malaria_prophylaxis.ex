defmodule Medcamp.Mch.MalariaProphylaxis do
  use Ecto.Schema
  import Ecto.Changeset

  schema "mch_malaria_prophylaxis" do
    belongs_to :pregnancy, Medcamp.Mch.Pregnancy
    field :dose_number, :integer
    field :date_given, :date

    timestamps(type: :utc_datetime)
  end

  def changeset(prophylaxis, attrs) do
    prophylaxis
    |> cast(attrs, [:pregnancy_id, :dose_number, :date_given])
    |> validate_required([:pregnancy_id])
    |> foreign_key_constraint(:pregnancy_id)
  end
end
