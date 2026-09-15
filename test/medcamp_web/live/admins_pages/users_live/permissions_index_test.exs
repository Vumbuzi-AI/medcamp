defmodule MedcampWeb.AdminUsersLive.PermissionsIndexTest do
  use MedcampWeb.ConnCase

  import Phoenix.LiveViewTest
  import Medcamp.AccountsFixtures

  alias Medcamp.Authorization

  setup %{conn: conn} do
    admin = user_fixture(%{role: "admin", name: "Admin User"})
    doctor = user_fixture(%{role: "doctor", name: "Dr. Test"})

    %{conn: log_in_user(conn, admin), admin: admin, doctor: doctor}
  end

  test "lists the panels of the user's own sidebar, grouped as they see them", %{
    conn: conn,
    doctor: doctor
  } do
    {:ok, _view, html} = live(conn, ~p"/admin/users/#{doctor}/permissions")

    assert html =~ "Panels - Dr. Test"
    # Group headings and tab names from the doctor sidebar.
    assert html =~ "Patient Management"
    assert html =~ "Clinical Work"
    assert html =~ "Lab Results"
    assert html =~ "role default"

    # Panels of other roles are not offered here - this page configures the
    # doctor sidebar, not every permission in the system.
    refute html =~ "Sentry Webhooks"
  end

  test "unchecking a role-default panel creates a deny override", %{
    conn: conn,
    doctor: doctor
  } do
    {:ok, view, _html} = live(conn, ~p"/admin/users/#{doctor}/permissions")

    html =
      view
      |> element("#permission-doctor\\.lab_results")
      |> render_click(%{"slug" => "doctor.lab_results", "granted" => "false"})

    assert html =~ "Overridden"
    refute Authorization.can?(doctor, "doctor.lab_results")

    [override] = Authorization.list_user_overrides(doctor)
    assert override.effect == "deny"
    assert override.granted_by_id
  end

  test "toggling a panel back to the role default removes the override", %{
    conn: conn,
    doctor: doctor
  } do
    {:ok, _} = Authorization.deny_user_override(doctor, "doctor.lab_results", nil)

    {:ok, view, _html} = live(conn, ~p"/admin/users/#{doctor}/permissions")

    view
    |> element("#permission-doctor\\.lab_results")
    |> render_click(%{"slug" => "doctor.lab_results", "granted" => "true"})

    assert Authorization.can?(doctor, "doctor.lab_results")
    assert Authorization.list_user_overrides(doctor) == []
  end

  test "the granted count reflects the overrides applied", %{conn: conn, doctor: doctor} do
    {:ok, _view, html} = live(conn, ~p"/admin/users/#{doctor}/permissions")
    assert html =~ ~r/\d+ of \d+ panels enabled/

    {:ok, _} = Authorization.deny_user_override(doctor, "doctor.lab_results", nil)

    {:ok, _view, after_html} = live(conn, ~p"/admin/users/#{doctor}/permissions")
    assert after_html =~ ~r/\d+ of \d+ panels enabled/
    refute html == after_html
  end
end
