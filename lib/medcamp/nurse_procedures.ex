defmodule Medcamp.NurseProcedures do
  @moduledoc """
  The NurseProcedures context.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo

  alias Medcamp.NurseProcedures.NurseProcedure

  @doc """
  Returns the list of nurse_procedures.

  ## Examples

      iex> list_nurse_procedures()
      [%NurseProcedure{}, ...]

  """
  def list_nurse_procedures do
    Repo.all(NurseProcedure)
    |> Repo.preload([:procedure, :subsidized_procedure, :nurse, :patient])
  end

  def list_nurse_procedures_for_nurse(nurse_id, filters \\ %{}) do
    NurseProcedure
    |> where([np], np.nurse_id == ^nurse_id)
    |> apply_nurse_procedure_search(filters[:search])
    |> apply_nurse_procedure_payment_type(filters[:payment_type])
    |> apply_nurse_procedure_status(filters[:status])
    |> Repo.all()
    |> Repo.preload([:procedure, :subsidized_procedure, :nurse, :patient])
  end

  @doc """
  Returns the distinct, non-nil payment types currently in use, for populating
  a filter dropdown without hardcoding values the data may not actually use.
  """
  def list_distinct_payment_types do
    NurseProcedure
    |> where([np], not is_nil(np.payment_type) and np.payment_type != "")
    |> distinct(true)
    |> select([np], np.payment_type)
    |> order_by([np], np.payment_type)
    |> Repo.all()
  end

  defp apply_nurse_procedure_search(query, nil), do: query
  defp apply_nurse_procedure_search(query, ""), do: query

  defp apply_nurse_procedure_search(query, term) do
    term = String.trim(term)

    if term == "" do
      query
    else
      pattern = "%#{term}%"

      from(np in query,
        left_join: pat in assoc(np, :patient),
        where:
          ilike(pat.first_name, ^pattern) or ilike(pat.middle_name, ^pattern) or
            ilike(pat.last_name, ^pattern)
      )
    end
  end

  defp apply_nurse_procedure_payment_type(query, nil), do: query
  defp apply_nurse_procedure_payment_type(query, ""), do: query

  defp apply_nurse_procedure_payment_type(query, payment_type) do
    from(np in query, where: np.payment_type == ^payment_type)
  end

  defp apply_nurse_procedure_status(query, "paid"),
    do: from(np in query, where: np.has_paid == true)

  defp apply_nurse_procedure_status(query, "not_paid"),
    do: from(np in query, where: np.has_paid == false)

  defp apply_nurse_procedure_status(query, _), do: query

  def list_nurse_procedures_for_patient(patient_id) do
    NurseProcedure
    |> where([np], np.patient_id == ^patient_id)
    |> Repo.all()
    |> Repo.preload([:procedure, :subsidized_procedure, :nurse, :patient])
  end

  def list_nurse_procedures_for_nurse_paginated(
        nurse_id,
        filters \\ %{},
        page \\ 1,
        per_page \\ 10
      ) do
    NurseProcedure
    |> where([np], np.nurse_id == ^nurse_id)
    |> apply_nurse_procedure_search(filters[:search])
    |> apply_nurse_procedure_payment_type(filters[:payment_type])
    |> apply_nurse_procedure_status(filters[:status])
    |> order_by([np], desc: np.inserted_at)
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
    |> Repo.preload([:procedure, :subsidized_procedure, :nurse, :patient])
  end

  def count_nurse_procedures_for_nurse(nurse_id, filters \\ %{}) do
    NurseProcedure
    |> where([np], np.nurse_id == ^nurse_id)
    |> apply_nurse_procedure_search(filters[:search])
    |> apply_nurse_procedure_payment_type(filters[:payment_type])
    |> apply_nurse_procedure_status(filters[:status])
    |> Repo.aggregate(:count, :id)
  end

  def list_nurse_procedures_for_patient_paginated(patient_id, page \\ 1, per_page \\ 10) do
    NurseProcedure
    |> where([np], np.patient_id == ^patient_id)
    |> order_by([np], desc: np.inserted_at)
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
    |> Repo.preload([:procedure, :subsidized_procedure, :nurse, :patient])
  end

  def count_nurse_procedures_for_patient(patient_id) do
    NurseProcedure
    |> where([np], np.patient_id == ^patient_id)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Gets a single nurse_procedure.

  Raises `Ecto.NoResultsError` if the Nurse procedure does not exist.

  ## Examples

      iex> get_nurse_procedure!(123)
      %NurseProcedure{}

      iex> get_nurse_procedure!(456)
      ** (Ecto.NoResultsError)

  """
  def get_nurse_procedure!(id),
    do:
      Repo.get!(NurseProcedure, id)
      |> Repo.preload([:procedure, :subsidized_procedure, :nurse, :patient])

  @doc """
  Creates a nurse_procedure.

  ## Examples

      iex> create_nurse_procedure(%{field: value})
      {:ok, %NurseProcedure{}}

      iex> create_nurse_procedure(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_nurse_procedure(attrs \\ %{}) do
    %NurseProcedure{}
    |> NurseProcedure.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a nurse_procedure.

  ## Examples

      iex> update_nurse_procedure(nurse_procedure, %{field: new_value})
      {:ok, %NurseProcedure{}}

      iex> update_nurse_procedure(nurse_procedure, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_nurse_procedure(%NurseProcedure{} = nurse_procedure, attrs) do
    nurse_procedure
    |> NurseProcedure.changeset(attrs)
    |> Repo.audited_update()
  end

  @doc """
  Deletes a nurse_procedure.

  ## Examples

      iex> delete_nurse_procedure(nurse_procedure)
      {:ok, %NurseProcedure{}}

      iex> delete_nurse_procedure(nurse_procedure)
      {:error, %Ecto.Changeset{}}

  """
  def delete_nurse_procedure(%NurseProcedure{} = nurse_procedure) do
    Repo.delete(nurse_procedure)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking nurse_procedure changes.

  ## Examples

      iex> change_nurse_procedure(nurse_procedure)
      %Ecto.Changeset{data: %NurseProcedure{}}

  """
  def change_nurse_procedure(%NurseProcedure{} = nurse_procedure, attrs \\ %{}) do
    NurseProcedure.changeset(nurse_procedure, attrs)
  end
end
