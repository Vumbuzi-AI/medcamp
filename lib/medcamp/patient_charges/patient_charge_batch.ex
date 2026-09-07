defmodule Medcamp.PatientCharges.PatientChargeBatch do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(pending paid cancelled)

  schema "patient_charge_batches" do
    field :total_amount, :integer, default: 0
    field :status, :string, default: "pending"
    field :paid_at, :utc_datetime

    belongs_to :doctor_note, Medcamp.DoctorNotes.DoctorNote
    belongs_to :patient, Medcamp.Patients.Patient
    belongs_to :created_by, Medcamp.Accounts.User
    has_many :patient_charges, Medcamp.PatientCharges.PatientCharge

    timestamps(type: :utc_datetime)
  end

  def changeset(patient_charge_batch, attrs) do
    patient_charge_batch
    |> cast(attrs, [
      :total_amount,
      :status,
      :paid_at,
      :doctor_note_id,
      :patient_id,
      :created_by_id
    ])
    |> validate_required([:total_amount, :status, :doctor_note_id, :patient_id])
    |> validate_number(:total_amount, greater_than: 0)
    |> validate_inclusion(:status, @statuses)
  end
end
