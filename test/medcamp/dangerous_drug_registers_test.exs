defmodule Medcamp.DangerousDrugRegistersTest do
  use Medcamp.DataCase, async: true

  alias Medcamp.Accounts
  alias Medcamp.DangerousDrugRegisters
  alias Medcamp.Drugs

  import Medcamp.InventoriesReceivedFixtures

  describe "register balances" do
    test "carries forward the previous month's closing balance" do
      user = create_user()

      inventory_received =
        inventory_received_fixture(
          brand_name: "Diazepam",
          generic_name: "Diazepam",
          weight: 1
        )

      {:ok, drug} =
        Drugs.create_drug(%{
          inventory_received_id: inventory_received.id,
          inventory_manager_id: user.id,
          generic_name: inventory_received.generic_name,
          brand_name: inventory_received.brand_name
        })

      {:ok, april_register} = DangerousDrugRegisters.ensure_register(drug.id, 4, 2026, user.id)

      {:ok, april_register} =
        DangerousDrugRegisters.update_entry(april_register, 1, "quantity_received", "20")

      {:ok, april_register} =
        DangerousDrugRegisters.update_entry(april_register, 1, "quantity_dispensed", "5")

      assert DangerousDrugRegisters.closing_balance(april_register) == 15.0

      {:ok, may_register} = DangerousDrugRegisters.ensure_register(drug.id, 5, 2026, user.id)

      assert DangerousDrugRegisters.opening_balance(may_register) == 15.0

      {:ok, may_register} =
        DangerousDrugRegisters.update_entry(may_register, 1, "quantity_dispensed", "2")

      assert DangerousDrugRegisters.closing_balance(may_register) == 13.0
    end

    test "adds rows in numeric order" do
      user = create_user()

      inventory_received =
        inventory_received_fixture(
          brand_name: "Morphine",
          generic_name: "Morphine",
          weight: 1
        )

      {:ok, drug} =
        Drugs.create_drug(%{
          inventory_received_id: inventory_received.id,
          inventory_manager_id: user.id,
          generic_name: inventory_received.generic_name,
          brand_name: inventory_received.brand_name
        })

      {:ok, register} = DangerousDrugRegisters.ensure_register(drug.id, 5, 2026, user.id)
      {:ok, register} = DangerousDrugRegisters.add_entry(register)
      {:ok, register} = DangerousDrugRegisters.add_entry(register)

      assert Enum.map(DangerousDrugRegisters.list_entries(register), &elem(&1, 0)) == [
               "1",
               "2",
               "3"
             ]
    end

    test "only drugs marked for DDA appear in the register list and filter" do
      user = create_user()

      dda_drug = create_drug(user, "Phenobarbital", "Phenobarbital", true)
      regular_drug = create_drug(user, "Paracetamol", "Paracetamol", false)

      assert Enum.map(Drugs.list_register_drugs(), & &1.id) == [dda_drug.id]
      assert Enum.map(Drugs.filter_drugs(%{"dda_filter" => "dda"}), & &1.id) == [dda_drug.id]

      assert Enum.map(Drugs.filter_drugs(%{"dda_filter" => "non_dda"}), & &1.id) == [
               regular_drug.id
             ]
    end
  end

  defp create_user do
    {:ok, user} =
      Accounts.register_user(%{
        "email" => "register-user-#{System.unique_integer([:positive])}@example.com",
        "password" => "hello world!",
        "name" => "Register User"
      })

    user
  end

  defp create_drug(user, brand_name, generic_name, is_dangerous_drug) do
    inventory_received =
      inventory_received_fixture(
        brand_name: brand_name,
        generic_name: generic_name,
        weight: 1
      )

    {:ok, drug} =
      Drugs.create_drug(%{
        inventory_received_id: inventory_received.id,
        inventory_manager_id: user.id,
        generic_name: inventory_received.generic_name,
        brand_name: inventory_received.brand_name,
        is_dangerous_drug: is_dangerous_drug
      })

    drug
  end
end
