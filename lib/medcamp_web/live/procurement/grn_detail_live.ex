defmodule MedcampWeb.Procurement.GrnDetailLive do
  use MedcampWeb, :procurement_live_view

  import MedcampWeb.ProcurementComponents,
    only: [status_badge: 1, grn_summary_strip: 1, pipeline_tracker: 1]

  alias Medcamp.Procurement.GoodsReceived
  alias MedcampWeb.Procurement.LiveHelpers

  @refresh_events ~w(grn_flagged grn_finalised invoice_grn_confirmed)a

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "GRN Detail")}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    {:noreply, assign_grn(socket, id)}
  end

  @impl true
  def handle_info({event, _payload}, socket) when event in @refresh_events do
    {:noreply, assign_grn(socket, socket.assigns.grn.id)}
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  defp assign_grn(socket, id) do
    grn = GoodsReceived.get_grn!(id)
    summary = GoodsReceived.compute_summary(grn)

    socket
    |> assign(:grn, grn)
    |> assign(:summary, %{
      accepted: summary.accepted,
      partial: summary.partial,
      quantity: LiveHelpers.decimal_to_string(summary.quantity_received),
      value: LiveHelpers.money(summary.value)
    })
    |> assign(:page_title, grn.reference)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6 print:space-y-4">
      <div class="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
        <div class="space-y-2">
          <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">GRN detail</p>
          <h1 class="text-3xl font-semibold tracking-tight text-slate-900">{@grn.reference}</h1>
          <p class="text-sm leading-6 text-slate-500">
            Read-only received-goods summary for invoice {@grn.invoice && @grn.invoice.reference}.
          </p>
        </div>
        <.status_badge status={@grn.status} />
      </div>

      <.pipeline_tracker
        steps={LiveHelpers.pipeline_steps()}
        current={:grn}
        document_ids={
          %{
            purchase_order: "/procurement/purchase-orders/#{@grn.purchase_order_id}",
            invoice: "/procurement/invoices/#{@grn.invoice_id}",
            grn: "/procurement/grn/#{@grn.id}"
          }
        }
      />

      <.grn_summary_strip summary={@summary} />

      <div class="space-y-6">
        <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
          <div class="overflow-x-auto">
            <table class="w-full min-w-[720px] table-auto text-left text-sm">
              <thead class="border-b border-slate-200 text-slate-500">
                <tr>
                  <th class="pb-3 pr-6 font-semibold">Description</th>
                  <th class="w-28 pb-3 pr-6 text-right font-semibold">PO qty</th>
                  <th class="w-28 pb-3 pr-6 text-right font-semibold">Received</th>
                  <th class="w-28 pb-3 pr-6 text-right font-semibold">Variance</th>
                  <th class="w-40 pb-3 font-semibold">Condition</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-100">
                <tr :for={item <- @grn.items} class="align-top hover:bg-slate-50/60">
                  <td class="py-4 pr-6">
                    <p
                      class="whitespace-normal break-words font-medium leading-6 text-slate-900"
                      title={item.description}
                    >
                      {item.description}
                    </p>
                  </td>
                  <td class="py-4 pr-6 text-right tabular-nums text-slate-600">
                    {LiveHelpers.decimal_to_string(item.po_quantity)}
                  </td>
                  <td class="py-4 pr-6 text-right tabular-nums text-slate-600">
                    {LiveHelpers.decimal_to_string(item.quantity_received)}
                  </td>
                  <td class="py-4 pr-6 text-right tabular-nums text-slate-600">
                    {LiveHelpers.decimal_to_string(item.variance)}
                  </td>
                  <td class="py-4 text-slate-600 whitespace-nowrap">
                    {String.capitalize(item.condition || "accepted")}
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
          <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
            Receipt details
          </p>
          <div class="mt-5 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            <div class="rounded-2xl bg-slate-50 px-4 py-3">
              <p class="text-xs font-semibold uppercase tracking-[0.22em] text-slate-400">
                Received date
              </p>
              <p class="mt-2 text-sm font-medium text-slate-800">
                {LiveHelpers.format_date(@grn.received_date)}
              </p>
            </div>
            <div class="rounded-2xl bg-slate-50 px-4 py-3">
              <p class="text-xs font-semibold uppercase tracking-[0.22em] text-slate-400">
                Received time
              </p>
              <p class="mt-2 text-sm font-medium text-slate-800">
                {@grn.received_time || "N/A"}
              </p>
            </div>
            <div class="rounded-2xl bg-slate-50 px-4 py-3">
              <p class="text-xs font-semibold uppercase tracking-[0.22em] text-slate-400">
                Overall condition
              </p>
              <p class="mt-2 text-sm font-medium text-slate-800">
                {@grn.overall_condition || "N/A"}
              </p>
            </div>
            <div class="rounded-2xl bg-slate-50 px-4 py-3">
              <p class="text-xs font-semibold uppercase tracking-[0.22em] text-slate-400">
                Packages received
              </p>
              <p class="mt-2 text-sm font-medium text-slate-800">
                {@grn.packages_received || 0}
              </p>
            </div>
            <div class="rounded-2xl bg-slate-50 px-4 py-3">
              <p class="text-xs font-semibold uppercase tracking-[0.22em] text-slate-400">
                Received by
              </p>
              <p class="mt-2 text-sm font-medium text-slate-800">
                {(@grn.received_by && @grn.received_by.name) || "N/A"}
              </p>
            </div>
            <div class="rounded-2xl bg-slate-50 px-4 py-3">
              <p class="text-xs font-semibold uppercase tracking-[0.22em] text-slate-400">
                Finalised by
              </p>
              <p class="mt-2 text-sm font-medium text-slate-800">
                {(@grn.finalised_by && @grn.finalised_by.name) || "Pending"}
              </p>
            </div>
          </div>
        </div>

        <div
          :if={
            LiveHelpers.present?(@grn.discrepancy_description) or
              LiveHelpers.present?(@grn.delivery_remarks)
          }
          class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm"
        >
          <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">Remarks</p>
          <p
            :if={LiveHelpers.present?(@grn.delivery_remarks)}
            class="mt-4 text-sm leading-6 text-slate-600"
          >
            {@grn.delivery_remarks}
          </p>
          <p
            :if={LiveHelpers.present?(@grn.discrepancy_description)}
            class="mt-4 text-sm leading-6 text-slate-600"
          >
            {@grn.discrepancy_description}
          </p>
        </div>
      </div>
    </div>
    """
  end
end
