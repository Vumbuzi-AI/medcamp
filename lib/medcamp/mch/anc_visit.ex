defmodule Medcamp.Mch.AncVisit do
  use Ecto.Schema
  import Ecto.Changeset

  schema "mch_anc_visits" do
    belongs_to :pregnancy, Medcamp.Mch.Pregnancy
    field :contact_number, :integer
    field :visit_date, :date
    field :urine_test, :string
    field :muac_cm, :decimal
    field :bp_systolic, :integer
    field :bp_diastolic, :integer
    field :haemoglobin, :decimal
    field :pallor, :boolean
    field :gestation_weeks, :integer
    field :fundal_height, :decimal
    field :presentation, :string
    field :lie, :string
    field :foetal_heart_rate, :integer
    field :foetal_movement, :string
    field :next_visit_date, :date
    field :weight_kg, :decimal

    timestamps(type: :utc_datetime)
  end

  def changeset(anc_visit, attrs) do
    anc_visit
    |> cast(attrs, [
      :pregnancy_id,
      :contact_number,
      :visit_date,
      :urine_test,
      :muac_cm,
      :bp_systolic,
      :bp_diastolic,
      :haemoglobin,
      :pallor,
      :gestation_weeks,
      :fundal_height,
      :presentation,
      :lie,
      :foetal_heart_rate,
      :foetal_movement,
      :next_visit_date,
      :weight_kg
    ])
    |> validate_required([:pregnancy_id])
    |> foreign_key_constraint(:pregnancy_id)
  end
end
