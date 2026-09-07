defmodule Medcamp.Referrals do
  @moduledoc """
  The Referrals context.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo

  alias Medcamp.Referrals.Referral

  @doc """
  Returns the list of referrals.

  ## Examples

      iex> list_referrals()
      [%Referral{}, ...]

  """
  def list_referrals do
    Repo.all(Referral)
  end

  def list_referrals_for_a_doctor_note(doctor_note_id) do
    Referral
    |> where([r], r.doctor_note_id == ^doctor_note_id)
    |> Repo.all()
    |> Repo.preload([:doctor, :patient, :doctor_note])
  end

  def list_referrals_for_a_patient(patient_id) do
    Referral
    |> where([r], r.patient_id == ^patient_id)
    |> Repo.all()
    |> Repo.preload([:doctor, :patient, :doctor_note])
  end

  @doc """
  Gets a single referral.

  Raises `Ecto.NoResultsError` if the Referral does not exist.

  ## Examples

      iex> get_referral!(123)
      %Referral{}

      iex> get_referral!(456)
      ** (Ecto.NoResultsError)

  """
  def get_referral!(id), do: Repo.get!(Referral, id)

  @doc """
  Creates a referral.

  ## Examples

      iex> create_referral(%{field: value})
      {:ok, %Referral{}}

      iex> create_referral(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_referral(attrs \\ %{}) do
    %Referral{}
    |> Referral.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a referral.

  ## Examples

      iex> update_referral(referral, %{field: new_value})
      {:ok, %Referral{}}

      iex> update_referral(referral, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_referral(%Referral{} = referral, attrs) do
    referral
    |> Referral.changeset(attrs)
    |> Repo.audited_update()
  end

  @doc """
  Deletes a referral.

  ## Examples

      iex> delete_referral(referral)
      {:ok, %Referral{}}

      iex> delete_referral(referral)
      {:error, %Ecto.Changeset{}}

  """
  def delete_referral(%Referral{} = referral) do
    Repo.delete(referral)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking referral changes.

  ## Examples

      iex> change_referral(referral)
      %Ecto.Changeset{data: %Referral{}}

  """
  def change_referral(%Referral{} = referral, attrs \\ %{}) do
    Referral.changeset(referral, attrs)
  end
end
