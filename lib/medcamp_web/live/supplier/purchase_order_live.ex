defmodule MedcampWeb.Supplier.PurchaseOrderLive do
  use MedcampWeb, :supplier_live_view

  import MedcampWeb.ProcurementComponents, only: [status_badge: 1, pipeline_tracker: 1]

  alias Medcamp.Procurement.{Invoices, PurchaseOrders}
  alias MedcampWeb.Supplier.LiveHelpers

  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    case LiveHelpers.load_supplier(socket.assigns.current_user, create?: true) do
      {:ok, supplier, user} ->
        {:ok,
         socket
         |> LiveHelpers.maybe_assign_current_user(user)
         |> assign(:page_title, "Purchase Orders")
         |> assign(:supplier, supplier)
         |> assign(:purchase_order, nil)
         |> assign(:linked_invoice, nil)
         |> assign(:page, 1)
         |> assign(:per_page, @per_page)
         |> load_purchase_orders()}

      {:error, :missing_supplier} ->
        {:ok, push_navigate(socket, to: LiveHelpers.registration_path(:company))}
    end
  end

  defp load_purchase_orders(socket) do
    all = PurchaseOrders.list_purchase_orders(supplier_id: socket.assigns.supplier.id)
    total_count = length(all)
    total_pages = Medcamp.Pagination.total_pages(total_count, socket.assigns.per_page)
    page = min(max(1, socket.assigns.page || 1), total_pages)

    purchase_orders =
      Enum.slice(all, (page - 1) * socket.assigns.per_page, socket.assigns.per_page)

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:purchase_orders, purchase_orders)
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("acknowledge", %{"id" => id}, socket) do
    purchase_order = PurchaseOrders.get_purchase_order!(id)

    if purchase_order.supplier_id == socket.assigns.supplier.id and
         purchase_order.status == "sent" do
      case PurchaseOrders.acknowledge(purchase_order) do
        {:ok, acknowledged} ->
          {:noreply,
           socket
           |> put_flash(:info, "Purchase order acknowledged successfully.")
           |> assign_show(acknowledged.id)}

        {:error, _reason} ->
          {:noreply,
           put_flash(socket, :error, "Unable to acknowledge this purchase order right now.")}
      end
    else
      {:noreply, put_flash(socket, :error, "That purchase order cannot be acknowledged.")}
    end
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, max(1, String.to_integer(page)))
     |> load_purchase_orders()}
  end

  @impl true
  def handle_info({_event, _payload}, socket) do
    socket =
      socket
      |> load_purchase_orders()
      |> maybe_refresh_show()

    {:noreply, socket}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Purchase Orders")
    |> assign(:purchase_order, nil)
    |> assign(:linked_invoice, nil)
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    assign_show(socket, id)
  end

  defp assign_show(socket, id) do
    purchase_order = PurchaseOrders.get_purchase_order!(id)

    if purchase_order.supplier_id == socket.assigns.supplier.id do
      linked_invoice = linked_invoice(socket.assigns.supplier.id, purchase_order.id)

      socket
      |> assign(:page_title, purchase_order.reference)
      |> assign(:purchase_order, purchase_order)
      |> assign(:linked_invoice, linked_invoice)
    else
      socket
      |> put_flash(:error, "That purchase order is not available to your supplier account.")
      |> push_navigate(to: ~p"/supplier/purchase-orders")
    end
  end

  defp linked_invoice(supplier_id, purchase_order_id) do
    Invoices.list_invoices(supplier_id: supplier_id)
    |> Enum.find(&(&1.purchase_order_id == purchase_order_id))
    |> case do
      nil -> nil
      invoice -> Invoices.get_invoice!(invoice.id)
    end
  end

  defp maybe_refresh_show(%{assigns: %{live_action: :show, purchase_order: %{id: id}}} = socket),
    do: assign_show(socket, id)

  defp maybe_refresh_show(socket), do: socket

  defp po_document_ids(po, invoice) do
    %{
      rfq: po.rfq_id && "/supplier/rfqs/#{po.rfq_id}",
      proforma: po.proforma_invoice_id && "/supplier/proforma-invoices/#{po.proforma_invoice_id}",
      purchase_order: "/supplier/purchase-orders/#{po.id}",
      invoice: invoice && "/supplier/invoices/#{invoice.id}"
    }
    |> Enum.reject(fn {_key, value} -> LiveHelpers.blank?(value) end)
    |> Map.new()
  end

  defp pipeline_steps,
    do: [:registration, :rfq, :quote, :proforma, :purchase_order, :invoice, :shipment, :grn]

  @impl true
  def render(%{live_action: :show} = assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
        <div class="space-y-2">
          <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
            Purchase order
          </p>
          <h1 class="text-3xl font-semibold tracking-tight text-slate-900">
            {@purchase_order.reference}
          </h1>
          <p class="max-w-3xl text-sm leading-6 text-slate-500">
            Track approval progress, expected delivery timing, and the next invoice handoff from this purchase order.
          </p>
        </div>

        <.status_badge status={@purchase_order.status} />
      </div>

      <.pipeline_tracker
        steps={pipeline_steps()}
        current={:purchase_order}
        document_ids={po_document_ids(@purchase_order, @linked_invoice)}
      />

      <div
        :if={@purchase_order.status in ["pending_approval", "approved", "sent", "acknowledged"]}
        class="rounded-2xl border border-sky-200 bg-sky-50 px-5 py-4 text-sm text-sky-800"
      >
        <span class="font-semibold">Approval pipeline:</span>
        Procurement has progressed this order to the purchase-order stage. Acknowledge it once it has been formally issued to your team.
      </div>

      <div class="rounded-[2rem] border border-slate-200 bg-white p-5 shadow-sm">
        <div class="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
          <div class="space-y-1">
            <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
              Next step
            </p>
            <p :if={@purchase_order.status == "sent"} class="text-sm font-medium text-amber-700">
              Acknowledge this purchase order once your team has accepted it and is ready to invoice against it.
            </p>
            <p
              :if={@purchase_order.status == "acknowledged"}
              class="text-sm font-medium text-emerald-700"
            >
              This purchase order has been acknowledged. You can now prepare the supplier invoice.
            </p>
          </div>

          <div class="flex flex-wrap items-center gap-3">
            <button
              :if={@purchase_order.status == "sent"}
              type="button"
              phx-click="acknowledge"
              phx-value-id={@purchase_order.id}
              class="inline-flex items-center justify-center rounded-xl bg-[#373896] px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-[#2d2d7a]"
            >
              Acknowledge purchase order
            </button>

            <.link
              navigate={
                if @linked_invoice,
                  do: ~p"/supplier/invoices/#{@linked_invoice.id}",
                  else: ~p"/supplier/invoices/new/#{@purchase_order.id}"
              }
              class={[
                "inline-flex items-center justify-center rounded-xl px-4 py-2.5 text-sm font-semibold transition",
                if(@purchase_order.status == "acknowledged",
                  do: "bg-[#373896] text-white hover:bg-[#2d2d7a]",
                  else: "border border-slate-200 text-slate-700 hover:bg-slate-50"
                )
              ]}
            >
              {if @linked_invoice, do: "Open supplier invoice", else: "Create supplier invoice"}
            </.link>
          </div>
        </div>
      </div>

      <div class="space-y-6">
        <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
          <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
            Order summary
          </p>
          <div class="mt-5 grid gap-4 sm:grid-cols-2">
            <.info_tile label="PO date" value={LiveHelpers.format_date(@purchase_order.po_date)} />
            <.info_tile
              label="Source request for quotation"
              value={@purchase_order.rfq && @purchase_order.rfq.reference}
            />
            <.info_tile
              label="Expected delivery"
              value={LiveHelpers.format_date(@purchase_order.expected_delivery_date)}
            />
            <.info_tile label="Payment terms" value={@purchase_order.payment_terms} />
            <.info_tile label="Delivery address" value={@purchase_order.delivery_address} />
            <.info_tile label="Subtotal" value={LiveHelpers.money(@purchase_order.subtotal)} />
            <.info_tile label="VAT" value={LiveHelpers.money(@purchase_order.vat_amount)} />
            <.info_tile label="Total" value={LiveHelpers.money(@purchase_order.total)} />
            <.info_tile label="Currency" value={@purchase_order.currency || "KES"} />
          </div>
        </div>

        <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
          <div class="flex items-center justify-between gap-3">
            <div>
              <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
                Line items
              </p>
              <h2 class="mt-2 text-xl font-semibold text-slate-900">Ordered products</h2>
            </div>
            <span class="rounded-full bg-slate-100 px-3 py-2 text-sm font-semibold text-slate-700">
              {length(@purchase_order.items)} items
            </span>
          </div>

          <div class="mt-5 overflow-x-auto">
            <table class="w-full min-w-[760px] table-auto text-left text-sm">
              <thead class="border-b border-slate-200 text-slate-500">
                <tr>
                  <th class="w-12 pb-3 pr-6 font-semibold">#</th>
                  <th class="pb-3 pr-6 font-semibold">Description</th>
                  <th class="w-24 pb-3 pr-6 text-right font-semibold">Qty</th>
                  <th class="w-32 pb-3 pr-6 text-right font-semibold">Unit price</th>
                  <th class="w-32 pb-3 text-right font-semibold">Total</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-100">
                <tr :for={item <- @purchase_order.items} class="align-top hover:bg-slate-50/60">
                  <td class="py-4 pr-6 text-slate-600">{item.position}</td>
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
      </div>
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="space-y-2">
        <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
          Purchase orders
        </p>
        <h1 class="text-3xl font-semibold tracking-tight text-slate-900">
          Issued orders from procurement
        </h1>
        <p class="max-w-3xl text-sm leading-6 text-slate-500">
          View every purchase order sent to your supplier account, monitor statuses, and open the ones ready for invoicing.
        </p>
      </div>

      <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
        <div class="mb-5 rounded-2xl border border-violet-200 bg-violet-50 px-4 py-4 text-sm text-violet-800">
          Purchase orders are the next stage after quote acceptance. If you are still pricing an item, go back to the request for quotation inbox instead.
        </div>

        <div class="flex items-center justify-between gap-3">
          <div>
            <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">Orders</p>
            <h2 class="mt-2 text-xl font-semibold text-slate-900">All purchase orders</h2>
          </div>
          <span class="rounded-full bg-slate-100 px-3 py-2 text-sm font-semibold text-slate-700">
            {@total_count} POs
          </span>
        </div>

        <div
          :if={Enum.empty?(@purchase_orders)}
          class="mt-5 rounded-2xl border border-dashed border-slate-200 px-4 py-8 text-sm text-slate-500"
        >
          Purchase orders will appear here once procurement accepts your quote or proforma and issues the order.
        </div>

        <div :if={!Enum.empty?(@purchase_orders)} class="mt-5 overflow-x-auto">
          <table class="min-w-full text-left text-sm">
            <thead class="border-b border-slate-200 text-slate-500">
              <tr>
                <th class="pb-3 pr-4 font-semibold">Reference</th>
                <th class="pb-3 pr-4 font-semibold">PO date</th>
                <th class="pb-3 pr-4 font-semibold">Expected delivery</th>
                <th class="pb-3 pr-4 font-semibold">Total</th>
                <th class="pb-3 pr-4 font-semibold">Status</th>
                <th class="pb-3 font-semibold text-right">Action</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
              <tr :for={purchase_order <- @purchase_orders}>
                <td class="py-4 pr-4">
                  <p class="font-medium text-slate-900">{purchase_order.reference}</p>
                  <p class="mt-1 text-xs text-slate-500">
                    {if purchase_order.rfq, do: purchase_order.rfq.reference, else: "Direct PO"}
                  </p>
                </td>
                <td class="py-4 pr-4 text-slate-600">
                  {LiveHelpers.format_date(purchase_order.po_date)}
                </td>
                <td class="py-4 pr-4 text-slate-600">
                  {LiveHelpers.format_date(purchase_order.expected_delivery_date)}
                </td>
                <td class="py-4 pr-4 text-slate-600">{LiveHelpers.money(purchase_order.total)}</td>
                <td class="py-4 pr-4"><.status_badge status={purchase_order.status} /></td>
                <td class="py-4 text-right">
                  <.link
                    navigate={~p"/supplier/purchase-orders/#{purchase_order.id}"}
                    class="text-sm font-semibold text-[#373896] hover:text-[#2d2d7a]"
                  >
                    Open PO
                  </.link>
                </td>
              </tr>
            </tbody>
          </table>
          <.pagination
            page={@page}
            total_pages={@total_pages}
            total_count={@total_count}
            per_page={@per_page}
          />
        </div>
      </div>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :value, :any, default: nil

  defp info_tile(assigns) do
    ~H"""
    <div class="rounded-2xl bg-slate-50 px-4 py-3">
      <p class="text-xs font-semibold uppercase tracking-[0.22em] text-slate-400">{@label}</p>
      <p class="mt-2 text-sm font-medium text-slate-800">
        {if LiveHelpers.blank?(@value), do: "Not provided", else: @value}
      </p>
    </div>
    """
  end
end
