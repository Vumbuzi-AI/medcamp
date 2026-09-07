defmodule Medcamp.AssignedTags do
  @moduledoc """
  The AssignedTags context.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo

  alias Medcamp.AssignedTags.AssignedTag

  @doc """
  Returns the list of assigned_tags.

  ## Examples

      iex> list_assigned_tags()
      [%AssignedTag{}, ...]

  """
  def list_assigned_tags do
    assigned_tags_query()
    |> Repo.all()
  end

  def list_assigned_tags_paginated(page \\ 1, per_page \\ 20) do
    assigned_tags_query()
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
  end

  def count_assigned_tags do
    assigned_tags_query()
    |> select([a], count(a.id))
    |> Repo.one()
  end

  @doc """
  Gets a single assigned_tag.

  Raises `Ecto.NoResultsError` if the Assigned tag does not exist.

  ## Examples

      iex> get_assigned_tag!(123)
      %AssignedTag{}

      iex> get_assigned_tag!(456)
      ** (Ecto.NoResultsError)

  """
  def get_assigned_tag!(id), do: Repo.get!(AssignedTag, id)

  @doc """
  Creates a assigned_tag.

  ## Examples

      iex> create_assigned_tag(%{field: value})
      {:ok, %AssignedTag{}}

      iex> create_assigned_tag(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_assigned_tag(attrs \\ %{}) do
    %AssignedTag{}
    |> AssignedTag.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a assigned_tag.

  ## Examples

      iex> update_assigned_tag(assigned_tag, %{field: new_value})
      {:ok, %AssignedTag{}}

      iex> update_assigned_tag(assigned_tag, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_assigned_tag(%AssignedTag{} = assigned_tag, attrs) do
    assigned_tag
    |> AssignedTag.changeset(attrs)
    |> Repo.audited_update()
  end

  @doc """
  Deletes a assigned_tag.

  ## Examples

      iex> delete_assigned_tag(assigned_tag)
      {:ok, %AssignedTag{}}

      iex> delete_assigned_tag(assigned_tag)
      {:error, %Ecto.Changeset{}}

  """
  def delete_assigned_tag(%AssignedTag{} = assigned_tag) do
    Repo.delete(assigned_tag)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking assigned_tag changes.

  ## Examples

      iex> change_assigned_tag(assigned_tag)
      %Ecto.Changeset{data: %AssignedTag{}}

  """
  def change_assigned_tag(%AssignedTag{} = assigned_tag, attrs \\ %{}) do
    AssignedTag.changeset(assigned_tag, attrs)
  end

  defp assigned_tags_query do
    from(a in AssignedTag, order_by: [desc: a.inserted_at])
  end
end
