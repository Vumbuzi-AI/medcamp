defmodule Medcamp.LabAllocationsTest do
  use Medcamp.DataCase

  alias Medcamp.LabAllocations

  describe "lab_allocations" do
    alias Medcamp.LabAllocations.LabAllocation

    import Medcamp.LabAllocationsFixtures

    @invalid_attrs %{allocated_quantity: nil, remaining_quantity: nil, uom: nil, expiry_date: nil}

    test "list_lab_allocations/0 returns all lab_allocations" do
      lab_allocation = lab_allocation_fixture()
      assert LabAllocations.list_lab_allocations() == [lab_allocation]
    end

    test "get_lab_allocation!/1 returns the lab_allocation with given id" do
      lab_allocation = lab_allocation_fixture()
      assert LabAllocations.get_lab_allocation!(lab_allocation.id) == lab_allocation
    end

    test "create_lab_allocation/1 with valid data creates a lab_allocation" do
      valid_attrs = %{
        allocated_quantity: 42,
        remaining_quantity: 42,
        uom: "some uom",
        expiry_date: ~D[2025-09-17]
      }

      assert {:ok, %LabAllocation{} = lab_allocation} =
               LabAllocations.create_lab_allocation(valid_attrs)

      assert lab_allocation.allocated_quantity == 42
      assert lab_allocation.remaining_quantity == 42
      assert lab_allocation.uom == "some uom"
      assert lab_allocation.expiry_date == ~D[2025-09-17]
    end

    test "create_lab_allocation/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = LabAllocations.create_lab_allocation(@invalid_attrs)
    end

    test "update_lab_allocation/2 with valid data updates the lab_allocation" do
      lab_allocation = lab_allocation_fixture()

      update_attrs = %{
        allocated_quantity: 43,
        remaining_quantity: 43,
        uom: "some updated uom",
        expiry_date: ~D[2025-09-18]
      }

      assert {:ok, %LabAllocation{} = lab_allocation} =
               LabAllocations.update_lab_allocation(lab_allocation, update_attrs)

      assert lab_allocation.allocated_quantity == 43
      assert lab_allocation.remaining_quantity == 43
      assert lab_allocation.uom == "some updated uom"
      assert lab_allocation.expiry_date == ~D[2025-09-18]
    end

    test "update_lab_allocation/2 with invalid data returns error changeset" do
      lab_allocation = lab_allocation_fixture()

      assert {:error, %Ecto.Changeset{}} =
               LabAllocations.update_lab_allocation(lab_allocation, @invalid_attrs)

      assert lab_allocation == LabAllocations.get_lab_allocation!(lab_allocation.id)
    end

    test "delete_lab_allocation/1 deletes the lab_allocation" do
      lab_allocation = lab_allocation_fixture()
      assert {:ok, %LabAllocation{}} = LabAllocations.delete_lab_allocation(lab_allocation)

      assert_raise Ecto.NoResultsError, fn ->
        LabAllocations.get_lab_allocation!(lab_allocation.id)
      end
    end

    test "change_lab_allocation/1 returns a lab_allocation changeset" do
      lab_allocation = lab_allocation_fixture()
      assert %Ecto.Changeset{} = LabAllocations.change_lab_allocation(lab_allocation)
    end
  end
end
