defmodule Medcamp.ShiftHandovers do
  @moduledoc """
  The ShiftHandovers context.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo

  alias Medcamp.ShiftHandovers.ShiftHandover

  @doc """
  Returns the list of shift_handovers.

  ## Examples

      iex> list_shift_handovers()
      [%ShiftHandover{}, ...]

  """
  def list_shift_handovers do
    from(s in ShiftHandover,
      order_by: [desc: s.shift_date, desc: s.inserted_at],
      preload: [:submitted_by, :acknowledged_by]
    )
    |> Repo.all()
  end

  def list_unique_departments do
    from(s in ShiftHandover,
      select: s.department,
      distinct: true,
      where: not is_nil(s.department),
      order_by: s.department
    )
    |> Repo.all()
  end

  def list_shift_handovers_by_status(status) do
    from(s in ShiftHandover,
      where: s.status == ^status,
      order_by: [desc: s.shift_date, desc: s.inserted_at],
      preload: [:submitted_by, :acknowledged_by]
    )
    |> Repo.all()
  end

  def list_shift_handovers_by_role(role, user_id) do
    from(s in ShiftHandover,
      join: u in assoc(s, :submitted_by),
      where: u.role == ^role or s.submitted_by_id == ^user_id,
      order_by: [desc: s.shift_date, desc: s.inserted_at],
      preload: [:submitted_by, :acknowledged_by]
    )
    |> Repo.all()
  end

  def list_shift_handovers_by_status_and_role(status, role, user_id) do
    from(s in ShiftHandover,
      join: u in assoc(s, :submitted_by),
      where: s.status == ^status and (u.role == ^role or s.submitted_by_id == ^user_id),
      order_by: [desc: s.shift_date, desc: s.inserted_at],
      preload: [:submitted_by, :acknowledged_by]
    )
    |> Repo.all()
  end

  def search_shift_handovers(query) do
    search_term = "%#{query}%"

    from(s in ShiftHandover,
      where:
        ilike(s.department, ^search_term) or
          ilike(s.handover_from, ^search_term) or
          ilike(s.handover_to, ^search_term) or
          ilike(s.notes, ^search_term),
      order_by: [desc: s.shift_date, desc: s.inserted_at],
      preload: [:submitted_by, :acknowledged_by]
    )
    |> Repo.all()
  end

  def search_shift_handovers_by_role(query, role, user_id) do
    search_term = "%#{query}%"

    from(s in ShiftHandover,
      join: u in assoc(s, :submitted_by),
      where:
        (ilike(s.department, ^search_term) or
           ilike(s.handover_from, ^search_term) or
           ilike(s.handover_to, ^search_term) or
           ilike(s.notes, ^search_term)) and
          (u.role == ^role or s.submitted_by_id == ^user_id),
      order_by: [desc: s.shift_date, desc: s.inserted_at],
      preload: [:submitted_by, :acknowledged_by]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single shift_handover.

  Raises `Ecto.NoResultsError` if the Shift handover does not exist.

  ## Examples

      iex> get_shift_handover!(123)
      %ShiftHandover{}

      iex> get_shift_handover!(456)
      ** (Ecto.NoResultsError)

  """
  def get_shift_handover!(id), do: Repo.get!(ShiftHandover, id)

  @doc """
  Creates a shift_handover.

  ## Examples

      iex> create_shift_handover(%{field: value})
      {:ok, %ShiftHandover{}}

      iex> create_shift_handover(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_shift_handover(attrs \\ %{}) do
    %ShiftHandover{}
    |> ShiftHandover.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a shift_handover.

  ## Examples

      iex> update_shift_handover(shift_handover, %{field: new_value})
      {:ok, %ShiftHandover{}}

      iex> update_shift_handover(shift_handover, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_shift_handover(%ShiftHandover{} = shift_handover, attrs) do
    shift_handover
    |> ShiftHandover.changeset(attrs)
    |> Repo.audited_update()
  end

  @doc """
  Deletes a shift_handover.

  ## Examples

      iex> delete_shift_handover(shift_handover)
      {:ok, %ShiftHandover{}}

      iex> delete_shift_handover(shift_handover)
      {:error, %Ecto.Changeset{}}

  """
  def delete_shift_handover(%ShiftHandover{} = shift_handover) do
    Repo.delete(shift_handover)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking shift_handover changes.

  ## Examples

      iex> change_shift_handover(shift_handover)
      %Ecto.Changeset{data: %ShiftHandover{}}

  """
  def change_shift_handover(%ShiftHandover{} = shift_handover, attrs \\ %{}) do
    ShiftHandover.changeset(shift_handover, attrs)
  end
end
