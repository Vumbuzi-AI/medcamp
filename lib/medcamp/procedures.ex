defmodule Medcamp.Procedures do
  @moduledoc """
  The Procedures context.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo

  alias Medcamp.Procedures.Procedure

  @doc """
  Returns the name of the regular or subsidized procedure associated with a
  procedure record.

  The supplied fallback is returned when neither association has a name.
  """
  def service_name(procedure_record, fallback)

  def service_name(%{procedure: %{name: name}}, _fallback)
      when is_binary(name) and name != "",
      do: name

  def service_name(%{subsidized_procedure: %{name: name}}, _fallback)
      when is_binary(name) and name != "",
      do: name

  def service_name(_procedure_record, fallback), do: fallback

  @doc """
  Returns the list of procedure.

  ## Examples

      iex> list_procedure()
      [%Procedure{}, ...]

  """
  def list_procedure do
    Repo.all(Procedure)
  end

  def filter_procedures(filters) do
    Procedure
    |> maybe_filter_search(filters[:search])
    |> maybe_filter_date_from(filters[:date_from])
    |> maybe_filter_date_to(filters[:date_to])
    |> Repo.all()
  end

  def filter_procedures_paginated(filters, page \\ 1, per_page \\ 20) do
    Procedure
    |> maybe_filter_search(filters[:search])
    |> maybe_filter_date_from(filters[:date_from])
    |> maybe_filter_date_to(filters[:date_to])
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
  end

  def count_procedures(filters) do
    Procedure
    |> maybe_filter_search(filters[:search])
    |> maybe_filter_date_from(filters[:date_from])
    |> maybe_filter_date_to(filters[:date_to])
    |> Repo.aggregate(:count, :id)
  end

  def list_procedures_for_selection do
    Procedure
    |> Repo.all()
    |> Enum.map(fn p -> {"#{p.name} - #{p.price} KES", p.id} end)
  end

  @doc """
  Gets a single procedure.

  Raises `Ecto.NoResultsError` if the Procedure does not exist.

  ## Examples

      iex> get_procedure!(123)
      %Procedure{}

      iex> get_procedure!(456)
      ** (Ecto.NoResultsError)

  """
  def get_procedure!(id), do: Repo.get!(Procedure, id)

  @doc """
  Creates a procedure.

  ## Examples

      iex> create_procedure(%{field: value})
      {:ok, %Procedure{}}

      iex> create_procedure(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_procedure(attrs \\ %{}) do
    %Procedure{}
    |> Procedure.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a procedure.

  ## Examples

      iex> update_procedure(procedure, %{field: new_value})
      {:ok, %Procedure{}}

      iex> update_procedure(procedure, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_procedure(%Procedure{} = procedure, attrs) do
    procedure
    |> Procedure.changeset(attrs)
    |> Repo.audited_update()
  end

  @doc """
  Deletes a procedure.

  ## Examples

      iex> delete_procedure(procedure)
      {:ok, %Procedure{}}

      iex> delete_procedure(procedure)
      {:error, %Ecto.Changeset{}}

  """
  def delete_procedure(%Procedure{} = procedure) do
    Repo.delete(procedure)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking procedure changes.

  ## Examples

      iex> change_procedure(procedure)
      %Ecto.Changeset{data: %Procedure{}}

  """
  def change_procedure(%Procedure{} = procedure, attrs \\ %{}) do
    Procedure.changeset(procedure, attrs)
  end

  defp maybe_filter_search(query, nil), do: query
  defp maybe_filter_search(query, ""), do: query

  defp maybe_filter_search(query, search) do
    trimmed_search = String.trim(search)

    if trimmed_search == "" do
      query
    else
      from(p in query, where: ilike(p.name, ^"%#{trimmed_search}%"))
    end
  end

  defp maybe_filter_date_from(query, value) do
    case parse_filter_date(value) do
      {:ok, date} -> from(p in query, where: fragment("date(?) >= ?", p.inserted_at, ^date))
      :error -> query
    end
  end

  defp maybe_filter_date_to(query, value) do
    case parse_filter_date(value) do
      {:ok, date} -> from(p in query, where: fragment("date(?) <= ?", p.inserted_at, ^date))
      :error -> query
    end
  end

  defp parse_filter_date(nil), do: :error
  defp parse_filter_date(""), do: :error
  defp parse_filter_date(%Date{} = date), do: {:ok, date}

  defp parse_filter_date(value) when is_binary(value) do
    case Date.from_iso8601(String.trim(value)) do
      {:ok, date} -> {:ok, date}
      _ -> :error
    end
  end
end
