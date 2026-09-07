defmodule Medcamp.PatientFormRecords do
  @moduledoc """
  The PatientFormRecords context.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo
  alias Medcamp.PatientFormRecords.PatientFormRecord

  def list_by_patient(patient_id) do
    list_patient_form_records(patient_id)
  end

  def get!(id) do
    get_patient_form_record!(id)
  end

  def create(attrs \\ %{}) do
    attrs = normalize_legacy_attrs(attrs)

    create_patient_form_record(attrs)
  end

  def delete(%PatientFormRecord{} = record) do
    delete_patient_form_record(record)
  end

  def change(%PatientFormRecord{} = record, attrs \\ %{}) do
    change_patient_form_record(record, attrs)
  end

  def list_patient_form_records(patient_id) do
    Repo.all(
      from r in PatientFormRecord,
        where: r.patient_id == ^patient_id,
        order_by: [desc: r.inserted_at],
        preload: [:created_by, :updated_by]
    )
  end

  def get_patient_form_record!(id),
    do: Repo.get!(PatientFormRecord, id) |> Repo.preload([:created_by, :updated_by])

  def get_patient_form_record_for_patient!(patient_id, id) do
    Repo.get_by!(PatientFormRecord, id: id, patient_id: patient_id)
    |> Repo.preload([:created_by, :updated_by])
  end

  def create_patient_form_record(attrs \\ %{}) do
    %PatientFormRecord{}
    |> PatientFormRecord.changeset(attrs)
    |> Repo.insert()
  end

  def update_patient_form_record(%PatientFormRecord{} = record, attrs) do
    record
    |> PatientFormRecord.changeset(normalize_legacy_attrs(attrs))
    |> Repo.update()
  end

  def delete_patient_form_record(%PatientFormRecord{} = record) do
    Repo.delete(record)
  end

  def change_patient_form_record(%PatientFormRecord{} = record, attrs \\ %{}) do
    PatientFormRecord.changeset(record, normalize_legacy_attrs(attrs))
  end

  defp normalize_legacy_attrs(attrs) when is_map(attrs) do
    attrs
    |> maybe_move_recorded_by_id()
    |> maybe_move_notes()
  end

  defp normalize_legacy_attrs(attrs), do: attrs

  defp maybe_move_recorded_by_id(attrs) do
    recorded_by_id = Map.get(attrs, :recorded_by_id) || Map.get(attrs, "recorded_by_id")

    if recorded_by_id do
      attrs
      |> Map.put_new(:created_by_id, recorded_by_id)
      |> Map.put_new(:updated_by_id, recorded_by_id)
      |> Map.put_new("created_by_id", recorded_by_id)
      |> Map.put_new("updated_by_id", recorded_by_id)
    else
      attrs
    end
  end

  defp maybe_move_notes(attrs) do
    notes = Map.get(attrs, :notes) || Map.get(attrs, "notes")

    cond do
      not (is_binary(notes) and String.trim(notes) != "") ->
        attrs

      Map.has_key?(attrs, :form_data) and is_map(Map.get(attrs, :form_data)) ->
        Map.update!(attrs, :form_data, &Map.put(&1, "notes", notes))

      Map.has_key?(attrs, "form_data") and is_map(Map.get(attrs, "form_data")) ->
        Map.update!(attrs, "form_data", &Map.put(&1, "notes", notes))

      true ->
        Map.put(attrs, :form_data, %{"notes" => notes})
    end
  end
end
