defmodule Medcamp.WalletDepositsTest do
  use Medcamp.DataCase

  alias Medcamp.WalletDeposits

  describe "wallet_deposits" do
    alias Medcamp.WalletDeposits.WalletDeposit

    import Medcamp.WalletDepositsFixtures

    @invalid_attrs %{reason: nil, phone_number: nil, amount: nil, patient_id: nil}

    test "list_wallet_deposits/0 returns all wallet_deposits" do
      wallet_Deposit = wallet_Deposit_fixture()
      assert [%WalletDeposit{id: id}] = WalletDeposits.list_wallet_deposits()
      assert id == wallet_Deposit.id
    end

    test "get_wallet_Deposit!/1 returns the wallet_Deposit with given id" do
      wallet_Deposit = wallet_Deposit_fixture()
      assert WalletDeposits.get_wallet_deposit!(wallet_Deposit.id).id == wallet_Deposit.id
    end

    test "create_wallet_Deposit/1 with valid data creates a wallet_Deposit" do
      patient = Medcamp.PatientsFixtures.patient_fixture()

      valid_attrs = %{
        reason: "some reason",
        phone_number: "some phone_number",
        amount: 42,
        has_been_paid: false,
        patient_id: patient.id
      }

      assert {:ok, %WalletDeposit{} = wallet_Deposit} =
               WalletDeposits.create_wallet_deposit(valid_attrs)

      assert wallet_Deposit.reason == "some reason"
      assert wallet_Deposit.phone_number == "some phone_number"
      assert wallet_Deposit.amount == 42
      assert wallet_Deposit.patient_id == patient.id
    end

    test "create_wallet_Deposit/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = WalletDeposits.create_wallet_deposit(@invalid_attrs)
    end

    test "update_wallet_Deposit/2 with valid data updates the wallet_Deposit" do
      wallet_Deposit = wallet_Deposit_fixture()

      update_attrs = %{
        reason: "some updated reason",
        phone_number: "some updated phone_number",
        amount: 43
      }

      assert {:ok, %WalletDeposit{} = wallet_Deposit} =
               WalletDeposits.update_wallet_deposit(wallet_Deposit, update_attrs)

      assert wallet_Deposit.reason == "some updated reason"
      assert wallet_Deposit.phone_number == "some updated phone_number"
      assert wallet_Deposit.amount == 43
    end

    test "update_wallet_Deposit/2 with invalid data returns error changeset" do
      wallet_Deposit = wallet_Deposit_fixture()

      assert {:error, %Ecto.Changeset{}} =
               WalletDeposits.update_wallet_deposit(wallet_Deposit, @invalid_attrs)

      assert WalletDeposits.get_wallet_deposit!(wallet_Deposit.id).reason == wallet_Deposit.reason
    end

    test "delete_wallet_Deposit/1 deletes the wallet_Deposit" do
      wallet_Deposit = wallet_Deposit_fixture()
      assert {:ok, %WalletDeposit{}} = WalletDeposits.delete_wallet_deposit(wallet_Deposit)

      assert_raise Ecto.NoResultsError, fn ->
        WalletDeposits.get_wallet_deposit!(wallet_Deposit.id)
      end
    end

    test "change_wallet_Deposit/1 returns a wallet_Deposit changeset" do
      wallet_Deposit = wallet_Deposit_fixture()
      assert %Ecto.Changeset{} = WalletDeposits.change_wallet_deposit(wallet_Deposit)
    end
  end
end
