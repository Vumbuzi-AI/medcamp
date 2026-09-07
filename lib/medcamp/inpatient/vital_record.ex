defmodule Medcamp.Inpatient.VitalRecord do
  use Ecto.Schema
  import Ecto.Changeset

  schema "vital_records" do
    field :recorded_date, :date, default: Date.utc_today()
    field :recorded_time, :time
    field :blood_pressure, :string
    field :pulse_rate, :integer
    field :temperature, :decimal
    field :spo2, :integer
    field :respiratory_rate, :integer
    field :remarks, :string

    belongs_to :admission_note, Medcamp.Inpatient.AdmissionNote
    belongs_to :recorded_by, Medcamp.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(vital_record, attrs) do
    vital_record
    |> cast(attrs, [
      :recorded_date,
      :recorded_time,
      :blood_pressure,
      :pulse_rate,
      :temperature,
      :spo2,
      :respiratory_rate,
      :remarks,
      :admission_note_id,
      :recorded_by_id
    ])
    |> validate_required([
      :recorded_date,
      :recorded_time,
      :admission_note_id,
      :recorded_by_id
    ])
    |> validate_number(:pulse_rate, greater_than: 0, less_than: 300)
    |> validate_number(:temperature, greater_than: 30, less_than: 45)
    |> validate_number(:spo2, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    |> validate_number(:respiratory_rate, greater_than: 0, less_than: 100)
  end
end
