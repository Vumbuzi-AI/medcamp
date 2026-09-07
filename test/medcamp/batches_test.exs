defmodule Medcamp.BatchesTest do
  use Medcamp.DataCase

  alias Medcamp.Batches

  describe "batches" do
    alias Medcamp.Batches.Batch

    import Medcamp.BatchesFixtures

    @invalid_attrs %{
      serial: nil,
      gtin: nil,
      batch: nil,
      expiry: nil,
      manufacturer: nil,
      quantity: nil
    }

    test "list_batches/0 returns all batches" do
      batch = batch_fixture()
      assert Batches.list_batches() == [batch]
    end

    test "get_batch!/1 returns the batch with given id" do
      batch = batch_fixture()
      assert Batches.get_batch!(batch.id) == batch
    end

    test "create_batch/1 with valid data creates a batch" do
      valid_attrs = %{
        serial: "some serial",
        gtin: "some gtin",
        batch: "some batch",
        expiry: "some expiry",
        manufacturer: "some manufacturer",
        quantity: 42
      }

      assert {:ok, %Batch{} = batch} = Batches.create_batch(valid_attrs)
      assert batch.serial == "some serial"
      assert batch.gtin == "some gtin"
      assert batch.batch == "some batch"
      assert batch.expiry == "some expiry"
      assert batch.manufacturer == "some manufacturer"
      assert batch.quantity == 42
    end

    test "create_batch/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Batches.create_batch(@invalid_attrs)
    end

    test "update_batch/2 with valid data updates the batch" do
      batch = batch_fixture()

      update_attrs = %{
        serial: "some updated serial",
        gtin: "some updated gtin",
        batch: "some updated batch",
        expiry: "some updated expiry",
        manufacturer: "some updated manufacturer",
        quantity: 43
      }

      assert {:ok, %Batch{} = batch} = Batches.update_batch(batch, update_attrs)
      assert batch.serial == "some updated serial"
      assert batch.gtin == "some updated gtin"
      assert batch.batch == "some updated batch"
      assert batch.expiry == "some updated expiry"
      assert batch.manufacturer == "some updated manufacturer"
      assert batch.quantity == 43
    end

    test "update_batch/2 with invalid data returns error changeset" do
      batch = batch_fixture()
      assert {:error, %Ecto.Changeset{}} = Batches.update_batch(batch, @invalid_attrs)
      assert batch == Batches.get_batch!(batch.id)
    end

    test "delete_batch/1 deletes the batch" do
      batch = batch_fixture()
      assert {:ok, %Batch{}} = Batches.delete_batch(batch)
      assert_raise Ecto.NoResultsError, fn -> Batches.get_batch!(batch.id) end
    end

    test "change_batch/1 returns a batch changeset" do
      batch = batch_fixture()
      assert %Ecto.Changeset{} = Batches.change_batch(batch)
    end
  end
end
