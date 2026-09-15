defmodule MedcampWeb.SidebarComponentsTest do
  use MedcampWeb.ConnCase, async: true

  import Medcamp.AccountsFixtures
  import Phoenix.LiveViewTest

  test "admin sidebar renders single-item groups as direct links", %{conn: conn} do
    user = user_fixture(%{role: "admin"})
    conn = log_in_user(conn, user)

    {:ok, _view, html} = live(conn, ~p"/admin/dashboard")

    assert html =~ ~s(href="/admin/medical_camp")
    assert html =~ "Camp Overview"
    refute html =~ "sidebar-group-camp-items"
  end

  test "clinical sidebar keeps dashboard first, then fast access links", %{conn: conn} do
    user = user_fixture(%{role: "nurse"})
    conn = log_in_user(conn, user)

    {:ok, _view, html} = live(conn, ~p"/nurse/scan")

    assert_before(html, ~s(href="/nurse/dashboard"), ~s(href="/nurse/scan"))
    assert_before(html, ~s(href="/nurse/scan"), ~s(href="/nurse/triages"))
    assert_before(html, ~s(href="/nurse/triages"), "Patient Management")
    refute html =~ "sidebar-group-quick-scan-items"
    refute html =~ "sidebar-group-quick-work-items"
  end

  defp assert_before(html, first, second) do
    first_index = :binary.match(html, first) |> elem(0)
    second_index = :binary.match(html, second) |> elem(0)

    assert first_index < second_index
  end
end
