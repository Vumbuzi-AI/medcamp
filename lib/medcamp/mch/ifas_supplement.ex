defmodule Medcamp.Mch.IfasSupplement do
  use Ecto.Schema
  import Ecto.Changeset

  schema "mch_ifas_supplements" do
    belongs_to :pregnancy, Medcamp.Mch.Pregnancy
    field :contact_number, :integer
    field :gestation_weeks, :integer
    field :tablets_issued, :integer
    field :date_given, :date

    timestamps(type: :utc_datetime)
  end

  def changeset(supplement, attrs) do
    supplement
    |> cast(attrs, [
      :pregnancy_id,
      :contact_number,
      :gestation_weeks,
      :tablets_issued,
      :date_given
    ])
    |> validate_required([:pregnancy_id])
    |> foreign_key_constraint(:pregnancy_id)
  end
end
