defmodule Medcamp.InventoryDisposalsTest do
  use Medcamp.DataCase

  import Medcamp.AccountsFixtures

  alias Medcamp.AuditLog
  alias Medcamp.Batches.Batch
  alias Medcamp.InventoriesReceived.InventoryReceived
  alias Medcamp.InventoryDisposals
  alias Medcamp.InventoryDisposals.InventoryDisposalItem

  setup do
    requester = user_fixture(%{role: "admin"})
    approver = user_fixture(%{role: "admin"})

    inventory =
      Repo.insert!(%InventoryReceived{
        gtin: "GTIN-#{System.unique_integer([:positive])}",
        brand_name: "Test Gloves",
        category: "Medical supplies"
      })

    batch =
      Repo.insert!(%Batch{
        gtin: inventory.gtin,
        batch: "BATCH-1",
        quantity: 20,
        remaining_quantity: 20,
        uom: "boxes",
        inventory_received_id: inventory.id
      })

    %{requester: requester, approver: approver, batch: batch}
  end

  test "donation can be submitted without a supporting PDF", %{
    requester: requester,
    batch: batch
  } do
    {:ok, disposal} =
      InventoryDisposals.create_disposal(%{
        kind: "donation",
        date: Date.utc_today(),
        requested_by_id: requester.id
      })

    {:ok, _item} = add_batch(disposal, batch, 3)

    assert {:ok, %{status: "pending"}} = InventoryDisposals.submit(disposal)
  end

  test "approval deducts the exact source quantity and records an audit log", context do
    %{requester: requester, approver: approver, batch: batch} = context

    {:ok, disposal} =
      InventoryDisposals.create_disposal(%{
        kind: "donation",
        date: Date.utc_today(),
        supporting_document_path: "/uploads/donations/request.pdf",
        requested_by_id: requester.id
      })

    {:ok, item} = add_batch(disposal, batch, 7)
    assert {:ok, pending} = InventoryDisposals.submit(disposal)
    assert {:ok, approved} = InventoryDisposals.approve(pending, approver.id)

    assert approved.status == "approved"
    assert Repo.get!(Batch, batch.id).remaining_quantity == 13
    assert Repo.get!(InventoryDisposalItem, item.id).has_been_applied

    audit =
      Repo.one!(
        from(a in AuditLog,
          where:
            a.action == "donation_inventory" and a.table_name == "batches" and
              a.record_id == ^batch.id
        )
      )

    assert audit.previous_state["remaining_quantity"] == 20
    assert audit.new_state["remaining_quantity"] == 13
    assert audit.new_state["quantity_removed"] == 7
  end

  test "approval rolls back when stock changed after the request was submitted", context do
    %{requester: requester, approver: approver, batch: batch} = context

    {:ok, disposal} =
      InventoryDisposals.create_disposal(%{
        kind: "expiry",
        date: Date.utc_today(),
        requested_by_id: requester.id
      })

    {:ok, item} = add_batch(disposal, batch, 12)
    assert {:ok, pending} = InventoryDisposals.submit(disposal)

    batch |> Batch.changeset(%{remaining_quantity: 5}) |> Repo.update!()

    assert {:error, {:insufficient_stock, "Test Gloves — BATCH-1", 5}} =
             InventoryDisposals.approve(pending, approver.id)

    assert Repo.get!(Batch, batch.id).remaining_quantity == 5
    refute Repo.get!(InventoryDisposalItem, item.id).has_been_applied
    assert InventoryDisposals.get_disposal!(disposal.id).status == "pending"
  end

  defp add_batch(disposal, batch, quantity) do
    InventoryDisposals.create_item(%{
      inventory_disposal_id: disposal.id,
      entity_type: "inventory_received",
      entity_id: batch.id,
      entity_name: "Test Gloves — BATCH-1",
      category: "Medical supplies",
      available_quantity: batch.remaining_quantity,
      quantity: quantity,
      uom: batch.uom
    })
  end
end
