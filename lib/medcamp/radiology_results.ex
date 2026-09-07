defmodule Medcamp.RadiologyResults do
  @moduledoc """
  The RadiologyResults context.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo

  alias Medcamp.RadiologyResults.RadiologyResult

  @doc """
  Returns the list of radiology_results.

  ## Examples

      iex> list_radiology_results()
      [%RadiologyResult{}, ...]

  """
  def list_radiology_results do
    Repo.all(RadiologyResult)
    |> Repo.preload([:patient, :doctor, :radiologist])
  end

  def list_radiology_results_paginated(page \\ 1, per_page \\ 20, filters \\ %{}) do
    RadiologyResult
    |> apply_radiology_result_filters(filters)
    |> order_by([r], desc: r.inserted_at)
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
    |> Repo.preload([:patient, :doctor, :radiologist])
  end

  def count_radiology_results(filters \\ %{}) do
    RadiologyResult
    |> apply_radiology_result_filters(filters)
    |> select([r], count(r.id))
    |> Repo.one()
  end

  defp apply_radiology_result_filters(query, filters) do
    query
    |> apply_radiology_result_search(Map.get(filters, "search", ""))
    |> apply_radiology_result_urgency(Map.get(filters, "urgency", ""))
    |> apply_radiology_result_report_complete(Map.get(filters, "report_complete", ""))
  end

  defp apply_radiology_result_search(query, ""), do: query

  defp apply_radiology_result_search(query, search) do
    term = "%#{search}%"

    query
    |> join(:left, [r], p in assoc(r, :patient))
    |> where([r, p], ilike(p.first_name, ^term) or ilike(p.last_name, ^term))
  end

  defp apply_radiology_result_urgency(query, ""), do: query

  defp apply_radiology_result_urgency(query, urgency),
    do: where(query, [r], r.urgency == ^urgency)

  defp apply_radiology_result_report_complete(query, ""), do: query

  defp apply_radiology_result_report_complete(query, "true"),
    do: where(query, [r], r.report_complete == true)

  defp apply_radiology_result_report_complete(query, "false"),
    do: where(query, [r], r.report_complete == false)

  def list_radiology_results_by_doctor_note_id(doctor_note_id) do
    from(r in RadiologyResult,
      where: r.doctor_note_id == ^doctor_note_id,
      order_by: [desc: r.inserted_at]
    )
    |> Repo.all()
    |> Repo.preload([:patient, :doctor, :radiologist])
  end

  def list_radiology_results_by_patient_id_paginated(patient_id, page \\ 1, per_page \\ 20) do
    from(r in RadiologyResult,
      where: r.patient_id == ^patient_id,
      order_by: [desc: r.inserted_at]
    )
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
    |> Repo.preload([:patient, :doctor, :radiologist])
  end

  def count_radiology_results_by_patient_id(patient_id) do
    from(r in RadiologyResult, where: r.patient_id == ^patient_id, select: count(r.id))
    |> Repo.one()
  end

  def list_radiology_results_by_patient_id(patient_id) do
    from(r in RadiologyResult,
      where: r.patient_id == ^patient_id,
      order_by: [desc: r.inserted_at]
    )
    |> Repo.all()
    |> Repo.preload([:patient, :doctor, :radiologist])
  end

  @doc """
  Gets a single radiology_result.

  Raises `Ecto.NoResultsError` if the Radiology result does not exist.

  ## Examples

      iex> get_radiology_result!(123)
      %RadiologyResult{}

      iex> get_radiology_result!(456)
      ** (Ecto.NoResultsError)

  """
  def get_radiology_result!(id),
    do: Repo.get!(RadiologyResult, id) |> Repo.preload([:patient, :doctor, :radiologist])

  @doc """
  Creates a radiology_result.

  ## Examples

      iex> create_radiology_result(%{field: value})
      {:ok, %RadiologyResult{}}

      iex> create_radiology_result(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_radiology_result(attrs \\ %{}) do
    %RadiologyResult{}
    |> RadiologyResult.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a radiology_result.

  ## Examples

      iex> update_radiology_result(radiology_result, %{field: new_value})
      {:ok, %RadiologyResult{}}

      iex> update_radiology_result(radiology_result, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_radiology_result(%RadiologyResult{} = radiology_result, attrs) do
    radiology_result
    |> RadiologyResult.changeset(attrs)
    |> Repo.audited_update()
  end

  @doc """
  Deletes a radiology_result.

  ## Examples

      iex> delete_radiology_result(radiology_result)
      {:ok, %RadiologyResult{}}

      iex> delete_radiology_result(radiology_result)
      {:error, %Ecto.Changeset{}}

  """
  def delete_radiology_result(%RadiologyResult{} = radiology_result) do
    Repo.delete(radiology_result)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking radiology_result changes.

  ## Examples

      iex> change_radiology_result(radiology_result)
      %Ecto.Changeset{data: %RadiologyResult{}}

  """
  def change_radiology_result(%RadiologyResult{} = radiology_result, attrs \\ %{}) do
    RadiologyResult.changeset(radiology_result, attrs)
  end
end
