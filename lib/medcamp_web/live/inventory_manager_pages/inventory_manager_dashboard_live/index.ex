defmodule MedcampWeb.InventoryManagerDashboardLive.Index do
  use MedcampWeb, :shared_live_view

  alias Medcamp.InventoriesIssues
  alias Medcamp.InventoriesReceived
  alias Medcamp.StockAlerts
  alias MedcampWeb.Dashboards.WidgetResolver

  @role "inventory_manager"

  @impl true
  def mount(_params, _session, socket) do
    {date_from, date_to} = current_month_range()

    {:ok,
     socket
     |> assign(:active_tab, :dashboard)
     |> assign(:page_title, "Inventory Dashboard")
     |> assign(:date_from, date_from)
     |> assign(:date_to, date_to)
     |> assign(:visible_summary_cards, WidgetResolver.summary_cards(@role))
     |> load_data()}
  end

  defp load_data(socket) do
    date_from = socket.assigns.date_from
    date_to = socket.assigns.date_to

    received =
      InventoriesReceived.list_inventories_received()
      |> Enum.filter(&inserted_in_range?(&1.inserted_at, date_from, date_to))

    issued =
      InventoriesIssues.list_inventories_issued()
      |> Enum.filter(&inserted_in_range?(&1.inserted_at, date_from, date_to))

    socket
    |> assign(:received, received)
    |> assign(:issued, issued)
    |> assign(:stock_alerts, StockAlerts.list_all_alerts())
    |> assign(:recent_items, recent_inventory_items(received))
  end

  defp inventory_manager_tabs do
    [
      %{
        name: "Inventories Received",
        icon: "inbox-arrow-down",
        url: "/inventory_manager/inventories_received",
        tab_name: :inventories_received
      },
      %{
        name: "In Store",
        icon: "archive-box",
        url: "/inventory_manager/in_store",
        tab_name: :in_store
      },
      %{
        name: "Inventories Issued",
        icon: "inbox-stack",
        url: "/inventory_manager/inventories_issued",
        tab_name: :inventories_issued
      },
      %{
        name: "All Batches",
        icon: "beaker",
        url: "/inventory_manager/batches",
        tab_name: :all_batches
      },
      %{
        name: "Suppliers",
        icon: "users",
        url: "/inventory_manager/suppliers",
        tab_name: :suppliers
      },
      %{
        name: "Requisitions",
        icon: "document-text",
        url: "/inventory_manager/requisitions",
        tab_name: :requisitions
      },
      %{
        name: "Settings",
        icon: "cog-6-tooth",
        url: "/inventory_manager/settings",
        tab_name: :settings
      },
      %{
        name: "Consumption Analysis",
        icon: "chart-bar",
        url: "/inventory_manager/consumption_analysis",
        tab_name: :consumption_analysis
      },
      %{name: "Home", icon: "arrow-left", url: "/", tab_name: :home}
    ]
  end

  defp get_icon_name(icon), do: icon
  defp get_color_for_tab(:inventories_received), do: "green"
  defp get_color_for_tab(:in_store), do: "blue"
  defp get_color_for_tab(:inventories_issued), do: "orange"
  defp get_color_for_tab(:all_batches), do: "purple"
  defp get_color_for_tab(:suppliers), do: "red"
  defp get_color_for_tab(:requisitions), do: "cyan"
  defp get_color_for_tab(:settings), do: "indigo"
  defp get_color_for_tab(:consumption_analysis), do: "pink"
  defp get_color_for_tab(:home), do: "gray"
  defp get_color_for_tab(_), do: "gray"

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50 -m-4 sm:-m-6 p-4 sm:p-6">
      <div class="w-[95%] mx-auto space-y-6">
        <.dashboard_top_card
          title="Inventory Dashboard"
          subtitle={"Stock movement and supply health for #{month_label(@date_from)}"}
        />

        <.summary_card_grid cards={dashboard_cards(assigns)} />

        <div class="grid grid-cols-1 xl:grid-cols-3 gap-6">
          <div class="xl:col-span-2 bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
            <div class="mb-6">
              <h2 class="text-xl font-semibold text-gray-900">Quick actions</h2>
              <p class="text-sm text-gray-500 mt-1">
                Open inventory intake, issuance, and supply workflows.
              </p>
            </div>

            <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
              <%= for tab <- inventory_manager_tabs() do %>
                <.quick_action
                  label={tab.name}
                  icon={"hero-#{get_icon_name(tab.icon)}"}
                  href={tab.url}
                  color={get_color_for_tab(tab.tab_name)}
                />
              <% end %>
            </div>
          </div>

          <.recent_items
            title="Recent receipts"
            items={@recent_items}
            empty_message="No inventory receipts recorded for this month yet."
          />
        </div>
      </div>
    </div>
    """
  end

  defp dashboard_cards(assigns) do
    summary_cards_for(assigns.visible_summary_cards, %{
      inventory_items: {length(assigns.received), "Distinct receipts captured this month"},
      inventories_received: {length(assigns.received), "Inbound inventory records"},
      inventories_issued: {length(assigns.issued), "Outbound issues logged this month"},
      stock_alerts: {stock_alert_count(assigns.stock_alerts), "Near-expiry or low-stock alerts"}
    })
  end

  defp stock_alert_count(alerts) do
    length(alerts.near_expiry) + length(alerts.below_reorder)
  end

  defp recent_inventory_items(received) do
    received
    |> Enum.sort_by(& &1.inserted_at, {:desc, DateTime})
    |> Enum.take(5)
    |> Enum.map(fn item ->
      %{
        title: item.brand_name || item.generic_name || "Inventory item",
        subtitle: item.supplier || "Supplier not captured",
        badge: item.category || "Received",
        badge_color: "bg-emerald-100 text-emerald-700"
      }
    end)
  end

  defp month_label(date), do: Calendar.strftime(date, "%B %Y")

  defp current_month_range do
    today = Date.utc_today()
    {%{today | day: 1}, today}
  end

  defp inserted_in_range?(nil, _from, _to), do: false

  defp inserted_in_range?(inserted_at, from, to) do
    date = DateTime.to_date(inserted_at)
    Date.compare(date, from) != :lt and Date.compare(date, to) != :gt
  end
end
