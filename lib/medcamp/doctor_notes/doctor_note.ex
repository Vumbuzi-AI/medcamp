defmodule Medcamp.DoctorNotes.DoctorNote do
  use Ecto.Schema
  use Medcamp.Tenancy.Schema
  import Ecto.Changeset

  schema "doctor_notes" do
    tenant_field()

    field :date, :date
    field :reason_for_consulatation, :string
    field :symptoms, :string
    field :prescribed_medication, :string
    field :lifestyle_recommendations, :string
    field :diagnosis, :string
    field :diagnosis_icd_code, :string
    field :last_period_date, :date
    field :investigations, :string
    field :impression, :string
    field :management, :string
    field :clinical_notes, :string
    field :past_medical_history, :string
    field :time, :time
    field :lab_imaging_request, :string
    field :ai_review_payload, :map, default: %{}
    field :ai_review_status, :string, default: "pending"
    field :ai_review_generated_at, :utc_datetime
    field :doctor_signature, :string
    field :signed_at, :utc_datetime
    belongs_to :doctor, Medcamp.Accounts.User
    belongs_to :patient, Medcamp.Patients.Patient
    belongs_to :patient_visit, Medcamp.PatientVisits.PatientVisit
    belongs_to :parent, __MODULE__, foreign_key: :parent_id
    has_many :child_notes, __MODULE__, foreign_key: :parent_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(doctor_note, attrs) do
    doctor_note
    |> cast(attrs, [
      :date,
      :reason_for_consulatation,
      :symptoms,
      :prescribed_medication,
      :lifestyle_recommendations,
      :lab_imaging_request,
      :diagnosis,
      :diagnosis_icd_code,
      :clinical_notes,
      :impression,
      :investigations,
      :last_period_date,
      :past_medical_history,
      :time,
      :management,
      :doctor_signature,
      :doctor_id,
      :patient_id,
      :patient_visit_id,
      :parent_id
    ])
    |> validate_required([
      :date,
      :symptoms,
      :time,
      :doctor_id,
      :patient_id
    ])
    |> put_date_if_missing()
    |> put_time_if_missing()
    |> put_signed_at_if_signature_added()
    |> put_org_id()
  end

  def ai_review_changeset(doctor_note, attrs) do
    doctor_note
    |> cast(attrs, [:ai_review_payload, :ai_review_status, :ai_review_generated_at])
    |> validate_required([:ai_review_payload, :ai_review_status])
  end

  defp put_date_if_missing(changeset) do
    if get_field(changeset, :date) do
      changeset
    else
      put_change(changeset, :date, Date.utc_today())
    end
  end

  defp put_signed_at_if_signature_added(changeset) do
    case fetch_change(changeset, :doctor_signature) do
      {:ok, sig} when sig in [nil, ""] ->
        put_change(changeset, :signed_at, nil)

      {:ok, _signature} ->
        put_change(changeset, :signed_at, DateTime.utc_now() |> DateTime.truncate(:second))

      :error ->
        changeset
    end
  end

  defp put_time_if_missing(changeset) do
    if get_field(changeset, :time) do
      changeset
    else
      current_time =
        Time.utc_now()
        |> Time.add(3 * 60 * 60)
        |> Time.truncate(:second)

      put_change(changeset, :time, current_time)
    end
  end
end
