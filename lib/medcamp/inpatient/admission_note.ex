defmodule Medcamp.Inpatient.AdmissionNote do
  use Ecto.Schema
  import Ecto.Changeset

  schema "admission_notes" do
    field :admission_date, :date, default: Date.utc_today()
    field :admission_time, :time
    field :complaints, :string
    field :history_of_presenting_illness, :string
    field :physical_examination, :string
    field :diagnosis, :string
    field :diagnosis_icd_code, :string
    field :management_plan, :string
    field :ward, :string
    field :bed_number, :string

    # Vital signs at admission
    field :blood_pressure, :string
    field :pulse_rate, :integer
    field :temperature, :decimal
    field :spo2, :integer
    field :respiratory_rate, :integer

    belongs_to :patient, Medcamp.Patients.Patient
    belongs_to :doctor, Medcamp.Accounts.User
    belongs_to :doctor_note, Medcamp.DoctorNotes.DoctorNote

    has_many :continuation_notes, Medcamp.Inpatient.ContinuationNote
    has_many :treatment_sheets, Medcamp.Inpatient.TreatmentSheet
    has_many :vital_records, Medcamp.Inpatient.VitalRecord
    has_many :cadex_notes, Medcamp.CadexNotes.CadexNote
    has_one :discharge_summary, Medcamp.Inpatient.DischargeSummary

    timestamps(type: :utc_datetime)
  end

  def changeset(admission_note, attrs) do
    admission_note
    |> cast(attrs, [
      :admission_date,
      :admission_time,
      :complaints,
      :history_of_presenting_illness,
      :physical_examination,
      :diagnosis,
      :diagnosis_icd_code,
      :management_plan,
      :ward,
      :bed_number,
      :blood_pressure,
      :pulse_rate,
      :temperature,
      :spo2,
      :respiratory_rate,
      :patient_id,
      :doctor_id,
      :doctor_note_id
    ])
    |> validate_required([
      :admission_date,
      :admission_time,
      :complaints,
      :patient_id,
      :doctor_id
    ])
    |> put_time_if_missing()
  end

  defp put_time_if_missing(changeset) do
    if get_field(changeset, :admission_time) do
      changeset
    else
      current_time = Time.utc_now() |> Time.add(3 * 60 * 60) |> Time.truncate(:second)
      put_change(changeset, :admission_time, current_time)
    end
  end
end
