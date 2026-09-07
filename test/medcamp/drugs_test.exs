defmodule Medcamp.DrugsTest do
  use Medcamp.DataCase

  alias Medcamp.Drugs

  describe "drugs" do
    alias Medcamp.Drugs.Drug

    import Medcamp.DrugsFixtures

    @invalid_attrs %{inventory_received_id: nil, inventory_manager_id: nil}

    test "list_drugs/0 returns all drugs" do
      drug = drug_fixture()
      assert [%Drug{id: id}] = Drugs.list_drugs()
      assert id == drug.id
    end

    test "get_drug!/1 returns the drug with given id" do
      drug = drug_fixture()
      assert Drugs.get_drug!(drug.id).id == drug.id
    end

    test "create_drug/1 with valid data creates a drug" do
      inventory_received = Medcamp.InventoriesReceivedFixtures.inventory_received_fixture()
      inventory_manager = Medcamp.AccountsFixtures.user_fixture()

      valid_attrs = %{
        brand_name: "some brand_name",
        generic_name: "some generic_name",
        inventory_received_id: inventory_received.id,
        inventory_manager_id: inventory_manager.id,
        is_otc: true,
        is_dangerous_drug: false
      }

      assert {:ok, %Drug{} = drug} = Drugs.create_drug(valid_attrs)
      assert drug.brand_name == "some brand_name"
      assert drug.generic_name == "some generic_name"
      assert drug.inventory_received_id == inventory_received.id
      assert drug.inventory_manager_id == inventory_manager.id
      assert drug.is_otc == true
      assert drug.is_dangerous_drug == false
    end

    test "create_drug/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Drugs.create_drug(@invalid_attrs)
    end

    test "update_drug/2 with valid data updates the drug" do
      drug = drug_fixture()

      update_attrs = %{
        brand_name: "some updated brand_name",
        generic_name: "some updated generic_name",
        is_otc: false,
        is_dangerous_drug: true
      }

      assert {:ok, %Drug{} = drug} = Drugs.update_drug(drug, update_attrs)
      assert drug.brand_name == "some updated brand_name"
      assert drug.generic_name == "some updated generic_name"
      assert drug.is_otc == false
      assert drug.is_dangerous_drug == true
    end

    test "update_drug/2 with invalid data returns error changeset" do
      drug = drug_fixture()
      assert {:error, %Ecto.Changeset{}} = Drugs.update_drug(drug, @invalid_attrs)
      assert Drugs.get_drug!(drug.id).brand_name == drug.brand_name
    end

    test "delete_drug/1 deletes the drug" do
      drug = drug_fixture()
      assert {:ok, %Drug{}} = Drugs.delete_drug(drug)
      assert_raise Ecto.NoResultsError, fn -> Drugs.get_drug!(drug.id) end
    end

    test "change_drug/1 returns a drug changeset" do
      drug = drug_fixture()
      assert %Ecto.Changeset{} = Drugs.change_drug(drug)
    end
  end
end
