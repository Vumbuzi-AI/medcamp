defmodule Medcamp.WalletWithdrawals do
  @moduledoc """
  The WalletWithdrawals context.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo

  alias Medcamp.WalletWithdrawals.WalletWithdrawal

  @doc """
  Returns the list of wallet_withdrawals.

  ## Examples

      iex> list_wallet_withdrawals()
      [%WalletWithdrawal{}, ...]

  """
  def list_wallet_withdrawals do
    Repo.all(WalletWithdrawal)
  end

  @doc """
  Gets a single wallet_withdrawal.

  Raises `Ecto.NoResultsError` if the Wallet withdrawal does not exist.

  ## Examples

      iex> get_wallet_withdrawal!(123)
      %WalletWithdrawal{}

      iex> get_wallet_withdrawal!(456)
      ** (Ecto.NoResultsError)

  """
  def get_wallet_withdrawal!(id), do: Repo.get!(WalletWithdrawal, id)

  @doc """
  Creates a wallet_withdrawal.

  ## Examples

      iex> create_wallet_withdrawal(%{field: value})
      {:ok, %WalletWithdrawal{}}

      iex> create_wallet_withdrawal(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_wallet_withdrawal(attrs \\ %{}) do
    %WalletWithdrawal{}
    |> WalletWithdrawal.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a wallet_withdrawal.

  ## Examples

      iex> update_wallet_withdrawal(wallet_withdrawal, %{field: new_value})
      {:ok, %WalletWithdrawal{}}

      iex> update_wallet_withdrawal(wallet_withdrawal, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_wallet_withdrawal(%WalletWithdrawal{} = wallet_withdrawal, attrs) do
    wallet_withdrawal
    |> WalletWithdrawal.changeset(attrs)
    |> Repo.audited_update()
  end

  @doc """
  Deletes a wallet_withdrawal.

  ## Examples

      iex> delete_wallet_withdrawal(wallet_withdrawal)
      {:ok, %WalletWithdrawal{}}

      iex> delete_wallet_withdrawal(wallet_withdrawal)
      {:error, %Ecto.Changeset{}}

  """
  def delete_wallet_withdrawal(%WalletWithdrawal{} = wallet_withdrawal) do
    Repo.delete(wallet_withdrawal)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking wallet_withdrawal changes.

  ## Examples

      iex> change_wallet_withdrawal(wallet_withdrawal)
      %Ecto.Changeset{data: %WalletWithdrawal{}}

  """
  def change_wallet_withdrawal(%WalletWithdrawal{} = wallet_withdrawal, attrs \\ %{}) do
    WalletWithdrawal.changeset(wallet_withdrawal, attrs)
  end
end
