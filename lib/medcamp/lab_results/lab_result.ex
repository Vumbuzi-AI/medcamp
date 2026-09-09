defmodule Medcamp.LabResults.LabResult do
  use Ecto.Schema
  use Medcamp.Tenancy.Schema
  import Ecto.Changeset

  schema "lab_results" do
    tenant_field()

    field :name, :string
    field :description, :string
    field :date_of_test, :date
    field :query, :string, virtual: true
    field :urgency, :string
    field :lab_report, :string
    field :test_findings, :string
    field :payment_type, :string
    field :insurance_name, :string
    field :total_amount_paid, :integer
    field :has_paid, :boolean, default: false
    field :excluded_from_insurance_invoice, :boolean, default: false
    field :sample_collection_date, :date
    field :sample_collection_description, :string
    field :test_entries, :any, virtual: true
    field :time, :time
    field :technician_name, :string
    field :report_complete, :boolean, default: false
    field :interpretation_payload, :map, default: %{}
    field :interpretation_status, :string, default: "pending"
    field :interpretation_generated_at, :utc_datetime
    belongs_to :doctor_note, Medcamp.DoctorNotes.DoctorNote
    belongs_to :patient, Medcamp.Patients.Patient
    belongs_to :doctor, Medcamp.Accounts.User
    belongs_to :lab_technician, Medcamp.Accounts.User
    embeds_many :tests, Medcamp.LabResults.LabTest

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(lab_result, attrs) do
    lab_result
    |> cast(attrs, [
      :name,
      :description,
      :date_of_test,
      :payment_type,
      :insurance_name,
      :total_amount_paid,
      :has_paid,
      :excluded_from_insurance_invoice,
      :urgency,
      :query,
      :lab_report,
      :test_findings,
      :sample_collection_date,
      :sample_collection_description,
      :technician_name,
      :report_complete,
      :interpretation_payload,
      :interpretation_status,
      :interpretation_generated_at,
      :time,
      :doctor_note_id,
      :patient_id,
      :doctor_id,
      :lab_technician_id
    ])
    |> validate_required([
      :urgency,
      :doctor_note_id,
      :patient_id,
      :doctor_id
    ])
    |> put_time_if_missing()
    |> cast_embed(:tests, with: &Medcamp.LabResults.LabTest.changeset/2)
    |> put_org_id()
  end

  def interpretation_changeset(lab_result, attrs) do
    lab_result
    |> cast(attrs, [:interpretation_payload, :interpretation_status, :interpretation_generated_at])
    |> validate_required([:interpretation_payload, :interpretation_status])
  end

  @doc false
  def camp_changeset(lab_result, attrs) do
    lab_result
    |> cast(attrs, [
      :name,
      :description,
      :urgency,
      :payment_type,
      :insurance_name,
      :total_amount_paid,
      :has_paid,
      :excluded_from_insurance_invoice,
      :patient_id,
      :doctor_id,
      :doctor_note_id,
      :time
    ])
    |> validate_required([:urgency, :patient_id, :doctor_id])
    |> put_time_if_missing()
    |> cast_embed(:tests, with: &Medcamp.LabResults.LabTest.changeset/2)
    |> put_change(:has_paid, true)
    |> put_total_from_tests()
    |> put_org_id()
  end

  defp put_total_from_tests(changeset) do
    tests = get_field(changeset, :tests) || []
    total = Enum.sum(Enum.map(tests, fn t -> t.price || 0 end))

    if total > 0 do
      put_change(changeset, :total_amount_paid, total)
    else
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
