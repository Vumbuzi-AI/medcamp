defmodule MedcampWeb.AdminStockTakeLive.IndexTest do
  use MedcampWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Medcamp.AccountsFixtures
  alias Medcamp.Repo
  alias Medcamp.Departments.Department
  alias Medcamp.StockTakes

  setup do
    admin = user_fixture(%{role: "admin", name: "Admin User"})

    {:ok, dept_pharmacy} =
      %Department{}
      |> Department.changeset(%{name: "Pharmacy", code: "PHARM_#{System.unique_integer()}"})
      |> Repo.insert()

    {:ok, dept_lab} =
      %Department{}
      |> Department.changeset(%{name: "Laboratory", code: "LAB_#{System.unique_integer()}"})
      |> Repo.insert()

    {:ok, dept_nursing} =
      %Department{}
      |> Department.changeset(%{name: "Nursing", code: "NURS_#{System.unique_integer()}"})
      |> Repo.insert()

    %{
      admin: admin,
      dept_pharmacy: dept_pharmacy,
      dept_lab: dept_lab,
      dept_nursing: dept_nursing
    }
  end

  test "renders stock take page and lists existing sessions with department names", %{
    conn: conn,
    admin: admin,
    dept_pharmacy: dept_pharmacy
  } do
    conn = log_in_user(conn, admin)

    {:ok, _stock_take} =
      StockTakes.create_stock_take(%{
        date: ~D[2026-07-31],
        admin_id: admin.id,
        department_id: dept_pharmacy.id,
        notes: "Monthly Pharmacy Audit"
      })

    {:ok, view, html} = live(conn, ~p"/admin/stock_takes")

    assert html =~ "Stock Takes"
    assert html =~ "Pharmacy"
    assert html =~ "Monthly Pharmacy Audit"
    assert has_element?(view, "td", "Pharmacy")
  end

  test "shows validation error when starting stock take without selecting a department", %{
    conn: conn,
    admin: admin
  } do
    conn = log_in_user(conn, admin)
    {:ok, view, _html} = live(conn, ~p"/admin/stock_takes")

    view |> element("button", "New Stock Take") |> render_click()

    assert has_element?(view, "h2", "Start New Stock Take Session")

    html =
      view
      |> form("form[phx-submit='create']", %{
        "stock_take" => %{
          "department_id" => "",
          "date" => "2026-07-31",
          "notes" => "Invalid count"
        }
      })
      |> render_submit()

    assert html =~ "can&#39;t be blank"
  end

  test "creates stock take successfully when department is selected", %{
    conn: conn,
    admin: admin,
    dept_lab: dept_lab
  } do
    conn = log_in_user(conn, admin)
    {:ok, view, _html} = live(conn, ~p"/admin/stock_takes")

    view |> element("button", "New Stock Take") |> render_click()

    result =
      view
      |> form("form[phx-submit='create']", %{
        "stock_take" => %{
          "department_id" => dept_lab.id,
          "date" => "2026-07-31",
          "notes" => "Lab Count"
        }
      })
      |> render_submit()

    assert {:error, {:live_redirect, %{to: to}}} = result
    assert to =~ ~r"/admin/stock_takes/"
  end

  test "filters stock takes by department via select and URL parameter", %{
    conn: conn,
    admin: admin,
    dept_pharmacy: dept_pharmacy,
    dept_lab: dept_lab
  } do
    conn = log_in_user(conn, admin)

    {:ok, _st1} =
      StockTakes.create_stock_take(%{
        date: ~D[2026-07-30],
        admin_id: admin.id,
        department_id: dept_pharmacy.id,
        notes: "Pharmacy Audit 1"
      })

    {:ok, _st2} =
      StockTakes.create_stock_take(%{
        date: ~D[2026-07-31],
        admin_id: admin.id,
        department_id: dept_lab.id,
        notes: "Laboratory Audit 1"
      })

    # Direct URL navigation with department_id filter parameter
    {:ok, _view, html} = live(conn, ~p"/admin/stock_takes?department_id=#{dept_pharmacy.id}")

    assert html =~ "Pharmacy Audit 1"
    refute html =~ "Laboratory Audit 1"

    # Selecting department in filter dropdown updates URL and results
    {:ok, view, _html} = live(conn, ~p"/admin/stock_takes")

    html =
      view
      |> form("form[phx-change='filter_department']", %{
        "department_id" => dept_lab.id
      })
      |> render_change()

    assert html =~ "Laboratory Audit 1"
    refute html =~ "Pharmacy Audit 1"
    assert_patched(view, ~p"/admin/stock_takes?department_id=#{dept_lab.id}")
  end

  test "shows empty state message when no stock takes match filtered department", %{
    conn: conn,
    admin: admin,
    dept_nursing: dept_nursing
  } do
    conn = log_in_user(conn, admin)

    {:ok, _view, html} = live(conn, ~p"/admin/stock_takes?department_id=#{dept_nursing.id}")

    assert html =~ "No stock takes found"
    assert html =~ "No stock take sessions match the selected department filter."
  end

  test "preserves department filter parameter across pagination", %{
    conn: conn,
    admin: admin,
    dept_pharmacy: dept_pharmacy
  } do
    conn = log_in_user(conn, admin)

    for i <- 1..12 do
      StockTakes.create_stock_take(%{
        date: ~D[2026-07-01],
        admin_id: admin.id,
        department_id: dept_pharmacy.id,
        notes: "Batch count #{i}"
      })
    end

    {:ok, view, html} = live(conn, ~p"/admin/stock_takes?department_id=#{dept_pharmacy.id}")

    assert html =~ "Showing 1–10 of 12"
    assert has_element?(view, "button", "Next")

    view |> element("button", "Next") |> render_click()

    assert_patched(view, ~p"/admin/stock_takes?department_id=#{dept_pharmacy.id}&page=2")
  end

  test "handles invalid department filter parameter gracefully", %{
    conn: conn,
    admin: admin,
    dept_pharmacy: dept_pharmacy
  } do
    conn = log_in_user(conn, admin)

    {:ok, _st} =
      StockTakes.create_stock_take(%{
        date: ~D[2026-07-31],
        admin_id: admin.id,
        department_id: dept_pharmacy.id,
        notes: "Valid Pharmacy Take"
      })

    {:ok, _view, html} = live(conn, ~p"/admin/stock_takes?department_id=non-existent-invalid-id")

    # Invalid department parameter falls back to all departments without error
    assert html =~ "Valid Pharmacy Take"
  end

  test "allows admin to delete an unapproved draft stock take session", %{
    conn: conn,
    admin: admin,
    dept_pharmacy: dept_pharmacy
  } do
    conn = log_in_user(conn, admin)

    {:ok, st} =
      StockTakes.create_stock_take(%{
        date: ~D[2026-07-31],
        admin_id: admin.id,
        department_id: dept_pharmacy.id,
        notes: "Draft session to delete"
      })

    {:ok, view, html} = live(conn, ~p"/admin/stock_takes")
    assert html =~ "Draft session to delete"

    view
    |> element(~s(button[phx-click="confirm_delete"][phx-value-id="#{st.id}"]))
    |> render_click()

    assert has_element?(view, "#delete-confirm-modal")
    assert has_element?(view, "h3", "Delete Stock Take Session")

    html =
      view
      |> element("button", "Delete Session")
      |> render_click()

    assert html =~ "Stock take deleted."
    refute html =~ "Draft session to delete"
  end
end
