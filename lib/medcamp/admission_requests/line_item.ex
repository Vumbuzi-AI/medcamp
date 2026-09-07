defmodule Medcamp.AdmissionRequests.LineItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "admission_request_line_items" do
    field :item_type, :string
    field :price, :integer
    field :amount_paid, :integer, default: 0
    belongs_to :admission_request, Medcamp.AdmissionRequests.AdmissionRequest

    timestamps(type: :utc_datetime)
  end

  @item_types ~w(
    daily_bed_charges doctors_fee daily_nursing_services daily_laundry_services
    daily_ngt_feeding daily_bed_pan_care daily_bed_bath daily_assisted_bath
    daily_physiotherapy_care clean_gloves surgical_sterile_gloves syringes_needles
    infusion_set sterile_gauzes crepe_bandages_5cm crepe_bandages_7_5cm
    crepe_bandages_10cm crepe_bandages_15cm paraffin_gauze patient_gown
    daily_urinary_catheter_management oxygen_therapy nebulization
    outpatient_observation_bed_charges breakfast tea_10am lunch tea_4pm supper
    applying_plaster_of_paris wound_cleaning_small wound_cleaning_large
    wound_cleaning_extra_large wound_stitching toiletries_pack bathing_soap
    vaseline toothpaste slippers towel
    bed_charges nursing_charges lab_charges pharmacy_charges consultation_charges other
  )

  def item_types, do: @item_types

  # Proposed Inpatient Charges - Daily & Services
  def item_type_label("daily_bed_charges"), do: "Daily Bed Charges"
  def item_type_label("doctors_fee"), do: "Doctor's Fee"
  def item_type_label("daily_nursing_services"), do: "Daily Nursing Services"
  def item_type_label("daily_laundry_services"), do: "Daily Laundry Services"
  def item_type_label("daily_ngt_feeding"), do: "Daily NGT Feeding"
  def item_type_label("daily_bed_pan_care"), do: "Daily Bed Pan Care"
  def item_type_label("daily_bed_bath"), do: "Daily Bed bath"
  def item_type_label("daily_assisted_bath"), do: "Daily Assisted bath"
  def item_type_label("daily_physiotherapy_care"), do: "Daily Physiotherapy Care"

  def item_type_label("daily_urinary_catheter_management"),
    do: "Daily Urinary Catheter Management"

  def item_type_label("oxygen_therapy"), do: "Oxygen therapy"
  def item_type_label("nebulization"), do: "Nebulization"

  def item_type_label("outpatient_observation_bed_charges"),
    do: "Outpatient Observation Bed Charges"

  # Non-Pharms
  def item_type_label("clean_gloves"), do: "Clean Gloves"
  def item_type_label("surgical_sterile_gloves"), do: "Surgical/Sterile Gloves"
  def item_type_label("syringes_needles"), do: "Syringes + Needles"
  def item_type_label("infusion_set"), do: "Infusion set"
  def item_type_label("sterile_gauzes"), do: "Sterile gauzes"
  def item_type_label("crepe_bandages_5cm"), do: "Crepe bandages 5cm"
  def item_type_label("crepe_bandages_7_5cm"), do: "Crepe bandages 7.5cm"
  def item_type_label("crepe_bandages_10cm"), do: "Crepe bandages 10cm"
  def item_type_label("crepe_bandages_15cm"), do: "Crepe bandages 15cm"
  def item_type_label("paraffin_gauze"), do: "Paraffin gauze"
  def item_type_label("patient_gown"), do: "Patient gown"

  # Meals
  def item_type_label("breakfast"), do: "Breakfast"
  def item_type_label("tea_10am"), do: "10:00 am Tea"
  def item_type_label("lunch"), do: "Lunch"
  def item_type_label("tea_4pm"), do: "4:00 pm Tea"
  def item_type_label("supper"), do: "Supper"

  # Procedures & Wound care
  def item_type_label("applying_plaster_of_paris"), do: "Applying Plaster of Paris"
  def item_type_label("wound_cleaning_small"), do: "Wound Cleaning and Dressing (Small)"
  def item_type_label("wound_cleaning_large"), do: "Wound Cleaning and Dressing (Large)"

  def item_type_label("wound_cleaning_extra_large"),
    do: "Wound Cleaning and Dressing (Extra Large)"

  def item_type_label("wound_stitching"), do: "Wound Stitching"

  # Toiletries
  def item_type_label("toiletries_pack"), do: "Toiletries Pack (complete)"
  def item_type_label("bathing_soap"), do: "Bathing soap"
  def item_type_label("vaseline"), do: "Vaseline"
  def item_type_label("toothpaste"), do: "Toothpaste"
  def item_type_label("slippers"), do: "Slippers"
  def item_type_label("towel"), do: "Towel"

  # Legacy
  def item_type_label("bed_charges"), do: "Bed charges"
  def item_type_label("nursing_charges"), do: "Nursing charges"
  def item_type_label("lab_charges"), do: "Lab charges"
  def item_type_label("pharmacy_charges"), do: "Pharmacy charges"
  def item_type_label("consultation_charges"), do: "Consultation charges"
  def item_type_label("other"), do: "Other"
  def item_type_label(type), do: type || "Other"

  # Default prices (KSh) from Proposed Inpatient Charges - editable when adding
  def default_price("daily_bed_charges"), do: 2500
  def default_price("doctors_fee"), do: 2000
  def default_price("daily_nursing_services"), do: 1500
  def default_price("daily_laundry_services"), do: 500
  def default_price("daily_ngt_feeding"), do: 500
  def default_price("daily_bed_pan_care"), do: 500
  def default_price("daily_bed_bath"), do: 500
  def default_price("daily_assisted_bath"), do: 500
  def default_price("daily_physiotherapy_care"), do: 3000
  def default_price("daily_urinary_catheter_management"), do: 500
  def default_price("oxygen_therapy"), do: 500
  def default_price("nebulization"), do: 2000
  def default_price("outpatient_observation_bed_charges"), do: 1500
  def default_price("clean_gloves"), do: 20
  def default_price("surgical_sterile_gloves"), do: 150
  def default_price("syringes_needles"), do: 20
  def default_price("infusion_set"), do: 100
  def default_price("sterile_gauzes"), do: 10
  def default_price("crepe_bandages_5cm"), do: 100
  def default_price("crepe_bandages_7_5cm"), do: 100
  def default_price("crepe_bandages_10cm"), do: 200
  def default_price("crepe_bandages_15cm"), do: 200
  def default_price("paraffin_gauze"), do: 200
  def default_price("patient_gown"), do: 300
  def default_price("breakfast"), do: 100
  def default_price("tea_10am"), do: 200
  def default_price("lunch"), do: 700
  def default_price("tea_4pm"), do: 100
  def default_price("supper"), do: 700
  def default_price("applying_plaster_of_paris"), do: 5000
  def default_price("wound_cleaning_small"), do: 500
  def default_price("wound_cleaning_large"), do: 1000
  def default_price("wound_cleaning_extra_large"), do: 2000
  def default_price("wound_stitching"), do: 1500
  def default_price("toiletries_pack"), do: 2000
  def default_price("bathing_soap"), do: 200
  def default_price("vaseline"), do: 200
  def default_price("toothpaste"), do: 200
  def default_price("slippers"), do: 500
  def default_price("towel"), do: 500
  def default_price("bed_charges"), do: 2500
  def default_price("nursing_charges"), do: 1500
  def default_price(_), do: nil

  @doc false
  def changeset(line_item, attrs) do
    line_item
    |> cast(attrs, [:item_type, :price, :amount_paid, :admission_request_id])
    |> validate_required([:item_type, :price, :admission_request_id])
    |> validate_inclusion(:item_type, @item_types, message: "is not valid")
    |> validate_number(:price, greater_than_or_equal_to: 0)
    |> validate_number(:amount_paid, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:admission_request_id)
  end

  def amount_unpaid(%__MODULE__{} = li) do
    max(0, (li.price || 0) - (li.amount_paid || 0))
  end
end
