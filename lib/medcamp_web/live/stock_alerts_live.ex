defmodule MedcampWeb.StockAlertsLive do
  @moduledoc """
  On-mount hook to assign stock alerts for inventory manager and pharmacist views.
  """
  import Phoenix.Component

  def on_mount(:assign_stock_alerts, _params, _session, socket) do
    # Some LiveViews (notably a superadmin or a disconnected mount) can be
    # reached before a tenant has been established. Stock tables are tenant
    # scoped, so do not query them until the current process has an org.
    alerts =
      if Medcamp.Tenancy.current_org_id() do
        Medcamp.StockAlerts.list_all_alerts()
      else
        %{near_expiry: [], below_reorder: []}
      end

    alert_count = length(alerts.near_expiry) + length(alerts.below_reorder)

    socket =
      socket
      |> assign(:stock_alerts, alerts)
      |> assign(:stock_alert_count, alert_count)

    {:cont, socket}
  end
end
