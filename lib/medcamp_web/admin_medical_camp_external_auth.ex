defmodule MedcampWeb.AdminMedicalCampExternalAuth do
  import Phoenix.Component, only: [assign: 3]
  import Phoenix.LiveView

  alias Medcamp.Accounts

  def on_mount(:mount_external_admin, _params, session, socket) do
    {:cont, assign_external_admin(socket, session)}
  end

  def on_mount(:require_external_admin, _params, session, socket) do
    socket = assign_external_admin(socket, session)

    if match?(%{role: "admin", is_active: true}, socket.assigns.external_admin_user) do
      {:cont, socket}
    else
      socket =
        socket
        |> put_flash(:error, "Enter a valid admin PIN to continue.")
        |> redirect(to: "/admin/medical_camp/access")

      {:halt, socket}
    end
  end

  defp assign_external_admin(socket, session) do
    user =
      case session["admin_medical_camp_access_user_id"] do
        nil -> nil
        user_id -> fetch_external_admin(user_id)
      end

    # This page is reached with a PIN rather than a login, so the admin found
    # here is what establishes the tenant for everything the page queries.
    if user, do: MedcampWeb.PublicTenant.enter(user.organisation_id)

    socket
    |> assign(:external_admin_user, user)
    |> assign(:current_organisation, Medcamp.Organisations.get_user_organisation(user))
  end

  defp fetch_external_admin(user_id) when is_integer(user_id) do
    get_active_admin(user_id)
  rescue
    Ecto.NoResultsError -> nil
  end

  defp fetch_external_admin(user_id) when is_binary(user_id) do
    case Integer.parse(user_id) do
      {parsed_id, ""} -> fetch_external_admin(parsed_id)
      _ -> nil
    end
  end

  defp fetch_external_admin(_), do: nil

  defp get_active_admin(user_id) do
    case Accounts.get_user_across_organisations(user_id) do
      %{role: "admin", is_active: true} = user -> user
      _ -> nil
    end
  end
end
