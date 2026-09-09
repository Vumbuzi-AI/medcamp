defmodule MedcampWeb.SuperadminOrganisationsShowLiveTest do
  use MedcampWeb.ConnCase, async: true

  import Medcamp.AccountsFixtures
  import Phoenix.LiveViewTest

  alias Medcamp.Accounts
  alias Medcamp.Organisations
  alias Medcamp.Repo
  alias Medcamp.Tenancy

  defp superadmin_fixture do
    user_fixture(%{
      email: "superadmin-#{System.unique_integer([:positive])}@example.com",
      role: "admin"
    })
    |> Ecto.Changeset.change(%{is_superadmin: true})
    |> Repo.update!()
  end

  defp pending_org_fixture do
    {:ok, %{organisation: organisation, admin: admin}} =
      Organisations.register_organisation(
        %{
          "name" => "Pending Health #{System.unique_integer([:positive])}",
          "email" => "pending-#{System.unique_integer([:positive])}@example.com",
          "contact_name" => "Pat Ndegwa"
        },
        %{
          "email" => "admin-#{System.unique_integer([:positive])}@example.com",
          "password" => valid_user_password(),
          "password_confirmation" => valid_user_password()
        }
      )

    {organisation, admin}
  end

  defp postal_calls do
    Process.sleep(50)
    Medcamp.Postal.TestClient.calls()
  end

  defp add_admin(org_id, attrs) do
    {:ok, user} =
      Tenancy.with_org(org_id, fn ->
        Accounts.register_user(
          Map.merge(
            %{
              "email" => "adm-#{System.unique_integer([:positive])}@example.com",
              "password" => valid_user_password(),
              "role" => "admin"
            },
            attrs
          )
        )
      end)

    user
  end

  test "renders the detail page for an organisation", %{conn: conn, organisation: organisation} do
    conn = log_in_user(conn, superadmin_fixture())

    {:ok, _view, html} = live(conn, ~p"/superadmin/organisations/#{organisation.id}")

    assert html =~ organisation.name
    assert html =~ "Contact name"
    assert html =~ "Created"
    assert html =~ "Admin users"
    assert html =~ "Back to organisations"
  end

  test "superadmin edits an organisation", %{conn: conn, organisation: organisation} do
    conn = log_in_user(conn, superadmin_fixture())

    {:ok, view, _html} = live(conn, ~p"/superadmin/organisations/#{organisation.id}/edit")

    assert view
           |> form("#edit-org-modal form", org: %{name: "Renamed Org"})
           |> render_submit()

    assert_patch(view, ~p"/superadmin/organisations/#{organisation.id}")
    assert Organisations.get_organisation!(organisation.id).name == "Renamed Org"
  end

  test "superadmin rejects a pending signup with a reason", %{conn: conn} do
    {organisation, _admin} = pending_org_fixture()
    conn = log_in_user(conn, superadmin_fixture())

    {:ok, view, _html} = live(conn, ~p"/superadmin/organisations/#{organisation.id}/reject")

    view
    |> form("#reject-org-modal form", reject: %{reason: "Could not verify the organisation."})
    |> render_submit()

    assert_patch(view, ~p"/superadmin/organisations/#{organisation.id}")

    reloaded = Organisations.get_organisation!(organisation.id)
    assert reloaded.rejection_reason == "Could not verify the organisation."
    assert reloaded.rejected_at
    assert Organisations.status(reloaded) == :rejected
  end

  test "reject requires a reason", %{conn: conn} do
    {organisation, _admin} = pending_org_fixture()
    conn = log_in_user(conn, superadmin_fixture())

    {:ok, view, _html} = live(conn, ~p"/superadmin/organisations/#{organisation.id}/reject")

    html =
      view
      |> form("#reject-org-modal form", reject: %{reason: "   "})
      |> render_submit()

    assert html =~ "Give a reason"
    assert Organisations.get_organisation!(organisation.id).rejected_at == nil
  end

  test "superadmin approves a pending organisation from the detail page", %{conn: conn} do
    {organisation, admin} = pending_org_fixture()
    conn = log_in_user(conn, superadmin_fixture())

    {:ok, view, _html} = live(conn, ~p"/superadmin/organisations/#{organisation.id}")

    view |> element("button", "Approve") |> render_click()

    assert Organisations.get_organisation!(organisation.id).is_active

    assert [{_url, body, _headers}] = postal_calls()
    payload = Jason.decode!(body)
    assert payload["to"] == [admin.email]
    assert payload["subject"] =~ "#{organisation.name} is approved"
    assert payload["plain_body"] =~ "/users/reset_password/"
  end

  test "superadmin adds an admin from the detail page", %{conn: conn, organisation: organisation} do
    conn = log_in_user(conn, superadmin_fixture())

    {:ok, view, _html} = live(conn, ~p"/superadmin/organisations/#{organisation.id}/admin/new")

    email = "new-admin-#{System.unique_integer([:positive])}@example.com"

    view
    |> form("#add-admin-modal form",
      admin: %{name: "New Admin", email: email}
    )
    |> render_submit()

    assert_patch(view, ~p"/superadmin/organisations/#{organisation.id}")

    admin =
      Enum.find(
        Medcamp.Accounts.list_admins_for_organisation(organisation.id),
        &(&1.email == email)
      )

    assert admin
    refute Accounts.get_user_by_email_and_password(email, valid_user_password())

    assert [{_url, body, _headers}] = postal_calls()
    payload = Jason.decode!(body)
    assert payload["to"] == [email]
    assert payload["subject"] =~ "Set up your #{organisation.name} admin account"
    assert payload["plain_body"] =~ "/users/reset_password/"
  end

  test "the admins table filters by search term", %{conn: conn, organisation: organisation} do
    add_admin(organisation.id, %{"name" => "Grace Wanjiru"})
    add_admin(organisation.id, %{"name" => "Samuel Otieno"})
    conn = log_in_user(conn, superadmin_fixture())

    {:ok, view, html} = live(conn, ~p"/superadmin/organisations/#{organisation.id}")

    assert html =~ "Grace Wanjiru"
    assert html =~ "Samuel Otieno"

    filtered =
      view
      |> form("form[phx-change='search-admins']", %{"search" => "grace"})
      |> render_change()

    assert filtered =~ "Grace Wanjiru"
    refute filtered =~ "Samuel Otieno"
  end

  test "a superadmin cannot deactivate their own account from the admins table", %{
    conn: conn,
    organisation: organisation
  } do
    me = superadmin_fixture()
    conn = log_in_user(conn, me)

    {:ok, view, html} = live(conn, ~p"/superadmin/organisations/#{organisation.id}")

    assert html =~ "You"
    refute has_element?(view, "button[phx-click='toggle-admin-active'][phx-value-id='#{me.id}']")

    render_click(view, "toggle-admin-active", %{"id" => to_string(me.id)})

    assert render(view) =~ "can&#39;t deactivate your own account"
    assert Repo.reload!(me).is_active
  end

  test "the admins table paginates", %{conn: conn, organisation: organisation} do
    for i <- 1..12, do: add_admin(organisation.id, %{"name" => "Admin Number #{i}"})
    conn = log_in_user(conn, superadmin_fixture())

    {:ok, view, html} = live(conn, ~p"/superadmin/organisations/#{organisation.id}")

    assert html =~ "Showing 1–10 of"
    assert has_element?(view, "button[phx-value-page='2']:not([disabled])")

    page_two = view |> element("button[phx-value-page='2']") |> render_click()
    assert page_two =~ "Showing 11–"
  end
end
