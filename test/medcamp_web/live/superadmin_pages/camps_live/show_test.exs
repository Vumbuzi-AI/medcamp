defmodule MedcampWeb.SuperadminCampsLive.ShowTest do
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

  setup %{conn: conn} do
    %{conn: log_in_user(conn, superadmin_fixture())}
  end

  defp camp_in(org_name, camp_name) do
    org = organisation_fixture(%{"name" => org_name})
    {:ok, camp} = Tenancy.with_org(org.id, fn -> Camps.create_camp(%{name: camp_name}) end)
    {org, camp}
  end

  test "overview shows the camp, its organisation and a record breakdown", %{conn: conn} do
    {_org, camp} = camp_in("Alpha Org", "Alpha Camp")

    {:ok, _view, html} = live(conn, ~p"/superadmin/camps/#{camp.id}")

    assert html =~ "Alpha Camp"
    assert html =~ "Alpha Org"
    assert html =~ "Records logged"
    assert html =~ "Patient visits"
  end

  test "the staff tab lists the organisation's user accounts", %{conn: conn} do
    {org, camp} = camp_in("Beta Org", "Beta Camp")

    nurse =
      user_fixture(%{role: "nurse"})
      |> Ecto.Changeset.change(%{organisation_id: org.id, name: "Nurse Joy"})
      |> Repo.update!()

    {:ok, view, _html} = live(conn, ~p"/superadmin/camps/#{camp.id}")

    html = view |> element("button[phx-value-tab='staff']") |> render_click()

    assert html =~ "Nurse Joy"
    assert html =~ nurse.email
  end

  test "an unknown camp id redirects back to the camp list", %{conn: conn} do
    assert {:error, {:live_redirect, %{to: "/superadmin/camps"}}} =
             live(conn, ~p"/superadmin/camps/999999")
  end
end
