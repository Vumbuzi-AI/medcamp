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

  describe "activating a camp from the list (D-9)" do
    test "'Set active' flashes and deactivates whichever camp was active", %{conn: conn} do
      # First camp auto-activates (Camps.create_camp/1); the second does not.
      {:ok, first} = Camps.create_camp(%{name: "First Camp"})
      {:ok, second} = Camps.create_camp(%{name: "Second Camp"})
      assert first.is_active
      refute second.is_active

      {:ok, view, _html} = live(conn, ~p"/admin/camps")

      html =
        view
        |> element("a[phx-click='activate'][phx-value-id='#{second.id}']")
        |> render_click()

      assert html =~ "Second Camp is now the active camp."
      assert Camps.get_active_camp().id == second.id
      refute Camps.get_camp!(first.id).is_active
    end

    @tag :known_bug
    @tag :skip
    test "DESIRED: a losing concurrent set_active_camp returns {:error, _} not a raise (C-4)" do
      # CURRENT (C-4): Camps.set_active_camp/1 (and create_camp/1 auto-activate)
      # do `Repo.update!` inside the transaction, so when two requests race for
      # the partial unique index `camps_one_active_per_org`, the loser raises
      # Ecto.ConstraintError / Postgrex.Error rather than returning an error
      # tuple the caller can handle. Unblocked when set_active_camp/1 switches
      # to `unique_constraint` + `Repo.update` + `Repo.rollback`.
      {:ok, a} = Camps.create_camp(%{name: "Camp A"})
      {:ok, b} = Camps.create_camp(%{name: "Camp B"})

      # Simulate the two writes interleaving so both try to end up active.
      task = Task.async(fn -> Camps.set_active_camp(a) end)
      first = Camps.set_active_camp(b)
      second = Task.await(task)

      assert match?({:ok, _}, first)
      assert match?({:error, _}, second) or match?({:ok, _}, second)
    end
  end
end
