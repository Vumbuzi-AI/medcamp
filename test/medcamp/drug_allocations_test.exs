defmodule Medcamp.DrugAllocationsTest do
  use Medcamp.DataCase

  alias Medcamp.DrugAllocations

  describe "drug_allocations" do
    alias Medcamp.DrugAllocations.DrugAllocation

    import Medcamp.DrugAllocationsFixtures

    # A prescription with no drug lines is invalid - the drug lines *are* the
    # prescription; the free-text note is optional.
    @invalid_attrs %{quantity: nil, drugs_assigned: []}

    test "list_drug_allocations/0 returns all drug_allocations" do
      drug_allocation = drug_allocation_fixture()
      assert [%DrugAllocation{id: id}] = DrugAllocations.list_drug_allocations()
      assert id == drug_allocation.id
    end

    test "get_drug_allocation!/1 returns the drug_allocation with given id" do
      drug_allocation = drug_allocation_fixture()
      assert DrugAllocations.get_drug_allocation!(drug_allocation.id).id == drug_allocation.id
    end

    test "create_drug_allocation/1 with valid data creates a drug_allocation" do
      drug_allocation =
        drug_allocation_fixture(%{quantity: 42, prescription: "some prescription"})

      assert drug_allocation.quantity == 42
      assert drug_allocation.prescription == "some prescription"
      assert length(drug_allocation.drugs_assigned) >= 1
    end

    test "create_drug_allocation/1 without drug lines is rejected" do
      patient = Medcamp.PatientsFixtures.patient_fixture()

      assert {:error, changeset} =
               DrugAllocations.create_drug_allocation(%{
                 has_been_assigned: false,
                 patient_id: patient.id,
                 prescription: "note only, no drugs"
               })

      assert %{drugs_assigned: _} = errors_on(changeset)
    end

    test "create_drug_allocation/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = DrugAllocations.create_drug_allocation(@invalid_attrs)
    end

    test "update_drug_allocation/2 with valid data updates the drug_allocation" do
      drug_allocation = drug_allocation_fixture()
      update_attrs = %{quantity: 43, prescription: "some updated prescription"}

      assert {:ok, %DrugAllocation{} = drug_allocation} =
               DrugAllocations.update_drug_allocation(drug_allocation, update_attrs)

      assert drug_allocation.quantity == 43
      assert drug_allocation.prescription == "some updated prescription"
    end

    test "update_drug_allocation/2 with invalid data returns error changeset" do
      drug_allocation = drug_allocation_fixture()

      assert {:error, %Ecto.Changeset{}} =
               DrugAllocations.update_drug_allocation(drug_allocation, @invalid_attrs)

      assert DrugAllocations.get_drug_allocation!(drug_allocation.id).prescription ==
               drug_allocation.prescription
    end

    test "delete_drug_allocation/1 deletes the drug_allocation" do
      drug_allocation = drug_allocation_fixture()
      assert {:ok, %DrugAllocation{}} = DrugAllocations.delete_drug_allocation(drug_allocation)

      assert_raise Ecto.NoResultsError, fn ->
        DrugAllocations.get_drug_allocation!(drug_allocation.id)
      end
    end

    test "change_drug_allocation/1 returns a drug_allocation changeset" do
      drug_allocation = drug_allocation_fixture()
      assert %Ecto.Changeset{} = DrugAllocations.change_drug_allocation(drug_allocation)
    end
  end

  describe "issued_drug_report/1" do
    import Medcamp.DrugsFixtures
    import Medcamp.DrugsGivenFixtures
    import Medcamp.InventoriesReceivedFixtures

    test "totals issued quantities and groups drugs by received inventory item" do
      antibiotic_inventory =
        inventory_received_fixture(%{
          brand_name: "Amoxil",
          generic_name: "Amoxicillin",
          category: "Antibiotics",
          type: "Medicine",
          uom: "Capsules"
        })

      analgesic_inventory =
        inventory_received_fixture(%{
          brand_name: "Panadol",
          generic_name: "Paracetamol",
          category: "Analgesics",
          type: "Medicine"
        })

      antibiotic = drug_fixture(%{inventory_received: antibiotic_inventory})
      analgesic = drug_fixture(%{inventory_received: analgesic_inventory})

      drug_given_fixture(%{drug: antibiotic, quantity: 6})
      drug_given_fixture(%{drug: antibiotic, quantity: 4})
      drug_given_fixture(%{drug: analgesic, quantity: 3})

      assert [antibiotic_row, analgesic_row] = DrugAllocations.issued_drug_report()
      assert antibiotic_row.category == "Antibiotics"
      assert antibiotic_row.issued_quantity == 10
      assert antibiotic_row.issue_count == 2
      assert antibiotic_row.allocation_count == 2
      assert analgesic_row.issued_quantity == 3
    end

    test "filters by inventory category, product type, and drug search" do
      antibiotic_inventory =
        inventory_received_fixture(%{
          brand_name: "Cefix",
          generic_name: "Cefixime",
          category: "Antibiotics",
          type: "Medicine"
        })

      consumable_inventory =
        inventory_received_fixture(%{
          brand_name: "Gauze",
          generic_name: "Sterile gauze",
          category: "Non-Pharma",
          type: "Consumable"
        })

      drug_given_fixture(%{
        drug: drug_fixture(%{inventory_received: antibiotic_inventory}),
        quantity: 8
      })

      drug_given_fixture(%{
        drug: drug_fixture(%{inventory_received: consumable_inventory}),
        quantity: 2
      })

      assert [%{brand_name: "Cefix"}] =
               DrugAllocations.issued_drug_report(%{category: "antibiotics"})

      assert [%{brand_name: "Gauze"}] =
               DrugAllocations.issued_drug_report(%{"inventory_type" => "consumable"})

      assert [%{brand_name: "Cefix"}] =
               DrugAllocations.issued_drug_report(%{search: "cefixime"})
    end
  end
end
