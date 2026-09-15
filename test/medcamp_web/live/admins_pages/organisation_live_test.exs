defmodule MedcampWeb.AdminOrganisationLiveTest do
  use MedcampWeb.ConnCase, async: true

  import Medcamp.AccountsFixtures
  import Phoenix.LiveViewTest

  alias Medcamp.Organisations

  test "admin can view and update organisation profile and branding", %{
    conn: conn,
    organisation: organisation
  } do
    user = user_fixture(%{role: "admin"})
    conn = log_in_user(conn, user)

    {:ok, view, html} = live(conn, ~p"/admin/organisation")

    assert html =~ "Organisation details"
    assert html =~ "Brand colours"
    assert html =~ "Organisation logo"
    assert html =~ "Preview"
    assert html =~ "Changes apply to this organisation"
    refute html =~ "Organisation settings"

    view
    |> form("#organisation-form",
      organisation: %{
        name: "Updated Camp Org",
        email: "updated@example.com",
        phone_number: "0700000000",
        location: "Kisumu",
        primary_color: "#0c2765",
        accent_color: "#52b2d8"
      }
    )
    |> render_submit()

    assert render(view) =~ "Organisation profile updated."

    reloaded = Organisations.get_organisation!(organisation.id)
    assert reloaded.name == "Updated Camp Org"
    assert reloaded.email == "updated@example.com"
    assert reloaded.location == "Kisumu"
  end

  test "shows a 'default branding' hint until colours and logo are customised", %{
    conn: conn,
    organisation: organisation
  } do
    conn = log_in_user(conn, user_fixture(%{role: "admin"}))

    {:ok, view, html} = live(conn, ~p"/admin/organisation")
    assert html =~ "Using the default Tibasasa palette"
    assert html =~ "Using the default Tibasasa logo"

    view
    |> form("#organisation-form",
      organisation: %{name: organisation.name, primary_color: "#123456", accent_color: "#abcdef"}
    )
    |> render_submit()

    refute render(view) =~ "Using the default Tibasasa palette"
    # logo is still stock
    assert render(view) =~ "Using the default Tibasasa logo"
  end

  test "admin can change the organisation slug; free text is slugified", %{
    conn: conn,
    organisation: organisation
  } do
    conn = log_in_user(conn, user_fixture(%{role: "admin"}))
    {:ok, view, _html} = live(conn, ~p"/admin/organisation")

    assert has_element?(view, "#organisation-form input[name='organisation[slug]']")

    view
    |> form("#organisation-form", organisation: %{name: organisation.name, slug: "Renamed Camp!"})
    |> render_submit()

    assert render(view) =~ "Organisation profile updated."
    assert Organisations.get_organisation!(organisation.id).slug == "renamed-camp"
  end
end
