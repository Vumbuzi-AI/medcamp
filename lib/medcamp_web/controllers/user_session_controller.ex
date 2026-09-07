defmodule MedcampWeb.UserSessionController do
  use MedcampWeb, :controller

  alias Medcamp.Accounts
  alias Medcamp.Accounts.LoginOtp
  alias MedcampWeb.UserAuth

  @otp_exempt_emails ~w(
    admin@gmail.com
    labtechnician@gmail.com
    pharmacist@gmail.com
    nurse@gmail.com
    reception@gmail.com
    doctor@gmail.com
  )

  def create(conn, %{"_action" => "registered"} = params) do
    create(conn, params, "Account created successfully!")
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    conn
    |> put_session(:user_return_to, ~p"/users/settings")
    |> create(params, "Password updated successfully!")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  def verify_otp(conn, %{"otp" => %{"code" => code}}) do
    challenge = get_session(conn, :login_otp_challenge)

    case LoginOtp.verify(challenge, code) do
      {:ok, challenge} ->
        user = Accounts.get_user!(challenge["user_id"])
        remember_me = to_string(challenge["remember_me"])

        conn
        |> delete_session(:login_otp_challenge)
        |> UserAuth.log_in_user(user, %{"remember_me" => remember_me})

      {:error, :invalid, updated_challenge} ->
        conn
        |> put_session(:login_otp_challenge, updated_challenge)
        |> put_flash(:error, "Invalid verification code")
        |> redirect(to: ~p"/users/log_in/otp")

      {:error, reason} when reason in [:expired, :too_many_attempts, :invalid_challenge] ->
        conn
        |> delete_session(:login_otp_challenge)
        |> put_flash(
          :error,
          "That login code expired or can no longer be used. Please sign in again."
        )
        |> redirect(to: ~p"/users/log_in")
    end
  end

  def resend_otp(conn, _params) do
    with %{"user_id" => user_id, "remember_me" => remember_me} <-
           get_session(conn, :login_otp_challenge),
         user <- Accounts.get_user!(user_id),
         {:ok, challenge} <- LoginOtp.issue(user, remember_me) do
      conn
      |> put_session(:login_otp_challenge, challenge)
      |> put_flash(:info, "A new verification code has been sent.")
      |> redirect(to: ~p"/users/log_in/otp")
    else
      _ ->
        conn
        |> delete_session(:login_otp_challenge)
        |> put_flash(:error, "We could not send a new code. Please sign in again.")
        |> redirect(to: ~p"/users/log_in")
    end
  end

  def create_with_token(conn, %{"token" => token}) do
    case Phoenix.Token.verify(MedcampWeb.Endpoint, "user login", token, max_age: 300) do
      {:ok, %{user_id: user_id, remember_me: remember_me}} ->
        user = Accounts.get_user!(user_id)
        UserAuth.log_in_user(conn, user, %{"remember_me" => to_string(remember_me)})

      {:error, _} ->
        conn
        |> put_flash(:error, "Invalid or expired login token")
        |> redirect(to: ~p"/users/log_in")
    end
  end

  defp create(conn, %{"user" => user_params}, info) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      if not login_otp_enabled?() or otp_exempt?(user) do
        conn
        |> put_session(:login_success_message, info)
        |> UserAuth.log_in_user(user, %{"remember_me" => to_string(user_params["remember_me"])})
      else
        case LoginOtp.issue(user, user_params["remember_me"] == "true") do
          {:ok, challenge} ->
            conn
            |> put_session(:login_otp_challenge, challenge)
            |> put_session(:login_success_message, info)
            |> redirect(to: ~p"/users/log_in/otp")

          {:error, _reason} ->
            conn
            |> put_flash(:error, "We could not send a verification code. Please try again.")
            |> put_flash(:email, String.slice(email, 0, 160))
            |> redirect(to: ~p"/users/log_in")
        end
      end
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/users/log_in")
    end
  end

  defp otp_exempt?(user), do: String.downcase(user.email) in @otp_exempt_emails
  defp login_otp_enabled?, do: Application.get_env(:medcamp, :login_otp_enabled, false)

  def delete(conn, _params), do: UserAuth.log_out_user(conn)

  def delete_due_to_inactivity(conn, _params) do
    UserAuth.log_out_user(
      conn,
      "You were signed out after 30 minutes of inactivity. Please sign in again.",
      ~p"/users/log_in",
      :warning
    )
  end
end
