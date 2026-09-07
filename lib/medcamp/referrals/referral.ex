defmodule Medcamp.Referrals.Referral do
  use Ecto.Schema
  import Ecto.Changeset

  schema "referrals" do
    field :date, :date, default: Date.utc_today()
    field :time, :time
    field :referral_note, :string
    field :hospital, :string
    belongs_to :patient, Medcamp.Patients.Patient
    belongs_to :doctor, Medcamp.Accounts.User
    belongs_to :doctor_note, Medcamp.DoctorNotes.DoctorNote

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(referral, attrs) do
    referral
    |> cast(attrs, [
      :date,
      :time,
      :referral_note,
      :hospital,
      :patient_id,
      :doctor_id,
      :doctor_note_id
    ])
    |> validate_required([
      :date,
      :time,
      :referral_note,
      :hospital,
      :patient_id,
      :doctor_id,
      :doctor_note_id
    ])
    |> put_time_if_missing()
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
