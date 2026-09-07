defmodule MedcampWeb.LabStockRequestLiveTest do
  use MedcampWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Medcamp.AccountsFixtures

  alias Medcamp.StockTakes

  test "a lab user with no profile department gets the Lab department pre-filled by bucket inference",
       %{conn: conn} do
    {:ok, lab_department} =
      %Medcamp.Departments.Department{}
      |> Medcamp.Departments.Department.changeset(%{name: "Laboratory", code: "LAB"})
      |> Medcamp.Repo.insert()

    lab_tech = user_fixture(%{role: "labtechnician"})
    conn = log_in_user(conn, lab_tech)

    {:ok, view, _html} = live(conn, ~p"/lab/stock_requests")

    view |> element("button", "Stock Takes") |> render_click()
    view |> element("button", "New Stock take request") |> render_click()

    assert has_element?(
             view,
             ~s(option[value="#{lab_department.id}"][selected]),
             "Laboratory"
           )

    # Submitting without touching the (already pre-filled) dropdown still
    # succeeds and uses the bucket-inferred department.
    view
    |> form("form[phx-submit='create_stock_take']", %{
      "date" => "2026-08-01",
      "notes" => "Lab bucket-inferred department"
    })
    |> render_submit()

    assert [stock_take] = StockTakes.list_requester_stock_takes(lab_tech.id)
    assert stock_take.department_id == lab_department.id
  end
end
