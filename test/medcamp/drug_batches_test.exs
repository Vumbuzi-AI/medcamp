defmodule Medcamp.DrugBatchesTest do
  use Medcamp.DataCase

  alias Medcamp.DrugBatches

  describe "drug_batches" do
    alias Medcamp.DrugBatches.DrugBatch

    import Medcamp.DrugBatchesFixtures
    import Medcamp.DrugsFixtures
    import Medcamp.BatchesFixtures
    import Medcamp.InventoriesReceivedFixtures
    import Medcamp.AccountsFixtures

    @invalid_attrs %{
      drug_id: nil,
      batch_id: nil,
      remaining_quantity: nil,
      inventory_manager_id: nil,
      inventory_received_id: nil
    }

    test "list_drug_batches/0 returns all drug_batches" do
      drug_batch = drug_batch_fixture()
      assert DrugBatches.list_drug_batches() == [drug_batch]
    end

    test "get_drug_batch!/1 returns the drug_batch with given id" do
      drug_batch = drug_batch_fixture()

      assert DrugBatches.get_drug_batch!(drug_batch.id) ==
               Medcamp.Repo.preload(drug_batch, [
                 :drug,
                 :batch,
                 :inventory_received,
                 :inventory_manager
               ])
    end

    test "create_drug_batch/1 with valid data creates a drug_batch" do
      drug = drug_fixture()
      batch = batch_fixture()
      inventory_received = inventory_received_fixture()
      inventory_manager = user_fixture()

      valid_attrs = %{
        drug_id: drug.id,
        batch_id: batch.id,
        inventory_received_id: inventory_received.id,
        inventory_manager_id: inventory_manager.id,
        remaining_quantity: 42
      }

      assert {:ok, %DrugBatch{} = drug_batch} = DrugBatches.create_drug_batch(valid_attrs)
      assert drug_batch.drug_id == drug.id
      assert drug_batch.batch_id == batch.id
      assert drug_batch.inventory_received_id == inventory_received.id
      assert drug_batch.inventory_manager_id == inventory_manager.id
      assert drug_batch.remaining_quantity == 42
    end

    test "create_drug_batch/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = DrugBatches.create_drug_batch(@invalid_attrs)
    end

    test "update_drug_batch/2 with valid data updates the drug_batch" do
      drug_batch = drug_batch_fixture()
      update_attrs = %{}

      assert {:ok, %DrugBatch{} = drug_batch} =
               DrugBatches.update_drug_batch(drug_batch, update_attrs)
    end

    test "update_drug_batch/2 with invalid data returns error changeset" do
      drug_batch = drug_batch_fixture()

      assert {:error, %Ecto.Changeset{}} =
               DrugBatches.update_drug_batch(drug_batch, @invalid_attrs)

      assert Medcamp.Repo.preload(drug_batch, [
               :drug,
               :batch,
               :inventory_received,
               :inventory_manager
             ]) ==
               DrugBatches.get_drug_batch!(drug_batch.id)
    end

    test "delete_drug_batch/1 deletes the drug_batch" do
      drug_batch = drug_batch_fixture()
      assert {:ok, %DrugBatch{}} = DrugBatches.delete_drug_batch(drug_batch)
      assert_raise Ecto.NoResultsError, fn -> DrugBatches.get_drug_batch!(drug_batch.id) end
    end

    test "change_drug_batch/1 returns a drug_batch changeset" do
      drug_batch = drug_batch_fixture()
      assert %Ecto.Changeset{} = DrugBatches.change_drug_batch(drug_batch)
    end
  end
end
