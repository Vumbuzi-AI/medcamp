defmodule Medcamp.PatientCharges.PatientCharge do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(pending_review approved paid waived)

  schema "patient_charges" do
    field :description, :string
    field :quantity, :integer
    field :unit_price, :integer, default: 0
    field :total_price, :integer, default: 0
    field :status, :string, default: "pending_review"
    field :approved_at, :utc_datetime
    field :paid_at, :utc_datetime
    field :waived_at, :utc_datetime

    belongs_to :patient, Medcamp.Patients.Patient
    belongs_to :doctor_note, Medcamp.DoctorNotes.DoctorNote
    belongs_to :nursing_consumable, Medcamp.NursingConsumables.NursingConsumable
    belongs_to :patient_charge_batch, Medcamp.PatientCharges.PatientChargeBatch
    belongs_to :created_by, Medcamp.Accounts.User
    belongs_to :approved_by, Medcamp.Accounts.User
    belongs_to :waived_by, Medcamp.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(patient_charge, attrs) do
    patient_charge
    |> cast(attrs, [
      :description,
      :quantity,
      :unit_price,
      :total_price,
      :status,
      :approved_at,
      :paid_at,
      :waived_at,
      :patient_id,
      :doctor_note_id,
      :nursing_consumable_id,
      :patient_charge_batch_id,
      :created_by_id,
      :approved_by_id,
      :waived_by_id
    ])
    |> validate_required([
      :description,
      :quantity,
      :unit_price,
      :total_price,
      :status,
      :patient_id,
      :doctor_note_id,
      :nursing_consumable_id
    ])
    |> validate_number(:quantity, greater_than: 0)
    |> validate_number(:unit_price, greater_than_or_equal_to: 0)
    |> validate_number(:total_price, greater_than_or_equal_to: 0)
    |> validate_inclusion(:status, @statuses)
    |> unique_constraint(:nursing_consumable_id)
  end
end
