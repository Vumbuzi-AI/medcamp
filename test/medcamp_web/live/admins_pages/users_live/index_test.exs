defmodule MedcampWeb.AdminUsersLive.IndexTest do
  use MedcampWeb.ConnCase

  import Phoenix.LiveViewTest
  import Medcamp.AccountsFixtures

  setup %{conn: conn} do
    admin = user_fixture(%{role: "admin", name: "Admin User"})
    %{conn: log_in_user(conn, admin), admin: admin}
  end

  test "renders the list_page shell: header, search toolbar and a data_table row", %{
    conn: conn,
    admin: admin
  } do
    nurse = user_fixture(%{role: "nurse", name: "Nurse Nia"})

    {:ok, view, html} = live(conn, ~p"/admin/users")

    # Header card
    assert html =~ "System Users"
    assert html =~ "Add User"
    # Toolbar
    assert has_element?(
             view,
             "input[name='filters[search]'][placeholder='Search by name or email']"
           )

    # data_table body + rows
    assert has_element?(view, "#users-table tr#user-#{admin.id}")
    assert has_element?(view, "#users-table tr#user-#{nurse.id}")
    assert html =~ "Nurse Nia"
    # canonical flat-table header casing
    assert html =~ "uppercase"
  end

  test "the Add User button opens the new-user form instead of the sign-in-as route", %{
    conn: conn
  } do
    {:ok, view, _html} = live(conn, ~p"/admin/users")

    # Regression: `get "/admin/users/:email"` used to shadow this LiveView route,
    # so clicking Add User redirected with "No user with that email".
    view
    |> element("a[href='/admin/users/new']")
    |> render_click()

    assert_patched(view, ~p"/admin/users/new")
    assert has_element?(view, "#user-modal")
    refute render(view) =~ "No user with that email"
  end

  test "navigating straight to /admin/users/new opens the form", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/admin/users/new")
    assert has_element?(view, "#user-modal")
    refute html =~ "No user with that email"
  end

  test "the new-user form only asks for name, email and role", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/admin/users/new")

    assert has_element?(view, "#user-form input[name='user[name]']")
    assert has_element?(view, "#user-form input[name='user[email]']")
    assert has_element?(view, "#user-form select[name='user[role]']")
    refute has_element?(view, "#user-form input[name='user[inserted_at]']")
    refute has_element?(view, "#user-form input[name='user[phone_number]']")
    refute has_element?(view, "#user-form input[name='user[is_active]']")
  end

  test "inviting a user creates an inactive account and sends a set-password email", %{
    conn: conn
  } do
    {:ok, view, _html} = live(conn, ~p"/admin/users/new")

    view
    |> form("#user-form", user: %{name: "Nia Nurse", email: "nia@example.com", role: "nurse"})
    |> render_submit()

    Process.sleep(50)

    user = Medcamp.Accounts.get_user_by_email("nia@example.com")
    assert user.name == "Nia Nurse"
    assert user.role == "nurse"
    refute user.is_active
    assert is_nil(user.activated_at)
    assert Medcamp.Accounts.User.status(user) == :pending
    assert [{_url, body, _headers}] = Medcamp.Postal.TestClient.calls()
    assert body =~ "reset_password"
  end

  test "an invited user shows as Pending, then Active once they set a password", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/admin/users/new")

    view
    |> form("#user-form", user: %{name: "Pat Pending", email: "pat@example.com", role: "doctor"})
    |> render_submit()

    {:ok, _view, html} = live(conn, ~p"/admin/users")
    assert html =~ "Pending"

    user = Medcamp.Accounts.get_user_by_email("pat@example.com")

    {:ok, activated} =
      Medcamp.Accounts.reset_user_password(user, %{
        password: "a valid long password",
        password_confirmation: "a valid long password"
      })

    assert activated.is_active
    assert activated.activated_at
    assert Medcamp.Accounts.User.status(activated) == :active
  end

  test "search narrows the table to matching users", %{conn: conn} do
    user_fixture(%{role: "doctor", name: "Findme Doctor", email: "findme@example.com"})
    user_fixture(%{role: "doctor", name: "Someone Else", email: "other@example.com"})

    {:ok, view, _html} = live(conn, ~p"/admin/users")

    html =
      view
      |> form("form[phx-change='filter']", %{"filters" => %{"search" => "Findme"}})
      |> render_change()

    assert html =~ "Findme Doctor"
    refute html =~ "Someone Else"
  end

  test "shows the blank_state when a filter matches nothing", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/admin/users")

    html =
      view
      |> form("form[phx-change='filter']", %{"filters" => %{"search" => "zzz-no-such-user"}})
      |> render_change()

    assert html =~ "No users found"
    assert html =~ "No users match the current filters."
  end
end
