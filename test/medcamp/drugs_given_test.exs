defmodule Medcamp.DrugsGivenTest do
  use Medcamp.DataCase

  alias Medcamp.DrugsGiven

  describe "drugs_given" do
    alias Medcamp.DrugsGiven.DrugGiven

    import Medcamp.DrugsGivenFixtures
    import Medcamp.DrugAllocationsFixtures
    import Medcamp.DrugBatchesFixtures
    import Medcamp.DrugsFixtures
    import Medcamp.BatchesFixtures
    import Medcamp.InventoriesReceivedFixtures
    import Medcamp.AccountsFixtures

    @invalid_attrs %{quantity: nil, price: nil}

    test "list_drugs_given/0 returns all drugs_given" do
      drug_given = drug_given_fixture()
      assert [%DrugGiven{id: id}] = DrugsGiven.list_drugs_given()
      assert id == drug_given.id
    end

    test "get_drug_given!/1 returns the drug_given with given id" do
      drug_given = drug_given_fixture()
      assert DrugsGiven.get_drug_given!(drug_given.id).id == drug_given.id
    end

    test "create_drug_given/1 with valid data creates a drug_given" do
      drug = Medcamp.DrugsFixtures.drug_fixture()
      drug_allocation = Medcamp.DrugAllocationsFixtures.drug_allocation_fixture()
      pharmacist = Medcamp.AccountsFixtures.user_fixture()

      valid_attrs = %{
        drug_id: drug.id,
        drug_allocation_id: drug_allocation.id,
        pharmacist_id: pharmacist.id,
        quantity: 42,
        price: 42
      }

      assert {:ok, %DrugGiven{} = drug_given} = DrugsGiven.create_drug_given(valid_attrs)
      assert drug_given.drug_id == drug.id
      assert drug_given.drug_allocation_id == drug_allocation.id
      assert drug_given.pharmacist_id == pharmacist.id
      assert drug_given.quantity == 42
      assert drug_given.price == 42
    end

    test "create_drug_given/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = DrugsGiven.create_drug_given(@invalid_attrs)
    end

    test "update_drug_given/2 with valid data updates the drug_given" do
      drug_given = drug_given_fixture()
      update_attrs = %{quantity: 43, price: 43}

      assert {:ok, %DrugGiven{} = drug_given} =
               DrugsGiven.update_drug_given(drug_given, update_attrs)

      assert drug_given.quantity == 43
      assert drug_given.price == 43
    end

    test "update_drug_given/2 with invalid data returns error changeset" do
      drug_given = drug_given_fixture()

      assert {:error, %Ecto.Changeset{}} =
               DrugsGiven.update_drug_given(drug_given, @invalid_attrs)

      assert DrugsGiven.get_drug_given!(drug_given.id).quantity == drug_given.quantity
    end

    test "delete_drug_given/1 deletes the drug_given" do
      drug_given = drug_given_fixture()
      assert {:ok, %DrugGiven{}} = DrugsGiven.delete_drug_given(drug_given)
      assert_raise Ecto.NoResultsError, fn -> DrugsGiven.get_drug_given!(drug_given.id) end
    end

    test "change_drug_given/1 returns a drug_given changeset" do
      drug_given = drug_given_fixture()
      assert %Ecto.Changeset{} = DrugsGiven.change_drug_given(drug_given)
    end

    test "create_drug_given_by_brand/6 dispenses the clicked duplicate drug assignment" do
      pharmacist = user_fixture()

      old_inventory =
        inventory_received_fixture(
          brand_name: "HYOSCINE TABS COSMOS 10",
          generic_name: "HYOSCINE BUTYLBROMIDE"
        )

      current_inventory =
        inventory_received_fixture(
          brand_name: "HYOSCINE TABS COSMOS 10",
          generic_name: "HYOSCINE BUTYLBROMIDE"
        )

      old_drug =
        drug_fixture(%{
          inventory_received: old_inventory,
          brand_name: "HYOSCINE TABS COSMOS 10",
          generic_name: "HYOSCINE BUTYLBROMIDE"
        })

      current_drug =
        drug_fixture(%{
          inventory_received: current_inventory,
          brand_name: "HYOSCINE TABS COSMOS 10",
          generic_name: "HYOSCINE BUTYLBROMIDE"
        })

      old_batch =
        batch_fixture(%{batch: "OLD", expiry: "2030-01-01", price_per_unit: 100, quantity: 10})

      current_batch =
        batch_fixture(%{
          batch: "CURRENT",
          expiry: "2030-01-01",
          price_per_unit: 100,
          quantity: 10
        })

      old_drug_batch =
        drug_batch_fixture(%{
          drug: old_drug,
          batch: old_batch,
          inventory_received: old_inventory,
          inventory_manager: pharmacist,
          is_confirmed: true,
          remaining_quantity: 10
        })

      current_drug_batch =
        drug_batch_fixture(%{
          drug: current_drug,
          batch: current_batch,
          inventory_received: current_inventory,
          inventory_manager: pharmacist,
          is_confirmed: true,
          remaining_quantity: 10
        })

      drug_allocation =
        drug_allocation_fixture(%{
          has_been_assigned: true,
          drugs_assigned: [
            %{
              brand_name: old_drug.brand_name,
              generic_name: old_drug.generic_name,
              inventory_received_id: old_inventory.id,
              quantity: 10,
              frequency: "Twice daily",
              duration_in_days: 5
            },
            %{
              brand_name: current_drug.brand_name,
              generic_name: current_drug.generic_name,
              inventory_received_id: current_inventory.id,
              quantity: 10,
              frequency: "Twice daily",
              duration_in_days: 5
            }
          ]
        })

      [_old_assignment, current_assignment] = drug_allocation.drugs_assigned

      assert {:ok, _} =
               Medcamp.DrugBatches.update_drug_batch(old_drug_batch, %{remaining_quantity: 0})

      assert {:ok, drug_given} =
               DrugsGiven.create_drug_given_by_brand(
                 drug_allocation.id,
                 current_assignment.brand_name,
                 current_assignment.generic_name,
                 pharmacist.id,
                 current_assignment.id,
                 "Give after meals"
               )

      assert drug_given.drug_id == current_drug.id

      updated_allocation = Medcamp.DrugAllocations.get_drug_allocation!(drug_allocation.id)
      [updated_old_assignment, updated_current_assignment] = updated_allocation.drugs_assigned

      refute updated_old_assignment.has_been_given
      assert updated_current_assignment.has_been_given
      assert updated_current_assignment.pharmacist_note == "Give after meals"

      assert Medcamp.DrugBatches.get_drug_batch!(current_drug_batch.id).remaining_quantity == 0
      assert Medcamp.DrugBatches.get_drug_batch!(old_drug_batch.id).remaining_quantity == 0

      assert {:ok, %{drug_allocation: undone_allocation}} =
               DrugsGiven.cancel_drug_given(drug_given.id)

      [undone_old_assignment, undone_current_assignment] = undone_allocation.drugs_assigned

      refute undone_old_assignment.has_been_given
      refute undone_current_assignment.has_been_given

      assert Medcamp.DrugBatches.get_drug_batch!(current_drug_batch.id).remaining_quantity == 10
      assert Medcamp.DrugBatches.get_drug_batch!(old_drug_batch.id).remaining_quantity == 0
      assert_raise Ecto.NoResultsError, fn -> DrugsGiven.get_drug_given!(drug_given.id) end
    end
  end
end
