defmodule MedcampWeb.ProcurementPortal do
  @moduledoc """
  Shared supplier/procurement portal on-mount hook.
  """

  import Ecto.Query, warn: false
  import Phoenix.Component
  import Phoenix.LiveView

  alias Medcamp.Repo
  alias Medcamp.Suppliers.{Supplier, SupplierDocument}

  alias Medcamp.Procurement.{
    Dashboard,
    Notifications,
    ProformaInvoice,
    PurchaseOrder,
    Quote,
    Invoice,
    ShipmentAdvice,
    GoodsReceivedNote
  }

  @refresh_events ~w(
    registration_submitted supplier_approved supplier_rejected supplier_info_requested
    rfq_sent rfq_closed quote_submitted quote_accepted quote_rejected
    proforma_submitted proforma_accepted proforma_rejected
    po_pending_approval po_approved po_sent po_acknowledged
    invoice_submitted invoice_approved invoice_rejected invoice_grn_confirmed
    shipment_submitted grn_flagged grn_finalised
  )a

  def on_mount(:supplier, params, _session, socket) do
    {:cont, build_socket(socket, :supplier, params)}
  end

  def on_mount(:procurement, params, _session, socket) do
    {:cont, build_socket(socket, :procurement, params)}
  end

  def active_tab?(current_tab, nav_key) do
    normalize_tab(current_tab) == normalize_tab(nav_key)
  end

  def item_count(nil), do: nil
  def item_count(count) when is_integer(count) and count > 0, do: count
  def item_count(_), do: nil

  def nav_item_classes(current_tab, nav_key, disabled?) do
    base =
      "group flex items-start justify-between gap-3 rounded-2xl px-4 py-3 text-sm transition"

    cond do
      active_tab?(current_tab, nav_key) ->
        base <>
          " bg-[#185b5f] text-white shadow-[0_12px_30px_rgba(24,91,95,0.2)]"

      disabled? ->
        base <> " cursor-not-allowed bg-slate-50 text-slate-400"

      true ->
        base <> " text-slate-600 hover:bg-white hover:text-slate-900 hover:shadow-sm"
    end
  end

  def nav_count_classes(current_tab, nav_key) do
    if active_tab?(current_tab, nav_key) do
      "inline-flex min-w-6 items-center justify-center rounded-full bg-white/15 px-2 py-1 text-xs font-semibold text-white"
    else
      "inline-flex min-w-6 items-center justify-center rounded-full bg-slate-200 px-2 py-1 text-xs font-semibold text-slate-700"
    end
  end

  def initials(nil), do: "GH"

  def initials(name) when is_binary(name) do
    name
    |> String.split(~r/\s+/, trim: true)
    |> Enum.take(2)
    |> Enum.map_join(&String.first/1)
    |> case do
      "" -> "GH"
      value -> String.upcase(value)
    end
  end

  def notification_title(notification) do
    Map.get(notification, :title) || Map.get(notification, "title") ||
      notification
      |> Map.get(:type, Map.get(notification, "type", "update"))
      |> to_string()
      |> String.replace("_", " ")
      |> String.capitalize()
  end

  def notification_body(notification) do
    Map.get(notification, :body) || Map.get(notification, "body") || "Portal activity updated."
  end

  defp build_socket(socket, portal, params) do
    socket
    |> assign(:portal_kind, portal)
    |> assign(
      :active_tab,
      infer_active_tab(portal, socket.view, socket.assigns[:live_action], params)
    )
    |> assign(:portal_shell_title, portal_title(portal))
    |> assign(:portal_switch_links, portal_switch_links(portal))
    |> refresh_portal_assigns()
    |> maybe_subscribe()
    |> attach_hook(:procurement_portal_updates, :handle_info, &handle_portal_message/2)
  end

  defp maybe_subscribe(socket) do
    if connected?(socket) do
      Enum.each(subscription_topics(socket), &Phoenix.PubSub.subscribe(Medcamp.PubSub, &1))
    end

    socket
  end

  defp subscription_topics(
         %{assigns: %{current_user: %{id: user_id}, portal_kind: :supplier}} = socket
       ) do
    topics = ["user:#{user_id}:notifications"]

    case socket.assigns.current_user.supplier_id do
      nil -> topics
      supplier_id -> ["supplier:#{supplier_id}" | topics]
    end
  end

  defp subscription_topics(%{assigns: %{current_user: %{id: user_id}, portal_kind: :procurement}}) do
    ["procurement:all", "user:#{user_id}:notifications"]
  end

  defp subscription_topics(_), do: []

  defp handle_portal_message({:notification, _notification}, socket) do
    {:cont, refresh_portal_assigns(socket)}
  end

  defp handle_portal_message({event, _payload}, socket) when event in @refresh_events do
    {:cont, refresh_portal_assigns(socket)}
  end

  defp handle_portal_message(_message, socket), do: {:cont, socket}

  defp refresh_portal_assigns(%{assigns: %{current_user: nil}} = socket) do
    socket
    |> assign(:unread_count, 0)
    |> assign(:portal_notifications, [])
    |> assign(:sidebar_counts, %{})
    |> assign(:portal_sections, portal_sections(socket.assigns.portal_kind, %{}))
  end

  defp refresh_portal_assigns(%{assigns: %{portal_kind: :supplier, current_user: user}} = socket) do
    counts = supplier_sidebar_counts(user.supplier_id)

    socket
    |> assign(:sidebar_counts, counts)
    |> assign(:unread_count, Notifications.unread_count(user.id))
    |> assign(:portal_notifications, Notifications.list_for_user(user.id, limit: 6))
    |> assign(:portal_sections, portal_sections(:supplier, counts))
  end

  defp refresh_portal_assigns(
         %{assigns: %{portal_kind: :procurement, current_user: user}} = socket
       ) do
    counts = procurement_sidebar_counts()

    socket
    |> assign(:sidebar_counts, counts)
    |> assign(:unread_count, Notifications.unread_count(user.id))
    |> assign(:portal_notifications, Notifications.list_for_user(user.id, limit: 6))
    |> assign(:portal_sections, portal_sections(:procurement, counts))
  end

  defp supplier_sidebar_counts(nil) do
    %{
      rfqs: 0,
      quotes: 0,
      proformas: 0,
      purchase_orders: 0,
      invoices: 0,
      shipments: 0
    }
  end

  defp supplier_sidebar_counts(supplier_id) do
    stats = Dashboard.supplier_stats(supplier_id)

    proformas =
      from(p in ProformaInvoice,
        where: p.supplier_id == ^supplier_id and p.status in ["draft", "submitted", "accepted"]
      )
      |> Repo.aggregate(:count, :id)

    shipments =
      from(s in ShipmentAdvice,
        where: s.supplier_id == ^supplier_id and s.status in ["submitted", "received"]
      )
      |> Repo.aggregate(:count, :id)

    docs =
      from(d in SupplierDocument, where: d.supplier_id == ^supplier_id)
      |> Repo.aggregate(:count, :id)

    %{
      dashboard: 0,
      profile: docs,
      rfqs: stats.open_rfqs,
      quotes: stats.submitted_quotes,
      proformas: proformas,
      purchase_orders: stats.open_purchase_orders,
      invoices: stats.pending_invoices,
      shipments: shipments
    }
  end

  defp procurement_sidebar_counts do
    stats = Dashboard.procurement_stats()

    suppliers_total =
      from(s in Supplier)
      |> Repo.aggregate(:count, :id)

    purchase_orders_pending =
      from(p in PurchaseOrder, where: p.status in ["draft", "pending_approval", "approved"])
      |> Repo.aggregate(:count, :id)

    quote_inbox =
      from(q in Quote, where: q.status in ["submitted", "under_review"])
      |> Repo.aggregate(:count, :id)

    invoice_inbox =
      from(i in Invoice, where: i.status in ["submitted", "pending_grn", "grn_confirmed"])
      |> Repo.aggregate(:count, :id)

    grn_attention =
      from(g in GoodsReceivedNote, where: g.status in ["pending_review", "flagged"])
      |> Repo.aggregate(:count, :id)

    %{
      dashboard: length(Dashboard.action_queue()),
      suppliers: suppliers_total,
      onboarding: stats.pending_registrations,
      rfqs: stats.active_rfqs,
      purchase_orders: purchase_orders_pending,
      quotes: quote_inbox,
      invoices: invoice_inbox,
      grn: grn_attention
    }
  end

  defp portal_sections(:supplier, _counts) do
    [
      %{
        title: "Setup",
        items: [
          nav_item(:dashboard, "Home", "/supplier/dashboard"),
          nav_item(:profile, "Company profile", "/supplier/profile")
        ]
      },
      %{
        title: "Order flow",
        items: [
          nav_item(:rfqs, "1. Request for quotation inbox", "/supplier/rfqs"),
          nav_item(:purchase_orders, "2. Purchase orders", "/supplier/purchase-orders"),
          nav_item(:invoices, "3. Invoices", "/supplier/order-flow/invoices"),
          nav_item(:shipments, "4. Shipment advice", "/supplier/order-flow/shipments")
        ]
      }
    ]
  end

  defp portal_sections(:procurement, _counts) do
    [
      %{
        title: "Start here",
        items: [
          nav_item(:dashboard, "Home", "/procurement/dashboard"),
          nav_item(:suppliers, "Suppliers", "/procurement/suppliers"),
          nav_item(:onboarding, "Pending onboarding", "/procurement/onboarding"),
          nav_item(:requisitions, "Requisitions", "/procurement/requisitions")
        ]
      },
      %{
        title: "Buying flow",
        items: [
          nav_item(:rfqs, "1. Requests for quotation", "/procurement/rfqs"),
          nav_item(:purchase_orders, "2. Purchase orders", "/procurement/purchase-orders")
        ]
      },
      %{
        title: "Receiving flow",
        items: [
          nav_item(:invoices, "3. Supplier invoices", "/procurement/invoices"),
          nav_item(:grn, "4. Goods received", "/procurement/grn")
        ]
      }
    ]
  end

  defp portal_sections(_, _), do: []

  defp nav_item(key, label, path, opts \\ []) do
    %{
      key: key,
      label: label,
      path: path,
      count: Keyword.get(opts, :count),
      disabled_label: Keyword.get(opts, :disabled_label)
    }
  end

  defp portal_title(:supplier), do: "Supplier Portal"
  defp portal_title(:procurement), do: "Procurement Workspace"

  defp portal_switch_links(:supplier) do
    [
      %{label: "Hospital", path: "/todos", current: false},
      %{label: "Supplier", path: "/supplier/dashboard", current: true}
    ]
  end

  defp portal_switch_links(:procurement) do
    [
      %{label: "Hospital", path: "/todos", current: false},
      %{label: "Procurement", path: "/procurement/dashboard", current: true}
    ]
  end

  defp infer_active_tab(:supplier, MedcampWeb.Supplier.DashboardLive, _, _), do: :dashboard
  defp infer_active_tab(:supplier, MedcampWeb.Supplier.ProfileLive, _, _), do: :profile
  defp infer_active_tab(:supplier, MedcampWeb.Supplier.RegistrationLive, _, _), do: :profile
  defp infer_active_tab(:supplier, MedcampWeb.Supplier.RfqInboxLive, _, _), do: :rfqs
  defp infer_active_tab(:supplier, MedcampWeb.Supplier.QuoteLive, _, _), do: :quotes
  defp infer_active_tab(:supplier, MedcampWeb.Supplier.ProformaLive, _, _), do: :proformas

  defp infer_active_tab(:supplier, MedcampWeb.Supplier.PurchaseOrderLive, _, _),
    do: :purchase_orders

  defp infer_active_tab(:supplier, MedcampWeb.Supplier.InvoiceLive, _, _), do: :invoices
  defp infer_active_tab(:supplier, MedcampWeb.Supplier.ShipmentLive, _, _), do: :shipments
  defp infer_active_tab(:procurement, MedcampWeb.Procurement.DashboardLive, _, _), do: :dashboard
  defp infer_active_tab(:procurement, MedcampWeb.Procurement.SupplierListLive, _, _), do: :suppliers

  defp infer_active_tab(:procurement, MedcampWeb.Procurement.SupplierDetailLive, _, _),
    do: :suppliers

  defp infer_active_tab(:procurement, MedcampWeb.Procurement.OnboardingQueueLive, _, _),
    do: :onboarding

  defp infer_active_tab(:procurement, MedcampWeb.Procurement.RfqListLive, _, _), do: :rfqs
  defp infer_active_tab(:procurement, MedcampWeb.Procurement.RfqFormLive, _, _), do: :rfqs
  defp infer_active_tab(:procurement, MedcampWeb.Procurement.RfqDetailLive, _, _), do: :rfqs
  defp infer_active_tab(:procurement, MedcampWeb.Procurement.QuoteComparisonLive, _, _), do: :quotes
  defp infer_active_tab(:procurement, MedcampWeb.Procurement.PoListLive, _, _), do: :purchase_orders
  defp infer_active_tab(:procurement, MedcampWeb.Procurement.PoFormLive, _, _), do: :purchase_orders

  defp infer_active_tab(:procurement, MedcampWeb.Procurement.PoDetailLive, _, _),
    do: :purchase_orders

  defp infer_active_tab(:procurement, MedcampWeb.Procurement.InvoiceListLive, _, _), do: :invoices
  defp infer_active_tab(:procurement, MedcampWeb.Procurement.InvoiceDetailLive, _, _), do: :invoices
  defp infer_active_tab(:procurement, MedcampWeb.Procurement.GrnListLive, _, _), do: :grn
  defp infer_active_tab(:procurement, MedcampWeb.Procurement.GrnFormLive, _, _), do: :grn
  defp infer_active_tab(:procurement, MedcampWeb.Procurement.GrnDetailLive, _, _), do: :grn
  defp infer_active_tab(:procurement, MedcampWeb.RequisitionLive.Index, _, _), do: :requisitions
  defp infer_active_tab(:procurement, MedcampWeb.RequisitionLive.Show, _, _), do: :requisitions
  defp infer_active_tab(_, _, _, _), do: :dashboard

  defp normalize_tab(:overview), do: :dashboard
  defp normalize_tab(value), do: value
end
