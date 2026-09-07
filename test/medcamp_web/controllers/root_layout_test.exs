defmodule MedcampWeb.RootLayoutTest do
  use MedcampWeb.ConnCase, async: true

  import Medcamp.AccountsFixtures

  test "marks the page as unauthenticated when no user is logged in", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ ~s(name="user-authenticated" content="false")
  end

  test "marks the page as authenticated when a user is logged in", %{conn: conn} do
    conn = conn |> log_in_user(user_fixture()) |> get(~p"/users/settings")
    assert html_response(conn, 200) =~ ~s(name="user-authenticated" content="true")
  end
end
