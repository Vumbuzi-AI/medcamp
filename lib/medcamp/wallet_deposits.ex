defmodule Medcamp.WalletDeposits do
  @moduledoc """
  The WalletDeposits context.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo

  alias Medcamp.WalletDeposits.WalletDeposit
  alias Medcamp.WalletWithdrawals

  @doc """
  Returns the list of wallet_deposits.

  ## Examples

      iex> list_wallet_deposits()
      [%WalletDeposit{}, ...]

  """
  def list_wallet_deposits do
    Repo.all(WalletDeposit)
  end

  def list_wallet_deposits_with_usage do
    # Get all deposits with patient preloaded
    deposits =
      from(d in WalletDeposit,
        preload: [:patient],
        order_by: [desc: d.inserted_at]
      )
      |> Repo.all()

    # Calculate usage for each deposit
    deposits
    |> Enum.map(fn deposit ->
      amount_used =
        from(w in WalletWithdrawals.WalletWithdrawal,
          where: w.wallet_deposit_id == ^deposit.id,
          select: coalesce(sum(w.amount), 0)
        )
        |> Repo.one() || 0

      %{
        id: deposit.id,
        phone_number: deposit.phone_number,
        amount: deposit.amount,
        reason: deposit.reason,
        patient: deposit.patient,
        inserted_at: deposit.inserted_at,
        amount_used: amount_used
      }
    end)
  end

  def list_wallet_deposits_with_usage_for_patient(patient_id) do
    # Get all deposits with patient preloaded
    deposits =
      from(d in WalletDeposit,
        where: d.patient_id == ^patient_id and d.has_been_paid == true,
        preload: [:patient],
        order_by: [desc: d.inserted_at]
      )
      |> Repo.all()

    # Calculate usage for each deposit
    deposits
    |> Enum.map(fn deposit ->
      amount_used =
        from(w in WalletWithdrawals.WalletWithdrawal,
          where: w.wallet_deposit_id == ^deposit.id,
          select: coalesce(sum(w.amount), 0)
        )
        |> Repo.one() || 0

      %{
        id: deposit.id,
        phone_number: deposit.phone_number,
        amount: deposit.amount,
        reason: deposit.reason,
        patient: deposit.patient,
        inserted_at: deposit.inserted_at,
        amount_used: amount_used
      }
    end)
  end

  def get_wallet_deposit_with_usage(id) do
    # Get the deposit with patient
    deposit = get_wallet_deposit!(id)

    # Get usage amount for this deposit
    amount_used =
      from(w in WalletWithdrawals.WalletWithdrawal,
        where: w.wallet_deposit_id == ^id,
        select: coalesce(sum(w.amount), 0)
      )
      |> Repo.one() || 0

    %{
      id: deposit.id,
      phone_number: deposit.phone_number,
      amount: deposit.amount,
      reason: deposit.reason,
      patient: deposit.patient,
      inserted_at: deposit.inserted_at,
      amount_used: amount_used
    }
  end

  def get_wallet_statistics do
    total_deposits =
      from(d in WalletDeposit, select: coalesce(sum(d.amount), 0))
      |> Medcamp.Repo.one() || 0

    total_used =
      from(w in WalletWithdrawals.WalletWithdrawal, select: coalesce(sum(w.amount), 0))
      |> Medcamp.Repo.one() || 0

    # Fix: Use subquery to count active wallets properly
    active_deposits_subquery =
      from(d in WalletDeposit,
        left_join: w in WalletWithdrawals.WalletWithdrawal,
        on: w.wallet_deposit_id == d.id,
        group_by: d.id,
        having: coalesce(sum(w.amount), 0) < d.amount,
        select: d.id
      )

    active_wallets =
      from(sub in subquery(active_deposits_subquery), select: count())
      |> Medcamp.Repo.one() || 0

    %{
      total_deposits: total_deposits,
      total_used: total_used,
      available_balance: total_deposits - total_used,
      active_wallets: active_wallets
    }
  end

  def get_wallet_statistics_for_patient(patient_id) do
    total_deposits =
      from(d in WalletDeposit,
        where: d.patient_id == ^patient_id and d.has_been_paid == true,
        select: coalesce(sum(d.amount), 0)
      )
      |> Medcamp.Repo.one() || 0

    total_used =
      from(w in WalletWithdrawals.WalletWithdrawal,
        join: d in WalletDeposit,
        on: w.wallet_deposit_id == d.id,
        where: d.patient_id == ^patient_id,
        select: coalesce(sum(w.amount), 0)
      )
      |> Medcamp.Repo.one() || 0

    # Fix: Use subquery to count active wallets properly
    active_deposits_subquery =
      from(d in WalletDeposit,
        left_join: w in WalletWithdrawals.WalletWithdrawal,
        on: w.wallet_deposit_id == d.id,
        where: d.patient_id == ^patient_id,
        group_by: d.id,
        having: coalesce(sum(w.amount), 0) < d.amount,
        select: d.id
      )

    active_wallets =
      from(sub in subquery(active_deposits_subquery), select: count())
      |> Medcamp.Repo.one() || 0

    %{
      total_deposits: total_deposits,
      total_used: total_used,
      available_balance: total_deposits - total_used,
      active_wallets: active_wallets
    }
  end

  @doc """
  Gets a single wallet_Deposit.

  Raises `Ecto.NoResultsError` if the Wallet Deposit does not exist.

  ## Examples

      iex> get_wallet_Deposit!(123)
      %WalletDeposit{}

      iex> get_wallet_Deposit!(456)
      ** (Ecto.NoResultsError)

  """
  def get_wallet_deposit!(id), do: Repo.get!(WalletDeposit, id) |> Repo.preload(:patient)

  @doc """
  Creates a wallet_Deposit.

  ## Examples

      iex> create_wallet_Deposit(%{field: value})
      {:ok, %WalletDeposit{}}

      iex> create_wallet_Deposit(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_wallet_deposit(attrs \\ %{}) do
    %WalletDeposit{}
    |> WalletDeposit.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a wallet_Deposit.

  ## Examples

      iex> update_wallet_Deposit(wallet_Deposit, %{field: new_value})
      {:ok, %WalletDeposit{}}

      iex> update_wallet_Deposit(wallet_Deposit, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_wallet_deposit(%WalletDeposit{} = wallet_Deposit, attrs) do
    wallet_Deposit
    |> WalletDeposit.changeset(attrs)
    |> Repo.audited_update()
  end

  @doc """
  Deletes a wallet_Deposit.

  ## Examples

      iex> delete_wallet_Deposit(wallet_Deposit)
      {:ok, %WalletDeposit{}}

      iex> delete_wallet_Deposit(wallet_Deposit)
      {:error, %Ecto.Changeset{}}

  """
  def delete_wallet_deposit(%WalletDeposit{} = wallet_Deposit) do
    Repo.delete(wallet_Deposit)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking wallet_Deposit changes.

  ## Examples

      iex> change_wallet_Deposit(wallet_Deposit)
      %Ecto.Changeset{data: %WalletDeposit{}}

  """
  def change_wallet_deposit(%WalletDeposit{} = wallet_Deposit, attrs \\ %{}) do
    WalletDeposit.changeset(wallet_Deposit, attrs)
  end
end
