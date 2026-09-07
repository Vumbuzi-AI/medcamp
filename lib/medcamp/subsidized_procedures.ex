defmodule Medcamp.SubsidizedProcedures do
  @moduledoc """
  The SubsidizedProcedures context.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo

  alias Medcamp.SubsidizedProcedures.SubsidizedProcedure

  def list_subsidized_procedures do
    subsidized_procedures_query(%{}) |> Repo.all()
  end

  def filter_subsidized_procedures(filters) do
    subsidized_procedures_query(filters) |> Repo.all()
  end

  def filter_subsidized_procedures_paginated(filters \\ %{}, page \\ 1, per_page \\ 10) do
    subsidized_procedures_query(filters)
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
  end

  def count_subsidized_procedures(filters \\ %{}) do
    subsidized_procedures_base_query(filters)
    |> select([sp], count(sp.id))
    |> Repo.one()
  end

  def list_subsidized_procedures_for_selection do
    SubsidizedProcedure
    |> Repo.all()
    |> Enum.map(fn p -> {"#{p.name} - #{p.price} KES", p.id} end)
  end

  def get_subsidized_procedure!(id), do: Repo.get!(SubsidizedProcedure, id)

  def create_subsidized_procedure(attrs \\ %{}) do
    %SubsidizedProcedure{}
    |> SubsidizedProcedure.changeset(attrs)
    |> Repo.insert()
  end

  def update_subsidized_procedure(%SubsidizedProcedure{} = subsidized_procedure, attrs) do
    subsidized_procedure
    |> SubsidizedProcedure.changeset(attrs)
    |> Repo.audited_update()
  end

  def delete_subsidized_procedure(%SubsidizedProcedure{} = subsidized_procedure) do
    Repo.delete(subsidized_procedure)
  end

  def change_subsidized_procedure(%SubsidizedProcedure{} = subsidized_procedure, attrs \\ %{}) do
    SubsidizedProcedure.changeset(subsidized_procedure, attrs)
  end

  defp subsidized_procedures_query(filters) do
    subsidized_procedures_base_query(filters)
    |> order_by([sp], desc: sp.inserted_at)
  end

  defp subsidized_procedures_base_query(filters) do
    SubsidizedProcedure
    |> maybe_filter_search(filters[:search])
    |> maybe_filter_date_from(filters[:date_from])
    |> maybe_filter_date_to(filters[:date_to])
  end

  defp maybe_filter_search(query, nil), do: query
  defp maybe_filter_search(query, ""), do: query

  defp maybe_filter_search(query, search) do
    trimmed_search = String.trim(search)

    if trimmed_search == "" do
      query
    else
      from(sp in query, where: ilike(sp.name, ^"%#{trimmed_search}%"))
    end
  end

  defp maybe_filter_date_from(query, value) do
    case parse_filter_date(value) do
      {:ok, date} -> from(sp in query, where: fragment("date(?) >= ?", sp.inserted_at, ^date))
      :error -> query
    end
  end

  defp maybe_filter_date_to(query, value) do
    case parse_filter_date(value) do
      {:ok, date} -> from(sp in query, where: fragment("date(?) <= ?", sp.inserted_at, ^date))
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
