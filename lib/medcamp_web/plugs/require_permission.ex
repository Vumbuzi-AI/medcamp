defmodule MedcampWeb.Plugs.RequirePermission do
  @moduledoc """
  Enforces `Medcamp.Authorization.can?/2` for a single permission slug, as
  both a plug (controller routes) and a LiveView `on_mount` hook (`live`
  routes via `live_session`). Opt-in per route - see
  `docs/RBAC_ACCESS_CONTROL_PLAN.md` §5.3.

  This sits on top of, not instead of, the existing role plugs: a route
  still needs `require_authenticated_<role>` (or equivalent) in its
  pipeline first, since `can?/2` fails closed for a user with no
  `current_user` assign at all.
  """

  import Plug.Conn

  alias Medcamp.Authorization

  def init(permission_slug) when is_binary(permission_slug), do: permission_slug

  def call(conn, permission_slug) do
    if allowed?(conn.assigns[:current_user], permission_slug) do
      conn
    else
      conn
      |> Phoenix.Controller.put_flash(:error, "You do not have permission to access that page.")
      |> Phoenix.Controller.redirect(to: fallback_path(conn.assigns[:current_user]))
      |> halt()
    end
  end

  def on_mount(permission_slug, _params, _session, socket) when is_binary(permission_slug) do
    if allowed?(socket.assigns[:current_user], permission_slug) do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "You do not have permission to access that page.")
        |> Phoenix.LiveView.redirect(to: fallback_path(socket.assigns[:current_user]))

      {:halt, socket}
    end
  end

  defp allowed?(nil, _permission_slug), do: false
  defp allowed?(user, permission_slug), do: Authorization.can?(user, permission_slug)

  defp fallback_path(nil), do: "/users/log_in"
  defp fallback_path(%{role: role}), do: MedcampWeb.UserAuth.default_path_for_role(role)
end
