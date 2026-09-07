defmodule Medcamp.PatientFormRecords.PatientFormRecord do
  use Ecto.Schema
  import Ecto.Changeset

  schema "patient_form_records" do
    field :form_type, :string
    field :form_data, :map, default: %{}
    field :notes, :string, virtual: true

    belongs_to :patient, Medcamp.Patients.Patient
    belongs_to :created_by, Medcamp.Accounts.User
    belongs_to :updated_by, Medcamp.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(record, attrs) do
    record
    |> cast(attrs, [:form_type, :notes, :form_data, :patient_id, :created_by_id, :updated_by_id])
    |> validate_required([:form_type, :patient_id])
    |> put_form_data()
  end

  def form_types do
    [
      {"dama", "Discharge Against Medical Advice"},
      {"lab_request", "Laboratory Request Form"},
      {"discharge_summary", "Discharge Summary"},
      {"radiology_request", "Radiology Request Form"},
      {"prescription_sheet", "Prescription Sheet"},
      {"sick_leave", "Sick Leave Sheet"},
      {"surgical_consent", "Surgical Consent Form"},
      {"blood_transfusion_consent", "Blood Transfusion Consent"},
      {"hiv_testing_consent", "HIV Testing Consent"},
      {"medical_report", "Medical Report"},
      {"patient_referral", "Patient Referral Form"},
      {"payment_receipt", "Payment Receipt"}
    ]
  end

  def form_label(form_type) do
    form_types()
    |> Enum.find(fn {key, _} -> key == form_type end)
    |> case do
      {_, label} -> label
      nil -> form_type
    end
  end

  def form_notes(%__MODULE__{form_data: form_data}) when is_map(form_data) do
    Map.get(form_data, "notes") || Map.get(form_data, :notes)
  end

  def form_notes(_), do: nil

  defp put_form_data(changeset) do
    notes = get_field(changeset, :notes)
    form_data = get_field(changeset, :form_data) || %{}

    form_data =
      if is_binary(notes) and String.trim(notes) != "" do
        Map.put(form_data, "notes", notes)
      else
        form_data
      end

    put_change(changeset, :form_data, form_data)
  end
end
