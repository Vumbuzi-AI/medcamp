defmodule MedcampWeb.AdminPatientVisitLive.IndexTest do
  use MedcampWeb.ConnCase

  import Phoenix.LiveViewTest
  import Medcamp.AccountsFixtures

  setup %{conn: conn} do
    admin = user_fixture(%{role: "admin", name: "Admin User"})
    %{conn: log_in_user(conn, admin)}
  end

  test "renders the list_page shell with the search toolbar and empty state", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/admin/patient_visits")

    assert html =~ "Patient Visits"
    assert html =~ "Search, filter and manage patient visit records."

    assert has_element?(
             view,
             "input[name='search'][placeholder='Search by patient name or GSRN']"
           )

    # No visits in a fresh org -> canonical blank_state, not a bare table.
    assert html =~ "No patient visits"
    assert html =~ "No patient visits have been recorded yet."
  end
end
