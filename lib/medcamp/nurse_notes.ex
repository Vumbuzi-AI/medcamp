defmodule Medcamp.NurseNotes do
  @moduledoc """
  The NurseNotes context.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo

  alias Medcamp.NurseNotes.NurseNote

  @doc """
  Returns the list of nurse_notes.

  ## Examples

      iex> list_nurse_notes()
      [%NurseNote{}, ...]

  """
  def list_nurse_notes do
    Repo.all(NurseNote)
  end

  def list_nurse_notes_by_patient(patient_id) do
    NurseNote
    |> where([n], n.patient_id == ^patient_id)
    |> Repo.all()
    |> Repo.preload([:patient, :nurse])
  end

  def list_nurse_notes_by_nurse(nurse_id, search \\ "") do
    NurseNote
    |> where([n], n.nurse_id == ^nurse_id)
    |> apply_nurse_note_search(search)
    |> Repo.all()
    |> Repo.preload([:patient, :nurse])
  end

  defp apply_nurse_note_search(query, ""), do: query

  defp apply_nurse_note_search(query, search) do
    term = "%#{search}%"

    query
    |> join(:left, [n], p in assoc(n, :patient))
    |> where(
      [n, p],
      ilike(p.first_name, ^term) or
        ilike(p.last_name, ^term) or
        ilike(n.content, ^term)
    )
  end

  def list_nurse_notes_by_nurse_paginated(nurse_id, search \\ "", page \\ 1, per_page \\ 10) do
    NurseNote
    |> where([n], n.nurse_id == ^nurse_id)
    |> order_by([n], desc: n.inserted_at)
    |> apply_nurse_note_search(search)
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
    |> Repo.preload([:patient, :nurse])
  end

  def count_nurse_notes_by_nurse(nurse_id, search \\ "") do
    NurseNote
    |> where([n], n.nurse_id == ^nurse_id)
    |> apply_nurse_note_search(search)
    |> Repo.aggregate(:count, :id)
  end

  def list_nurse_notes_by_patient_paginated(patient_id, page \\ 1, per_page \\ 10) do
    NurseNote
    |> where([n], n.patient_id == ^patient_id)
    |> order_by([n], desc: n.inserted_at)
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
    |> Repo.preload([:patient, :nurse])
  end

  def count_nurse_notes_by_patient(patient_id) do
    NurseNote
    |> where([n], n.patient_id == ^patient_id)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Gets a single nurse_note.

  Raises `Ecto.NoResultsError` if the Nurse note does not exist.

  ## Examples

      iex> get_nurse_note!(123)
      %NurseNote{}

      iex> get_nurse_note!(456)
      ** (Ecto.NoResultsError)

  """
  def get_nurse_note!(id),
    do:
      Repo.get!(NurseNote, id)
      |> Repo.preload([:patient, :nurse])

  @doc """
  Creates a nurse_note.

  ## Examples

      iex> create_nurse_note(%{field: value})
      {:ok, %NurseNote{}}

      iex> create_nurse_note(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_nurse_note(attrs \\ %{}) do
    %NurseNote{}
    |> NurseNote.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a nurse_note.

  ## Examples

      iex> update_nurse_note(nurse_note, %{field: new_value})
      {:ok, %NurseNote{}}

      iex> update_nurse_note(nurse_note, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_nurse_note(%NurseNote{} = nurse_note, attrs) do
    nurse_note
    |> NurseNote.changeset(attrs)
    |> Repo.audited_update()
  end

  @doc """
  Deletes a nurse_note.

  ## Examples

      iex> delete_nurse_note(nurse_note)
      {:ok, %NurseNote{}}

      iex> delete_nurse_note(nurse_note)
      {:error, %Ecto.Changeset{}}

  """
  def delete_nurse_note(%NurseNote{} = nurse_note) do
    Repo.delete(nurse_note)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking nurse_note changes.

  ## Examples

      iex> change_nurse_note(nurse_note)
      %Ecto.Changeset{data: %NurseNote{}}

  """
  def change_nurse_note(%NurseNote{} = nurse_note, attrs \\ %{}) do
    NurseNote.changeset(nurse_note, attrs)
  end
end
