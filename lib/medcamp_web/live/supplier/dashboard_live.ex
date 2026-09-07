defmodule MedcampWeb.Supplier.DashboardLive do
  use MedcampWeb, :supplier_live_view

  import MedcampWeb.ProcurementComponents,
    only: [status_badge: 1, registration_stepper: 1, deadline_alert: 1]

  alias Medcamp.Procurement.Dashboard
  alias MedcampWeb.Supplier.LiveHelpers

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
    case LiveHelpers.load_supplier(socket.assigns.current_user, create?: true) do
      {:ok, supplier, user} ->
        {:ok,
         socket
         |> LiveHelpers.maybe_assign_current_user(user)
         |> assign(:page_title, "Supplier Dashboard")
         |> assign_dashboard(supplier)}

      {:error, :missing_supplier} ->
        {:ok,
         socket
         |> put_flash(:error, "Your account is not linked to a supplier profile yet.")
         |> push_navigate(to: LiveHelpers.registration_path(:company))}
    end
  end

  @impl true
  def handle_info({event, _payload}, socket) when event in @refresh_events do
    {:noreply, assign_dashboard(socket, socket.assigns.supplier.id)}
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  defp assign_dashboard(socket, supplier_or_id) do
    supplier =
      case supplier_or_id do
        %{id: id} -> load_supplier(id)
        id when is_integer(id) -> load_supplier(id)
      end

    socket
    |> assign(:supplier, supplier)
    |> assign(:stats, Dashboard.supplier_stats(supplier.id))
    |> assign(:upcoming_rfqs, Dashboard.upcoming_deadlines(supplier.id, 14))
    |> assign(:activity, Dashboard.supplier_activity(supplier.id, 5))
    |> assign(:registration_progress, LiveHelpers.registration_progress(supplier))
  end

  defp load_supplier(id), do: Medcamp.Procurement.Suppliers.get_supplier!(id)

  defp supplier_status_message("approved"),
    do: "Your supplier profile is active and ready for procurement activity."

  defp supplier_status_message("under_review"),
    do: "Your onboarding file is under review by the procurement team."

  defp supplier_status_message("rejected"),
    do: "Your last submission needs updates before it can move forward."

  defp supplier_status_message(_),
    do: "Complete your supplier profile to unlock the full procurement workflow."

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="rounded-[2rem] bg-[#373896] px-6 py-7 text-white shadow-xl shadow-[#373896]/15">
        <p class="text-xs font-semibold uppercase tracking-[0.28em] text-white/70">
          Supplier workspace
        </p>
        <div class="mt-3 flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
          <div class="space-y-2">
            <h1 class="text-3xl font-semibold tracking-tight">
              {@supplier.legal_name || @supplier.name || "Supplier"} dashboard
            </h1>
            <p class="max-w-2xl text-sm leading-6 text-white/80">
              {supplier_status_message(@supplier.status)}
            </p>
          </div>
        </div>
      </div>

      <div class="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        <MedcampWeb.ProcurementComponents.stat_card
          label="Open requests for quotation"
          value={@stats.open_rfqs}
          sub="Invitations awaiting action"
        />
        <MedcampWeb.ProcurementComponents.stat_card
          label="Submitted Quotes"
          value={@stats.submitted_quotes}
          sub="Quotes in the pipeline"
        />
        <MedcampWeb.ProcurementComponents.stat_card
          label="Open POs"
          value={@stats.open_purchase_orders}
          sub="Purchase orders in progress"
        />
        <MedcampWeb.ProcurementComponents.stat_card
          label="Pending Invoices"
          value={@stats.pending_invoices}
          sub="Invoices awaiting GRN or approval"
        />
      </div>

      <.deadline_alert rfqs={@upcoming_rfqs} />

      <div class="grid gap-6">
        <div class="space-y-6">
          <div
            :if={@supplier.status != "approved"}
            class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm"
          >
            <div class="flex items-center justify-between gap-3">
              <div>
                <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
                  Registration status
                </p>
                <h2 class="mt-2 text-xl font-semibold text-slate-900">
                  Supplier onboarding progress
                </h2>
              </div>
              <.status_badge status={@supplier.status} />
            </div>

            <div class="mt-5">
              <.registration_stepper
                current={LiveHelpers.next_incomplete_step(@registration_progress)}
                progress={@registration_progress}
              />
            </div>

            <div class="mt-5 flex flex-wrap gap-3">
              <.link
                navigate={
                  LiveHelpers.registration_path(
                    LiveHelpers.next_incomplete_step(@registration_progress)
                  )
                }
                class="rounded-xl bg-[#373896] px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-[#2d2d7a]"
              >
                Continue registration
              </.link>
              <.link
                navigate={~p"/supplier/profile"}
                class="rounded-xl border border-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-700 transition hover:bg-slate-50"
              >
                Open profile
              </.link>
            </div>
          </div>

          <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
            <div class="flex items-center justify-between gap-3">
              <div>
                <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
                  Activity
                </p>
                <h2 class="mt-2 text-xl font-semibold text-slate-900">Latest supplier events</h2>
              </div>
            </div>

            <div class="mt-5 space-y-3">
              <div
                :for={activity <- @activity}
                class="rounded-2xl border border-slate-100 bg-slate-50 px-4 py-4"
              >
                <div class="flex items-start justify-between gap-3">
                  <div>
                    <p class="text-sm font-semibold text-slate-900">{activity.title}</p>
                    <p class="mt-1 text-sm text-slate-500">
                      {activity.type |> to_string() |> String.replace("_", " ") |> String.capitalize()}
                    </p>
                  </div>
                  <.status_badge status={activity.status} />
                </div>

                <div class="mt-3 flex items-center justify-between gap-3">
                  <p class="text-xs text-slate-400">{LiveHelpers.format_datetime(activity.at)}</p>
                  <.link
                    navigate={LiveHelpers.activity_path(activity)}
                    class="text-sm font-semibold text-[#373896] hover:text-[#2d2d7a]"
                  >
                    Open
                  </.link>
                </div>
              </div>

              <div
                :if={Enum.empty?(@activity)}
                class="rounded-2xl border border-dashed border-slate-200 px-4 py-6 text-sm text-slate-500"
              >
                Activity will appear here as you submit quotes, receive purchase orders, and send invoices.
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
