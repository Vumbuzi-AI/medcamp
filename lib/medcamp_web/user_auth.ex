defmodule MedcampWeb.UserAuth do
  use MedcampWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  alias Medcamp.Accounts
  alias Medcamp.Camps
  alias Medcamp.Camps.Scope
  alias Medcamp.Organisations
  alias Medcamp.Tenancy
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

    # Logging in is the moment the tenant becomes known. Everything below -
    # the login-session record in particular - is written into it.
    Tenancy.put_org_id(user.organisation_id)

    case login_block_reason(user) do
      nil ->
        token = Accounts.generate_user_session_token(user)

        Accounts.update_user_last_logged_in(user)
        UserLoginSessions.create_login(user.id)

        conn
        |> renew_session()
        |> put_token_in_session(token)
        |> maybe_write_remember_me_cookie(token, params)
        |> put_flash(:info, get_session(conn, :login_success_message) || "Welcome back!")
        |> redirect(to: user_return_to || signed_in_path_for_user(user))

      message ->
        conn
        |> renew_session()
        |> put_flash(:error, message)
        |> redirect(to: ~p"/")
    end
  end

  @pending_message "Your organisation is awaiting approval. We will email you once it is active."
  @suspended_message "Your organisation is not active. Please contact support."
  @deactivated_message "Your account has been deactivated. Please contact admin."

  # An organisation that has been deactivated - or a self-serve signup that has
  # not been approved yet - must not be usable, however the login is reached.
  # Checking the user's flag alone would have left the superadmin console's
  # "Deactivate" button doing nothing.
  defp login_block_reason(user) do
    organisation = Organisations.get_user_organisation(user)

    cond do
      is_nil(organisation) -> @suspended_message
      not organisation.is_active and is_nil(organisation.approved_at) -> @pending_message
      not organisation.is_active -> @suspended_message
      not user.is_active -> @deactivated_message
      true -> nil
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
        Tenancy.put_org_id(user.organisation_id)
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

  Also establishes the tenant: everything the request does from here on is
  filtered to this user's organisation by `Medcamp.Repo.prepare_query/3`.
  Doing it here rather than in a separate plug means it cannot end up ordered
  before the user is known.
  """
  def fetch_current_user(conn, _opts) do
    {user_token, conn} = ensure_user_token(conn)

    user =
      user_token
      |> then(&(&1 && Accounts.get_user_by_session_token(&1)))
      |> reject_inactive_organisation()

    conn
    |> assign(:current_user, user)
    |> assign_organisation(user)
    |> fetch_camp_filter()
  end

  @camp_filter_session_key "camp_filter_id"

  @doc """
  The session key the admin camp switcher writes its choice to.
  """
  def camp_filter_session_key, do: @camp_filter_session_key

  @doc """
  Restores the viewer's camp filter from the session.

  This is only the reading lens. The camp records are *written* into comes
  from the organisation and is established in `assign_organisation/2`, so
  editing the session cannot move or widen it.
  """
  def fetch_camp_filter(conn) do
    camp_filter_id = get_session(conn, @camp_filter_session_key)

    # Guarded on the organisation: a camp lookup is a tenant query, and a
    # request with no user (or a superadmin, who has no organisation) has no
    # tenant for it to run in.
    camp =
      if conn.assigns[:current_organisation] && camp_filter_id,
        do: Camps.get_camp(camp_filter_id)

    Scope.put_camp_filter(camp && camp.id)

    assign(conn, :camp_filter, camp)
  end

  @doc """
  Drops a user whose organisation is no longer active.

  Deactivating an organisation has to end the sessions its staff already hold,
  not just stop new logins - otherwise a suspended tenant keeps working until
  everyone happens to log out.
  """
  def reject_inactive_organisation(nil), do: nil

  def reject_inactive_organisation(user) do
    case Organisations.get_user_organisation(user) do
      %{is_active: true} -> user
      _ -> nil
    end
  end

  @doc """
  Puts `user`'s organisation into process scope and assigns it for layouts.

  Public for the entry points that resolve a tenant some other way - the
  GSRN camp routes and the scan API - where there is no session to read.
  """
  def assign_organisation(conn, user) do
    organisation = Organisations.get_user_organisation(user)

    if organisation, do: Tenancy.put_org_id(organisation.id)

    active_camp = Camps.get_active_camp_for_organisation(organisation && organisation.id)
    Scope.put_active_camp_id(active_camp && active_camp.id)

    conn
    |> assign(:current_organisation, organisation)
    |> assign(:active_camp, active_camp)
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

  @doc """
  `on_mount` counterpart to `require_superadmin/2`, for the superadmin
  LiveViews.
  """
  def on_mount(:ensure_superadmin, _params, session, socket) do
    socket = mount_current_user(socket, session)

    if match?(%{is_superadmin: true}, socket.assigns.current_user) do
      {:cont, socket}
    else
      {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/users/log_in")}
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
    socket =
      Phoenix.Component.assign_new(socket, :current_user, fn ->
        if user_token = session["user_token"] do
          user_token
          |> Accounts.get_user_by_session_token()
          |> reject_inactive_organisation()
        end
      end)

    user = socket.assigns.current_user

    # A LiveView owns its own process, so the audit user and the tenant have
    # to be re-established here - the plug that set them ran in the process
    # that served the initial HTTP request, not this one. Kept outside
    # `assign_new/3` so the connected mount sets them too, even when the user
    # itself came across from the disconnected render.
    if user, do: Medcamp.Repo.put_audit_user(user.id)

    Phoenix.Component.assign_new(socket, :current_organisation, fn ->
      Organisations.get_user_organisation(user)
    end)
    |> tap(fn socket ->
      if org = socket.assigns.current_organisation, do: Tenancy.put_org_id(org.id)
    end)
    |> mount_camp_scope(session)
  end

  # The camp half of the same re-establishment: the active camp records are
  # written into, and the camp the viewer has filtered down to. Both are read
  # fresh rather than carried in `assign_new/3` - an admin switching camps in
  # one tab must not leave another tab writing into the previous one.
  defp mount_camp_scope(socket, session) do
    organisation = socket.assigns.current_organisation
    active_camp = Camps.get_active_camp_for_organisation(organisation && organisation.id)
    Scope.put_active_camp_id(active_camp && active_camp.id)

    camp_filter_id = organisation && session[@camp_filter_session_key]
    camp_filter = camp_filter_id && Camps.get_camp(camp_filter_id)

    Scope.put_camp_filter(camp_filter && camp_filter.id)

    socket
    |> Phoenix.Component.assign(:active_camp, active_camp)
    |> Phoenix.Component.assign(:camp_filter, camp_filter)
    |> assign_camp_options()
  end

  # Only the admin layout renders the switcher, so only an admin pays for the
  # list behind it.
  defp assign_camp_options(%{assigns: %{current_user: %{role: "admin"}}} = socket) do
    Phoenix.Component.assign_new(socket, :camp_options, fn -> Camps.list_camps() end)
  end

  defp assign_camp_options(socket),
    do: Phoenix.Component.assign_new(socket, :camp_options, fn -> [] end)

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
    receptionist: "receptionist",
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
      %{is_superadmin: true} ->
        redirect_to_page_conn(conn, ~p"/superadmin/organisations")

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

  @doc """
  Gates the console that provisions organisations.

  A superadmin sits outside every tenant - the flag is set directly in the
  database, never through the UI, so there is no path for an organisation's
  own admin to grant it to themselves.
  """
  def require_superadmin(conn, _opts) do
    case conn.assigns[:current_user] do
      %{is_superadmin: true} ->
        conn

      %{role: role} ->
        redirect_to_page_conn_case(conn, role)

      nil ->
        conn
        |> put_flash(:error, "You must log in to access this page.")
        |> maybe_store_return_to()
        |> redirect(to: ~p"/users/log_in")
        |> halt()
    end
  end

  def redirect_to_correct_page(conn, _opts) do
    case conn.assigns[:current_user] do
      nil -> conn
      %{is_superadmin: true} -> redirect_to_page_conn(conn, ~p"/superadmin/organisations")
      %{role: role} -> redirect_to_page_conn_case(conn, role)
    end
  end

  @doc "The correct landing page for a signed-in user."
  def landing_path_for_user(%{is_superadmin: true}), do: "/superadmin/organisations"
  def landing_path_for_user(%{role: role}), do: default_path_for_role(role)
  def landing_path_for_user(_user), do: "/users/log_in"

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
      "receptionist" -> "/receptionist/patients"
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

  defp signed_in_path(%{assigns: assigns}) do
    signed_in_path_for_user(assigns[:current_user])
  end

  defp signed_in_path_for_user(%{is_superadmin: true}), do: "/superadmin/organisations"
  defp signed_in_path_for_user(user), do: landing_path_for_user(user)
end
