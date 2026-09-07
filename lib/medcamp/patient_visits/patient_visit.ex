defmodule Medcamp.PatientVisits.PatientVisit do
  use Ecto.Schema
  import Ecto.Changeset

  schema "patient_visits" do
    field :reason, :string
    field :date, :date, default: Date.utc_today()
    field :time, :time
    field :payment_type, :string
    field :insurance_name, :string
    field :visit_type, :string
    field :total_amount_paid, :integer
    field :has_paid, :boolean, default: false
    field :excluded_from_insurance_invoice, :boolean, default: false
    belongs_to :patient, Medcamp.Patients.Patient
    belongs_to :creator, Medcamp.Accounts.User
    belongs_to :doctor, Medcamp.Accounts.User
    has_one :doctor_note, Medcamp.DoctorNotes.DoctorNote
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(patient_visit, attrs) do
    patient_visit
    |> cast(attrs, [
      :date,
      :reason,
      :patient_id,
      :visit_type,
      :time,
      :total_amount_paid,
      :creator_id,
      :doctor_id,
      :payment_type,
      :insurance_name,
      :has_paid,
      :excluded_from_insurance_invoice
    ])
    |> validate_required([:date, :patient_id, :creator_id, :payment_type, :has_paid])
    |> put_time_if_missing()
    |> put_date_if_missing()
  end

  defp put_date_if_missing(changeset) do
    if get_field(changeset, :date) do
      changeset
    else
      local_date =
        DateTime.utc_now()
        |> DateTime.add(3 * 60 * 60)
        |> DateTime.to_date()

      put_change(changeset, :date, local_date)
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
