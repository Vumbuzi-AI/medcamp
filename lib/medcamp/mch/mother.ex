defmodule Medcamp.Mch.Mother do
  use Ecto.Schema
  import Ecto.Changeset

  schema "mch_mothers" do
    belongs_to :patient, Medcamp.Patients.Patient
    field :gravida, :integer
    field :parity, :integer
    field :height_cm, :decimal
    field :lmp, :date
    field :edd, :date
    field :marital_status, :string
    field :education_level, :string
    field :county, :string
    field :subcounty, :string
    field :ward, :string
    field :town_village, :string
    field :physical_address, :string
    field :next_of_kin_name, :string
    field :next_of_kin_relationship, :string
    field :next_of_kin_phone, :string
    field :health_facility_name, :string
    field :kmhfl_code, :string
    field :anc_number, :string
    field :pnc_number, :string

    has_many :pregnancies, Medcamp.Mch.Pregnancy
    has_many :children, Medcamp.Mch.Child
    has_many :td_vaccinations, Medcamp.Mch.TdVaccination
    has_many :pnc_mother_visits, Medcamp.Mch.PncMotherVisit

    timestamps(type: :utc_datetime)
  end

  def changeset(mother, attrs) do
    mother
    |> cast(attrs, [
      :patient_id,
      :gravida,
      :parity,
      :height_cm,
      :lmp,
      :edd,
      :marital_status,
      :education_level,
      :county,
      :subcounty,
      :ward,
      :town_village,
      :physical_address,
      :next_of_kin_name,
      :next_of_kin_relationship,
      :next_of_kin_phone,
      :health_facility_name,
      :kmhfl_code,
      :anc_number,
      :pnc_number
    ])
    |> validate_required([:patient_id])
    |> foreign_key_constraint(:patient_id)
  end
end
