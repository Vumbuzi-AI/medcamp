defmodule MedcampWeb.InventoryReceivedLive.Show do
  use MedcampWeb, :inventory_manager_live_view

  alias Medcamp.InventoriesReceived
  alias Medcamp.InventoriesIssues

  @default_filters %{
    "location" => "",
    "batch" => "",
    "quantity_min" => "",
    "quantity_max" => "",
    "date_from" => "",
    "date_to" => "",
    "assigned_to" => ""
  }

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :inventories_received)
     |> assign(:filters, @default_filters)
     |> assign(:issued_list, [])}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    inventory_received = InventoriesReceived.get_inventory_received!(id)
    issued = InventoriesIssues.list_inventories_issued_for_item(id, socket.assigns.filters)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:inventory_received, inventory_received)
     |> assign(:issued_list, issued)}
  end

  @impl true
  def handle_event("filter_issued", params, socket) do
    filters = Map.merge(@default_filters, params)

    issued =
      InventoriesIssues.list_inventories_issued_for_item(
        socket.assigns.inventory_received.id,
        filters
      )

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign(:issued_list, issued)}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    issued =
      InventoriesIssues.list_inventories_issued_for_item(
        socket.assigns.inventory_received.id,
        @default_filters
      )

    {:noreply,
     socket
     |> assign(:filters, @default_filters)
     |> assign(:issued_list, issued)}
  end

  defp page_title(:show), do: "Show Inventory received"
  defp page_title(:edit), do: "Edit Inventory received"
  defp page_title(:print_preview), do: "Print Preview Inventory received"
end
