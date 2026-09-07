defmodule Medcamp.Mch.Child do
  use Ecto.Schema
  import Ecto.Changeset

  schema "mch_children" do
    belongs_to :mother, Medcamp.Mch.Mother
    field :name, :string
    field :sex, :string
    field :date_of_birth, :date
    field :gestation_at_birth_weeks, :integer
    field :birth_weight_grams, :integer
    field :birth_length_cm, :decimal
    field :head_circumference_cm, :decimal
    field :birth_order, :integer
    field :place_of_birth, :string
    field :immunization_register_number, :string
    field :cwc_number, :string
    field :health_facility_name, :string
    field :kmhfl_code, :string
    field :guardian_name, :string
    field :guardian_phone, :string

    has_one :delivery, Medcamp.Mch.Delivery
    has_many :growth_measurements, Medcamp.Mch.GrowthMeasurement
    has_many :immunizations, Medcamp.Mch.Immunization
    has_many :pnc_baby_visits, Medcamp.Mch.PncBabyVisit
    has_many :vitamin_a_supplements, Medcamp.Mch.VitaminASupplement
    has_many :child_deworming, Medcamp.Mch.ChildDeworming
    has_many :developmental_milestones, Medcamp.Mch.DevelopmentalMilestone
    has_many :eye_assessments, Medcamp.Mch.EyeAssessment

    timestamps(type: :utc_datetime)
  end

  def changeset(child, attrs) do
    child
    |> cast(attrs, [
      :mother_id,
      :name,
      :sex,
      :date_of_birth,
      :gestation_at_birth_weeks,
      :birth_weight_grams,
      :birth_length_cm,
      :head_circumference_cm,
      :birth_order,
      :place_of_birth,
      :immunization_register_number,
      :cwc_number,
      :health_facility_name,
      :kmhfl_code,
      :guardian_name,
      :guardian_phone
    ])
    |> validate_required([:mother_id])
    |> foreign_key_constraint(:mother_id)
  end

  def age_in_months(%__MODULE__{date_of_birth: nil}), do: nil

  def age_in_months(%__MODULE__{date_of_birth: dob}) do
    today = Date.utc_today()
    (today.year - dob.year) * 12 + (today.month - dob.month)
  end
end
