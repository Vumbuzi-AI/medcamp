defmodule Medcamp.Mch.GrowthMeasurement do
  use Ecto.Schema
  import Ecto.Changeset

  schema "mch_growth_measurements" do
    belongs_to :child, Medcamp.Mch.Child
    field :measurement_date, :date
    field :age_months, :integer
    field :weight_kg, :decimal
    field :length_height_cm, :decimal
    field :head_circumference_cm, :decimal
    field :muac_cm, :decimal
    field :nutritional_status, :string
    field :next_visit_date, :date

    timestamps(type: :utc_datetime)
  end

  def changeset(measurement, attrs) do
    measurement
    |> cast(attrs, [
      :child_id,
      :measurement_date,
      :age_months,
      :weight_kg,
      :length_height_cm,
      :head_circumference_cm,
      :muac_cm,
      :nutritional_status,
      :next_visit_date
    ])
    |> validate_required([:child_id])
    |> foreign_key_constraint(:child_id)
  end
end
