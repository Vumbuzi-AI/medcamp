defmodule MedcampWeb.BatchLive.ShowTest do
  use MedcampWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Medcamp.AccountsFixtures

  alias Medcamp.Batches.Batch
  alias Medcamp.DrugAllocations.DrugAllocation
  alias Medcamp.Drugs.Drug
  alias Medcamp.DrugsGiven.BatchAllocation
  alias Medcamp.DrugsGiven.DrugGiven
  alias Medcamp.InventoriesReceived.InventoryReceived
  alias Medcamp.Patients.Patient
  alias Medcamp.Repo
  alias Medcamp.Suppliers.Supplier

  setup do
    inventory_manager = user_fixture(%{role: "inventory_manager", name: "IM User"})
    pharmacist = user_fixture(%{role: "pharmacist", name: "Pharmacist Dispenser"})

    supplier =
      Repo.insert!(%Supplier{
        name: "PharmaSupplies Ltd",
        email: "contact@pharmasupplies.com",
        contact: "+254700000000"
      })

    inventory =
      Repo.insert!(%InventoryReceived{
        gtin: "GTIN-#{System.unique_integer([:positive])}",
        brand_name: "Panadol Extra 500mg",
        generic_name: "Paracetamol",
        category: "Pharmaceuticals"
      })

    batch =
      Repo.insert!(%Batch{
        gtin: inventory.gtin,
        batch: "BATCH-TEST-999",
        quantity: 100,
        remaining_quantity: 80,
        uom: "tablets",
        cost_per_unit: 15,
        expiry: "2028-12-31",
        inventory_received_id: inventory.id,
        supplier_id: supplier.id
      })

    patient =
      Repo.insert!(%Patient{
        first_name: "Jane",
        last_name: "Doe",
        phone_number: "0700000000",
        date_of_birth: ~D[1996-01-01],
        gender: "Female",
        home_address: "Nairobi",
        creator_id: inventory_manager.id
      })

    drug =
      Repo.insert!(%Drug{
        brand_name: inventory.brand_name,
        generic_name: inventory.generic_name,
        inventory_received_id: inventory.id,
        inventory_manager_id: inventory_manager.id
      })

    {:ok, allocation} =
      %DrugAllocation{}
      |> DrugAllocation.changeset(%{
        prescription: "Take 1 tablet twice daily",
        patient_id: patient.id,
        pharmacist_id: pharmacist.id,
        has_been_assigned: true
      })
      |> Repo.insert()

    _drugs_given =
      Repo.insert!(%DrugGiven{
        drug_id: drug.id,
        quantity: 20,
        price: 300,
        pharmacist_id: pharmacist.id,
        drug_allocation_id: allocation.id,
        batch_allocations: [
          %BatchAllocation{
            batch_id: batch.id,
            quantity: 20,
            unit_price: 15,
            drug_batch_id: 1,
            is_verified: true
          }
        ]
      })

    %{
      inventory_manager: inventory_manager,
      batch: batch,
      supplier: supplier,
      inventory: inventory,
      patient: patient,
      allocation: allocation
    }
  end

  test "renders core batch metrics and drug allocations for a valid batch", %{
    conn: conn,
    inventory_manager: inventory_manager,
    batch: batch,
    supplier: supplier,
    inventory: inventory
  } do
    conn = log_in_user(conn, inventory_manager)

    {:ok, _view, html} = live(conn, ~p"/inventory_manager/batches/#{batch.id}")

    assert html =~ "Batch: #{batch.batch}"
    assert html =~ inventory.gtin
    assert html =~ inventory.brand_name
    assert html =~ supplier.name
    assert html =~ "80"
    assert html =~ "tablets"
    assert html =~ "2028-12-31"

    # Drug Allocations Section
    assert html =~ "Drug Allocations Drawn From This Batch"
    assert html =~ "Jane Doe"
    assert html =~ "Pharmacist Dispenser"
  end

  test "renders empty allocations state when batch has no drug allocations", %{
    conn: conn,
    inventory_manager: inventory_manager,
    inventory: inventory
  } do
    empty_batch =
      Repo.insert!(%Batch{
        gtin: inventory.gtin,
        batch: "BATCH-EMPTY-000",
        quantity: 50,
        remaining_quantity: 50,
        uom: "boxes",
        inventory_received_id: inventory.id
      })

    conn = log_in_user(conn, inventory_manager)

    {:ok, _view, html} = live(conn, ~p"/inventory_manager/batches/#{empty_batch.id}")

    assert html =~ "Batch: BATCH-EMPTY-000"
    assert html =~ "No drug allocations found"
    assert html =~ "No patient drug allocations have been dispensed from this specific batch yet."
  end

  test "returns 404 error for invalid batch id", %{
    conn: conn,
    inventory_manager: inventory_manager
  } do
    conn = log_in_user(conn, inventory_manager)

    assert_error_sent 404, fn ->
      live(conn, ~p"/inventory_manager/batches/99999999")
    end
  end

  test "AllBatchesLive.Index links to batch show page", %{
    conn: conn,
    inventory_manager: inventory_manager,
    batch: batch
  } do
    conn = log_in_user(conn, inventory_manager)

    {:ok, _view, html} = live(conn, ~p"/inventory_manager/batches")

    assert html =~ ~p"/inventory_manager/batches/#{batch.id}"
    assert html =~ batch.batch
  end

  test "shows an Expired badge for a batch past its expiry date", %{
    conn: conn,
    inventory_manager: inventory_manager,
    inventory: inventory
  } do
    expired_batch =
      Repo.insert!(%Batch{
        gtin: inventory.gtin,
        batch: "BATCH-EXPIRED-000",
        quantity: 50,
        remaining_quantity: 20,
        uom: "boxes",
        expiry: "2020-01-01",
        inventory_received_id: inventory.id
      })

    conn = log_in_user(conn, inventory_manager)

    {:ok, _view, html} = live(conn, ~p"/inventory_manager/batches/#{expired_batch.id}")

    assert html =~ "Expired"
  end

  test "shows a Depleted badge for a batch with zero remaining quantity", %{
    conn: conn,
    inventory_manager: inventory_manager,
    inventory: inventory
  } do
    depleted_batch =
      Repo.insert!(%Batch{
        gtin: inventory.gtin,
        batch: "BATCH-DEPLETED-000",
        quantity: 50,
        remaining_quantity: 0,
        uom: "boxes",
        expiry: "2028-12-31",
        inventory_received_id: inventory.id
      })

    conn = log_in_user(conn, inventory_manager)

    {:ok, _view, html} = live(conn, ~p"/inventory_manager/batches/#{depleted_batch.id}")

    assert html =~ "Depleted"
  end

  test "shows a Low Stock badge for a batch with 10 or fewer remaining", %{
    conn: conn,
    inventory_manager: inventory_manager,
    inventory: inventory
  } do
    low_stock_batch =
      Repo.insert!(%Batch{
        gtin: inventory.gtin,
        batch: "BATCH-LOWSTOCK-000",
        quantity: 50,
        remaining_quantity: 5,
        uom: "boxes",
        expiry: "2028-12-31",
        inventory_received_id: inventory.id
      })

    conn = log_in_user(conn, inventory_manager)

    {:ok, _view, html} = live(conn, ~p"/inventory_manager/batches/#{low_stock_batch.id}")

    assert html =~ "Low Stock"
  end
end
