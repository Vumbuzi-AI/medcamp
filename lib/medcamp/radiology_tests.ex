defmodule Medcamp.RadiologyTests do
  @moduledoc """
  The RadiologyTests context.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo

  alias Medcamp.RadiologyTests.RadiologyTest

  @doc """
  Returns the list of radiology_tests.

  ## Examples

      iex> list_radiology_tests()
      [%RadiologyTest{}, ...]

  """
  def list_radiology_tests do
    Repo.all(RadiologyTest)
  end

  def filter_radiology_tests(filters) do
    radiology_tests_query(filters) |> Repo.all()
  end

  def filter_radiology_tests_paginated(filters \\ %{}, page \\ 1, per_page \\ 10) do
    radiology_tests_query(filters)
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
  end

  def count_radiology_tests(filters \\ %{}) do
    radiology_tests_base_query(filters)
    |> select([r], count(r.id))
    |> Repo.one()
  end

  def search_radiology_tests(query) do
    search_query = from(r in RadiologyTest, where: ilike(r.name, ^"%#{query}%"))
    Repo.all(search_query)
  end

  defp maybe_filter_search(query, search) when is_binary(search) and search != "" do
    from(r in query, where: ilike(r.name, ^"%#{search}%"))
  end

  defp maybe_filter_search(query, _search), do: query

  defp maybe_filter_date_from(query, nil), do: query

  defp maybe_filter_date_from(query, date_from),
    do: from(r in query, where: r.inserted_at >= ^date_from)

  defp maybe_filter_date_to(query, nil), do: query

  defp maybe_filter_date_to(query, date_to),
    do: from(r in query, where: r.inserted_at <= ^date_to)

  @doc """
  Gets a single radiology_test.

  Raises `Ecto.NoResultsError` if the Radiology test does not exist.

  ## Examples

      iex> get_radiology_test!(123)
      %RadiologyTest{}

      iex> get_radiology_test!(456)
      ** (Ecto.NoResultsError)

  """
  def get_radiology_test!(id), do: Repo.get!(RadiologyTest, id)

  @doc """
  Creates a radiology_test.

  ## Examples

      iex> create_radiology_test(%{field: value})
      {:ok, %RadiologyTest{}}

      iex> create_radiology_test(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_radiology_test(attrs \\ %{}) do
    %RadiologyTest{}
    |> RadiologyTest.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a radiology_test.

  ## Examples

      iex> update_radiology_test(radiology_test, %{field: new_value})
      {:ok, %RadiologyTest{}}

      iex> update_radiology_test(radiology_test, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_radiology_test(%RadiologyTest{} = radiology_test, attrs) do
    radiology_test
    |> RadiologyTest.changeset(attrs)
    |> Repo.audited_update()
  end

  @doc """
  Deletes a radiology_test.

  ## Examples

      iex> delete_radiology_test(radiology_test)
      {:ok, %RadiologyTest{}}

      iex> delete_radiology_test(radiology_test)
      {:error, %Ecto.Changeset{}}

  """
  def delete_radiology_test(%RadiologyTest{} = radiology_test) do
    Repo.delete(radiology_test)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking radiology_test changes.

  ## Examples

      iex> change_radiology_test(radiology_test)
      %Ecto.Changeset{data: %RadiologyTest{}}

  """
  def change_radiology_test(%RadiologyTest{} = radiology_test, attrs \\ %{}) do
    RadiologyTest.changeset(radiology_test, attrs)
  end

  defp radiology_tests_query(filters) do
    radiology_tests_base_query(filters)
    |> order_by([r], desc: r.inserted_at)
  end

  defp radiology_tests_base_query(filters) do
    RadiologyTest
    |> maybe_filter_search(filters[:search])
    |> maybe_filter_date_from(filters[:date_from])
    |> maybe_filter_date_to(filters[:date_to])
  end
end
