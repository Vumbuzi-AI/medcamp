defmodule Medcamp.WalletWithdrawalsTest do
  use Medcamp.DataCase

  alias Medcamp.WalletWithdrawals

  describe "wallet_withdrawals" do
    alias Medcamp.WalletWithdrawals.WalletWithdrawal

    import Medcamp.WalletWithdrawalsFixtures
    import Medcamp.PatientsFixtures
    import Medcamp.WalletDepositsFixtures

    @invalid_attrs %{
      reason: nil,
      date: nil,
      amount: nil,
      patient_id: nil,
      wallet_deposit_id: nil
    }

    test "list_wallet_withdrawals/0 returns all wallet_withdrawals" do
      wallet_withdrawal = wallet_withdrawal_fixture()
      assert WalletWithdrawals.list_wallet_withdrawals() == [wallet_withdrawal]
    end

    test "get_wallet_withdrawal!/1 returns the wallet_withdrawal with given id" do
      wallet_withdrawal = wallet_withdrawal_fixture()
      assert WalletWithdrawals.get_wallet_withdrawal!(wallet_withdrawal.id) == wallet_withdrawal
    end

    test "create_wallet_withdrawal/1 with valid data creates a wallet_withdrawal" do
      patient = patient_fixture()
      wallet_deposit = wallet_Deposit_fixture(%{patient: patient})

      valid_attrs = %{
        reason: "some reason",
        date: ~D[2025-09-27],
        amount: 42,
        patient_id: patient.id,
        wallet_deposit_id: wallet_deposit.id
      }

      assert {:ok, %WalletWithdrawal{} = wallet_withdrawal} =
               WalletWithdrawals.create_wallet_withdrawal(valid_attrs)

      assert wallet_withdrawal.reason == "some reason"
      assert wallet_withdrawal.date == ~D[2025-09-27]
    end

    test "create_wallet_withdrawal/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               WalletWithdrawals.create_wallet_withdrawal(@invalid_attrs)
    end

    test "update_wallet_withdrawal/2 with valid data updates the wallet_withdrawal" do
      wallet_withdrawal = wallet_withdrawal_fixture()
      update_attrs = %{reason: "some updated reason", date: ~D[2025-09-28]}

      assert {:ok, %WalletWithdrawal{} = wallet_withdrawal} =
               WalletWithdrawals.update_wallet_withdrawal(wallet_withdrawal, update_attrs)

      assert wallet_withdrawal.reason == "some updated reason"
      assert wallet_withdrawal.date == ~D[2025-09-28]
    end

    test "update_wallet_withdrawal/2 with invalid data returns error changeset" do
      wallet_withdrawal = wallet_withdrawal_fixture()

      assert {:error, %Ecto.Changeset{}} =
               WalletWithdrawals.update_wallet_withdrawal(wallet_withdrawal, @invalid_attrs)

      assert wallet_withdrawal == WalletWithdrawals.get_wallet_withdrawal!(wallet_withdrawal.id)
    end

    test "delete_wallet_withdrawal/1 deletes the wallet_withdrawal" do
      wallet_withdrawal = wallet_withdrawal_fixture()

      assert {:ok, %WalletWithdrawal{}} =
               WalletWithdrawals.delete_wallet_withdrawal(wallet_withdrawal)

      assert_raise Ecto.NoResultsError, fn ->
        WalletWithdrawals.get_wallet_withdrawal!(wallet_withdrawal.id)
      end
    end

    test "change_wallet_withdrawal/1 returns a wallet_withdrawal changeset" do
      wallet_withdrawal = wallet_withdrawal_fixture()
      assert %Ecto.Changeset{} = WalletWithdrawals.change_wallet_withdrawal(wallet_withdrawal)
    end
  end
end
