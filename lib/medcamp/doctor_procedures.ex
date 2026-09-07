defmodule Medcamp.DoctorProcedures do
  @moduledoc """
  The DoctorProcedures context.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo

  alias Medcamp.DoctorProcedures.DoctorProcedure

  @doc """
  Returns the list of doctor_procedures.

  ## Examples

      iex> list_doctor_procedures()
      [%DoctorProcedure{}, ...]

  """
  def list_doctor_procedures do
    Repo.all(DoctorProcedure)
  end

  def list_doctor_procedures_for_doctor(doctor_id) do
    DoctorProcedure
    |> where([dp], dp.doctor_id == ^doctor_id)
    |> Repo.all()
    |> Repo.preload([:procedure, :subsidized_procedure, :doctor, :patient])
  end

  def list_doctor_procedures_for_doctor_paginated(
        doctor_id,
        filters \\ %{},
        page \\ 1,
        per_page \\ 20
      ) do
    doctor_id
    |> doctor_procedures_for_doctor_query(filters)
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
    |> Repo.preload([:procedure, :subsidized_procedure, :doctor, :patient])
  end

  def count_doctor_procedures_for_doctor(doctor_id, filters \\ %{}) do
    doctor_id
    |> doctor_procedures_for_doctor_query(filters)
    |> Repo.aggregate(:count, :id)
  end

  defp doctor_procedures_for_doctor_query(doctor_id, filters) do
    from(dp in DoctorProcedure,
      as: :doctor_procedure,
      left_join: patient in assoc(dp, :patient),
      as: :patient,
      left_join: procedure in assoc(dp, :procedure),
      as: :procedure,
      left_join: subsidized_procedure in assoc(dp, :subsidized_procedure),
      as: :subsidized_procedure,
      where: dp.doctor_id == ^doctor_id,
      order_by: [desc: dp.inserted_at]
    )
    |> apply_doctor_procedure_search(filters[:search])
    |> apply_doctor_procedure_payment_type(filters[:payment_type])
    |> apply_doctor_procedure_status(filters[:status])
    |> apply_doctor_procedure_price(:min, filters[:min_price])
    |> apply_doctor_procedure_price(:max, filters[:max_price])
    |> apply_doctor_procedure_date(:from, filters[:date_from])
    |> apply_doctor_procedure_date(:to, filters[:date_to])
    |> apply_doctor_procedure_type(filters[:procedure_id])
  end

  defp apply_doctor_procedure_search(query, nil), do: query
  defp apply_doctor_procedure_search(query, ""), do: query

  defp apply_doctor_procedure_search(query, term) do
    term = String.trim(term)

    if term == "" do
      query
    else
      pattern = "%#{term}%"

      from([doctor_procedure: dp, patient: pat, procedure: p, subsidized_procedure: sp] in query,
        where:
          ilike(pat.first_name, ^pattern) or ilike(pat.middle_name, ^pattern) or
            ilike(pat.last_name, ^pattern) or ilike(p.name, ^pattern) or
            ilike(sp.name, ^pattern)
      )
    end
  end

  defp apply_doctor_procedure_price(query, _boundary, value) when value in [nil, ""], do: query

  defp apply_doctor_procedure_price(query, boundary, value) do
    case parse_price(value) do
      {:ok, price} -> filter_doctor_procedure_price(query, boundary, price)
      :error -> query
    end
  end

  defp filter_doctor_procedure_price(query, :min, price) do
    from([procedure: p, subsidized_procedure: sp] in query,
      where: p.price >= ^price or sp.price >= ^price
    )
  end

  defp filter_doctor_procedure_price(query, :max, price) do
    from([procedure: p, subsidized_procedure: sp] in query,
      where: p.price <= ^price or sp.price <= ^price
    )
  end

  defp apply_doctor_procedure_type(query, value) when value in [nil, ""], do: query

  defp apply_doctor_procedure_type(query, procedure_id) do
    from([doctor_procedure: dp] in query, where: dp.procedure_id == ^procedure_id)
  end

  defp apply_doctor_procedure_payment_type(query, nil), do: query
  defp apply_doctor_procedure_payment_type(query, ""), do: query

  defp apply_doctor_procedure_payment_type(query, payment_type) do
    from(dp in query, where: dp.payment_type == ^payment_type)
  end

  defp apply_doctor_procedure_status(query, "paid"),
    do: from(dp in query, where: dp.has_paid == true)

  defp apply_doctor_procedure_status(query, "not_paid"),
    do: from(dp in query, where: dp.has_paid == false)

  defp apply_doctor_procedure_status(query, _), do: query

  defp apply_doctor_procedure_date(query, _boundary, value) when value in [nil, ""], do: query

  defp apply_doctor_procedure_date(query, boundary, value) do
    case parse_date(value) do
      {:ok, date} when boundary == :from ->
        where(query, [doctor_procedure: dp], fragment("DATE(?)", dp.inserted_at) >= ^date)

      {:ok, date} when boundary == :to ->
        where(query, [doctor_procedure: dp], fragment("DATE(?)", dp.inserted_at) <= ^date)

      :error ->
        query
    end
  end

  @doc """
  Lists every regular procedure type together with how often the given doctor
  has performed it and how many distinct patients received it.
  """
  def list_procedure_types_for_doctor_paginated(
        doctor_id,
        filters \\ %{},
        page \\ 1,
        per_page \\ 20
      ) do
    doctor_id
    |> procedure_types_for_doctor_query(filters)
    |> limit(^per_page)
    |> offset(^((page - 1) * per_page))
    |> Repo.all()
  end

  def count_procedure_types(filters \\ %{}) do
    Medcamp.Procedures.Procedure
    |> apply_procedure_type_search(filters[:search])
    |> apply_procedure_type_price(:min, filters[:min_price])
    |> apply_procedure_type_price(:max, filters[:max_price])
    |> Repo.aggregate(:count, :id)
  end

  defp procedure_types_for_doctor_query(doctor_id, filters) do
    performed_procedures =
      from(dp in DoctorProcedure, as: :doctor_procedure, where: dp.doctor_id == ^doctor_id)
      |> apply_doctor_procedure_date(:from, filters[:date_from])
      |> apply_doctor_procedure_date(:to, filters[:date_to])

    from(p in Medcamp.Procedures.Procedure,
      left_join: dp in subquery(performed_procedures),
      on: dp.procedure_id == p.id,
      group_by: p.id,
      select: %{
        id: p.id,
        name: p.name,
        description: p.description,
        price: p.price,
        performed_count: count(dp.id),
        patient_count: count(dp.patient_id, :distinct),
        last_performed_at: max(dp.inserted_at)
      },
      order_by: [desc: count(dp.id), asc: p.name]
    )
    |> apply_procedure_type_search(filters[:search])
    |> apply_procedure_type_price(:min, filters[:min_price])
    |> apply_procedure_type_price(:max, filters[:max_price])
  end

  defp apply_procedure_type_search(query, value) when value in [nil, ""], do: query

  defp apply_procedure_type_search(query, value) do
    value = String.trim(value)

    if value == "" do
      query
    else
      from(p in query, where: ilike(p.name, ^"%#{value}%"))
    end
  end

  defp apply_procedure_type_price(query, _boundary, value) when value in [nil, ""], do: query

  defp apply_procedure_type_price(query, boundary, value) do
    case parse_price(value) do
      {:ok, price} when boundary == :min -> from(p in query, where: p.price >= ^price)
      {:ok, price} when boundary == :max -> from(p in query, where: p.price <= ^price)
      :error -> query
    end
  end

  @doc """
  Returns a procedure type and the signed-in doctor's summary for that type.
  """
  def get_procedure_type_stats_for_doctor!(doctor_id, procedure_id) do
    procedure = Medcamp.Procedures.get_procedure!(procedure_id)

    stats =
      from(dp in DoctorProcedure,
        where: dp.doctor_id == ^doctor_id and dp.procedure_id == ^procedure_id,
        select: %{
          performed_count: count(dp.id),
          patient_count: count(dp.patient_id, :distinct),
          paid_count: filter(count(dp.id), dp.has_paid == true),
          total_collected: coalesce(sum(dp.total_amount_paid), 0),
          last_performed_at: max(dp.inserted_at)
        }
      )
      |> Repo.one!()

    Map.put(stats, :procedure, procedure)
  end

  defp parse_price(value) when is_integer(value) and value >= 0, do: {:ok, value}

  defp parse_price(value) when is_binary(value) do
    case Integer.parse(String.trim(value)) do
      {price, ""} when price >= 0 -> {:ok, price}
      _ -> :error
    end
  end

  defp parse_price(_), do: :error

  defp parse_date(%Date{} = value), do: {:ok, value}

  defp parse_date(value) when is_binary(value) do
    case Date.from_iso8601(String.trim(value)) do
      {:ok, date} -> {:ok, date}
      _ -> :error
    end
  end

  defp parse_date(_), do: :error

  @doc """
  Returns the distinct, non-nil payment types currently in use, for populating
  a filter dropdown without hardcoding values the data may not actually use.
  """
  def list_distinct_payment_types do
    DoctorProcedure
    |> where([dp], not is_nil(dp.payment_type) and dp.payment_type != "")
    |> distinct(true)
    |> select([dp], dp.payment_type)
    |> order_by([dp], dp.payment_type)
    |> Repo.all()
  end

  def list_doctor_procedures_for_patient(patient_id) do
    DoctorProcedure
    |> where([dp], dp.patient_id == ^patient_id)
    |> Repo.all()
    |> Repo.preload([:procedure, :subsidized_procedure, :doctor, :patient])
  end

  def list_doctor_procedures_for_patient_paginated(patient_id, page \\ 1, per_page \\ 10) do
    DoctorProcedure
    |> where([dp], dp.patient_id == ^patient_id)
    |> order_by([dp], desc: dp.inserted_at)
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
    |> Repo.preload([:procedure, :subsidized_procedure, :doctor, :patient])
  end

  def count_doctor_procedures_for_patient(patient_id) do
    from(dp in DoctorProcedure, where: dp.patient_id == ^patient_id, select: count(dp.id))
    |> Repo.one()
  end

  @doc """
  Gets a single doctor_procedure.

  Raises `Ecto.NoResultsError` if the Doctor procedure does not exist.

  ## Examples

      iex> get_doctor_procedure!(123)
      %DoctorProcedure{}

      iex> get_doctor_procedure!(456)
      ** (Ecto.NoResultsError)

  """
  def get_doctor_procedure!(id),
    do:
      Repo.get!(DoctorProcedure, id)
      |> Repo.preload([:procedure, :subsidized_procedure, :doctor, :patient])

  @doc """
  Creates a doctor_procedure.

  ## Examples

      iex> create_doctor_procedure(%{field: value})
      {:ok, %DoctorProcedure{}}

      iex> create_doctor_procedure(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_doctor_procedure(attrs \\ %{}) do
    %DoctorProcedure{}
    |> DoctorProcedure.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a doctor_procedure.

  ## Examples

      iex> update_doctor_procedure(doctor_procedure, %{field: new_value})
      {:ok, %DoctorProcedure{}}

      iex> update_doctor_procedure(doctor_procedure, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_doctor_procedure(%DoctorProcedure{} = doctor_procedure, attrs) do
    doctor_procedure
    |> DoctorProcedure.changeset(attrs)
    |> Repo.audited_update()
  end

  @doc """
  Deletes a doctor_procedure.

  ## Examples

      iex> delete_doctor_procedure(doctor_procedure)
      {:ok, %DoctorProcedure{}}

      iex> delete_doctor_procedure(doctor_procedure)
      {:error, %Ecto.Changeset{}}

  """
  def delete_doctor_procedure(%DoctorProcedure{} = doctor_procedure) do
    Repo.delete(doctor_procedure)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking doctor_procedure changes.

  ## Examples

      iex> change_doctor_procedure(doctor_procedure)
      %Ecto.Changeset{data: %DoctorProcedure{}}

  """
  def change_doctor_procedure(%DoctorProcedure{} = doctor_procedure, attrs \\ %{}) do
    DoctorProcedure.changeset(doctor_procedure, attrs)
  end
end
