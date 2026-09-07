defmodule MedcampWeb.AssignedTagLive.Show do
  use MedcampWeb, :live_view

  alias Medcamp.AssignedTags

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:assigned_tag, AssignedTags.get_assigned_tag!(id))}
  end

  defp page_title(:show), do: "Show Assigned tag"
  defp page_title(:edit), do: "Edit Assigned tag"
end
