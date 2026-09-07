defmodule MedcampWeb.Plugs.RequirePanelPermission do
  @moduledoc """
  Closes the URL behind every sidebar panel the current user cannot see.

  Unlike `MedcampWeb.Plugs.RequirePermission`, which guards one named slug
  on one route, this takes no argument: it works out which panel the
  request is for from the path (`MedcampWeb.SidebarCatalog`) and checks the
  permission that panel's sidebar link is hidden by. Mount it once per
  `live_session` and every route under a role's prefix is covered, so a
  hidden link and a typed-in URL can never disagree.

  Paths no panel claims - a role's landing page, shared pages like
  `/chat`, sub-resources not represented by their own tab - are left
  alone; the existing `require_authenticated_<role>` plug is still what
  keeps other roles out of them.

  Like `RequirePermission` this sits on top of, not instead of, the role
  plugs: it fails closed only for a user who is signed in but lacks the
  panel, and defers "not signed in at all" to the auth plug that ran
  first.
  """

  import Plug.Conn

  alias Medcamp.Authorization
  alias MedcampWeb.SidebarCatalog

  def init(opts), do: opts

  def call(conn, _opts) do
    user = conn.assigns[:current_user]

    case required_permissions(user, conn.request_path) do
      [] ->
        conn

      slugs ->
        if Enum.any?(slugs, &Authorization.can?(user, &1)) do
          conn
        else
          conn
          |> Phoenix.Controller.put_flash(:error, denied_message())
          |> Phoenix.Controller.redirect(to: fallback_path(conn.assigns[:current_user]))
          |> halt()
        end
    end
  end

  def on_mount(:default, _params, _session, socket) do
    {:cont,
     Phoenix.LiveView.attach_hook(
       socket,
       :require_panel_permission,
       :handle_params,
       &check_params/3
     )}
  end

  defp check_params(_params, uri, socket) do
    user = socket.assigns[:current_user]
    path = URI.parse(uri).path || "/"

    case required_permissions(user, path) do
      [] ->
        {:cont, socket}

      slugs ->
        if Enum.any?(slugs, &Authorization.can?(user, &1)) do
          {:cont, socket}
        else
          socket =
            socket
            |> Phoenix.LiveView.put_flash(:error, denied_message())
            |> Phoenix.LiveView.redirect(to: fallback_path(user))

          {:halt, socket}
        end
    end
  end

  # An empty list means "this request is not something a panel permission
  # governs", either because nobody is signed in (the auth plug's problem,
  # not ours) or because no tab in this panel's sidebar owns the path.
  # More than one slug means the path is cross-linked between sidebars and
  # any one of them lets the user through.
  defp required_permissions(nil, _path), do: []

  defp required_permissions(%{role: role}, path) do
    SidebarCatalog.permissions_for_path(role, path)
  end

  defp denied_message, do: "You do not have permission to access that page."

  defp fallback_path(nil), do: "/users/log_in"
  defp fallback_path(%{role: role}), do: MedcampWeb.UserAuth.default_path_for_role(role)
end
