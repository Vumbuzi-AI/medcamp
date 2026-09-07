defmodule MedcampWeb.StockAlertComponents do
  @moduledoc """
  Components for stock alert notifications.
  """
  use Phoenix.Component
  use MedcampWeb, :verified_routes

  attr :stock_alerts, :map, default: %{near_expiry: [], below_reorder: []}
  attr :alert_count, :integer, default: 0

  attr :context, :atom,
    default: :pharmacist,
    doc: ":pharmacist, :inventory_manager, or :admin - controls which action links to show"

  def stock_alerts_banner(assigns) do
    ~H"""
    <div :if={@alert_count > 0} class="mx-4 mt-4 md:mx-8 md:mt-6 lg:ml-72 lg:mr-8">
      <details
        class="group rounded-lg border w-[98%] mx-auto border-amber-200/80 bg-gradient-to-r from-amber-50 to-orange-50/50 shadow-sm [&_summary::-webkit-details-marker]:hidden"
        id="stock-alerts-banner"
      >
        <summary class="flex cursor-pointer list-none items-center justify-between gap-3 px-3 py-2 hover:bg-amber-100/50 rounded-lg transition-colors">
          <div class="flex items-center gap-2 min-w-0">
            <Heroicons.icon
              name="exclamation-triangle"
              type="outline"
              class="h-4 w-4 shrink-0 text-amber-600"
            />
            <span class="text-sm font-medium text-amber-900 truncate">
              {@alert_count} stock alert{if @alert_count == 1, do: "", else: "s"} — items need attention
            </span>
            <Heroicons.icon
              name="chevron-down"
              type="outline"
              class="h-4 w-4 shrink-0 text-amber-600 transition-transform group-open:rotate-180"
            />
          </div>
          <div class="flex gap-1.5 shrink-0">
            <.link
              :if={@context == :pharmacist}
              navigate={~p"/pharmacist/drugs"}
              class="rounded-md bg-amber-600 px-2.5 py-1 text-xs font-medium text-white hover:bg-amber-700 transition-colors"
              onclick="event.stopPropagation()"
            >
              View drugs
            </.link>
            <.link
              :if={@context == :inventory_manager}
              navigate={~p"/inventory_manager/inventories_received"}
              class="rounded-md bg-amber-600 px-2.5 py-1 text-xs font-medium text-white hover:bg-amber-700 transition-colors"
              onclick="event.stopPropagation()"
            >
              View inventory
            </.link>
            <.link
              :if={@context == :admin}
              navigate={~p"/admin/drugs"}
              class="rounded-md bg-amber-600 px-2.5 py-1 text-xs font-medium text-white hover:bg-amber-700 transition-colors"
              onclick="event.stopPropagation()"
            >
              View drugs
            </.link>
          </div>
        </summary>

        <div id="stock-alerts-details" class="space-y-3 border-t border-amber-200/50 px-3 py-3">
          <div :if={length(@stock_alerts.near_expiry || []) > 0}>
            <h4 class="mb-2 text-xs font-semibold uppercase tracking-wider text-amber-800">
              Near expiry (≤ 3 months)
            </h4>
            <ul class="space-y-1.5 text-sm text-amber-900">
              <li
                :for={alert <- Enum.take(@stock_alerts.near_expiry || [], 10)}
                class="flex flex-wrap gap-x-2"
              >
                <span class="font-medium">{alert.item_name}</span>
                <span class="text-amber-700">
                  Batch {alert.batch_number} · {alert.days_to_expiry} days left {if alert.remaining_quantity,
                    do: " · #{alert.remaining_quantity} units",
                    else: ""}
                </span>
              </li>
              <li :if={length(@stock_alerts.near_expiry || []) > 10} class="text-amber-600 text-xs">
                +{length(@stock_alerts.near_expiry) - 10} more
              </li>
            </ul>
          </div>

          <div :if={length(@stock_alerts.below_reorder || []) > 0}>
            <h4 class="mb-2 text-xs font-semibold uppercase tracking-wider text-amber-800">
              Below reorder level
            </h4>
            <ul class="space-y-1.5 text-sm text-amber-900">
              <li
                :for={alert <- Enum.take(@stock_alerts.below_reorder || [], 10)}
                class="flex flex-wrap gap-x-2"
              >
                <span class="font-medium">{alert.item_name}</span>
                <span class="text-amber-700">
                  {alert.current_quantity} {alert[:unit] || "units"} (reorder at {alert.reorder_level})
                </span>
              </li>
              <li :if={length(@stock_alerts.below_reorder || []) > 10} class="text-amber-600 text-xs">
                +{length(@stock_alerts.below_reorder) - 10} more
              </li>
            </ul>
          </div>
        </div>
      </details>
    </div>
    """
  end
end
