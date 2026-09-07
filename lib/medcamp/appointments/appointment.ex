defmodule Medcamp.Appointments.Appointment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "appointments" do
    field :reason, :string
    field :date, :date, default: Date.utc_today()
    field :time, :time
    belongs_to :patient, Medcamp.Patients.Patient
    belongs_to :doctor, Medcamp.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(appointment, attrs) do
    appointment
    |> cast(attrs, [:date, :time, :reason, :patient_id, :doctor_id])
    |> put_time_if_missing()
    |> validate_required([:date, :time, :reason, :patient_id])
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
