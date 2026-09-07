defmodule MedcampWeb.AdminInventoryDisposalLive.PrintTest do
  use MedcampWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Medcamp.AccountsFixtures

  alias Medcamp.InventoryDisposals

  setup %{conn: conn} do
    admin = user_fixture(%{role: "admin"})
    requester = user_fixture(%{role: "admin", name: "Jane Requester"})

    {:ok, disposal} =
      InventoryDisposals.create_disposal(%{
        kind: "donation",
        date: ~D[2026-07-01],
        reason: "Excess stock nearing expiry",
        requested_by_id: requester.id
      })

    %{conn: log_in_user(conn, admin), disposal: disposal}
  end

  test "does not render a print modal when the request has no items", %{
    conn: conn,
    disposal: disposal
  } do
    {:ok, view, _html} = live(conn, ~p"/admin/inventory_disposals/#{disposal.id}")

    refute has_element?(view, "#print-modal")
  end

  test "renders the donation note with item description, unit of issue, quantities, and comments",
       %{conn: conn, disposal: disposal} do
    {:ok, _item} =
      InventoryDisposals.create_item(%{
        inventory_disposal_id: disposal.id,
        entity_type: "inventory_received",
        entity_id: 1,
        entity_name: "Amoxicillin 500mg",
        available_quantity: 50,
        quantity: 20,
        uom: "boxes",
        notes: "Handled by field team"
      })

    {:ok, view, html} = live(conn, ~p"/admin/inventory_disposals/#{disposal.id}")

    assert html =~ "COUNTER REQUISITION AND ISSUE VOUCHER"
    assert html =~ "Jane Requester"
    assert html =~ "Excess stock nearing expiry"

    assert has_element?(view, "#print-modal table td", "Amoxicillin 500mg")
    assert has_element?(view, "#print-modal table td", "boxes")
    assert has_element?(view, "#print-modal table td", "Handled by field team")

    quantity_cells =
      view
      |> render()
      |> Floki.find(
        "table#voucher-items tbody tr td:nth-child(4), table#voucher-items tbody tr td:nth-child(5)"
      )
      |> Enum.map(&(Floki.text(&1) |> String.trim()))

    assert quantity_cells == ["20", "—"]
  end

  test "shows the requested quantity as issued only once the request is approved", %{
    conn: conn,
    disposal: disposal
  } do
    {:ok, _item} =
      InventoryDisposals.create_item(%{
        inventory_disposal_id: disposal.id,
        entity_type: "inventory_received",
        entity_id: 1,
        entity_name: "Amoxicillin 500mg",
        available_quantity: 50,
        quantity: 20,
        uom: "boxes"
      })

    {:ok, _approved} =
      disposal
      |> Medcamp.InventoryDisposals.InventoryDisposal.changeset(%{status: "approved"})
      |> Medcamp.Repo.update()

    {:ok, view, html} = live(conn, ~p"/admin/inventory_disposals/#{disposal.id}")

    assert html =~ "APPROVED"

    quantity_cells =
      view
      |> render()
      |> Floki.find(
        "table#voucher-items tbody tr td:nth-child(4), table#voucher-items tbody tr td:nth-child(5)"
      )
      |> Enum.map(&(Floki.text(&1) |> String.trim()))

    assert quantity_cells == ["20", "20"]
  end

  test "flags a rejected request as not issued", %{conn: conn, disposal: disposal} do
    {:ok, _item} =
      InventoryDisposals.create_item(%{
        inventory_disposal_id: disposal.id,
        entity_type: "inventory_received",
        entity_id: 1,
        entity_name: "Amoxicillin 500mg",
        available_quantity: 50,
        quantity: 20,
        uom: "boxes"
      })

    {:ok, _rejected} =
      disposal
      |> Medcamp.InventoryDisposals.InventoryDisposal.changeset(%{status: "rejected"})
      |> Medcamp.Repo.update()

    {:ok, _view, html} = live(conn, ~p"/admin/inventory_disposals/#{disposal.id}")

    assert html =~ "REJECTED"
    assert html =~ "No stock was issued"
  end

  test "shows a dash for comments when the item has no notes", %{conn: conn, disposal: disposal} do
    {:ok, _item} =
      InventoryDisposals.create_item(%{
        inventory_disposal_id: disposal.id,
        entity_type: "inventory_received",
        entity_id: 2,
        entity_name: "Paracetamol 500mg",
        available_quantity: 30,
        quantity: 10,
        uom: "boxes"
      })

    {:ok, view, _html} = live(conn, ~p"/admin/inventory_disposals/#{disposal.id}")

    assert has_element?(view, "#print-modal table td", "—")
  end

  test "includes a print button inside the modal", %{conn: conn, disposal: disposal} do
    {:ok, _item} =
      InventoryDisposals.create_item(%{
        inventory_disposal_id: disposal.id,
        entity_type: "inventory_received",
        entity_id: 1,
        entity_name: "Amoxicillin 500mg",
        available_quantity: 50,
        quantity: 20,
        uom: "boxes"
      })

    {:ok, _view, html} = live(conn, ~p"/admin/inventory_disposals/#{disposal.id}")

    assert html =~ ~s|onclick="window.print()"|
  end

  test "auto-fills the requester's designation and the request date", %{
    conn: conn,
    disposal: disposal
  } do
    {:ok, _item} =
      InventoryDisposals.create_item(%{
        inventory_disposal_id: disposal.id,
        entity_type: "inventory_received",
        entity_id: 1,
        entity_name: "Amoxicillin 500mg",
        available_quantity: 50,
        quantity: 20,
        uom: "boxes"
      })

    {:ok, view, html} = live(conn, ~p"/admin/inventory_disposals/#{disposal.id}")

    assert html =~ "01 Jul 2026"

    requested_by_row =
      view
      |> render()
      |> Floki.find("#print-modal table:not(#voucher-items) tr:first-child")
      |> Floki.text()

    assert requested_by_row =~ "Admin"
  end

  test "auto-fills the approver's designation and the approval date once approved", %{
    conn: conn,
    disposal: disposal
  } do
    {:ok, _item} =
      InventoryDisposals.create_item(%{
        inventory_disposal_id: disposal.id,
        entity_type: "inventory_received",
        entity_id: 1,
        entity_name: "Amoxicillin 500mg",
        available_quantity: 50,
        quantity: 20,
        uom: "boxes"
      })

    approver = user_fixture(%{role: "inventory_manager", name: "Ian Approver"})
    approved_at = DateTime.new!(~D[2026-07-05], ~T[10:00:00], "Etc/UTC")

    {:ok, _approved} =
      disposal
      |> Medcamp.InventoryDisposals.InventoryDisposal.changeset(%{
        status: "approved",
        approved_by_id: approver.id,
        approved_at: approved_at
      })
      |> Medcamp.Repo.update()

    {:ok, _view, html} = live(conn, ~p"/admin/inventory_disposals/#{disposal.id}")

    assert html =~ "Ian Approver"
    assert html =~ "Inventory manager"
    assert html =~ "05 Jul 2026"
  end

  test "leaves the Issued by designation and date blank while still pending", %{
    conn: conn,
    disposal: disposal
  } do
    {:ok, _item} =
      InventoryDisposals.create_item(%{
        inventory_disposal_id: disposal.id,
        entity_type: "inventory_received",
        entity_id: 1,
        entity_name: "Amoxicillin 500mg",
        available_quantity: 50,
        quantity: 20,
        uom: "boxes"
      })

    {:ok, view, _html} = live(conn, ~p"/admin/inventory_disposals/#{disposal.id}")

    issued_by_row =
      view
      |> render()
      |> Floki.find("#print-modal table:not(#voucher-items) tr:nth-child(2)")
      |> Floki.text()

    assert issued_by_row =~ "Issued by"
    refute issued_by_row =~ "Jane Requester"
  end
end
