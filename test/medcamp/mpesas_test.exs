defmodule Medcamp.MpesasTest do
  use Medcamp.DataCase

  alias Medcamp.Mpesas

  describe "mpesas" do
    alias Medcamp.Mpesas.Mpesa

    import Medcamp.MpesasFixtures

    @invalid_attrs %{
      reason: nil,
      description: nil,
      account_number: nil,
      amount: nil,
      phone: nil,
      receipt: nil,
      transactiondate: nil,
      checkout_request_id: nil,
      merchant_request_id: nil,
      actionable_id: nil,
      actionable_type: nil,
      patient_id: nil,
      prompter_id: nil
    }

    test "list_mpesas/0 returns all mpesas" do
      mpesa = mpesa_fixture()
      assert Mpesas.list_mpesas() == [mpesa]
    end

    test "get_mpesa!/1 returns the mpesa with given id" do
      mpesa = mpesa_fixture()
      assert Mpesas.get_mpesa!(mpesa.id) == mpesa
    end

    test "create_mpesa/1 with valid data creates a mpesa" do
      valid_attrs = %{
        reason: "some reason",
        description: "some description",
        account_number: "some account_number",
        amount: 1200,
        phone: "some phone",
        receipt: "some receipt",
        transactiondate: "some transactiondate",
        checkout_request_id: "checkout-123",
        merchant_request_id: "merchant-123",
        actionable_id: 1,
        actionable_type: "create_wallet_deposit",
        patient_id: Medcamp.PatientsFixtures.patient_fixture().id,
        prompter_id:
          Medcamp.Accounts.register_user(%{
            "email" => "prompter#{System.unique_integer()}@example.com",
            "password" => "hello world!",
            "name" => "Payment Prompter",
            "role" => "admin"
          })
          |> case do
            {:ok, user} -> user.id
            {:error, _} -> nil
          end
      }

      assert {:ok, %Mpesa{} = mpesa} = Mpesas.create_mpesa(valid_attrs)
      assert mpesa.reason == "some reason"
      assert mpesa.description == "some description"
      assert mpesa.account_number == "some account_number"
      assert mpesa.amount == 1200
      assert mpesa.phone == "some phone"
      assert mpesa.receipt == "some receipt"
      assert mpesa.transactiondate == "some transactiondate"
    end

    test "create_mpesa/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Mpesas.create_mpesa(@invalid_attrs)
    end

    test "update_mpesa/2 with valid data updates the mpesa" do
      mpesa = mpesa_fixture()

      update_attrs = %{
        reason: "some updated reason",
        description: "some updated description",
        account_number: "some updated account_number",
        amount: 4567,
        phone: "some updated phone",
        receipt: "some updated receipt",
        transactiondate: "some updated transactiondate"
      }

      assert {:ok, %Mpesa{} = mpesa} = Mpesas.update_mpesa(mpesa, update_attrs)
      assert mpesa.reason == "some updated reason"
      assert mpesa.description == "some updated description"
      assert mpesa.account_number == "some updated account_number"
      assert mpesa.amount == 4567
      assert mpesa.phone == "some updated phone"
      assert mpesa.receipt == "some updated receipt"
      assert mpesa.transactiondate == "some updated transactiondate"
    end

    test "update_mpesa/2 with invalid data returns error changeset" do
      mpesa = mpesa_fixture()
      assert {:error, %Ecto.Changeset{}} = Mpesas.update_mpesa(mpesa, @invalid_attrs)
      assert mpesa == Mpesas.get_mpesa!(mpesa.id)
    end

    test "delete_mpesa/1 deletes the mpesa" do
      mpesa = mpesa_fixture()
      assert {:ok, %Mpesa{}} = Mpesas.delete_mpesa(mpesa)
      assert_raise Ecto.NoResultsError, fn -> Mpesas.get_mpesa!(mpesa.id) end
    end

    test "change_mpesa/1 returns a mpesa changeset" do
      mpesa = mpesa_fixture()
      assert %Ecto.Changeset{} = Mpesas.change_mpesa(mpesa)
    end
  end
end
