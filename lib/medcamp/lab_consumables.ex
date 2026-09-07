defmodule Medcamp.LabConsumables do
  @moduledoc """
  The LabConsumables context.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo

  alias Medcamp.LabConsumables.LabConsumable

  @doc """
  Returns the list of lab_consumables.

  ## Examples

      iex> list_lab_consumables()
      [%LabConsumable{}, ...]

  """
  def list_lab_consumables do
    Repo.all(LabConsumable)
  end

  def list_lab_consumables_for_allocation(lab_allocation_id) do
    from(lc in LabConsumable, where: lc.lab_allocation_id == ^lab_allocation_id)
    |> Repo.all()
    |> Repo.preload(:patient)
  end

  @doc """
  Gets a single lab_consumable.

  Raises `Ecto.NoResultsError` if the Lab consumable does not exist.

  ## Examples

      iex> get_lab_consumable!(123)
      %LabConsumable{}

      iex> get_lab_consumable!(456)
      ** (Ecto.NoResultsError)

  """
  def get_lab_consumable!(id), do: Repo.get!(LabConsumable, id)

  @doc """
  Creates a lab_consumable.

  ## Examples

      iex> create_lab_consumable(%{field: value})
      {:ok, %LabConsumable{}}

      iex> create_lab_consumable(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_lab_consumable(attrs \\ %{}) do
    %LabConsumable{}
    |> LabConsumable.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a lab_consumable.

  ## Examples

      iex> update_lab_consumable(lab_consumable, %{field: new_value})
      {:ok, %LabConsumable{}}

      iex> update_lab_consumable(lab_consumable, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_lab_consumable(%LabConsumable{} = lab_consumable, attrs) do
    lab_consumable
    |> LabConsumable.changeset(attrs)
    |> Repo.audited_update()
  end

  @doc """
  Deletes a lab_consumable.

  ## Examples

      iex> delete_lab_consumable(lab_consumable)
      {:ok, %LabConsumable{}}

      iex> delete_lab_consumable(lab_consumable)
      {:error, %Ecto.Changeset{}}

  """
  def delete_lab_consumable(%LabConsumable{} = lab_consumable) do
    Repo.delete(lab_consumable)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking lab_consumable changes.

  ## Examples

      iex> change_lab_consumable(lab_consumable)
      %Ecto.Changeset{data: %LabConsumable{}}

  """
  def change_lab_consumable(%LabConsumable{} = lab_consumable, attrs \\ %{}) do
    LabConsumable.changeset(lab_consumable, attrs)
  end
end
