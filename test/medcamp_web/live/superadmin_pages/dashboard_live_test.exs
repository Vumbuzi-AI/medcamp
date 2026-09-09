defmodule MedcampWeb.SuperadminDashboardLiveTest do
  use MedcampWeb.ConnCase, async: true

  import Medcamp.AccountsFixtures
  import Medcamp.OrganisationsFixtures
  import Phoenix.LiveViewTest

  alias Medcamp.Accounts
  alias Medcamp.Organisations
  alias Medcamp.Repo

  defp postal_calls do
    Process.sleep(50)
    Medcamp.Postal.TestClient.calls()
  end

  defp superadmin_fixture do
    user =
      user_fixture(%{
        email: "superadmin-#{System.unique_integer([:positive])}@example.com",
        role: "admin"
      })

    user
    |> Ecto.Changeset.change(%{is_superadmin: true})
    |> Repo.update!()
  end

  test "superadmin sees dashboard and organisations in the platform sidebar", %{
    conn: conn,
    organisation: organisation
  } do
    conn = log_in_user(conn, superadmin_fixture())

    {:ok, _view, html} = live(conn, ~p"/superadmin/dashboard")

    assert html =~ "Platform"
    assert html =~ "Dashboard"
    assert html =~ "Organisations"
    assert html =~ "Total Organisations"
    assert html =~ "Active Organisations"
    assert html =~ "Pending Approvals"
    assert html =~ "Tenant workspaces"
    assert html =~ organisation.name
  end

  test "superadmin can open the organisations management page", %{conn: conn} do
    conn = log_in_user(conn, superadmin_fixture())

    {:ok, view, html} = live(conn, ~p"/superadmin/organisations")

    assert html =~ "Add organisation"
    assert html =~ "Actions"
    refute html =~ "Set the organisation identity and default brand colours."

    assert view
           |> element("a", "Add organisation")
           |> render_click() =~ "Set the organisation identity and default brand colours."

    assert_patch(view, ~p"/superadmin/organisations/new")

    refute view
           |> element("button", "Cancel")
           |> render_click() =~ "Set the organisation identity and default brand colours."

    assert_patch(view, ~p"/superadmin/organisations")
  end

  test "superadmin searches organisations by name or slug", %{
    conn: conn,
    organisation: organisation
  } do
    other = organisation_fixture(%{"name" => "Remote Health Camp", "slug" => "remote-health"})
    conn = log_in_user(conn, superadmin_fixture())

    {:ok, view, html} = live(conn, ~p"/superadmin/organisations")

    assert html =~ organisation.name
    assert html =~ other.name

    filtered =
      view
      |> form("form[phx-change='search']", %{"search" => "remote"})
      |> render_change()

    assert filtered =~ other.name
    refute filtered =~ organisation.name
  end

  test "superadmin creates an approved organisation and is sent to add its first admin", %{
    conn: conn
  } do
    conn = log_in_user(conn, superadmin_fixture())

    {:ok, view, _html} = live(conn, ~p"/superadmin/organisations/new")

    view
    |> form("#organisation-modal form",
      org: %{
        name: "Mobile Care",
        slug: "mobile-care",
        email: "ops@mobile-care.example",
        location: "Nakuru",
        primary_color: "#373896",
        accent_color: "#6667ab"
      }
    )
    |> render_submit()

    organisation = Organisations.get_organisation_by_slug("mobile-care")

    assert organisation
    assert organisation.is_active
    assert organisation.approved_at
    assert_redirect(view, ~p"/superadmin/organisations/#{organisation.id}/admin/new")
  end

  test "create organisation modal shows validation errors without creating a row", %{conn: conn} do
    conn = log_in_user(conn, superadmin_fixture())

    before_count = Organisations.organisation_stats().total
    {:ok, view, _html} = live(conn, ~p"/superadmin/organisations/new")

    html =
      view
      |> form("#organisation-modal form",
        org: %{
          name: "",
          slug: "Bad Slug",
          email: "not-email",
          primary_color: "purple",
          accent_color: "#12"
        }
      )
      |> render_submit()

    assert html =~ "can&#39;t be blank"
    assert html =~ "must be lowercase letters, numbers and hyphens"
    assert html =~ "must be a valid email address"
    assert html =~ "must be a hex colour like #1D3557"
    assert Organisations.organisation_stats().total == before_count
  end

  test "organisation list distinguishes rejected signups from pending signups", %{conn: conn} do
    {:ok, %{organisation: pending}} =
      Organisations.register_organisation(
        %{
          "name" => "Pending Camp",
          "email" => "pending-camp@example.com",
          "contact_name" => "Pending Admin"
        },
        %{"email" => "pending-admin@example.com", "password" => valid_user_password()}
      )

    {:ok, rejected} = Organisations.reject_organisation(pending, "Could not verify")
    conn = log_in_user(conn, superadmin_fixture())

    {:ok, _view, html} = live(conn, ~p"/superadmin/organisations")

    assert html =~ rejected.name
    assert html =~ "Rejected"
  end

  test "a rejected signup is not counted as pending on the platform dashboard", %{conn: conn} do
    {:ok, %{organisation: pending}} =
      Organisations.register_organisation(
        %{
          "name" => "To Be Rejected",
          "email" => "tbr@example.com",
          "contact_name" => "Owner"
        },
        %{"email" => "tbr-admin@example.com", "password" => valid_user_password()}
      )

    {:ok, _} = Organisations.reject_organisation(pending, "Could not verify")

    stats = Organisations.organisation_stats()
    assert stats.pending == 0
    assert stats.rejected == 1

    conn = log_in_user(conn, superadmin_fixture())
    {:ok, _view, html} = live(conn, ~p"/superadmin/dashboard")

    refute html =~ "awaiting approval"
    # the activity row shows the real status, not "Pending"
    assert html =~ "Rejected"
  end

  test "duplicate organisation slug stays in the modal with a field error", %{
    conn: conn,
    organisation: organisation
  } do
    conn = log_in_user(conn, superadmin_fixture())

    {:ok, view, _html} = live(conn, ~p"/superadmin/organisations/new")

    html =
      view
      |> form("#organisation-modal form",
        org: %{
          name: "Duplicate Slug",
          slug: organisation.slug,
          primary_color: "#373896",
          accent_color: "#6667ab"
        }
      )
      |> render_submit()

    assert html =~ "has already been taken"
    assert has_element?(view, "#organisation-modal")
  end

  test "superadmin opens the organisation detail page and adds an admin there", %{
    conn: conn,
    organisation: organisation
  } do
    conn = log_in_user(conn, superadmin_fixture())

    {:ok, index, _html} = live(conn, ~p"/superadmin/organisations")

    {:ok, show, html} =
      index
      |> element("a[href='/superadmin/organisations/#{organisation.id}']", "Manage")
      |> render_click()
      |> follow_redirect(conn, ~p"/superadmin/organisations/#{organisation.id}")

    assert html =~ "Admin users"
    refute html =~ "This account can sign in and manage users inside the organisation."

    assert show
           |> element("a[href='/superadmin/organisations/#{organisation.id}/admin/new']")
           |> render_click() =~ "Add an admin to #{organisation.name}"

    assert_patch(show, ~p"/superadmin/organisations/#{organisation.id}/admin/new")

    refute show
           |> element("button", "Cancel")
           |> render_click() =~
             "This account can sign in and manage users inside the organisation."

    assert_patch(show, ~p"/superadmin/organisations/#{organisation.id}")
  end

  test "add admin modal rejects duplicate emails", %{conn: conn, organisation: organisation} do
    existing = user_fixture(%{role: "admin", email: "duplicate-admin@example.com"})
    conn = log_in_user(conn, superadmin_fixture())

    {:ok, view, _html} = live(conn, ~p"/superadmin/organisations/#{organisation.id}/admin/new")

    html =
      view
      |> form("#add-admin-modal form",
        admin: %{
          name: "Duplicate Admin",
          email: existing.email
        }
      )
      |> render_submit()

    assert html =~ "has already been taken"
    assert has_element?(view, "#add-admin-modal")

    refute Enum.any?(
             Accounts.list_admins_for_organisation(organisation.id),
             &(&1.name == "Duplicate Admin")
           )
  end

  test "approving a pending signup from the organisations page emails its admin setup link", %{
    conn: conn
  } do
    {:ok, %{organisation: pending, admin: admin}} =
      Organisations.register_organisation(
        %{
          "name" => "Pending Approval Camp",
          "email" => "pending-approval@example.com",
          "contact_name" => "Pending Owner"
        },
        %{
          "email" => "pending-owner@example.com",
          "password" => valid_user_password(),
          "password_confirmation" => valid_user_password()
        }
      )

    conn = log_in_user(conn, superadmin_fixture())
    {:ok, view, _html} = live(conn, ~p"/superadmin/organisations")

    html = render_click(view, "approve", %{"id" => to_string(pending.id)})

    assert html =~ "#{pending.name} approved. Admin setup email sent."

    assert [{_url, body, _headers}] = postal_calls()
    payload = Jason.decode!(body)
    assert payload["to"] == [admin.email]
    assert payload["subject"] =~ "#{pending.name} is approved"
    assert payload["plain_body"] =~ "/users/reset_password/"
  end

  test "superadmin can drill into one organisation's camp dashboard", %{
    conn: conn,
    organisation: organisation
  } do
    {:ok, organisation} = Organisations.approve(organisation)
    conn = log_in_user(conn, superadmin_fixture())

    {:ok, _view, html} = live(conn, ~p"/superadmin/organisations/#{organisation.id}/medical-camp")

    refute html =~ "Platform superadmin inspection"
    refute html =~ "Viewing"
    assert html =~ "Back to organisations"
    assert html =~ organisation.name
    assert html =~ "Medical Camp Dashboard"
  end
end
