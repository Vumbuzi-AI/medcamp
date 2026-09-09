defmodule MedcampWeb.UserLoginLiveTest do
  use MedcampWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "the sign-in page" do
    test "renders with both fields required and the sign-up / reset links", %{conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/users/log_in")

      assert html =~ "Sign in to your account"
      assert html =~ "Continue to your medical camp station"
      assert html =~ "New here?"
      assert html =~ "Create your organisation"
      assert has_element?(lv, "#login_form input[name='user[email]'][type='email'][required]")

      assert has_element?(
               lv,
               "#login_form input[name='user[password]'][type='password'][required]"
             )

      assert html =~ ~s(href="/users/reset_password")
      assert html =~ ~s(href="/organisations/register")
    end
  end

  describe "submitting credentials" do
    test "wrong credentials come back with a generic, non-enumerating error", %{conn: conn} do
      conn =
        post(conn, ~p"/users/log_in", %{
          "user" => %{"email" => "nobody@example.com", "password" => "wrong-password"}
        })

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password"
      assert redirected_to(conn) == ~p"/users/log_in"
      # the email is preserved so the field can be pre-filled on the retry
      assert Phoenix.Flash.get(conn.assigns.flash, :email) == "nobody@example.com"
    end

    test "a blank submission is refused the same generic way", %{conn: conn} do
      conn = post(conn, ~p"/users/log_in", %{"user" => %{"email" => "", "password" => ""}})

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password"
      assert redirected_to(conn) == ~p"/users/log_in"
    end
  end
end
