defmodule Medcamp.Inpatient.TreatmentSheet do
  use Ecto.Schema
  import Ecto.Changeset

  @route_types ["Oral", "IV", "IM", "SC", "Topical", "Rectal", "Inhalation"]
  @prescription_types ["Regular", "Stat", "Fluids"]

  schema "treatment_sheets" do
    field :prescription_date, :date, default: Date.utc_today()
    field :prescription_time, :time
    field :prescription_type, :string, default: "Regular"
    field :drug_name, :string
    field :route, :string
    field :dose, :string
    field :units, :string
    field :frequency, :string
    field :duration_days, :integer
    field :notes, :string

    # Embedded administrations for tracking when meds were given
    embeds_many :administrations, Administration, on_replace: :delete do
      field :administered_date, :date
      field :administered_time, :time
      field :administered_by_id, :integer
      field :administered_by_name, :string
      field :notes, :string
    end

    belongs_to :admission_note, Medcamp.Inpatient.AdmissionNote
    belongs_to :prescriber, Medcamp.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(treatment_sheet, attrs) do
    treatment_sheet
    |> cast(attrs, [
      :prescription_date,
      :prescription_time,
      :prescription_type,
      :drug_name,
      :route,
      :dose,
      :units,
      :frequency,
      :duration_days,
      :notes,
      :admission_note_id,
      :prescriber_id
    ])
    |> cast_embed(:administrations, with: &administration_changeset/2)
    |> validate_required([
      :prescription_date,
      :drug_name,
      :route,
      :dose,
      :frequency,
      :admission_note_id,
      :prescriber_id
    ])
    |> validate_inclusion(:route, @route_types)
    |> validate_inclusion(:prescription_type, @prescription_types)
  end

  defp administration_changeset(administration, attrs) do
    administration
    |> cast(attrs, [
      :administered_date,
      :administered_time,
      :administered_by_id,
      :administered_by_name,
      :notes
    ])
    |> validate_required([:administered_date, :administered_time, :administered_by_id])
  end

  def route_types, do: @route_types
  def prescription_types, do: @prescription_types
end
