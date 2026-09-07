defmodule MedcampWeb.Procurement.PoDetailLive do
  use MedcampWeb, :procurement_live_view

  import MedcampWeb.ProcurementComponents, only: [status_badge: 1, pipeline_tracker: 1]

  alias Medcamp.Procurement.PurchaseOrders
  alias MedcampWeb.Procurement.LiveHelpers

  @refresh_events ~w(po_pending_approval po_approved po_sent po_acknowledged)a

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Purchase Order Detail")}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    {:noreply, assign_po(socket, id)}
  end

  @impl true
  def handle_event("approve", %{"id" => id}, socket) do
    case PurchaseOrders.get_purchase_order(id) do
      nil ->
        {:noreply, put_flash(socket, :error, "Purchase order not found.")}

      po ->
        case PurchaseOrders.approve(po, socket.assigns.current_user) do
          {:ok, _po} ->
            {:noreply,
             socket
             |> put_flash(:info, "Purchase order approved.")
             |> assign_po(id)}

          _ ->
            {:noreply, put_flash(socket, :error, "Unable to approve that purchase order.")}
        end
    end
  end

  def handle_event("send", %{"id" => id}, socket) do
    case PurchaseOrders.get_purchase_order(id) do
      nil ->
        {:noreply, put_flash(socket, :error, "Purchase order not found.")}

      po ->
        case PurchaseOrders.send_to_supplier(po) do
          {:ok, _po} ->
            {:noreply,
             socket
             |> put_flash(:info, "Purchase order sent to supplier.")
             |> assign_po(id)}

          _ ->
            {:noreply, put_flash(socket, :error, "Unable to send that purchase order.")}
        end
    end
  end

  @impl true
  def handle_info({event, _payload}, socket) when event in @refresh_events do
    {:noreply, assign_po(socket, socket.assigns.po.id)}
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  defp assign_po(socket, id) do
    po = PurchaseOrders.get_purchase_order!(id)

    socket
    |> assign(:po, po)
    |> assign(:page_title, po.reference)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
        <div class="space-y-2">
          <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
            Purchase order detail
          </p>
          <h1 class="text-3xl font-semibold tracking-tight text-slate-900">{@po.reference}</h1>
          <p class="text-sm leading-6 text-slate-500">
            Review approval status, checklist completion, and send the PO to the supplier when ready.
          </p>
        </div>
        <.status_badge status={@po.status} />
      </div>

      <.pipeline_tracker
        steps={LiveHelpers.pipeline_steps()}
        current={:purchase_order}
        document_ids={
          %{
            rfq: @po.rfq_id && "/procurement/rfqs/#{@po.rfq_id}",
            purchase_order: "/procurement/purchase-orders/#{@po.id}"
          }
          |> Enum.reject(fn {_key, value} -> LiveHelpers.blank?(value) end)
          |> Map.new()
        }
      />

      <div class="rounded-2xl border border-violet-200 bg-violet-50 px-5 py-4 text-sm text-violet-800">
        This screen is already past the request for quotation and quote stages. If someone is still sourcing, send them back to the request for quotation or quote comparison screen first.
      </div>

      <div class="rounded-[2rem] border border-slate-200 bg-white p-5 shadow-sm">
        <div class="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
          <div class="space-y-1">
            <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
              Next action
            </p>
            <p :if={@po.status == "pending_approval"} class="text-sm font-medium text-amber-700">
              The PO is waiting for approval. Once approved, the next action is to send it to the supplier.
            </p>
            <p :if={@po.status == "approved"} class="text-sm font-medium text-emerald-700">
              Approval is complete. The next step is sending the purchase order to the supplier.
            </p>
            <p :if={@po.status in ["sent", "acknowledged"]} class="text-sm font-medium text-sky-700">
              Supplier-side work has started. They will acknowledge the PO and then invoice against this order.
            </p>
          </div>

          <div class="flex flex-wrap items-center gap-3">
            <button
              :if={@po.status == "pending_approval"}
              type="button"
              phx-click="approve"
              phx-value-id={@po.id}
              class="inline-flex items-center justify-center rounded-xl bg-[#373896] px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-[#2d2d7a]"
            >
              Approve PO
            </button>
            <button
              :if={@po.status == "approved"}
              type="button"
              phx-click="send"
              phx-value-id={@po.id}
              class="inline-flex items-center justify-center rounded-xl bg-[#373896] px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-[#2d2d7a]"
            >
              Send to supplier
            </button>
          </div>
        </div>
      </div>

      <div class="space-y-6">
        <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
          <div class="overflow-x-auto">
            <table class="w-full min-w-[720px] table-auto text-left text-sm">
              <thead class="border-b border-slate-200 text-slate-500">
                <tr>
                  <th class="pb-3 pr-6 font-semibold">Description</th>
                  <th class="w-24 pb-3 pr-6 text-right font-semibold">Qty</th>
                  <th class="w-32 pb-3 pr-6 text-right font-semibold">Unit price</th>
                  <th class="w-32 pb-3 text-right font-semibold">Total</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-100">
                <tr :for={item <- @po.items} class="align-top hover:bg-slate-50/60">
                  <td class="py-4 pr-6">
                    <p
                      class="whitespace-normal break-words font-medium leading-6 text-slate-900"
                      title={item.description}
                    >
                      {item.description}
                    </p>
                  </td>
                  <td class="py-4 pr-6 text-right tabular-nums text-slate-600">
                    {LiveHelpers.decimal_to_string(item.quantity)}
                  </td>
                  <td class="py-4 pr-6 text-right tabular-nums text-slate-600 whitespace-nowrap">
                    {LiveHelpers.money(item.unit_price)}
                  </td>
                  <td class="py-4 text-right tabular-nums text-slate-700 whitespace-nowrap">
                    {LiveHelpers.money(item.total)}
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
          <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
            Order summary
          </p>
          <div class="mt-5 space-y-4 text-sm text-slate-600">
            <div :if={@po.rfq} class="rounded-2xl border border-slate-100 bg-slate-50 px-4 py-4">
              <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-400">
                Source
              </p>
              <p class="mt-2 font-semibold text-slate-900">{@po.rfq.reference}</p>
              <p class="mt-1 text-sm text-slate-500">
                This purchase order came from a request for quotation and should only have been created after quote review.
              </p>
              <.link
                navigate={~p"/procurement/rfqs/#{@po.rfq_id}"}
                class="mt-3 inline-flex text-sm font-semibold text-[#373896] hover:text-[#2d2d7a]"
              >
                Re-open source request for quotation
              </.link>
            </div>

            <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
              <div class="rounded-2xl bg-slate-50 px-4 py-3">
                <p class="text-xs font-semibold uppercase tracking-[0.22em] text-slate-400">
                  Supplier
                </p>
                <p class="mt-2 text-sm font-medium text-slate-800">
                  {@po.supplier && (@po.supplier.legal_name || @po.supplier.name)}
                </p>
              </div>
              <div class="rounded-2xl bg-slate-50 px-4 py-3">
                <p class="text-xs font-semibold uppercase tracking-[0.22em] text-slate-400">
                  PO date
                </p>
                <p class="mt-2 text-sm font-medium text-slate-800">
                  {LiveHelpers.format_date(@po.po_date)}
                </p>
              </div>
              <div class="rounded-2xl bg-slate-50 px-4 py-3">
                <p class="text-xs font-semibold uppercase tracking-[0.22em] text-slate-400">
                  Expected delivery
                </p>
                <p class="mt-2 text-sm font-medium text-slate-800">
                  {LiveHelpers.format_date(@po.expected_delivery_date)}
                </p>
              </div>
              <div class="rounded-2xl bg-[#f5f4ff] px-4 py-3">
                <p class="text-xs font-semibold uppercase tracking-[0.22em] text-[#6667ab]">
                  Total
                </p>
                <p class="mt-2 text-base font-semibold text-[#373896]">
                  {LiveHelpers.money(@po.total)}
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
