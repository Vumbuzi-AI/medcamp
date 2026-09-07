defmodule MedcampWeb.AdminInventoryDisposalLive.ShowTest do
  use MedcampWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Medcamp.AccountsFixtures

  alias Medcamp.InventoryDisposals

  setup %{conn: conn} do
    admin = user_fixture(%{role: "admin"})
    requester = user_fixture(%{role: "admin"})

    {:ok, disposal} =
      InventoryDisposals.create_disposal(%{
        kind: "donation",
        date: ~D[2026-07-01],
        requested_by_id: requester.id
      })

    %{conn: log_in_user(conn, admin), disposal: disposal}
  end

  test "does not show a print button or modal when the request has no items", %{
    conn: conn,
    disposal: disposal
  } do
    {:ok, view, _html} = live(conn, ~p"/admin/inventory_disposals/#{disposal.id}")

    refute has_element?(view, "#print-modal")
    refute has_element?(view, "button", "Print")
  end

  test "shows a print button and modal once the request has at least one item", %{
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

    assert has_element?(view, "button", "Print")
    assert has_element?(view, "#print-modal")
  end
end
