defmodule Medcamp.RadiologyResults.RadiologyResult do
  use Ecto.Schema
  import Ecto.Changeset

  schema "radiology_results" do
    field :description, :string
    field :payment_type, :string
    field :total_amount_paid, :integer
    field :has_paid, :boolean, default: false
    field :findings, :string
    field :urgency, :string
    field :radiology_report, :string
    embeds_many :scans, Medcamp.RadiologyResults.Scans
    field :report_complete, :boolean, default: false
    belongs_to :patient, Medcamp.Patients.Patient
    belongs_to :doctor, Medcamp.Accounts.User
    belongs_to :radiologist, Medcamp.Accounts.User
    belongs_to :doctor_note, Medcamp.DoctorNotes.DoctorNote

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(radiology_result, attrs) do
    radiology_result
    |> cast(attrs, [
      :description,
      :payment_type,
      :urgency,
      :total_amount_paid,
      :has_paid,
      :findings,
      :radiology_report,
      :report_complete,
      :doctor_note_id,
      :patient_id,
      :doctor_id,
      :radiologist_id
    ])
    |> validate_required([
      :description,
      :payment_type,
      :urgency,
      :doctor_note_id,
      :patient_id,
      :doctor_id
    ])
    |> cast_embed(:scans, with: &Medcamp.RadiologyResults.Scans.changeset/2)
  end
end
