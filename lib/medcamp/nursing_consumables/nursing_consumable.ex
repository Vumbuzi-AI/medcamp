defmodule Medcamp.NursingConsumables.NursingConsumable do
  use Ecto.Schema
  import Ecto.Changeset

  schema "nursing_consumables" do
    field :date, :date
    field :consumed_quantity, :integer
    field :purpose, :string
    belongs_to :patient, Medcamp.Patients.Patient
    belongs_to :doctor_note, Medcamp.DoctorNotes.DoctorNote
    belongs_to :nursing_allocation, Medcamp.NursingAllocations.NursingAllocation
    has_one :patient_charge, Medcamp.PatientCharges.PatientCharge
    timestamps(type: :utc_datetime)
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [
      :consumed_quantity,
      :date,
      :purpose,
      :patient_id,
      :doctor_note_id,
      :nursing_allocation_id
    ])
    |> validate_required([:consumed_quantity, :date, :purpose])
    |> validate_number(:consumed_quantity, greater_than: 0)
    |> validate_doctor_note_for_patient_usage()
  end

  defp validate_doctor_note_for_patient_usage(changeset) do
    if get_field(changeset, :patient_id) && is_nil(get_field(changeset, :doctor_note_id)) do
      add_error(changeset, :doctor_note_id, "must be selected when usage is linked to a patient")
    else
      changeset
    end
  end
end
