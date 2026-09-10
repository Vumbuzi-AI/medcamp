defmodule MedcampWeb.HomeLiveTest do
  use MedcampWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Medcamp.AccountsFixtures

  test "renders the marketing landing page for an anonymous visitor", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/")

    assert html =~ "Run every medical camp from"
    assert html =~ "Plus+Jakarta+Sans"

    # Hero slogan chip.
    assert html =~ "Care that moves with the camp"

    # Every section anchor present.
    for id <- ~w(features departments workflow analysis) do
      assert html =~ ~s(id="#{id}")
    end

    # Story beats.
    assert html =~ "Every department, working from the same patient story."
    assert html =~ "Better coordination means more time for patients."

    # Anonymous visitor: staff portal CTA routes to login.
    assert html =~ ~s(href="/users/log_in")
    refute html =~ ~s(href="/organisations/register")

    # Current medical-camp product copy + imagery.
    assert html =~ "Laboratory"
    assert html =~ "/images/public/african-hospital-reception.png"
  end

  test "points a signed-in user at their portal instead of the login page", %{conn: conn} do
    user = user_fixture(%{role: "admin"})
    conn = log_in_user(conn, user)

    {:ok, _view, html} = live(conn, ~p"/")

    assert html =~ ~s(href="/admin/dashboard")
    refute html =~ ~s(href="/users/log_in")
  end
end
