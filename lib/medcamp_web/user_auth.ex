defmodule MedcampWeb.UserAuth do
  use MedcampWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  alias Medcamp.Accounts
  alias Medcamp.UserLoginSessions

  # Make the remember me cookie valid for 60 days.
  # If you want bump or reduce this value, also change
  # the token expiry itself in UserToken.
  @max_age 60 * 60 * 24 * 60
  @remember_me_cookie "_medic_web_user_remember_me"
  @remember_me_options [sign: true, max_age: @max_age, same_site: "Lax"]

  @doc """
  Logs the user in.

  It renews the session ID and clears the whole session
  to avoid fixation attacks. See the renew_session
  function to customize this behaviour.

  It also sets a `:live_socket_id` key in the session,
  so LiveView sessions are identified and automatically
  disconnected on log out. The line can be safely removed
  if you are not using LiveView.
  """
  def log_in_user(conn, user, params \\ %{}) do
    user_return_to = get_session(conn, :user_return_to)

    if user.is_active == true do
      token = Accounts.generate_user_session_token(user)

      Accounts.update_user_last_logged_in(user)
      UserLoginSessions.create_login(user.id)

      conn
      |> renew_session()
      |> put_token_in_session(token)
      |> maybe_write_remember_me_cookie(token, params)
      |> put_flash(:info, get_session(conn, :login_success_message) || "Welcome back!")
      |> redirect(to: user_return_to || signed_in_path(conn))
    else
      conn
      |> renew_session()
      |> redirect(to: ~p"/")
      |> put_flash(:error, "Your account has been deactivated. Please contact admin.")
    end
  end

  defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}) do
    put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
  end

  defp maybe_write_remember_me_cookie(conn, _token, _params) do
    conn
  end

  # This function renews the session ID and erases the whole
  # session to avoid fixation attacks. If there is any data
  # in the session you may want to preserve after log in/log out,
  # you must explicitly fetch the session data before clearing
  # and then immediately set it after clearing, for example:
  #
  #     defp renew_session(conn) do
  #       preferred_locale = get_session(conn, :preferred_locale)
  #
  #       conn
  #       |> configure_session(renew: true)
  #       |> clear_session()
  #       |> put_session(:preferred_locale, preferred_locale)
  #     end
  #
  defp renew_session(conn) do
    delete_csrf_token()

    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  @doc """
  Logs the user out.

  It clears all session data for safety. See renew_session.
  """
  def log_out_user(
        conn,
        message \\ "Logged out successfully",
        redirect_to \\ ~p"/",
        flash_kind \\ :info
      ) do
    user_token = get_session(conn, :user_token)

    if user_token do
      if user = Accounts.get_user_by_session_token(user_token) do
        Accounts.update_user_last_logged_out(user)
        UserLoginSessions.record_logout(user.id)
      end

      Accounts.delete_user_session_token(user_token)
    end

    if live_socket_id = get_session(conn, :live_socket_id) do
      MedcampWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session()
    |> delete_resp_cookie(@remember_me_cookie)
    |> put_flash(flash_kind, message)
    |> redirect(to: redirect_to)
  end

  @doc """
  Authenticates the user by looking into the session
  and remember me token.
  """
  def fetch_current_user(conn, _opts) do
    {user_token, conn} = ensure_user_token(conn)
    user = user_token && Accounts.get_user_by_session_token(user_token)
    assign(conn, :current_user, user)
  end

  defp ensure_user_token(conn) do
    if token = get_session(conn, :user_token) do
      {token, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if token = conn.cookies[@remember_me_cookie] do
        {token, put_token_in_session(conn, token)}
      else
        {nil, conn}
      end
    end
  end

  @doc """
  Handles mounting and authenticating the current_user in LiveViews.

  ## `on_mount` arguments

    * `:mount_current_user` - Assigns current_user
      to socket assigns based on user_token, or nil if
      there's no user_token or no matching user.

    * `:ensure_authenticated` - Authenticates the user from the session,
      and assigns the current_user to socket assigns based
      on user_token.
      Redirects to login page if there's no logged user.

    * `:redirect_if_user_is_authenticated` - Authenticates the user from the session.
      Redirects to signed_in_path if there's a logged user.

  ## Examples

  Use the `on_mount` lifecycle macro in LiveViews to mount or authenticate
  the current_user:

      defmodule MedcampWeb.PageLive do
        use MedcampWeb, :live_view

        on_mount {MedcampWeb.UserAuth, :mount_current_user}
        ...
      end

  Or use the `live_session` of your router to invoke the on_mount callback:

      live_session :authenticated, on_mount: [{MedcampWeb.UserAuth, :ensure_authenticated}] do
        live "/profile", ProfileLive, :index
      end
  """
  def on_mount(:mount_current_user, _params, session, socket) do
    {:cont, mount_current_user(socket, session)}
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    socket = mount_current_user(socket, session)

    if socket.assigns.current_user do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "You must log in to access this page.")
        |> Phoenix.LiveView.redirect(to: ~p"/users/log_in")

      {:halt, socket}
    end
  end

  def on_mount(:redirect_if_user_is_authenticated, _params, session, socket) do
    socket = mount_current_user(socket, session)

    if socket.assigns.current_user do
      {:halt, Phoenix.LiveView.redirect(socket, to: signed_in_path(socket))}
    else
      {:cont, socket}
    end
  end

  defp mount_current_user(socket, session) do
    Phoenix.Component.assign_new(socket, :current_user, fn ->
      if user_token = session["user_token"] do
        user = Accounts.get_user_by_session_token(user_token)

        if user do
          Medcamp.Repo.put_audit_user(user.id)
        end

        user
      end
    end)
  end

  @doc """
  Used for routes that require the user to not be authenticated.
  """
  def redirect_if_user_is_authenticated(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
      |> redirect(to: signed_in_path(conn))
      |> halt()
    else
      conn
    end
  end

  @doc """
  Used for routes that require the user to be authenticated.

  If you want to enforce the user email is confirmed before
  they use the application at all, here would be a good place.
  """
  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> maybe_store_return_to()
      |> redirect(to: ~p"/users/log_in")
      |> halt()
    end
  end

  @role_gates [
    doctor: "doctor",
    nurse: "nurse",
    admin: "admin",
    pharmacist: "pharmacist",
    lab_technician: "labtechnician"
  ]

  # One `require_authenticated_<role>` plug per camp role. They were eleven
  # near-identical copies before the trim; the five that survive differ only
  # in the role string, so they are generated from one clause.
  for {name, role} <- @role_gates do
    def unquote(:"require_authenticated_#{name}")(conn, _opts) do
      require_role(conn, unquote(role))
    end
  end

  defp require_role(conn, role) do
    case conn.assigns[:current_user] do
      %{role: ^role} ->
        conn

      %{role: other_role} ->
        redirect_to_page_conn_case(conn, other_role)

      nil ->
        conn
        |> put_flash(:error, "You must log in to access this page.")
        |> maybe_store_return_to()
        |> redirect(to: ~p"/users/log_in")
        |> halt()
    end
  end

  def redirect_to_correct_page(conn, _opts) do
    if conn.assigns[:current_user] do
      redirect_to_page_conn_case(conn, conn.assigns[:current_user].role)
    else
      conn
    end
  end

  @doc """
  Each role's default landing page - used both to send a just-logged-in user
  somewhere sensible and, by `MedcampWeb.Plugs.RequirePanelPermission`, as the
  fallback when a permission check fails.
  """
  def default_path_for_role(role) do
    case role do
      "admin" -> "/admin/dashboard"
      "doctor" -> "/doctor/scan"
      "nurse" -> "/nurse/scan"
      "labtechnician" -> "/lab/scan"
      "pharmacist" -> "/pharmacist/scan"
      _ -> "/users/log_in"
    end
  end

  defp redirect_to_page_conn_case(conn, role) do
    redirect_to_page_conn(conn, default_path_for_role(role))
  end

  defp redirect_to_page_conn(conn, url) do
    conn
    |> maybe_store_return_to()
    |> redirect(to: url)
    |> halt()
  end

  defp put_token_in_session(conn, token) do
    conn
    |> put_session(:user_token, token)
    |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :user_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn

  defp signed_in_path(_conn), do: ~p"/"
end
