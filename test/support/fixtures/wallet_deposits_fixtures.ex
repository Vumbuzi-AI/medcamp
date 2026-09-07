defmodule Medcamp.WalletDepositsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Medcamp.WalletDeposits` context.
  """

  @doc """
  Generate a wallet_Deposit.
  """
  def wallet_Deposit_fixture(attrs \\ %{}) do
    patient =
      Map.get(attrs, :patient) || Map.get(attrs, "patient") ||
        Medcamp.PatientsFixtures.patient_fixture()

    {:ok, wallet_Deposit} =
      attrs
      |> Map.drop([:patient, "patient"])
      |> Enum.into(%{
        amount: 42,
        has_been_paid: false,
        patient_id: patient.id,
        phone_number: "some phone_number",
        reason: "some reason"
      })
      |> Medcamp.WalletDeposits.create_wallet_deposit()

    wallet_Deposit
  end
end
