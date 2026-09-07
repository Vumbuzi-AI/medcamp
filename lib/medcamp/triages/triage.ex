defmodule Medcamp.Triages.Triage do
  use Ecto.Schema
  import Ecto.Changeset

  schema "triages" do
    field :date, :date
    field :temperature, :float
    field :blood_pressure, :string
    field :pulse_rate, :float
    field :oxygen_saturation, :float
    field :height, :float
    field :bmi, :float
    field :weight, :float
    field :allergies, :string
    field :emergency_scale, :string
    field :alert, :boolean, default: true
    field :verbal, :boolean, default: true
    field :pain, :boolean, default: false
    field :unresponsive, :boolean, default: false
    field :time, :time
    field :triage_notes, :string
    belongs_to :patient, Medcamp.Patients.Patient
    belongs_to :creator, Medcamp.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(triage, attrs) do
    triage
    |> cast(attrs, [
      :temperature,
      :blood_pressure,
      :pulse_rate,
      :bmi,
      :oxygen_saturation,
      :height,
      :weight,
      :date,
      :time,
      :allergies,
      :emergency_scale,
      :alert,
      :verbal,
      :pain,
      :unresponsive,
      :triage_notes,
      :patient_id,
      :creator_id
    ])
    |> validate_required([
      :temperature,
      :blood_pressure,
      :pulse_rate,
      :oxygen_saturation,
      :height,
      :weight,
      :date
    ])
    |> put_date_if_missing()
    |> put_time_if_missing()
    |> calculate_bmi()
  end

  defp put_date_if_missing(changeset) do
    if get_field(changeset, :date) do
      changeset
    else
      put_change(changeset, :date, Date.utc_today())
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

  defp calculate_bmi(changeset) do
    height = get_field(changeset, :height)
    weight = get_field(changeset, :weight)

    if height && weight && height > 0 do
      height_in_meters = height / 100
      bmi = weight / (height_in_meters * height_in_meters)

      bmi_rounded = Float.round(bmi, 2)

      put_change(changeset, :bmi, bmi_rounded)
    else
      changeset
    end
  end
end
