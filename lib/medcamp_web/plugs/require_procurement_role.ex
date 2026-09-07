defmodule MedcampWeb.Plugs.RequireProcurementRole do
  @moduledoc false

  import Plug.Conn

  @procurement_roles ~w(procurement_officer stores_officer finance_officer admin)

  def init(roles), do: roles

  def call(conn, roles) when is_list(roles) do
    if allowed?(conn.assigns[:current_user], roles) do
      conn
    else
      conn
      |> Phoenix.Controller.put_flash(:error, "Unauthorised")
      |> Phoenix.Controller.redirect(to: fallback_path(conn.assigns[:current_user], roles))
      |> halt()
    end
  end

  def on_mount(roles, _params, _session, socket) when is_list(roles) do
    if allowed?(socket.assigns[:current_user], roles) do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "Unauthorised")
        |> Phoenix.LiveView.redirect(to: fallback_path(socket.assigns[:current_user], roles))

      {:halt, socket}
    end
  end

  defp allowed?(%{role: role}, roles), do: role in roles
  defp allowed?(_, _roles), do: false

  defp fallback_path(nil, _roles), do: "/users/log_in"

  defp fallback_path(%{role: role}, _roles) when role in @procurement_roles,
    do: "/procurement/dashboard"

  defp fallback_path(%{role: "supplier"}, _roles), do: "/supplier/dashboard"
  defp fallback_path(_user, ["supplier"]), do: "/supplier/dashboard"
  defp fallback_path(_user, _roles), do: "/"
end
