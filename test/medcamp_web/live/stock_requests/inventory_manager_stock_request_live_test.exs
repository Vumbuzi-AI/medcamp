defmodule MedcampWeb.InventoryManagerStockRequestLiveTest do
  use MedcampWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Medcamp.AccountsFixtures

  alias Medcamp.InventoryDisposals
  alias Medcamp.StockTakes

  test "inventory manager can access stock requests hub and view donation requests", %{conn: conn} do
    inventory_mgr = user_fixture(%{role: "inventory_manager"})
    conn = log_in_user(conn, inventory_mgr)

    {:ok, view, html} = live(conn, ~p"/inventory_manager/stock_requests")

    assert html =~ "Stock Change Requests"
    assert has_element?(view, "button", "Donations")
    assert has_element?(view, "button", "Expiry")
    assert has_element?(view, "button", "Stock Takes")
  end

  test "inventory manager can create a stock take request and submit it for admin approval", %{
    conn: conn
  } do
    {:ok, department} =
      %Medcamp.Departments.Department{}
      |> Medcamp.Departments.Department.changeset(%{
        name: "Inventory",
        code: "INV_#{System.unique_integer()}"
      })
      |> Medcamp.Repo.insert()

    inventory_mgr = user_fixture(%{role: "inventory_manager"})

    {:ok, inventory_mgr} =
      inventory_mgr |> Ecto.Changeset.change(department_id: department.id) |> Medcamp.Repo.update()

    conn = log_in_user(conn, inventory_mgr)

    {:ok, view, _html} = live(conn, ~p"/inventory_manager/stock_requests")

    # Switch tab to Stock Takes
    view
    |> element("button", "Stock Takes")
    |> render_click()

    # Create new stock take
    view
    |> element("button", "New Stock take request")
    |> render_click()

    view
    |> form("form[phx-submit='create_stock_take']", %{
      "date" => "2026-07-31",
      "notes" => "Inventory count request"
    })
    |> render_submit()

    [stock_take] = StockTakes.list_requester_stock_takes(inventory_mgr.id)

    # Submit without counts should show error
    html =
      view
      |> element(~s([phx-click="submit_stock_take"]))
      |> render_click()

    assert html =~ "Record at least one counted quantity before submitting."

    # Add a count entry
    {:ok, _entry} =
      StockTakes.create_entry(%{
        stock_take_id: stock_take.id,
        entity_type: "inventory_received",
        entity_id: 1,
        entity_name: "Amoxicillin 500mg Batch A",
        previous_quantity: 100,
        counted_quantity: 95
      })

    html =
      view
      |> element(~s([phx-click="submit_stock_take"]))
      |> render_click()

    assert html =~ "Stock take submitted for admin approval."
    assert StockTakes.get_stock_take!(stock_take.id).status == "pending"
  end

  test "inventory manager with no profile department must pick one from the form", %{
    conn: conn
  } do
    {:ok, department} =
      %Medcamp.Departments.Department{}
      |> Medcamp.Departments.Department.changeset(%{
        name: "Pharmacy Store",
        code: "PHSTORE_#{System.unique_integer()}"
      })
      |> Medcamp.Repo.insert()

    inventory_mgr = user_fixture(%{role: "inventory_manager"})
    conn = log_in_user(conn, inventory_mgr)

    {:ok, view, _html} = live(conn, ~p"/inventory_manager/stock_requests")

    view |> element("button", "Stock Takes") |> render_click()
    view |> element("button", "New Stock take request") |> render_click()

    # Submitting without picking a department fails with a clear validation error.
    html =
      view
      |> form("form[phx-submit='create_stock_take']", %{
        "date" => "2026-07-31",
        "notes" => "No department picked"
      })
      |> render_submit()

    assert html =~ "Department"
    assert StockTakes.list_requester_stock_takes(inventory_mgr.id) == []

    # Picking a department in the form succeeds even though the profile has none.
    view
    |> form("form[phx-submit='create_stock_take']", %{
      "department_id" => to_string(department.id),
      "date" => "2026-07-31",
      "notes" => "Picked department manually"
    })
    |> render_submit()

    assert [stock_take] = StockTakes.list_requester_stock_takes(inventory_mgr.id)
    assert stock_take.department_id == department.id
  end

  test "clearing the pre-filled department back to blank blocks submission instead of silently reusing the profile department",
       %{conn: conn} do
    {:ok, department} =
      %Medcamp.Departments.Department{}
      |> Medcamp.Departments.Department.changeset(%{
        name: "Central Stores",
        code: "CENTRAL_#{System.unique_integer()}"
      })
      |> Medcamp.Repo.insert()

    inventory_mgr = user_fixture(%{role: "inventory_manager"})

    {:ok, inventory_mgr} =
      inventory_mgr |> Ecto.Changeset.change(department_id: department.id) |> Medcamp.Repo.update()

    conn = log_in_user(conn, inventory_mgr)

    {:ok, view, _html} = live(conn, ~p"/inventory_manager/stock_requests")

    view |> element("button", "Stock Takes") |> render_click()
    view |> element("button", "New Stock take request") |> render_click()

    # The dropdown is pre-filled from the profile, but the user explicitly
    # clears it back to blank before submitting.
    html =
      view
      |> form("form[phx-submit='create_stock_take']", %{
        "department_id" => "",
        "date" => "2026-07-31",
        "notes" => "Explicitly cleared department"
      })
      |> render_submit()

    assert html =~ "Department"
    assert StockTakes.list_requester_stock_takes(inventory_mgr.id) == []
  end

  test "inventory manager can create donation requests and attach a PDF document", %{
    conn: conn
  } do
    inventory_mgr = user_fixture(%{role: "inventory_manager"})
    conn = log_in_user(conn, inventory_mgr)

    {:ok, disposal} =
      InventoryDisposals.create_disposal(%{
        kind: "donation",
        date: ~D[2026-07-01],
        requested_by_id: inventory_mgr.id
      })

    {:ok, view, _html} = live(conn, ~p"/inventory_manager/stock_requests")

    view
    |> element(~s([phx-click="open_disposal"][phx-value-id="#{disposal.id}"]))
    |> render_click()

    assert has_element?(view, "p", "No document attached.")

    document =
      file_input(view, "#supporting-document-form", :supporting_document, [
        %{
          name: "donation_request.pdf",
          content: "dummy pdf binary content",
          type: "application/pdf"
        }
      ])

    html = render_upload(document, "donation_request.pdf")

    assert html =~ "Supporting document attached."
    assert has_element?(view, "a", "donation_request.pdf")

    assert InventoryDisposals.get_disposal!(disposal.id).supporting_document_path
  end

  test "inventory manager can switch to Expiry Write-Offs tab and view/create expiry requests", %{
    conn: conn
  } do
    inventory_mgr = user_fixture(%{role: "inventory_manager"})
    conn = log_in_user(conn, inventory_mgr)

    {:ok, view, _html} = live(conn, ~p"/inventory_manager/stock_requests")

    # Switch tab to Expiry
    html =
      view
      |> element("button", "Expiry")
      |> render_click()

    assert html =~ "New Expiry request"

    view
    |> element("button", "New Expiry request")
    |> render_click()

    view
    |> form("form[phx-submit='create_disposal']", %{
      "date" => "2026-07-31",
      "reason" => "Expired goods disposal"
    })
    |> render_submit()

    [disposal] = InventoryDisposals.list_requester_disposals(inventory_mgr.id)
    assert disposal.kind == "expiry"
    assert disposal.reason == "Expired goods disposal"
  end
end
