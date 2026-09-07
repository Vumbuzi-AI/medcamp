defmodule Medcamp.CadexNotes.CadexNote do
  use Ecto.Schema
  import Ecto.Changeset

  schema "cadex_notes" do
    field :note_date, :date
    field :note_time, :time
    field :note, :string

    belongs_to :patient, Medcamp.Patients.Patient
    belongs_to :nurse, Medcamp.Accounts.User
    belongs_to :admission_note, Medcamp.Inpatient.AdmissionNote

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(cadex_note, attrs) do
    cadex_note
    |> cast(attrs, [:note_date, :note_time, :note, :patient_id, :nurse_id, :admission_note_id])
    |> validate_required([:note_date, :note_time, :note, :patient_id, :nurse_id])
    |> maybe_validate_admission_required()
  end

  defp maybe_validate_admission_required(changeset) do
    if get_field(changeset, :id) == nil do
      validate_required(changeset, [:admission_note_id])
    else
      changeset
    end
  end
end
