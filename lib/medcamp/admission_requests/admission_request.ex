defmodule Medcamp.AdmissionRequests.AdmissionRequest do
  use Ecto.Schema
  import Ecto.Changeset

  schema "admission_requests" do
    field :date, :date
    field :start_time, :time
    field :end_time, :time
    field :discharge_date, :date
    field :discharged, :boolean, default: false
    field :payment_type, :string
    field :total_amount_paid, :integer
    field :has_paid, :boolean, default: false
    field :fully_paid, :boolean, default: false
    field :has_been_assigned_room, :boolean, default: false
    belongs_to :patient, Medcamp.Patients.Patient
    belongs_to :doctor, Medcamp.Accounts.User
    belongs_to :doctor_note, Medcamp.DoctorNotes.DoctorNote
    belongs_to :nurse, Medcamp.Accounts.User
    has_many :line_items, Medcamp.AdmissionRequests.LineItem

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(admission_request, attrs) do
    admission_request
    |> cast(attrs, [
      :date,
      :start_time,
      :end_time,
      :discharge_date,
      :discharged,
      :payment_type,
      :total_amount_paid,
      :has_paid,
      :fully_paid,
      :patient_id,
      :doctor_id,
      :nurse_id,
      :has_been_assigned_room,
      :doctor_note_id
    ])
    |> validate_required([:date, :patient_id, :doctor_id, :doctor_note_id])
  end
end
