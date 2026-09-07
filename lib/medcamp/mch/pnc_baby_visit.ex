defmodule Medcamp.Mch.PncBabyVisit do
  use Ecto.Schema
  import Ecto.Changeset

  schema "mch_pnc_baby_visits" do
    belongs_to :child, Medcamp.Mch.Child
    belongs_to :pnc_mother_visit, Medcamp.Mch.PncMotherVisit, foreign_key: :pnc_mother_visit_id
    field :general_condition, :string
    field :temperature, :decimal
    field :breaths_per_minute, :integer
    field :exclusive_breastfeeding, :boolean
    field :umbilical_cord_status, :string
    field :visit_date, :date

    timestamps(type: :utc_datetime)
  end

  def changeset(visit, attrs) do
    visit
    |> cast(attrs, [
      :child_id,
      :pnc_mother_visit_id,
      :general_condition,
      :temperature,
      :breaths_per_minute,
      :exclusive_breastfeeding,
      :umbilical_cord_status,
      :visit_date
    ])
    |> validate_required([:child_id])
    |> foreign_key_constraint(:child_id)
  end
end
