defmodule Medcamp.Inpatient.DischargeSummary do
  use Ecto.Schema
  import Ecto.Changeset

  schema "discharge_summaries" do
    field :discharge_date, :date
    field :admission_diagnosis, :string
    field :discharge_diagnosis, :string
    field :clinical_history, :string
    field :physical_examination, :string
    field :procedures_done, :string
    field :lab_investigations, :string
    field :drugs_given, :string
    field :discharge_drugs, :string
    field :follow_up_date, :date
    field :follow_up_clinic, :string
    field :doctor_notes, :string

    belongs_to :admission_note, Medcamp.Inpatient.AdmissionNote
    belongs_to :doctor, Medcamp.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(discharge_summary, attrs) do
    discharge_summary
    |> cast(attrs, [
      :discharge_date,
      :admission_diagnosis,
      :discharge_diagnosis,
      :clinical_history,
      :physical_examination,
      :procedures_done,
      :lab_investigations,
      :drugs_given,
      :discharge_drugs,
      :follow_up_date,
      :follow_up_clinic,
      :doctor_notes,
      :admission_note_id,
      :doctor_id
    ])
    |> validate_required([
      :discharge_date,
      :discharge_diagnosis,
      :admission_note_id,
      :doctor_id
    ])
  end
end
