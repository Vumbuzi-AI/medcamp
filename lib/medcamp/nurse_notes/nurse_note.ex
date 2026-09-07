defmodule Medcamp.NurseNotes.NurseNote do
  use Ecto.Schema
  import Ecto.Changeset

  schema "nurse_notes" do
    field :content, :string
    belongs_to :patient, Medcamp.Patients.Patient
    belongs_to :nurse, Medcamp.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(nurse_note, attrs) do
    nurse_note
    |> cast(attrs, [:content, :patient_id, :nurse_id])
    |> validate_required([:content, :patient_id, :nurse_id])
  end
end
