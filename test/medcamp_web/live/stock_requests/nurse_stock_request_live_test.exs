defmodule MedcampWeb.NurseStockRequestLiveTest do
  use MedcampWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Medcamp.AccountsFixtures

  test "nurse can create a stock take request and submit it for admin approval", %{
    conn: conn
  } do
    {:ok, department} =
      %Medcamp.Departments.Department{}
      |> Medcamp.Departments.Department.changeset(%{
        name: "Nursing",
        code: "NURSE_#{System.unique_integer()}"
      })
      |> Medcamp.Repo.insert()

    nurse = user_fixture(%{role: "nurse"})

    {:ok, nurse} =
      nurse |> Ecto.Changeset.change(department_id: department.id) |> Medcamp.Repo.update()

    conn = log_in_user(conn, nurse)

    {:ok, view, _html} = live(conn, ~p"/nurse/stock_requests")

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
      "notes" => "Nurse count"
    })
    |> render_submit()

    [stock_take] = Medcamp.StockTakes.list_requester_stock_takes(nurse.id)

    # Add a count entry
    {:ok, _entry} =
      Medcamp.StockTakes.create_entry(%{
        stock_take_id: stock_take.id,
        entity_type: "inventory_received",
        entity_id: 1,
        entity_name: "Syringes 5ml",
        previous_quantity: 100,
        counted_quantity: 95
      })

    html =
      view
      |> element(~s([phx-click="submit_stock_take"]))
      |> render_click()

    assert html =~ "Stock take submitted for admin approval."
    assert Medcamp.StockTakes.get_stock_take!(stock_take.id).status == "pending"
  end
end
