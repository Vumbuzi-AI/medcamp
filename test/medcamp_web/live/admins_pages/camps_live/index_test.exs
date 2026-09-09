defmodule MedcampWeb.AdminCampsLive.IndexTest do
  use MedcampWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Medcamp.AccountsFixtures

  alias Medcamp.Camps

  setup %{conn: conn} do
    %{conn: log_in_user(conn, user_fixture(%{role: "admin"}))}
  end

  test "renders through the list_page shell with a New camp action and search", %{conn: conn} do
    {:ok, _camp} = Camps.create_camp(%{name: "Rift Valley Outreach", location: "Nakuru"})

    {:ok, view, html} = live(conn, ~p"/admin/camps")

    assert html =~ "Camps"
    assert html =~ "New camp"
    assert has_element?(view, "form[phx-change='search'] input[name='search']")
    assert has_element?(view, "#camps tr#camp-#{Camps.list_camps() |> hd() |> Map.get(:id)}")
    assert html =~ "Rift Valley Outreach"
  end

  test "search narrows the camp list", %{conn: conn} do
    {:ok, _} = Camps.create_camp(%{name: "Coast Camp", location: "Mombasa"})
    {:ok, _} = Camps.create_camp(%{name: "Highlands Camp", location: "Eldoret"})

    {:ok, view, _html} = live(conn, ~p"/admin/camps")

    html =
      view
      |> form("form[phx-change='search']", %{"search" => "Mombasa"})
      |> render_change()

    assert html =~ "Coast Camp"
    refute html =~ "Highlands Camp"
  end

  test "the layout camp switcher is opt-in: hidden on camps & users, shown on visits", %{
    conn: conn
  } do
    {:ok, _} = Camps.create_camp(%{name: "Some Camp"})

    {:ok, _view, camps_html} = live(conn, ~p"/admin/camps")
    refute camps_html =~ ~s(action="/admin/camps/filter")

    {:ok, _view, users_html} = live(conn, ~p"/admin/users")
    refute users_html =~ ~s(action="/admin/camps/filter")

    {:ok, _view, visits_html} = live(conn, ~p"/admin/patient_visits")
    assert visits_html =~ ~s(action="/admin/camps/filter")
  end

  test "the new-camp form rejects a start date in the past", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/admin/camps/new")

    past = Date.utc_today() |> Date.add(-3) |> Date.to_iso8601()

    html =
      view
      |> form("#camp-modal form", camp: %{name: "Backdated", start_date: past})
      |> render_change()

    assert html =~ "cannot be in the past"
  end

  test "editing a camp still allows its (already past) start date", %{conn: conn} do
    past = Date.utc_today() |> Date.add(-10)
    {:ok, camp} = Camps.create_camp(%{name: "Ran Last Week", start_date: past})

    {:ok, view, _html} = live(conn, ~p"/admin/camps/#{camp.id}/edit")

    html =
      view
      |> form("#camp-modal form", camp: %{name: "Ran Last Week", location: "Kisii"})
      |> render_change()

    refute html =~ "cannot be in the past"
  end
end
