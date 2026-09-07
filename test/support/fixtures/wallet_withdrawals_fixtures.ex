defmodule Medcamp.WalletWithdrawalsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Medcamp.WalletWithdrawals` context.
  """

  @doc """
  Generate a wallet_withdrawal.
  """
  def wallet_withdrawal_fixture(attrs \\ %{}) do
    patient =
      Map.get(attrs, :patient) || Map.get(attrs, "patient") ||
        Medcamp.PatientsFixtures.patient_fixture()

    wallet_deposit =
      Map.get(attrs, :wallet_deposit) || Map.get(attrs, "wallet_deposit") ||
        Medcamp.WalletDepositsFixtures.wallet_Deposit_fixture(%{patient: patient})

    {:ok, wallet_withdrawal} =
      attrs
      |> Map.drop([:patient, "patient", :wallet_deposit, "wallet_deposit"])
      |> Enum.into(%{
        date: ~D[2025-09-27],
        reason: "some reason",
        amount: 42,
        patient_id: patient.id,
        wallet_deposit_id: wallet_deposit.id
      })
      |> Medcamp.WalletWithdrawals.create_wallet_withdrawal()

    wallet_withdrawal
  end
end
