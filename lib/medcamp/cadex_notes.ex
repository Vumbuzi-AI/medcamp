defmodule Medcamp.CadexNotes do
  @moduledoc """
  The CadexNotes context.

  CaDex notes are nursing notes captured per patient with a date + time.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo

  alias Medcamp.CadexNotes.CadexNote

  def list_cadex_notes_by_patient(patient_id) do
    CadexNote
    |> where([c], c.patient_id == ^patient_id)
    |> order_by([c], desc: c.note_date, desc: c.note_time, desc: c.inserted_at)
    |> Repo.all()
    |> Repo.preload([:patient, :nurse, :admission_note])
  end

  def list_cadex_notes_for_admission(admission_note_id) do
    CadexNote
    |> where([c], c.admission_note_id == ^admission_note_id)
    |> order_by([c], desc: c.note_date, desc: c.note_time, desc: c.inserted_at)
    |> Repo.all()
    |> Repo.preload([:patient, :nurse, :admission_note])
  end

  def get_cadex_note!(id) do
    Repo.get!(CadexNote, id)
    |> Repo.preload([:patient, :nurse, :admission_note])
  end

  def create_cadex_note(attrs \\ %{}) do
    %CadexNote{}
    |> CadexNote.changeset(attrs)
    |> Repo.insert()
  end

  def update_cadex_note(%CadexNote{} = cadex_note, attrs) do
    cadex_note
    |> CadexNote.changeset(attrs)
    |> Repo.audited_update()
  end

  def delete_cadex_note(%CadexNote{} = cadex_note) do
    Repo.delete(cadex_note)
  end

  def change_cadex_note(%CadexNote{} = cadex_note, attrs \\ %{}) do
    CadexNote.changeset(cadex_note, attrs)
  end
end
