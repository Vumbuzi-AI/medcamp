defmodule Medcamp.Costings do
  @moduledoc """
  The Costings context.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo

  alias Medcamp.Costings.Costing

  @doc """
  Returns the list of costings.

  ## Examples

      iex> list_costings()
      [%Costing{}, ...]

  """
  def list_costings do
    costings_query() |> Repo.all()
  end

  def list_costings_paginated(page \\ 1, per_page \\ 10) do
    costings_query()
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
  end

  def count_costings do
    costings_base_query()
    |> select([c], count(c.id))
    |> Repo.one()
  end

  def get_costings_by_type(type) do
    from(c in Costing, where: c.type == ^type)
    |> Repo.all()
    |> List.first()
  end

  @doc """
  Gets a single costing.

  Raises `Ecto.NoResultsError` if the Costing does not exist.

  ## Examples

      iex> get_costing!(123)
      %Costing{}

      iex> get_costing!(456)
      ** (Ecto.NoResultsError)

  """
  def get_costing!(id), do: Repo.get!(Costing, id)

  @doc """
  Creates a costing.

  ## Examples

      iex> create_costing(%{field: value})
      {:ok, %Costing{}}

      iex> create_costing(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_costing(attrs \\ %{}) do
    %Costing{}
    |> Costing.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a costing.

  ## Examples

      iex> update_costing(costing, %{field: new_value})
      {:ok, %Costing{}}

      iex> update_costing(costing, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_costing(%Costing{} = costing, attrs) do
    costing
    |> Costing.changeset(attrs)
    |> Repo.audited_update()
  end

  @doc """
  Deletes a costing.

  ## Examples

      iex> delete_costing(costing)
      {:ok, %Costing{}}

      iex> delete_costing(costing)
      {:error, %Ecto.Changeset{}}

  """
  def delete_costing(%Costing{} = costing) do
    Repo.delete(costing)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking costing changes.

  ## Examples

      iex> change_costing(costing)
      %Ecto.Changeset{data: %Costing{}}

  """
  def change_costing(%Costing{} = costing, attrs \\ %{}) do
    Costing.changeset(costing, attrs)
  end

  defp costings_query do
    costings_base_query()
    |> order_by([c], desc: c.inserted_at)
  end

  defp costings_base_query do
    from(c in Costing)
  end
end
