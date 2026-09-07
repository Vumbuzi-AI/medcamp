defmodule MedcampWeb.AdminStockTakeLive.ShowTest do
  use MedcampWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Medcamp.AccountsFixtures

  alias Medcamp.Batches.Batch
  alias Medcamp.Departments.Department
  alias Medcamp.DrugBatches.DrugBatch
  alias Medcamp.Drugs.Drug
  alias Medcamp.InventoriesReceived.InventoryReceived
  alias Medcamp.Repo
  alias Medcamp.StockTakes

  setup do
    admin = user_fixture(%{role: "admin", name: "Admin User"})
    pharmacist = user_fixture(%{role: "pharmacist", name: "Peter Pharmacist"})

    {:ok, department} =
      %Department{}
      |> Department.changeset(%{name: "Pharmacy", code: "PHARM_#{System.unique_integer()}"})
      |> Repo.insert()

    inventory =
      Repo.insert!(%InventoryReceived{
        gtin: "GTIN-#{System.unique_integer([:positive])}",
        brand_name: "Amoxicillin 500mg",
        category: "Pharmaceuticals"
      })

    batch =
      Repo.insert!(%Batch{
        gtin: inventory.gtin,
        batch: "BATCH-SHOW-1",
        quantity: 100,
        remaining_quantity: 100,
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
        remaining_quantity: 100,
        is_confirmed: true
      })

    {:ok, stock_take} =
      StockTakes.create_stock_take(%{
        date: ~D[2026-07-31],
        admin_id: admin.id,
        department_id: department.id,
        notes: "Show Test Count"
      })

    %{
      admin: admin,
      pharmacist: pharmacist,
      department: department,
      stock_take: stock_take,
      drug_batch: drug_batch
    }
  end

  test "displays the associated department name in stock take detail view", %{
    conn: conn,
    admin: admin,
    stock_take: stock_take,
    department: department
  } do
    conn = log_in_user(conn, admin)

    {:ok, _view, html} = live(conn, ~p"/admin/stock_takes/#{stock_take.id}")

    assert html =~ "Stock Take — July 31, 2026"
    assert html =~ "Department:"
    assert html =~ department.name
    assert html =~ "Show Test Count"
  end

  test "allows admin to delete an unapproved draft stock take from detail view", %{
    conn: conn,
    admin: admin,
    stock_take: stock_take
  } do
    conn = log_in_user(conn, admin)

    {:ok, view, _html} = live(conn, ~p"/admin/stock_takes/#{stock_take.id}")

    result =
      view
      |> element("button", "Delete Stock Take")
      |> render_click()

    assert {:error, {:live_redirect, %{to: "/admin/stock_takes"}}} = result
    assert_raise Ecto.NoResultsError, fn -> StockTakes.get_stock_take!(stock_take.id) end
  end

  test "admin can approve a pending stock take, updating status and inventory", %{
    conn: conn,
    admin: admin,
    pharmacist: pharmacist,
    department: department,
    drug_batch: drug_batch
  } do
    {:ok, req_st} =
      StockTakes.create_stock_take(%{
        date: ~D[2026-07-31],
        requested_by_id: pharmacist.id,
        department_id: department.id
      })

    {:ok, _entry} =
      StockTakes.create_entry(%{
        stock_take_id: req_st.id,
        entity_type: "drug_batch",
        entity_id: drug_batch.id,
        entity_name: "Amoxicillin 500mg",
        previous_quantity: 100,
        counted_quantity: 85
      })

    {:ok, pending_st} = StockTakes.submit_stock_take(req_st)

    conn = log_in_user(conn, admin)
    {:ok, view, html} = live(conn, ~p"/admin/stock_takes/#{pending_st.id}")

    assert html =~ "Pending approval"
    assert html =~ "Approve &amp; apply"

    html =
      view
      |> element("button", "Approve & apply")
      |> render_click()

    assert html =~ "Stock take approved."
    assert Repo.get!(DrugBatch, drug_batch.id).remaining_quantity == 85
    assert StockTakes.get_stock_take!(pending_st.id).status == "completed"
  end

  test "admin can reject a pending stock take, changing status without modifying inventory", %{
    conn: conn,
    admin: admin,
    pharmacist: pharmacist,
    department: department,
    drug_batch: drug_batch
  } do
    {:ok, req_st} =
      StockTakes.create_stock_take(%{
        date: ~D[2026-07-31],
        requested_by_id: pharmacist.id,
        department_id: department.id
      })

    {:ok, _entry} =
      StockTakes.create_entry(%{
        stock_take_id: req_st.id,
        entity_type: "drug_batch",
        entity_id: drug_batch.id,
        entity_name: "Amoxicillin 500mg",
        previous_quantity: 100,
        counted_quantity: 10
      })

    {:ok, pending_st} = StockTakes.submit_stock_take(req_st)

    conn = log_in_user(conn, admin)
    {:ok, view, html} = live(conn, ~p"/admin/stock_takes/#{pending_st.id}")

    assert html =~ "Pending approval"
    assert html =~ "Reject"

    html =
      view
      |> element("button", "Reject")
      |> render_click()

    assert html =~ "Stock take rejected."
    assert Repo.get!(DrugBatch, drug_batch.id).remaining_quantity == 100
    assert StockTakes.get_stock_take!(pending_st.id).status == "rejected"
  end

  test "admin can search, add item, update counted quantity, delete entry, and apply direct stock take",
       %{
         conn: conn,
         admin: admin,
         stock_take: stock_take,
         drug_batch: drug_batch
       } do
    conn = log_in_user(conn, admin)
    {:ok, view, _html} = live(conn, ~p"/admin/stock_takes/#{stock_take.id}")

    # Reveal the search panel (hidden by default)
    view |> element("button", "Add Items to Count") |> render_click()

    # Search entity (defaults to the drug_batch tab)
    view
    |> form("form[phx-change='search']", %{"q" => "Amoxicillin"})
    |> render_change()

    assert has_element?(view, "button", "Add")

    # Add drug batch item to stock take
    view
    |> element(~s(button[phx-click="add_drug_batch"]))
    |> render_click()

    assert has_element?(view, "td", "Amoxicillin 500mg")

    [entry] = StockTakes.get_stock_take!(stock_take.id).entries

    # Enter edit mode, then update counted quantity
    view
    |> element(~s(button[phx-click="edit_entry"][phx-value-id="#{entry.id}"]))
    |> render_click()

    view
    |> form(~s(form[id="save_count_#{entry.id}"]), %{"counted_quantity" => "80"})
    |> render_submit()

    assert Repo.get!(StockTakes.StockTakeEntry, entry.id).counted_quantity == 80

    # Delete entry
    view
    |> element(~s(button[phx-click="delete_entry"][phx-value-id="#{entry.id}"]))
    |> render_click()

    refute has_element?(view, "td", "Amoxicillin 500mg")

    # Re-add item and apply stock take (search panel is still open from earlier)
    view
    |> form("form[phx-change='search']", %{"q" => "Amoxicillin"})
    |> render_change()

    view
    |> element(~s(button[phx-click="add_drug_batch"]))
    |> render_click()

    [entry2] = StockTakes.get_stock_take!(stock_take.id).entries

    view
    |> element(~s(button[phx-click="edit_entry"][phx-value-id="#{entry2.id}"]))
    |> render_click()

    view
    |> form(~s(form[id="save_count_#{entry2.id}"]), %{"counted_quantity" => "75"})
    |> render_submit()

    # Open apply confirmation modal
    view
    |> element(~s(button[phx-click="confirm_apply"]))
    |> render_click()

    assert has_element?(view, "h3", "Apply Stock Take?")

    # Cancel modal
    view
    |> element("button", "Cancel")
    |> render_click()

    refute has_element?(view, "h3", "Apply Stock Take?")

    # Re-open apply modal and apply
    view
    |> element("button", "Apply Stock Take")
    |> render_click()

    html =
      view
      |> element("button", "Yes, Apply Stock Take")
      |> render_click()

    assert html =~ "Stock take applied successfully."
    assert Repo.get!(DrugBatch, drug_batch.id).remaining_quantity == 75
    assert StockTakes.get_stock_take!(stock_take.id).status == "completed"
  end
end
