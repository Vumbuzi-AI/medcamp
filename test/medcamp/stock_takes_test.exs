defmodule Medcamp.StockTakesTest do
  use Medcamp.DataCase

  import Medcamp.AccountsFixtures

  alias Medcamp.AuditLog
  alias Medcamp.Batches.Batch
  alias Medcamp.Departments.Department
  alias Medcamp.DrugBatches.DrugBatch
  alias Medcamp.Drugs.Drug
  alias Medcamp.InventoriesReceived.InventoryReceived
  alias Medcamp.StockTakes
  alias Medcamp.StockTakes.StockTake

  setup do
    admin = user_fixture(%{role: "admin", name: "Admin Approver"})
    requester = user_fixture(%{role: "pharmacist", name: "Peter Pharmacist"})

    department =
      Repo.insert!(%Department{
        name: "Pharmacy",
        code: "PHARM_TEST_#{System.unique_integer([:positive])}"
      })

    inventory =
      Repo.insert!(%InventoryReceived{
        gtin: "GTIN-#{System.unique_integer([:positive])}",
        brand_name: "Amoxicillin 500mg",
        generic_name: "Amoxicillin",
        category: "Pharmaceuticals"
      })

    batch =
      Repo.insert!(%Batch{
        gtin: inventory.gtin,
        batch: "BATCH-ST-1",
        quantity: 50,
        remaining_quantity: 50,
        uom: "boxes",
        inventory_received_id: inventory.id
      })

    drug =
      Repo.insert!(%Drug{
        brand_name: inventory.brand_name,
        generic_name: "Amoxicillin",
        inventory_received_id: inventory.id,
        inventory_manager_id: admin.id,
        is_otc: false
      })

    drug_batch =
      Repo.insert!(%DrugBatch{
        drug_id: drug.id,
        batch_id: batch.id,
        inventory_received_id: inventory.id,
        inventory_manager_id: admin.id,
        remaining_quantity: 50,
        is_confirmed: true
      })

    issued =
      Repo.insert!(%Medcamp.InventoriesIssues.InventoryIssued{
        gtin: inventory.gtin,
        quantity: 20,
        location: "Lab",
        inventory_received_id: inventory.id,
        batch_id: batch.id,
        inventory_manager_id: admin.id,
        assigned_to_id: admin.id
      })

    lab_alloc =
      Repo.insert!(%Medcamp.LabAllocations.LabAllocation{
        allocated_quantity: 20,
        remaining_quantity: 20,
        uom: "boxes",
        inventory_issued_id: issued.id,
        allocated_by: admin.id,
        allocated_to: admin.id
      })

    nursing_alloc =
      Repo.insert!(%Medcamp.NursingAllocations.NursingAllocation{
        allocated_quantity: 20,
        remaining_quantity: 20,
        uom: "boxes",
        inventory_issued_id: issued.id,
        allocated_by: admin.id,
        allocated_to: admin.id
      })

    %{
      admin: admin,
      requester: requester,
      department: department,
      inventory: inventory,
      batch: batch,
      drug: drug,
      drug_batch: drug_batch,
      lab_alloc: lab_alloc,
      nursing_alloc: nursing_alloc
    }
  end

  describe "stock take CRUD and validations" do
    test "create_stock_take/1 with valid attributes creates a stock take", %{
      admin: admin,
      department: department
    } do
      attrs = %{
        date: ~D[2026-07-31],
        admin_id: admin.id,
        department_id: department.id,
        notes: "Monthly count"
      }

      assert {:ok, %StockTake{} = stock_take} = StockTakes.create_stock_take(attrs)
      assert stock_take.status == "draft"
      assert stock_take.department_id == department.id
      assert stock_take.admin_id == admin.id
    end

    test "create_stock_take/1 fails when required department_id is missing on admin form", %{
      admin: admin
    } do
      attrs = %{
        date: ~D[2026-07-31],
        admin_id: admin.id,
        notes: "Missing department"
      }

      assert {:error, changeset} = StockTakes.create_stock_take(attrs)
      assert "can't be blank" in errors_on(changeset).department_id
    end

    test "create_stock_take/1 auto-populates department_id from requested_by user when available",
         %{
           department: department
         } do
      user_with_dept = user_fixture(%{role: "pharmacist"})
      user_with_dept |> Ecto.Changeset.change(department_id: department.id) |> Repo.update!()

      attrs = %{
        date: ~D[2026-07-31],
        requested_by_id: user_with_dept.id
      }

      assert {:ok, stock_take} = StockTakes.create_stock_take(attrs)
      assert stock_take.department_id == department.id
    end

    test "create_stock_take/1 does not silently override an explicit blank department_id, even when the requester has a profile department",
         %{department: department} do
      user_with_dept = user_fixture(%{role: "pharmacist"})
      user_with_dept |> Ecto.Changeset.change(department_id: department.id) |> Repo.update!()

      attrs = %{
        date: ~D[2026-07-31],
        requested_by_id: user_with_dept.id,
        department_id: ""
      }

      assert {:error, changeset} = StockTakes.create_stock_take(attrs)
      assert "can't be blank" in errors_on(changeset).department_id
    end

    test "create_stock_take/1 fails when neither admin_id nor requested_by_id is provided", %{
      department: department
    } do
      attrs = %{
        date: ~D[2026-07-31],
        department_id: department.id
      }

      assert {:error, changeset} = StockTakes.create_stock_take(attrs)
      assert "or requested_by is required" in errors_on(changeset).admin_id
    end
  end

  describe "stock take entries" do
    test "create_entry/1 and entry_already_in_stock_take?/3", %{
      admin: admin,
      department: department,
      drug_batch: drug_batch
    } do
      {:ok, stock_take} =
        StockTakes.create_stock_take(%{
          date: ~D[2026-07-31],
          admin_id: admin.id,
          department_id: department.id
        })

      refute StockTakes.entry_already_in_stock_take?(stock_take.id, "drug_batch", drug_batch.id)

      assert {:ok, entry} =
               StockTakes.create_entry(%{
                 stock_take_id: stock_take.id,
                 entity_type: "drug_batch",
                 entity_id: drug_batch.id,
                 entity_name: "Amoxicillin 500mg",
                 previous_quantity: 50,
                 counted_quantity: 45,
                 uom: "boxes"
               })

      assert entry.difference == -5
      assert StockTakes.entry_already_in_stock_take?(stock_take.id, "drug_batch", drug_batch.id)
    end
  end

  describe "submit_stock_take/1 status transitions and validation" do
    test "submits draft stock take with counted entries to pending status", %{
      requester: requester,
      department: department,
      drug_batch: drug_batch
    } do
      {:ok, stock_take} =
        StockTakes.create_stock_take(%{
          date: ~D[2026-07-31],
          requested_by_id: requester.id,
          department_id: department.id
        })

      {:ok, _entry} =
        StockTakes.create_entry(%{
          stock_take_id: stock_take.id,
          entity_type: "drug_batch",
          entity_id: drug_batch.id,
          entity_name: "Amoxicillin 500mg",
          previous_quantity: 50,
          counted_quantity: 45
        })

      assert {:ok, updated} = StockTakes.submit_stock_take(stock_take)
      assert updated.status == "pending"
    end

    test "submitting draft stock take without any counts fails with {:error, :no_counts}", %{
      requester: requester,
      department: department,
      drug_batch: drug_batch
    } do
      {:ok, stock_take} =
        StockTakes.create_stock_take(%{
          date: ~D[2026-07-31],
          requested_by_id: requester.id,
          department_id: department.id
        })

      # Add entry with NULL counted_quantity
      {:ok, _entry} =
        StockTakes.create_entry(%{
          stock_take_id: stock_take.id,
          entity_type: "drug_batch",
          entity_id: drug_batch.id,
          entity_name: "Amoxicillin 500mg",
          previous_quantity: 50
        })

      assert {:error, :no_counts} = StockTakes.submit_stock_take(stock_take)
    end

    test "submitting non-draft stock take fails with {:error, :invalid_status}", %{
      requester: requester,
      department: department,
      drug_batch: drug_batch
    } do
      {:ok, stock_take} =
        StockTakes.create_stock_take(%{
          date: ~D[2026-07-31],
          requested_by_id: requester.id,
          department_id: department.id
        })

      {:ok, _entry} =
        StockTakes.create_entry(%{
          stock_take_id: stock_take.id,
          entity_type: "drug_batch",
          entity_id: drug_batch.id,
          entity_name: "Amoxicillin 500mg",
          previous_quantity: 50,
          counted_quantity: 45
        })

      {:ok, pending_st} = StockTakes.submit_stock_take(stock_take)
      assert {:error, :invalid_status} = StockTakes.submit_stock_take(pending_st)
    end
  end

  describe "approve_stock_take/2 workflow and inventory adjustment" do
    test "approval updates stock take status to completed, records approver, and adjusts inventory",
         %{
           admin: admin,
           requester: requester,
           department: department,
           drug_batch: drug_batch
         } do
      {:ok, stock_take} =
        StockTakes.create_stock_take(%{
          date: ~D[2026-07-31],
          requested_by_id: requester.id,
          department_id: department.id
        })

      {:ok, _entry} =
        StockTakes.create_entry(%{
          stock_take_id: stock_take.id,
          entity_type: "drug_batch",
          entity_id: drug_batch.id,
          entity_name: "Amoxicillin 500mg",
          previous_quantity: 50,
          counted_quantity: 40
        })

      {:ok, pending_st} = StockTakes.submit_stock_take(stock_take)

      # Ensure remaining_quantity is 50 before approval
      assert Repo.get!(DrugBatch, drug_batch.id).remaining_quantity == 50

      assert {:ok, completed_st} = StockTakes.approve_stock_take(pending_st, admin.id)
      assert completed_st.status == "completed"
      assert completed_st.approved_by_id == admin.id
      assert completed_st.approved_at != nil

      # Verify inventory adjustment happened ON APPROVAL ONLY
      assert Repo.get!(DrugBatch, drug_batch.id).remaining_quantity == 40

      # Verify AuditLog recorded
      audit_logs = Repo.all(AuditLog)
      assert Enum.any?(audit_logs, fn log -> log.action == "stock_take_adjustment" end)
    end

    test "attempting approval on non-pending status fails transaction with :invalid_status", %{
      admin: admin,
      department: department,
      drug_batch: drug_batch
    } do
      {:ok, draft_st} =
        StockTakes.create_stock_take(%{
          date: ~D[2026-07-31],
          admin_id: admin.id,
          department_id: department.id
        })

      {:ok, _entry} =
        StockTakes.create_entry(%{
          stock_take_id: draft_st.id,
          entity_type: "drug_batch",
          entity_id: drug_batch.id,
          entity_name: "Amoxicillin 500mg",
          previous_quantity: 50,
          counted_quantity: 40
        })

      # Approving a draft directly (must be pending) rolls back
      assert {:error, :invalid_status} = StockTakes.approve_stock_take(draft_st, admin.id)
    end
  end

  describe "reject_stock_take/2 workflow" do
    test "rejection updates status to rejected, records approver, and DOES NOT adjust inventory",
         %{
           admin: admin,
           requester: requester,
           department: department,
           drug_batch: drug_batch
         } do
      {:ok, stock_take} =
        StockTakes.create_stock_take(%{
          date: ~D[2026-07-31],
          requested_by_id: requester.id,
          department_id: department.id
        })

      {:ok, _entry} =
        StockTakes.create_entry(%{
          stock_take_id: stock_take.id,
          entity_type: "drug_batch",
          entity_id: drug_batch.id,
          entity_name: "Amoxicillin 500mg",
          previous_quantity: 50,
          counted_quantity: 10
        })

      {:ok, pending_st} = StockTakes.submit_stock_take(stock_take)

      assert {:ok, rejected_st} = StockTakes.reject_stock_take(pending_st, admin.id)
      assert rejected_st.status == "rejected"
      assert rejected_st.approved_by_id == admin.id
      assert rejected_st.approved_at != nil

      # Inventory remaining_quantity MUST REMAIN UNCHANGED
      assert Repo.get!(DrugBatch, drug_batch.id).remaining_quantity == 50
    end

    test "attempting rejection on non-pending status fails transaction with :invalid_status", %{
      admin: admin,
      department: department
    } do
      {:ok, draft_st} =
        StockTakes.create_stock_take(%{
          date: ~D[2026-07-31],
          admin_id: admin.id,
          department_id: department.id
        })

      assert {:error, :invalid_status} = StockTakes.reject_stock_take(draft_st, admin.id)
    end
  end

  describe "delete_requester_stock_take/1" do
    test "allows deleting draft, pending, and rejected stock takes, but blocks completed ones", %{
      admin: admin,
      requester: requester,
      department: department,
      drug_batch: drug_batch
    } do
      {:ok, draft_st} =
        StockTakes.create_stock_take(%{
          date: ~D[2026-07-31],
          requested_by_id: requester.id,
          department_id: department.id
        })

      {:ok, _entry} =
        StockTakes.create_entry(%{
          stock_take_id: draft_st.id,
          entity_type: "drug_batch",
          entity_id: drug_batch.id,
          entity_name: "Amoxicillin 500mg",
          previous_quantity: 50,
          counted_quantity: 45
        })

      {:ok, pending_st} = StockTakes.submit_stock_take(draft_st)
      assert {:ok, _} = StockTakes.delete_requester_stock_take(pending_st)

      # Create and approve another
      {:ok, draft2} =
        StockTakes.create_stock_take(%{
          date: ~D[2026-07-31],
          requested_by_id: requester.id,
          department_id: department.id
        })

      {:ok, _entry} =
        StockTakes.create_entry(%{
          stock_take_id: draft2.id,
          entity_type: "drug_batch",
          entity_id: drug_batch.id,
          entity_name: "Amoxicillin 500mg",
          previous_quantity: 50,
          counted_quantity: 45
        })

      {:ok, pending2} = StockTakes.submit_stock_take(draft2)
      {:ok, completed_st} = StockTakes.approve_stock_take(pending2, admin.id)

      assert {:error, :not_deletable} = StockTakes.delete_requester_stock_take(completed_st)
    end
  end

  describe "stock take listing, pagination and search helpers" do
    test "list_stock_takes/0 and paginated listing with department filtering", %{
      admin: admin,
      department: department
    } do
      {:ok, st} =
        StockTakes.create_stock_take(%{
          date: ~D[2026-07-31],
          admin_id: admin.id,
          department_id: department.id
        })

      assert Enum.any?(StockTakes.list_stock_takes(), fn s -> s.id == st.id end)
      assert StockTakes.count_stock_takes(department.id) >= 1

      assert Enum.any?(StockTakes.list_stock_takes_paginated(1, 10, department.id), fn s ->
               s.id == st.id
             end)
    end

    test "string department ids from params are normalized for paginated list and count queries",
         %{
           admin: admin,
           department: department
         } do
      {:ok, st} =
        StockTakes.create_stock_take(%{
          date: ~D[2026-07-31],
          admin_id: admin.id,
          department_id: department.id
        })

      assert StockTakes.count_stock_takes(to_string(department.id)) >= 1

      assert Enum.any?(
               StockTakes.list_stock_takes_paginated(1, 10, to_string(department.id)),
               fn s ->
                 s.id == st.id
               end
             )
    end

    test "search helpers for drug_batches, lab, nursing, and inventory_received", %{
      inventory: inventory,
      drug_batch: drug_batch,
      lab_alloc: lab_alloc,
      nursing_alloc: nursing_alloc
    } do
      batches = StockTakes.search_drug_batches("Amoxicillin")
      assert Enum.any?(batches, fn b -> b.id == drug_batch.id end)

      all_batches = StockTakes.list_drug_batches_for_stock_take()
      assert Enum.any?(all_batches, fn b -> b.id == drug_batch.id end)

      inv_results = StockTakes.search_inventory_received("Amoxicillin")
      assert Enum.any?(inv_results, fn b -> b.inventory_received_id == inventory.id end)

      lab_results = StockTakes.search_lab_allocations("Amoxicillin")
      assert Enum.any?(lab_results, fn a -> a.id == lab_alloc.id end)

      nurse_results = StockTakes.search_nursing_allocations("Amoxicillin")
      assert Enum.any?(nurse_results, fn a -> a.id == nursing_alloc.id end)
    end
  end

  describe "entry update, lookup, summary and apply_stock_take for all entity types" do
    test "entry CRUD, lookups, and stock_take_summary", %{
      admin: admin,
      department: department,
      drug_batch: drug_batch,
      batch: batch,
      lab_alloc: lab_alloc,
      nursing_alloc: nursing_alloc
    } do
      {:ok, stock_take} =
        StockTakes.create_stock_take(%{
          date: ~D[2026-07-31],
          admin_id: admin.id,
          department_id: department.id
        })

      {:ok, entry} =
        StockTakes.create_entry(%{
          stock_take_id: stock_take.id,
          entity_type: "drug_batch",
          entity_id: drug_batch.id,
          entity_name: "Amoxicillin 500mg",
          previous_quantity: 50,
          counted_quantity: 40
        })

      # Update entry
      {:ok, updated_entry} = StockTakes.update_entry(entry, %{counted_quantity: 35})
      assert updated_entry.difference == -15

      # Lookup helpers
      {brand, generic, _batch_no} = StockTakes.lookup_entry_names(entry)
      assert brand == "Amoxicillin 500mg"
      assert generic == "Amoxicillin"

      assert StockTakes.lookup_entry_uom(entry) == "boxes"

      # Lookup lab and nursing allocation entry names & UOMs
      {:ok, lab_entry} =
        StockTakes.create_entry(%{
          stock_take_id: stock_take.id,
          entity_type: "lab_allocation",
          entity_id: lab_alloc.id,
          entity_name: "Lab Gloves",
          previous_quantity: 20,
          counted_quantity: 18
        })

      assert StockTakes.lookup_entry_uom(lab_entry) == "boxes"
      {lab_brand, _, _} = StockTakes.lookup_entry_names(lab_entry)
      assert lab_brand == "Amoxicillin 500mg"

      {:ok, nurse_entry} =
        StockTakes.create_entry(%{
          stock_take_id: stock_take.id,
          entity_type: "nursing_allocation",
          entity_id: nursing_alloc.id,
          entity_name: "Nursing Bandages",
          previous_quantity: 20,
          counted_quantity: 25
        })

      assert StockTakes.lookup_entry_uom(nurse_entry) == "boxes"
      {nurse_brand, _, _} = StockTakes.lookup_entry_names(nurse_entry)
      assert nurse_brand == "Amoxicillin 500mg"

      # Summary
      summary = StockTakes.stock_take_summary(stock_take)
      assert summary.total_entries == 3

      # Delete entry
      assert {:ok, _} = StockTakes.delete_entry(updated_entry)
      assert_raise Ecto.NoResultsError, fn -> StockTakes.get_entry!(entry.id) end

      # Apply stock take for lab, nursing, and inventory_received entities
      {:ok, _entry2} =
        StockTakes.create_entry(%{
          stock_take_id: stock_take.id,
          entity_type: "inventory_received",
          entity_id: batch.id,
          entity_name: "Amoxicillin 500mg",
          previous_quantity: 50,
          counted_quantity: 30
        })

      assert {:ok, applied_st} = StockTakes.apply_stock_take(stock_take, admin.id)
      assert applied_st.status == "completed"
      assert Repo.get!(Batch, batch.id).remaining_quantity == 30
      assert Repo.get!(Medcamp.LabAllocations.LabAllocation, lab_alloc.id).remaining_quantity == 18

      assert Repo.get!(Medcamp.NursingAllocations.NursingAllocation, nursing_alloc.id).remaining_quantity ==
               25
    end
  end
end
