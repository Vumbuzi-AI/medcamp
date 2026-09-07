defmodule Medcamp.Visitors do
  @moduledoc """
  The Visitors context.
  """

  import Ecto.Query, warn: false

  alias Medcamp.Repo
  alias Medcamp.Visitors.VisitorBookEntry

  def list_visitor_book_entries(opts \\ []) do
    opts
    |> normalize_opts()
    |> visitor_book_entries_query()
    |> Repo.all()
  end

  def list_visitor_book_entries_paginated(opts \\ [], page \\ 1, per_page \\ 10) do
    opts
    |> normalize_opts()
    |> visitor_book_entries_query()
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
  end

  def count_visitor_book_entries(opts \\ []) do
    VisitorBookEntry
    |> join(:left, [entry], user in assoc(entry, :user))
    |> apply_filters(normalize_opts(opts))
    |> select([entry], count(entry.id))
    |> Repo.one()
  end

  def count_distinct_visitor_recorders(opts \\ []) do
    VisitorBookEntry
    |> join(:left, [entry], user in assoc(entry, :user))
    |> apply_filters(normalize_opts(opts))
    |> where([entry], not is_nil(entry.user_id))
    |> select([entry], count(entry.user_id, :distinct))
    |> Repo.one()
  end

  defp visitor_book_entries_query(opts) do
    VisitorBookEntry
    |> join(:left, [entry], user in assoc(entry, :user))
    |> preload([_entry, user], user: user)
    |> order_by([entry], desc: entry.visited_on, desc: entry.visited_at, desc: entry.inserted_at)
    |> apply_filters(opts)
  end

  defp normalize_opts(opts) when is_map(opts), do: Map.to_list(opts)
  defp normalize_opts(opts), do: opts

  def create_visitor_book_entry(attrs \\ %{}) do
    %VisitorBookEntry{}
    |> VisitorBookEntry.changeset(attrs)
    |> Repo.insert()
  end

  def change_visitor_book_entry(%VisitorBookEntry{} = visitor_book_entry, attrs \\ %{}) do
    VisitorBookEntry.changeset(visitor_book_entry, attrs)
  end

  defp apply_filters(query, []), do: query

  defp apply_filters(query, [{:date_from, value} | rest]) do
    case parse_date(value) do
      nil -> apply_filters(query, rest)
      date -> query |> where([entry], entry.visited_on >= ^date) |> apply_filters(rest)
    end
  end

  defp apply_filters(query, [{:date_to, value} | rest]) do
    case parse_date(value) do
      nil -> apply_filters(query, rest)
      date -> query |> where([entry], entry.visited_on <= ^date) |> apply_filters(rest)
    end
  end

  defp apply_filters(query, [{:search, term} | rest]) when is_binary(term) do
    trimmed = String.trim(term)

    if trimmed == "" do
      apply_filters(query, rest)
    else
      pattern = "%#{trimmed}%"

      query
      |> where(
        [entry, user],
        ilike(entry.visitor_name, ^pattern) or
          ilike(entry.phone_number, ^pattern) or
          ilike(entry.person_to_see, ^pattern) or
          ilike(entry.purpose, ^pattern) or
          ilike(entry.message, ^pattern) or
          ilike(user.name, ^pattern)
      )
      |> apply_filters(rest)
    end
  end

  defp apply_filters(query, [_ | rest]), do: apply_filters(query, rest)

  defp parse_date(nil), do: nil
  defp parse_date(""), do: nil
  defp parse_date(%Date{} = date), do: date

  defp parse_date(value) when is_binary(value) do
    case Date.from_iso8601(value) do
      {:ok, date} -> date
      _ -> nil
    end
  end

  defp parse_date(_), do: nil
end
