defmodule Medcamp.LabTests do
  @moduledoc """
  The LabTests context.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo

  alias Medcamp.LabTests.LabTest

  @doc """
  Returns the list of lab_tests.

  ## Examples

      iex> list_lab_tests()
      [%LabTest{}, ...]

  """
  def list_lab_tests do
    filtered_lab_tests_query(%{})
    |> Repo.all()
  end

  def list_lab_tests_paginated(filters \\ %{}, page \\ 1, per_page \\ 20) do
    filtered_lab_tests_query(filters)
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
  end

  def get_camp_lab_tests(keywords) do
    conditions =
      Enum.reduce(keywords, false, fn keyword, acc ->
        import Ecto.Query
        dynamic([t], ilike(t.name, ^"%#{keyword}%") or ^acc)
      end)

    Repo.all(from t in LabTest, where: ^conditions)
  end

  def filter_lab_tests(filters) do
    filtered_lab_tests_query(filters)
    |> Repo.all()
  end

  def filter_lab_tests_paginated(filters, page \\ 1, per_page \\ 20) do
    filtered_lab_tests_query(filters)
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
  end

  def count_lab_tests(filters \\ %{}) do
    filtered_lab_tests_query(filters)
    |> exclude(:order_by)
    |> select([l], count(l.id))
    |> Repo.one()
  end

  def search_lab_tests(query) do
    query = from(l in LabTest, where: ilike(l.name, ^"%#{query}%"))
    Repo.all(query)
  end

  @doc """
  Gets a single lab_test.

  Raises `Ecto.NoResultsError` if the Lab test does not exist.

  ## Examples

      iex> get_lab_test!(123)
      %LabTest{}

      iex> get_lab_test!(456)
      ** (Ecto.NoResultsError)

  """
  def get_lab_test!(id), do: Repo.get!(LabTest, id)

  @doc """
  Creates a lab_test.

  ## Examples

      iex> create_lab_test(%{field: value})
      {:ok, %LabTest{}}

      iex> create_lab_test(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_lab_test(attrs \\ %{}) do
    %LabTest{}
    |> LabTest.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a lab_test.

  ## Examples

      iex> update_lab_test(lab_test, %{field: new_value})
      {:ok, %LabTest{}}

      iex> update_lab_test(lab_test, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_lab_test(%LabTest{} = lab_test, attrs) do
    lab_test
    |> LabTest.changeset(attrs)
    |> Repo.audited_update()
  end

  @doc """
  Deletes a lab_test.

  ## Examples

      iex> delete_lab_test(lab_test)
      {:ok, %LabTest{}}

      iex> delete_lab_test(lab_test)
      {:error, %Ecto.Changeset{}}

  """
  def delete_lab_test(%LabTest{} = lab_test) do
    Repo.delete(lab_test)
  end

  defp filtered_lab_tests_query(filters) do
    LabTest
    |> maybe_filter_search(filters[:search])
    |> maybe_filter_date_from(filters[:date_from])
    |> maybe_filter_date_to(filters[:date_to])
    |> maybe_filter_subsidy(filters[:subsidy])
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking lab_test changes.

  ## Examples

      iex> change_lab_test(lab_test)
      %Ecto.Changeset{data: %LabTest{}}

  """
  def change_lab_test(%LabTest{} = lab_test, attrs \\ %{}) do
    LabTest.changeset(lab_test, attrs)
  end

  defp maybe_filter_search(query, nil), do: query
  defp maybe_filter_search(query, ""), do: query

  defp maybe_filter_search(query, search) do
    trimmed_search = String.trim(search)

    if trimmed_search == "" do
      query
    else
      from(l in query, where: ilike(l.name, ^"%#{trimmed_search}%"))
    end
  end

  defp maybe_filter_date_from(query, value) do
    case parse_filter_date(value) do
      {:ok, date} -> from(l in query, where: fragment("date(?) >= ?", l.inserted_at, ^date))
      :error -> query
    end
  end

  defp maybe_filter_date_to(query, value) do
    case parse_filter_date(value) do
      {:ok, date} -> from(l in query, where: fragment("date(?) <= ?", l.inserted_at, ^date))
      :error -> query
    end
  end

  defp maybe_filter_subsidy(query, "subsidized"),
    do: from(l in query, where: not is_nil(l.subsidized_price))

  defp maybe_filter_subsidy(query, "standard"),
    do: from(l in query, where: is_nil(l.subsidized_price))

  defp maybe_filter_subsidy(query, _), do: query

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
