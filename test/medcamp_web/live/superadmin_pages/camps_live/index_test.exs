defmodule MedcampWeb.SuperadminCampsLive.IndexTest do
  use MedcampWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Medcamp.AccountsFixtures
  import Medcamp.OrganisationsFixtures

  alias Medcamp.Camps
  alias Medcamp.Repo
  alias Medcamp.Tenancy

  defp superadmin_fixture do
    user_fixture(%{role: "admin"})
    |> Ecto.Changeset.change(%{is_superadmin: true})
    |> Repo.update!()
  end

  defp camp_in(org_name, camp_name) do
    org = organisation_fixture(%{"name" => org_name})
    {:ok, camp} = Tenancy.with_org(org.id, fn -> Camps.create_camp(%{name: camp_name}) end)
    {org, camp}
  end

  setup %{conn: conn} do
    %{conn: log_in_user(conn, superadmin_fixture())}
  end

  test "lists camps from every organisation with their org name", %{conn: conn} do
    camp_in("Alpha Org", "Alpha Camp One")
    camp_in("Beta Org", "Beta Camp Two")

    {:ok, view, html} = live(conn, ~p"/superadmin/camps")

    assert html =~ "Camps"
    assert html =~ "Alpha Camp One"
    assert html =~ "Alpha Org"
    assert html =~ "Beta Camp Two"
    assert html =~ "Beta Org"
    assert has_element?(view, "#superadmin-camps tr", "Alpha Camp One")
  end

  test "search narrows to a matching camp or organisation", %{conn: conn} do
    camp_in("Alpha Org", "Alpha Camp One")
    camp_in("Beta Org", "Beta Camp Two")

    {:ok, view, _html} = live(conn, ~p"/superadmin/camps")

    html =
      view
      |> form("form[phx-change='search']", %{"search" => "Beta"})
      |> render_change()

    assert html =~ "Beta Camp Two"
    refute html =~ "Alpha Camp One"
  end

  test "shows the platform camp KPI band and busiest-camps analytics", %{conn: conn} do
    camp_in("Alpha Org", "Alpha Camp One")
    camp_in("Beta Org", "Beta Camp Two")

    {:ok, _view, html} = live(conn, ~p"/superadmin/camps")

    assert html =~ "Total Camps"
    assert html =~ "Patients Across Camps"
    assert html =~ "Busiest camps"
    assert html =~ "New vs returning patients"
  end

  test "hides the analytics band while a search is active", %{conn: conn} do
    camp_in("Alpha Org", "Alpha Camp One")

    {:ok, view, _html} = live(conn, ~p"/superadmin/camps")

    html =
      view
      |> form("form[phx-change='search']", %{"search" => "Alpha"})
      |> render_change()

    refute html =~ "Busiest camps"
  end

  test "shows the blank state when no camps exist", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/superadmin/camps")
    assert html =~ "No camps"
    assert html =~ "No organisation has created a camp yet."
  end
end
