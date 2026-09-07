defmodule MedcampWeb.Procurement.DashboardLive do
  use MedcampWeb, :procurement_live_view

  import MedcampWeb.ProcurementComponents, only: [status_badge: 1]

  alias Medcamp.Procurement.{Dashboard, Quotes}

  @refresh_events ~w(
    registration_submitted supplier_approved supplier_rejected supplier_info_requested
    rfq_sent rfq_closed quote_submitted quote_accepted quote_rejected
    proforma_submitted proforma_accepted proforma_rejected
    po_pending_approval po_approved po_sent po_acknowledged
    invoice_submitted invoice_approved invoice_rejected invoice_grn_confirmed
    shipment_submitted grn_flagged grn_finalised
  )a

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Procurement Dashboard")
     |> assign_dashboard()}
  end

  @impl true
  def handle_info({event, _payload}, socket) when event in @refresh_events do
    {:noreply, assign_dashboard(socket)}
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  defp assign_dashboard(socket) do
    stats = Dashboard.procurement_stats()
    action_queue = Dashboard.action_queue() |> Enum.map(&Map.put(&1, :path, action_path(&1)))

    socket
    |> assign(:stats, stats)
    |> assign(:action_queue, action_queue)
  end

  defp action_path(%{kind: :supplier, resource_id: id}), do: "/procurement/onboarding/#{id}"

  defp action_path(%{kind: :invoice, resource_id: id}), do: "/procurement/invoices/#{id}"

  defp action_path(%{kind: :grn, resource_id: id}), do: "/procurement/grn/#{id}"

  defp action_path(%{kind: :quote, resource_id: id}) do
    case Quotes.get_quote(id) do
      nil -> "/procurement/dashboard"
      quote -> "/procurement/quotes/#{quote.rfq_id}"
    end
  end

  defp action_path(_), do: "/procurement/dashboard"

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="flex flex-col gap-3 lg:flex-row lg:items-end lg:justify-between">
        <div class="space-y-2">
          <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">Overview</p>
          <h1 class="text-3xl font-semibold tracking-tight text-slate-900">Procurement workspace</h1>
          <p class="max-w-3xl text-sm leading-6 text-slate-500">
            Monitor onboarding, sourcing, invoice approvals, and goods receipt activity from one place.
          </p>
        </div>
      </div>

      <div
        :if={@stats.pending_registrations > 0}
        class="rounded-2xl border border-amber-200 bg-amber-50 px-5 py-4 text-sm text-amber-800"
      >
        <span class="font-semibold">Attention:</span>
        {@stats.pending_registrations} supplier registrations still need review.
      </div>

      <div class="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        <MedcampWeb.ProcurementComponents.stat_card
          label="Pending Registrations"
          value={@stats.pending_registrations}
          sub="Suppliers waiting for onboarding action"
        />
        <MedcampWeb.ProcurementComponents.stat_card
          label="Active requests for quotation"
          value={@stats.active_rfqs}
          sub="Requests for quotation currently in circulation"
        />
        <MedcampWeb.ProcurementComponents.stat_card
          label="Quotes Awaiting"
          value={@stats.quotes_awaiting}
          sub="Submitted quotes awaiting review"
        />
        <MedcampWeb.ProcurementComponents.stat_card
          label="Invoices Awaiting"
          value={@stats.invoices_awaiting}
          sub="Invoices queued for GRN or approval"
        />
      </div>

      <div class="grid gap-6">
        <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
          <div class="flex items-center justify-between gap-3">
            <div>
              <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
                Action queue
              </p>
              <h2 class="mt-2 text-xl font-semibold text-slate-900">Items needing attention</h2>
            </div>
            <span class="rounded-full bg-slate-100 px-3 py-2 text-sm font-semibold text-slate-700">
              {length(@action_queue)} open items
            </span>
          </div>

          <div class="mt-5 space-y-3">
            <div
              :for={item <- @action_queue}
              class="rounded-2xl border border-slate-100 bg-slate-50 px-4 py-4"
            >
              <div class="flex items-start justify-between gap-3">
                <div>
                  <p class="text-sm font-semibold text-slate-900">{item.reference}</p>
                  <p class="mt-1 text-sm text-slate-500">
                    {item.kind |> to_string() |> String.replace("_", " ") |> String.capitalize()}
                  </p>
                </div>
                <.status_badge status={if item.priority == :high, do: :flagged, else: :pending} />
              </div>

              <div class="mt-3 flex items-center justify-between gap-3">
                <p class="text-xs text-slate-400">
                  {if item.priority == :high, do: "High priority", else: "Normal priority"}
                </p>
                <.link
                  navigate={item.path}
                  class="text-sm font-semibold text-[#373896] hover:text-[#2d2d7a]"
                >
                  Open
                </.link>
              </div>
            </div>

            <div
              :if={Enum.empty?(@action_queue)}
              class="rounded-2xl border border-dashed border-slate-200 px-4 py-8 text-sm text-slate-500"
            >
              The action queue is clear right now.
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
