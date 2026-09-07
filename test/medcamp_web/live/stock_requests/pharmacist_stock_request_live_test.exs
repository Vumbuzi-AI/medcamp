defmodule MedcampWeb.PharmacistStockRequestLiveTest do
  use MedcampWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Medcamp.AccountsFixtures

  alias Medcamp.InventoryDisposals

  test "does not render a print modal until the donation request has items", %{conn: conn} do
    pharmacist = user_fixture(%{role: "pharmacist"})
    conn = log_in_user(conn, pharmacist)

    {:ok, disposal} =
      InventoryDisposals.create_disposal(%{
        kind: "donation",
        date: ~D[2026-07-01],
        requested_by_id: pharmacist.id
      })

    {:ok, view, _html} = live(conn, ~p"/pharmacist/stock_requests")

    view
    |> element(~s([phx-click="open_disposal"][phx-value-id="#{disposal.id}"]))
    |> render_click()

    refute has_element?(view, "#print-modal")

    {:ok, _item} =
      InventoryDisposals.create_item(%{
        inventory_disposal_id: disposal.id,
        entity_type: "drug_batch",
        entity_id: 1,
        entity_name: "Amoxicillin 500mg",
        available_quantity: 50,
        quantity: 20,
        uom: "boxes"
      })

    view |> element(~s([phx-click="back_to_list"])) |> render_click()

    html =
      view
      |> element(~s([phx-click="open_disposal"][phx-value-id="#{disposal.id}"]))
      |> render_click()

    assert html =~ "COUNTER REQUISITION AND ISSUE VOUCHER"
    assert has_element?(view, "#print-modal table td", "Amoxicillin 500mg")
  end

  test "selecting a PDF attaches it automatically, and it can be removed again", %{conn: conn} do
    pharmacist = user_fixture(%{role: "pharmacist"})
    conn = log_in_user(conn, pharmacist)

    {:ok, disposal} =
      InventoryDisposals.create_disposal(%{
        kind: "donation",
        date: ~D[2026-07-01],
        requested_by_id: pharmacist.id
      })

    {:ok, view, _html} = live(conn, ~p"/pharmacist/stock_requests")

    view
    |> element(~s([phx-click="open_disposal"][phx-value-id="#{disposal.id}"]))
    |> render_click()

    assert has_element?(view, "p", "No document attached.")
    refute has_element?(view, ~s([phx-click="remove_supporting_document"]))

    document =
      file_input(view, "#supporting-document-form", :supporting_document, [
        %{
          name: "request.pdf",
          content: "not a real pdf, just test bytes",
          type: "application/pdf"
        }
      ])

    html = render_upload(document, "request.pdf")

    assert html =~ "Supporting document attached."
    assert has_element?(view, "a", "request.pdf")
    assert has_element?(view, ~s([phx-click="remove_supporting_document"]))

    assert InventoryDisposals.get_disposal!(disposal.id).supporting_document_path

    html =
      view
      |> element(~s([phx-click="remove_supporting_document"]))
      |> render_click()

    assert html =~ "Document removed."
    assert has_element?(view, "p", "No document attached.")
    refute InventoryDisposals.get_disposal!(disposal.id).supporting_document_path
  end

  test "pharmacist can create a stock take request and submit it for admin approval", %{
    conn: conn
  } do
    {:ok, department} =
      %Medcamp.Departments.Department{}
      |> Medcamp.Departments.Department.changeset(%{
        name: "Pharmacy",
        code: "PHARM_#{System.unique_integer()}"
      })
      |> Medcamp.Repo.insert()

    pharmacist = user_fixture(%{role: "pharmacist"})

    {:ok, pharmacist} =
      pharmacist |> Ecto.Changeset.change(department_id: department.id) |> Medcamp.Repo.update()

    conn = log_in_user(conn, pharmacist)

    {:ok, view, _html} = live(conn, ~p"/pharmacist/stock_requests")

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
      "notes" => "Pharmacist count"
    })
    |> render_submit()

    [stock_take] = Medcamp.StockTakes.list_requester_stock_takes(pharmacist.id)

    # Submit without counts should show error
    html =
      view
      |> element(~s([phx-click="submit_stock_take"]))
      |> render_click()

    assert html =~ "Record at least one counted quantity before submitting."

    # Add a count entry
    {:ok, _entry} =
      Medcamp.StockTakes.create_entry(%{
        stock_take_id: stock_take.id,
        entity_type: "drug_batch",
        entity_id: 1,
        entity_name: "Amoxicillin 500mg",
        previous_quantity: 50,
        counted_quantity: 48
      })

    html =
      view
      |> element(~s([phx-click="submit_stock_take"]))
      |> render_click()

    assert html =~ "Stock take submitted for admin approval."
    assert Medcamp.StockTakes.get_stock_take!(stock_take.id).status == "pending"
  end
end
