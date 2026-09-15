defmodule MedcampWeb.SuperadminCampsLive.IndexTest do
  use MedcampWeb.ConnCase, async: true

  import Ecto.Query
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

  describe "creating a camp from the platform console" do
    test "a superadmin creates a camp for a chosen organisation", %{conn: conn} do
      org = organisation_fixture(%{"name" => "Provisioned Org"})

      {:ok, view, _html} = live(conn, ~p"/superadmin/camps/new")

      html =
        view
        |> form("#superadmin-camp-modal form", %{
          "camp" => %{
            "organisation_id" => org.id,
            "name" => "Console Camp",
            "location" => "Kisumu"
          }
        })
        |> render_submit()

      assert html =~ "Console Camp created for Provisioned Org."
      assert html =~ "Console Camp"

      camp = Tenancy.with_org(org.id, fn -> Repo.get_by!(Camps.Camp, name: "Console Camp") end)
      assert camp.organisation_id == org.id
      # First camp for the org -> auto-activated, exactly like the org admin's flow.
      assert camp.is_active
    end

    test "submitting with no organisation shows an error and creates nothing", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/superadmin/camps/new")

      html =
        view
        |> form("#superadmin-camp-modal form", %{
          "camp" => %{"organisation_id" => "", "name" => "Orphan Camp"}
        })
        |> render_submit()

      assert html =~ "can&#39;t be blank"

      refute Repo.exists?(from(c in Camps.Camp, where: c.name == "Orphan Camp"),
               skip_org_id: true
             )
    end
  end

  describe "deleting a camp from the platform console" do
    defp record_against(org, camp) do
      Tenancy.with_org(org.id, fn ->
        {:ok, patient} =
          Medcamp.Patients.create_patient(%{
            "first_name" => "Rec",
            "last_name" => "Ord",
            "gender" => "Female",
            "date_of_birth" => "1990-01-01",
            "phone_number" => "0712000000",
            "home_address" => "Nairobi",
            "creator_id" => user_fixture(%{role: "receptionist"}).id
          })

        %Medcamp.Triages.Triage{}
        |> Ecto.Changeset.change(%{
          organisation_id: org.id,
          camp_id: camp.id,
          patient_id: patient.id,
          date: ~D[2026-01-01],
          temperature: 36.5,
          blood_pressure: "120/80",
          pulse_rate: 70.0,
          oxygen_saturation: 98.0,
          height: 170.0,
          weight: 65.0
        })
        |> Repo.insert!()
      end)
    end

    test "an empty camp can be deleted", %{conn: conn} do
      {org, camp} = camp_in("Cleanup Org", "Typo Camp")

      {:ok, view, _html} = live(conn, ~p"/superadmin/camps")
      assert has_element?(view, "#camp-#{camp.id}")

      html =
        view
        |> element("a[phx-click='delete'][phx-value-id='#{camp.id}']")
        |> render_click()

      assert html =~ "Typo Camp deleted."
      refute has_element?(view, "#camp-#{camp.id}")
      refute Tenancy.with_org(org.id, fn -> Repo.get(Camps.Camp, camp.id) end)
    end

    test "a camp with records has no Delete action and is refused server-side", %{conn: conn} do
      {org, camp} = camp_in("Busy Org", "Busy Camp")
      record_against(org, camp)

      {:ok, view, _html} = live(conn, ~p"/superadmin/camps")

      refute has_element?(view, "a[phx-click='delete'][phx-value-id='#{camp.id}']")

      # Server-side backstop: even a crafted event is refused.
      html = render_click(view, "delete", %{"id" => camp.id})
      assert html =~ "has records and can&#39;t be deleted."
      assert Tenancy.with_org(org.id, fn -> Repo.get(Camps.Camp, camp.id) end)
    end
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

  test "shows the blank state when no camps exist", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/superadmin/camps")
    assert html =~ "No camps"
    assert html =~ "No organisation has created a camp yet."
  end

  describe "authorization (Phase 7 gap 2)" do
    test "a plain admin (non-superadmin) is redirected away from the camps console" do
      admin = user_fixture(%{role: "admin"})
      conn = log_in_user(Phoenix.ConnTest.build_conn(), admin)

      assert {:error, {:redirect, %{to: "/admin/dashboard"}}} =
               live(conn, ~p"/superadmin/camps")
    end

    test "a signed-in non-admin staff user is redirected away from the camps console" do
      nurse = user_fixture(%{role: "nurse"})
      conn = log_in_user(Phoenix.ConnTest.build_conn(), nurse)

      assert {:error, {:redirect, %{to: "/nurse/scan"}}} =
               live(conn, ~p"/superadmin/camps")
    end

    test "an unauthenticated visitor is redirected to log in" do
      assert {:error, {:redirect, %{to: "/users/log_in"}}} =
               live(Phoenix.ConnTest.build_conn(), ~p"/superadmin/camps")
    end
  end
end
