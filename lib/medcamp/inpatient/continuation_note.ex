defmodule Medcamp.Inpatient.ContinuationNote do
  use Ecto.Schema
  import Ecto.Changeset

  @review_types ["Major Ward Round", "Ward Round", "Periodic Review"]

  schema "continuation_notes" do
    field :review_date, :date, default: Date.utc_today()
    field :review_time, :time
    field :review_type, :string
    field :complaints, :string
    field :physical_examination, :string
    field :management_plan, :string

    # Vital signs at review
    field :blood_pressure, :string
    field :pulse_rate, :integer
    field :temperature, :decimal
    field :spo2, :integer
    field :respiratory_rate, :integer

    belongs_to :admission_note, Medcamp.Inpatient.AdmissionNote
    belongs_to :doctor, Medcamp.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(continuation_note, attrs) do
    continuation_note
    |> cast(attrs, [
      :review_date,
      :review_time,
      :review_type,
      :complaints,
      :physical_examination,
      :management_plan,
      :blood_pressure,
      :pulse_rate,
      :temperature,
      :spo2,
      :respiratory_rate,
      :admission_note_id,
      :doctor_id
    ])
    |> validate_required([
      :review_date,
      :review_time,
      :review_type,
      :admission_note_id,
      :doctor_id
    ])
    |> validate_inclusion(:review_type, @review_types)
  end

  def review_types, do: @review_types
end
