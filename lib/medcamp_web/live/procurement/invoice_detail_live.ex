defmodule MedcampWeb.Procurement.InvoiceDetailLive do
  use MedcampWeb, :procurement_live_view

  import MedcampWeb.ProcurementComponents, only: [status_badge: 1, pipeline_tracker: 1]

  alias Medcamp.Procurement.{GoodsReceived, Invoices, Shipments}
  alias MedcampWeb.Procurement.LiveHelpers

  @refresh_events ~w(invoice_submitted invoice_approved invoice_rejected invoice_grn_confirmed shipment_submitted grn_flagged grn_finalised)a

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Invoice Detail")}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    {:noreply, assign_invoice(socket, id)}
  end

  @impl true
  def handle_event("approve", %{"id" => id}, socket) do
    case Invoices.get_invoice(id) do
      nil ->
        {:noreply, put_flash(socket, :error, "Invoice not found.")}

      invoice ->
        case Invoices.approve(invoice, socket.assigns.current_user) do
          {:ok, _invoice} ->
            {:noreply,
             socket
             |> put_flash(:info, "Invoice approved successfully.")
             |> assign_invoice(id)}

          {:error, :not_grn_confirmed} ->
            {:noreply, put_flash(socket, :error, "Only GRN-confirmed invoices can be approved.")}

          _ ->
            {:noreply, put_flash(socket, :error, "Unable to approve that invoice right now.")}
        end
    end
  end

  @impl true
  def handle_info({event, _payload}, socket) when event in @refresh_events do
    {:noreply, assign_invoice(socket, socket.assigns.invoice.id)}
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  defp assign_invoice(socket, id) do
    invoice = Invoices.get_invoice!(id)
    related_shipment = related_shipment(invoice.id)
    related_grn = GoodsReceived.list_grns() |> Enum.find(&(&1.invoice_id == invoice.id))

    socket
    |> assign(:invoice, invoice)
    |> assign(:related_shipment, related_shipment)
    |> assign(:related_grn, related_grn)
    |> assign(:page_title, invoice.reference)
  end

  defp related_shipment(invoice_id) do
    Shipments.list_shipments()
    |> Enum.find(&(&1.invoice_id == invoice_id))
    |> case do
      nil -> nil
      shipment -> Shipments.get_shipment!(shipment.id)
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
        <div class="space-y-2">
          <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
            Invoice detail
          </p>
          <h1 class="text-3xl font-semibold tracking-tight text-slate-900">{@invoice.reference}</h1>
          <p class="text-sm leading-6 text-slate-500">
            Review the supplier invoice, related PO, and GRN state before approval.
          </p>
        </div>
        <.status_badge status={@invoice.status} />
      </div>

      <.pipeline_tracker
        steps={LiveHelpers.pipeline_steps()}
        current={:invoice}
        document_ids={
          %{
            purchase_order: "/procurement/purchase-orders/#{@invoice.purchase_order_id}",
            invoice: "/procurement/invoices/#{@invoice.id}",
            shipment: @related_shipment && "/procurement/grn/new/#{@related_shipment.id}",
            grn: @related_grn && "/procurement/grn/#{@related_grn.id}"
          }
          |> Enum.reject(fn {_key, value} -> LiveHelpers.blank?(value) end)
          |> Map.new()
        }
      />

      <div class="rounded-[2rem] border border-slate-200 bg-white p-5 shadow-sm">
        <div class="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
          <div class="space-y-1">
            <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
              Next step
            </p>
            <p class={[
              "text-sm font-medium",
              cond do
                @related_grn -> "text-emerald-700"
                @related_shipment -> "text-amber-700"
                true -> "text-slate-700"
              end
            ]}>
              {cond do
                @related_grn ->
                  "A GRN already exists for this invoice. Open it to review or continue processing."

                @related_shipment ->
                  "Shipment advice has been submitted. The next procurement action is to create the GRN."

                true ->
                  "Waiting for supplier shipment advice before a GRN can be created."
              end}
            </p>
          </div>

          <div class="flex flex-wrap items-center gap-3">
            <.link
              :if={LiveHelpers.present?(@invoice.invoice_document_path)}
              href={@invoice.invoice_document_path}
              target="_blank"
              class="inline-flex items-center justify-center rounded-xl border border-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-700 transition hover:bg-slate-50"
            >
              Open invoice document
            </.link>

            <button
              :if={@invoice.status == "grn_confirmed"}
              type="button"
              phx-click="approve"
              phx-value-id={@invoice.id}
              class="inline-flex items-center justify-center rounded-xl bg-emerald-600 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-emerald-700"
            >
              Approve invoice
            </button>

            <.link
              :if={@related_shipment}
              navigate={
                if @related_grn,
                  do: ~p"/procurement/grn/#{@related_grn.id}",
                  else: ~p"/procurement/grn/new/#{@related_shipment.id}"
              }
              class={[
                "inline-flex items-center justify-center rounded-xl px-4 py-2.5 text-sm font-semibold transition",
                if(@related_grn,
                  do: "border border-slate-200 text-slate-700 hover:bg-slate-50",
                  else: "bg-[#373896] text-white hover:bg-[#2d2d7a]"
                )
              ]}
            >
              {if @related_grn, do: "Open GRN", else: "Create GRN"}
            </.link>
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
                  <th class="w-28 pb-3 pr-6 text-right font-semibold">VAT</th>
                  <th class="w-32 pb-3 text-right font-semibold">Total</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-100">
                <tr :for={item <- @invoice.items} class="align-top hover:bg-slate-50/60">
                  <td class="py-4 pr-6">
                    <p
                      class="whitespace-normal break-words font-medium leading-6 text-slate-900"
                      title={item.description}
                    >
                      {item.description}
                    </p>
                  </td>
                  <td class="py-4 pr-6 text-right tabular-nums text-slate-600">
                    {LiveHelpers.decimal_to_string(item.quantity_delivered)}
                  </td>
                  <td class="py-4 pr-6 text-right tabular-nums text-slate-600 whitespace-nowrap">
                    {LiveHelpers.money(item.unit_price)}
                  </td>
                  <td class="py-4 pr-6 text-right tabular-nums text-slate-600 whitespace-nowrap">
                    {LiveHelpers.money(item.vat_amount)}
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
            Invoice summary
          </p>
          <div class="mt-5 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            <div class="rounded-2xl bg-slate-50 px-4 py-3">
              <p class="text-xs font-semibold uppercase tracking-[0.22em] text-slate-400">
                Supplier
              </p>
              <p class="mt-2 text-sm font-medium text-slate-800">
                {@invoice.supplier && (@invoice.supplier.legal_name || @invoice.supplier.name)}
              </p>
            </div>
            <div class="rounded-2xl bg-slate-50 px-4 py-3">
              <p class="text-xs font-semibold uppercase tracking-[0.22em] text-slate-400">
                Invoice date
              </p>
              <p class="mt-2 text-sm font-medium text-slate-800">
                {LiveHelpers.format_date(@invoice.invoice_date)}
              </p>
            </div>
            <div class="rounded-2xl bg-slate-50 px-4 py-3">
              <p class="text-xs font-semibold uppercase tracking-[0.22em] text-slate-400">
                Due date
              </p>
              <p class="mt-2 text-sm font-medium text-slate-800">
                {LiveHelpers.format_date(@invoice.due_date)}
              </p>
            </div>
            <div class="rounded-2xl bg-slate-50 px-4 py-3">
              <p class="text-xs font-semibold uppercase tracking-[0.22em] text-slate-400">
                Subtotal
              </p>
              <p class="mt-2 text-sm font-medium text-slate-800">
                {LiveHelpers.money(@invoice.subtotal)}
              </p>
            </div>
            <div class="rounded-2xl bg-slate-50 px-4 py-3">
              <p class="text-xs font-semibold uppercase tracking-[0.22em] text-slate-400">
                VAT
              </p>
              <p class="mt-2 text-sm font-medium text-slate-800">
                {LiveHelpers.money(@invoice.vat_amount)}
              </p>
            </div>
            <div class="rounded-2xl bg-[#f5f4ff] px-4 py-3">
              <p class="text-xs font-semibold uppercase tracking-[0.22em] text-[#6667ab]">
                Total
              </p>
              <p class="mt-2 text-base font-semibold text-[#373896]">
                {LiveHelpers.money(@invoice.total)}
              </p>
            </div>
          </div>
        </div>

        <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
          <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">Workflow</p>
          <div class="mt-5 grid gap-4 sm:grid-cols-3">
            <div class="rounded-2xl bg-slate-50 px-4 py-3">
              <p class="text-xs font-semibold uppercase tracking-[0.22em] text-slate-400">PO</p>
              <.link
                navigate={~p"/procurement/purchase-orders/#{@invoice.purchase_order_id}"}
                class="mt-2 inline-flex text-sm font-semibold text-[#373896] hover:text-[#2d2d7a]"
              >
                Open purchase order
              </.link>
            </div>
            <div class="rounded-2xl bg-slate-50 px-4 py-3">
              <p class="text-xs font-semibold uppercase tracking-[0.22em] text-slate-400">
                Shipment
              </p>
              <p class="mt-2 text-sm font-medium text-slate-800">
                {if @related_shipment, do: @related_shipment.reference, else: "Not submitted"}
              </p>
            </div>
            <div class="rounded-2xl bg-slate-50 px-4 py-3">
              <p class="text-xs font-semibold uppercase tracking-[0.22em] text-slate-400">GRN</p>
              <p class="mt-2 text-sm font-medium text-slate-800">
                {if @related_grn, do: @related_grn.reference, else: "Not created"}
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
