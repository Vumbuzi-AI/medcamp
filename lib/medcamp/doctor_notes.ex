defmodule Medcamp.DoctorNotes do
  @moduledoc """
  The DoctorNotes context.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo

  alias Medcamp.DoctorNotes.DoctorNote

  @doc """
  Returns the list of doctor_notes.

  ## Examples

      iex> list_doctor_notes()
      [%DoctorNote{}, ...]

  """
  def list_doctor_notes do
    Repo.all(DoctorNote)
    |> Repo.preload(:doctor)
  end

  @doc """
  Returns doctor notes used by the admin documentation-quality report.

  Supported filters are `:date_from`, `:date_to`, and `:doctor_id`.
  """
  def list_doctor_notes_for_quality(filters \\ %{}) do
    DoctorNote
    |> maybe_filter_quality_date(:date_from, filters[:date_from], :>=)
    |> maybe_filter_quality_date(:date_to, filters[:date_to], :<=)
    |> maybe_filter_quality_doctor(filters[:doctor_id])
    |> order_by([note], desc: note.date, desc: note.time)
    |> preload(:doctor)
    |> Repo.all()
  end

  defp maybe_filter_quality_date(query, _field, nil, _operator), do: query

  defp maybe_filter_quality_date(query, :date_from, date, :>=),
    do: where(query, [note], note.date >= ^date)

  defp maybe_filter_quality_date(query, :date_to, date, :<=),
    do: where(query, [note], note.date <= ^date)

  defp maybe_filter_quality_doctor(query, nil), do: query
  defp maybe_filter_quality_doctor(query, ""), do: query
  defp maybe_filter_quality_doctor(query, "all"), do: query

  defp maybe_filter_quality_doctor(query, doctor_id),
    do: where(query, [note], note.doctor_id == ^doctor_id)

  def list_doctor_notes_for_doctor(doctor_id) do
    from(d in DoctorNote,
      where: d.doctor_id == ^doctor_id,
      order_by: [desc: d.inserted_at]
    )
    |> Repo.all()
    |> Repo.preload(:doctor)
  end

  def doctor_notes_for_patient(patient_id) do
    from(d in DoctorNote,
      where: d.patient_id == ^patient_id,
      order_by: [desc: d.inserted_at]
    )
    |> Repo.all()
    |> Repo.preload([:doctor, :patient_visit])
  end

  def list_doctor_notes_for_patients([]), do: []

  def list_doctor_notes_for_patients(patient_ids) do
    from(d in DoctorNote,
      where: d.patient_id in ^patient_ids,
      order_by: [desc: d.inserted_at]
    )
    |> Repo.all()
    |> Repo.preload([:doctor, :patient_visit])
  end

  def list_doctor_note_options_for_patient(patient_id) do
    doctor_notes_for_patient(patient_id)
    |> Enum.map(fn note ->
      doctor_name = (note.doctor && note.doctor.name) || "Unknown Doctor"

      label =
        [
          note.date && Calendar.strftime(note.date, "%d %b %Y"),
          note.time && Time.to_string(note.time),
          "Dr. #{doctor_name}"
        ]
        |> Enum.reject(&is_nil/1)
        |> Enum.join(" • ")

      {label, note.id}
    end)
  end

  @doc """
  Gets a single doctor_note.

  Raises `Ecto.NoResultsError` if the Doctor note does not exist.

  ## Examples

      iex> get_doctor_note!(123)
      %DoctorNote{}

      iex> get_doctor_note!(456)
      ** (Ecto.NoResultsError)

  """
  def get_doctor_note!(id) do
    Repo.get!(DoctorNote, id)
    |> Repo.preload([:doctor, child_notes: [:doctor]])
  end

  def get_child_notes_for_note(parent_id) do
    from(d in DoctorNote,
      where: d.parent_id == ^parent_id,
      order_by: [asc: d.inserted_at]
    )
    |> Repo.all()
    |> Repo.preload(:doctor)
  end

  def count_patients_with_doctor_notes(patient_ids) when patient_ids == [], do: 0

  def count_patients_with_doctor_notes(patient_ids) do
    from(d in DoctorNote,
      where: d.patient_id in ^patient_ids,
      select: count(d.patient_id, :distinct)
    )
    |> Repo.one()
  end

  def create_child_doctor_note(attrs \\ %{}) do
    %DoctorNote{}
    |> DoctorNote.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates a doctor_note.

  ## Examples

      iex> create_doctor_note(%{field: value})
      {:ok, %DoctorNote{}}

      iex> create_doctor_note(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_doctor_note(attrs \\ %{}) do
    %DoctorNote{}
    |> DoctorNote.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a doctor_note.

  ## Examples

      iex> update_doctor_note(doctor_note, %{field: new_value})
      {:ok, %DoctorNote{}}

      iex> update_doctor_note(doctor_note, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_doctor_note(%DoctorNote{} = doctor_note, attrs) do
    doctor_note
    |> DoctorNote.changeset(attrs)
    |> Repo.audited_update()
  end

  @doc """
  Deletes a doctor_note.

  ## Examples

      iex> delete_doctor_note(doctor_note)
      {:ok, %DoctorNote{}}

      iex> delete_doctor_note(doctor_note)
      {:error, %Ecto.Changeset{}}

  """
  def delete_doctor_note(%DoctorNote{} = doctor_note) do
    Repo.delete(doctor_note)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking doctor_note changes.

  ## Examples

      iex> change_doctor_note(doctor_note)
      %Ecto.Changeset{data: %DoctorNote{}}

  """
  def change_doctor_note(%DoctorNote{} = doctor_note, attrs \\ %{}) do
    DoctorNote.changeset(doctor_note, attrs)
  end
end
