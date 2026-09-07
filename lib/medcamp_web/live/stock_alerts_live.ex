defmodule MedcampWeb.StockAlertsLive do
  @moduledoc """
  On-mount hook to assign stock alerts for inventory manager and pharmacist views.
  """
  import Phoenix.Component

  def on_mount(:assign_stock_alerts, _params, _session, socket) do
    alerts = Medcamp.StockAlerts.list_all_alerts()
    alert_count = length(alerts.near_expiry) + length(alerts.below_reorder)

    socket =
      socket
      |> assign(:stock_alerts, alerts)
      |> assign(:stock_alert_count, alert_count)

    {:cont, socket}
  end
end
