defmodule MedcampWeb.UserSessionControllerTest do
  use MedcampWeb.ConnCase, async: true

  import Medcamp.AccountsFixtures
  alias Medcamp.Accounts.LoginOtp

  setup do
    %{user: user_fixture()}
  end

  describe "POST /users/log_in" do
    for {role, landing_path} <- [
          {"admin", "/admin/dashboard"},
          {"labtechnician", "/lab/scan"},
          {"pharmacist", "/pharmacist/scan"},
          {"nurse", "/nurse/scan"},
          {"doctor", "/doctor/scan"},
          {"receptionist", "/receptionist/patients"}
        ] do
      test "#{role} logs in and is sent directly to their workspace", %{conn: conn} do
        email = unique_user_email()
        user_fixture(email: email, role: unquote(role))

        conn =
          post(conn, ~p"/users/log_in", %{
            "user" => %{"email" => email, "password" => valid_user_password()}
          })

        assert get_session(conn, :user_token)
        refute get_session(conn, :login_otp_challenge)
        assert redirected_to(conn) == unquote(landing_path)
      end
    end

    test "valid credentials log the user in without a verification code", %{
      conn: conn,
      user: user
    } do
      conn =
        post(conn, ~p"/users/log_in", %{
          "user" => %{"email" => user.email, "password" => valid_user_password()}
        })

      assert get_session(conn, :user_token)
      refute get_session(conn, :login_otp_challenge)
      assert redirected_to(conn) == ~p"/doctor/scan"
    end

    test "a valid verification code logs the user in", %{conn: conn, user: user} do
      challenge = LoginOtp.build_challenge(user, "123456", false)

      conn =
        conn
        |> init_test_session(login_otp_challenge: challenge)
        |> post(~p"/users/log_in/otp", %{"otp" => %{"code" => "123456"}})

      assert get_session(conn, :user_token)
      refute get_session(conn, :login_otp_challenge)
      assert redirected_to(conn) == ~p"/doctor/scan"
    end

    test "logs the user in with remember me", %{conn: conn, user: user} do
      challenge = LoginOtp.build_challenge(user, "123456", true)

      conn =
        conn
        |> init_test_session(login_otp_challenge: challenge)
        |> post(~p"/users/log_in/otp", %{"otp" => %{"code" => "123456"}})

      assert conn.resp_cookies["_medic_web_user_remember_me"]
      assert redirected_to(conn) == ~p"/doctor/scan"
    end

    test "logs the user in with return to", %{conn: conn, user: user} do
      challenge = LoginOtp.build_challenge(user, "123456", false)

      conn =
        conn
        |> init_test_session(
          user_return_to: "/foo/bar",
          login_otp_challenge: challenge,
          login_success_message: "Welcome back!"
        )
        |> post(~p"/users/log_in/otp", %{"otp" => %{"code" => "123456"}})

      assert redirected_to(conn) == "/foo/bar"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Welcome back!"
    end

    test "login following registration", %{conn: conn, user: user} do
      conn =
        conn
        |> post(~p"/users/log_in", %{
          "_action" => "registered",
          "user" => %{
            "email" => user.email,
            "password" => valid_user_password()
          }
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) == ~p"/doctor/scan"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Account created successfully"
    end

    test "login following password update", %{conn: conn, user: user} do
      conn =
        conn
        |> post(~p"/users/log_in", %{
          "_action" => "password_updated",
          "user" => %{
            "email" => user.email,
            "password" => valid_user_password()
          }
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) == ~p"/users/settings"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Password updated successfully"
    end

    test "redirects to login page with invalid credentials", %{conn: conn} do
      conn =
        post(conn, ~p"/users/log_in", %{
          "user" => %{"email" => "invalid@email.com", "password" => "invalid_password"}
        })

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password"
      assert redirected_to(conn) == ~p"/users/log_in"
    end

    test "an invalid verification code reduces the remaining attempts", %{conn: conn, user: user} do
      challenge = LoginOtp.build_challenge(user, "123456", false)

      conn =
        conn
        |> init_test_session(login_otp_challenge: challenge)
        |> post(~p"/users/log_in/otp", %{"otp" => %{"code" => "000000"}})

      assert redirected_to(conn) == ~p"/users/log_in/otp"
      assert get_session(conn, :login_otp_challenge)["attempts_left"] == 4
      refute get_session(conn, :user_token)
    end
  end

  describe "DELETE /users/log_out" do
    test "logs the user out", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user) |> delete(~p"/users/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the user is not logged in", %{conn: conn} do
      conn = delete(conn, ~p"/users/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end
  end

  describe "DELETE /users/log_out/inactivity" do
    test "logs the user out and redirects to the login page with an explanatory flash", %{
      conn: conn,
      user: user
    } do
      conn = conn |> log_in_user(user) |> delete(~p"/users/log_out/inactivity")
      assert redirected_to(conn) == ~p"/users/log_in"
      refute get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :warning) =~ "inactivity"
    end

    test "succeeds even if the user is not logged in", %{conn: conn} do
      conn = delete(conn, ~p"/users/log_out/inactivity")
      assert redirected_to(conn) == ~p"/users/log_in"
      refute get_session(conn, :user_token)
    end
  end
end
