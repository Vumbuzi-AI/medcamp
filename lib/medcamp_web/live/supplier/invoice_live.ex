defmodule MedcampWeb.Supplier.InvoiceLive do
  use MedcampWeb, :supplier_live_view

  import MedcampWeb.ProcurementComponents,
    only: [status_badge: 1, pipeline_tracker: 1, portal_form_shell: 1]

  alias Medcamp.Procurement.{Invoices, PurchaseOrders, Shipments}
  alias Medcamp.Repo
  alias MedcampWeb.Supplier.LiveHelpers

  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    socket =
      allow_upload(socket, :invoice_pdf,
        accept: ~w(.pdf),
        max_entries: 1,
        max_file_size: 10_000_000
      )

    case LiveHelpers.load_supplier(socket.assigns.current_user, create?: true) do
      {:ok, supplier, user} ->
        {:ok,
         socket
         |> LiveHelpers.maybe_assign_current_user(user)
         |> assign(:page_title, "Supplier Invoice")
         |> assign(:supplier, supplier)
         |> assign(:purchase_order, nil)
         |> assign(:invoice, nil)
         |> assign(:invoices, [])
         |> assign(:page, 1)
         |> assign(:per_page, @per_page)
         |> assign(:total_count, 0)
         |> assign(:total_pages, 1)
         |> assign(:linked_shipment, nil)
         |> assign(:invoice_form, %{})
         |> assign(:invoice_items, [])
         |> assign(:invoice_totals, %{
           subtotal: Decimal.new(0),
           vat_amount: Decimal.new(0),
           total: Decimal.new(0)
         })}

      {:error, :missing_supplier} ->
        {:ok, push_navigate(socket, to: LiveHelpers.registration_path(:company))}
    end
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("change", %{"invoice" => params}, socket) do
    items = invoice_items_from_params(params, socket.assigns.invoice_items)
    form = invoice_form_from_params(params, socket.assigns.invoice_form)

    {:noreply,
     socket
     |> assign(:invoice_form, form)
     |> assign(:invoice_items, items)
     |> assign(:invoice_totals, invoice_totals(items))}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :invoice_pdf, ref)}
  end

  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, max(1, String.to_integer(page)))
     |> load_invoices()}
  end

  def handle_event("submit", %{"invoice" => params}, socket) do
    items = invoice_items_from_params(params, socket.assigns.invoice_items)
    form = invoice_form_from_params(params, socket.assigns.invoice_form)

    uploaded_files =
      LiveHelpers.store_uploads(
        socket,
        :invoice_pdf,
        "procurement_invoices",
        "invoice_#{socket.assigns.supplier.id}"
      )

    document_path =
      case uploaded_files do
        [%{path: path} | _] -> path
        _ -> socket.assigns.invoice && socket.assigns.invoice.invoice_document_path
      end

    if LiveHelpers.blank?(document_path) do
      {:noreply, put_flash(socket, :error, "Attach the invoice PDF before submitting.")}
    else
      attrs = %{
        purchase_order_id: socket.assigns.purchase_order.id,
        supplier_id: socket.assigns.supplier.id,
        invoice_date: blank_to_nil(Map.get(form, "invoice_date")),
        due_date: blank_to_nil(Map.get(form, "due_date")),
        currency: Map.get(form, "currency"),
        supplier_pin: Map.get(form, "supplier_pin"),
        bill_to: Map.get(form, "bill_to"),
        invoice_document_path: document_path,
        items: submit_invoice_items(items)
      }

      result =
        case socket.assigns.invoice do
          nil ->
            with {:ok, invoice} <- Invoices.create(attrs),
                 {:ok, invoice} <- Invoices.submit(invoice) do
              {:ok, invoice}
            end

          invoice ->
            with {:ok, invoice} <- Invoices.update(invoice, attrs),
                 {:ok, invoice} <- Invoices.submit(invoice) do
              {:ok, invoice}
            end
        end

      case result do
        {:ok, invoice} ->
          {:noreply,
           socket
           |> put_flash(:info, "Invoice submitted successfully.")
           |> push_navigate(to: ~p"/supplier/invoices/#{invoice.id}")}

        {:error, _reason} ->
          {:noreply,
           socket
           |> assign(:invoice_form, form)
           |> assign(:invoice_items, items)
           |> assign(:invoice_totals, invoice_totals(items))
           |> put_flash(:error, "We could not submit the invoice right now.")}
      end
    end
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Supplier invoices")
    |> load_invoices()
  end

  defp apply_action(socket, :new, %{"po_id" => po_id}) do
    purchase_order = PurchaseOrders.get_purchase_order!(po_id)
    existing = existing_invoice(socket.assigns.supplier.id, purchase_order.id)

    cond do
      purchase_order.supplier_id != socket.assigns.supplier.id ->
        socket
        |> put_flash(:error, "That purchase order is not available to your supplier account.")
        |> push_navigate(to: ~p"/supplier/purchase-orders")

      existing && existing.status != "draft" ->
        socket
        |> put_flash(:info, "An invoice already exists for that purchase order.")
        |> push_navigate(to: ~p"/supplier/invoices/#{existing.id}")

      true ->
        items = draft_invoice_items(purchase_order, existing)
        form = draft_invoice_form(socket.assigns.supplier, purchase_order, existing)

        socket
        |> assign(:page_title, "Create Supplier Invoice")
        |> assign(:purchase_order, purchase_order)
        |> assign(:invoice, existing)
        |> assign(:linked_shipment, nil)
        |> assign(:invoice_form, form)
        |> assign(:invoice_items, items)
        |> assign(:invoice_totals, invoice_totals(items))
    end
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    invoice = Invoices.get_invoice!(id)

    if invoice.supplier_id == socket.assigns.supplier.id do
      linked_shipment = existing_shipment(socket.assigns.supplier.id, invoice.id)

      socket
      |> assign(:page_title, invoice.reference)
      |> assign(:purchase_order, invoice.purchase_order)
      |> assign(:invoice, invoice)
      |> assign(:linked_shipment, linked_shipment)
      |> assign(:invoice_form, show_invoice_form(invoice))
      |> assign(:invoice_items, show_invoice_items(invoice))
      |> assign(:invoice_totals, %{
        subtotal: invoice.subtotal,
        vat_amount: invoice.vat_amount,
        total: invoice.total
      })
    else
      socket
      |> put_flash(:error, "That invoice is not available to your supplier account.")
      |> push_navigate(to: ~p"/supplier/purchase-orders")
    end
  end

  defp load_invoices(socket) do
    all =
      Invoices.list_invoices(supplier_id: socket.assigns.supplier.id)
      |> Repo.preload(:purchase_order)

    total_count = length(all)
    total_pages = Medcamp.Pagination.total_pages(total_count, socket.assigns.per_page)
    page = min(max(1, socket.assigns.page || 1), total_pages)
    invoices = Enum.slice(all, (page - 1) * socket.assigns.per_page, socket.assigns.per_page)

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:invoices, invoices)
  end

  defp existing_invoice(supplier_id, purchase_order_id) do
    Invoices.list_invoices(supplier_id: supplier_id)
    |> Enum.find(&(&1.purchase_order_id == purchase_order_id))
    |> case do
      nil -> nil
      invoice -> Invoices.get_invoice!(invoice.id)
    end
  end

  defp existing_shipment(supplier_id, invoice_id) do
    Shipments.list_shipments(supplier_id: supplier_id)
    |> Enum.find(&(&1.invoice_id == invoice_id))
    |> case do
      nil -> nil
      shipment -> Shipments.get_shipment!(shipment.id)
    end
  end

  defp draft_invoice_form(supplier, purchase_order, nil) do
    %{
      "invoice_date" => Date.utc_today() |> Date.to_iso8601(),
      "due_date" =>
        (purchase_order.expected_delivery_date || Date.add(Date.utc_today(), 30))
        |> Date.to_iso8601(),
      "currency" => purchase_order.currency || "KES",
      "supplier_pin" => supplier.kra_pin,
      "bill_to" => purchase_order.delivery_address || ""
    }
  end

  defp draft_invoice_form(_supplier, _purchase_order, invoice), do: show_invoice_form(invoice)

  defp show_invoice_form(invoice) do
    %{
      "invoice_date" => invoice.invoice_date && Date.to_iso8601(invoice.invoice_date),
      "due_date" => invoice.due_date && Date.to_iso8601(invoice.due_date),
      "currency" => invoice.currency || "KES",
      "supplier_pin" => invoice.supplier_pin,
      "bill_to" => invoice.bill_to
    }
  end

  defp draft_invoice_items(purchase_order, nil) do
    Enum.map(purchase_order.items, fn item ->
      %{
        "purchase_order_item_id" => item.id,
        "inventory_received_id" => item.inventory_received_id,
        "position" => item.position,
        "description" => item.description,
        "unit" => item.unit,
        "quantity_delivered" => LiveHelpers.decimal_to_string(item.quantity),
        "unit_price" => LiveHelpers.decimal_to_string(item.unit_price),
        "vat_rate" => "0.16",
        "vat_amount" => Decimal.new(0),
        "total" => Decimal.new(0)
      }
    end)
    |> Enum.map(&normalize_invoice_item/1)
  end

  defp draft_invoice_items(_purchase_order, invoice), do: show_invoice_items(invoice)

  defp show_invoice_items(invoice) do
    Enum.map(invoice.items, fn item ->
      %{
        "purchase_order_item_id" => item.purchase_order_item_id,
        "inventory_received_id" => item.inventory_received_id,
        "position" => item.position,
        "description" => item.description,
        "unit" => item.unit,
        "quantity_delivered" => LiveHelpers.decimal_to_string(item.quantity_delivered),
        "unit_price" => LiveHelpers.decimal_to_string(item.unit_price),
        "vat_rate" => LiveHelpers.decimal_to_string(item.vat_rate),
        "vat_amount" => item.vat_amount || Decimal.new(0),
        "total" => item.total || Decimal.new(0)
      }
    end)
  end

  defp invoice_form_from_params(params, current),
    do:
      Map.merge(
        current,
        Map.take(params, ~w(invoice_date due_date currency supplier_pin bill_to))
      )

  defp invoice_items_from_params(params, current) do
    params
    |> Map.get("items", %{})
    |> LiveHelpers.listify_indexed_params()
    |> case do
      [] -> current
      items -> Enum.map(items, &normalize_invoice_item/1)
    end
  end

  defp normalize_invoice_item(item) do
    qty = LiveHelpers.decimal(Map.get(item, "quantity_delivered"))
    unit_price = LiveHelpers.decimal(Map.get(item, "unit_price"))
    vat_rate = LiveHelpers.decimal(Map.get(item, "vat_rate") || "0.16")
    subtotal = Decimal.mult(qty, unit_price)
    vat_amount = Decimal.mult(subtotal, vat_rate)

    item
    |> Map.put("vat_amount", vat_amount)
    |> Map.put("total", Decimal.add(subtotal, vat_amount))
  end

  defp submit_invoice_items(items) do
    Enum.map(items, fn item ->
      %{
        purchase_order_item_id: item["purchase_order_item_id"],
        inventory_received_id: blank_to_nil(item["inventory_received_id"]),
        position: item["position"],
        description: item["description"],
        unit: item["unit"],
        quantity_delivered: blank_to_nil(item["quantity_delivered"]),
        unit_price: blank_to_nil(item["unit_price"]),
        vat_rate: blank_to_nil(item["vat_rate"])
      }
    end)
  end

  defp invoice_totals(items) do
    subtotal =
      Enum.reduce(items, Decimal.new(0), fn item, acc ->
        line_total =
          LiveHelpers.decimal(Map.get(item, "quantity_delivered"))
          |> Decimal.mult(LiveHelpers.decimal(Map.get(item, "unit_price")))

        Decimal.add(acc, line_total)
      end)

    vat_amount =
      Enum.reduce(items, Decimal.new(0), fn item, acc ->
        Decimal.add(acc, LiveHelpers.decimal(Map.get(item, "vat_amount")))
      end)

    %{subtotal: subtotal, vat_amount: vat_amount, total: Decimal.add(subtotal, vat_amount)}
  end

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value

  defp pipeline_steps,
    do: [:registration, :rfq, :quote, :proforma, :purchase_order, :invoice, :shipment, :grn]

  defp invoice_table_input_classes do
    "h-11 w-full rounded-xl border border-slate-200 bg-white px-3 text-right tabular-nums text-sm text-slate-700 shadow-sm outline-none transition placeholder:text-slate-300 focus:border-[#373896] focus:ring-4 focus:ring-[#d2d3ff]"
  end

  defp invoice_panel_input_classes do
    "mt-3 h-12 w-full rounded-2xl border border-slate-200 bg-slate-50/70 px-4 text-sm text-slate-700 shadow-sm outline-none transition placeholder:text-slate-300 focus:border-[#373896] focus:bg-white focus:ring-4 focus:ring-[#d2d3ff]"
  end

  defp invoice_panel_textarea_classes do
    "mt-3 min-h-28 w-full rounded-2xl border border-slate-200 bg-slate-50/70 px-4 py-3 text-sm text-slate-700 shadow-sm outline-none transition placeholder:text-slate-300 focus:border-[#373896] focus:bg-white focus:ring-4 focus:ring-[#d2d3ff]"
  end

  @impl true
  def render(%{live_action: :index} = assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
        <div class="space-y-2">
          <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
            Supplier invoice
          </p>
          <h1 class="text-3xl font-semibold tracking-tight text-slate-900">All invoices</h1>
          <p class="text-sm leading-6 text-slate-500">
            View invoices submitted against your purchase orders.
          </p>
        </div>

        <.link
          navigate={~p"/supplier/purchase-orders"}
          class="inline-flex items-center justify-center rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm font-semibold text-slate-700 shadow-sm transition hover:bg-slate-50"
        >
          View purchase orders
        </.link>
      </div>

      <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
        <%= if Enum.empty?(@invoices) do %>
          <div class="flex flex-col items-center justify-center gap-3 py-12 text-center">
            <Heroicons.icon name="banknotes" type="outline" class="h-12 w-12 text-slate-300" />
            <p class="text-sm font-semibold text-slate-900">No invoices yet</p>
            <p class="max-w-md text-sm text-slate-500">
              Open a purchase order to create and submit the first supplier invoice.
            </p>
            <.link
              navigate={~p"/supplier/purchase-orders"}
              class="mt-2 inline-flex items-center justify-center rounded-2xl bg-[#373896] px-4 py-3 text-sm font-semibold text-white transition hover:bg-[#2d2d7a]"
            >
              Go to purchase orders
            </.link>
          </div>
        <% else %>
          <div class="overflow-x-auto">
            <table class="w-full min-w-[980px] table-auto text-left text-sm">
              <thead class="border-b border-slate-200 text-slate-500">
                <tr>
                  <th class="pb-3 pr-6 font-semibold">Invoice</th>
                  <th class="pb-3 pr-6 font-semibold">Purchase order</th>
                  <th class="pb-3 pr-6 font-semibold">Invoice date</th>
                  <th class="pb-3 pr-6 text-right font-semibold">Total</th>
                  <th class="pb-3 pr-6 font-semibold">Status</th>
                  <th class="pb-3 text-right font-semibold">Action</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-100">
                <tr :for={invoice <- @invoices} class="align-top hover:bg-slate-50/60">
                  <td class="py-4 pr-6 font-medium text-slate-900">{invoice.reference}</td>
                  <td class="py-4 pr-6 text-slate-600">
                    {(invoice.purchase_order && invoice.purchase_order.reference) || "—"}
                  </td>
                  <td class="py-4 pr-6 text-slate-600 whitespace-nowrap">
                    {LiveHelpers.format_date(invoice.invoice_date)}
                  </td>
                  <td class="py-4 pr-6 text-right tabular-nums font-medium text-slate-900">
                    {LiveHelpers.money(invoice.total)}
                  </td>
                  <td class="py-4 pr-6">
                    <.status_badge status={invoice.status} />
                  </td>
                  <td class="py-4 text-right">
                    <.link
                      navigate={~p"/supplier/invoices/#{invoice.id}"}
                      class="inline-flex items-center justify-center rounded-xl border border-slate-200 px-3 py-2 text-xs font-semibold text-slate-700 transition hover:bg-slate-50"
                    >
                      Open
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
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def render(%{live_action: :show} = assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
        <div class="space-y-2">
          <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">Invoice</p>
          <h1 class="text-3xl font-semibold tracking-tight text-slate-900">{@invoice.reference}</h1>
          <p class="text-sm leading-6 text-slate-500">
            Submitted against {@purchase_order.reference}.
          </p>
        </div>
        <.status_badge status={@invoice.status} />
      </div>

      <.pipeline_tracker
        steps={pipeline_steps()}
        current={:invoice}
        document_ids={
          %{
            purchase_order: "/supplier/purchase-orders/#{@purchase_order.id}",
            invoice: "/supplier/invoices/#{@invoice.id}",
            shipment: @linked_shipment && "/supplier/shipments/#{@linked_shipment.id}"
          }
        }
      />

      <div class="rounded-[2rem] border border-slate-200 bg-white p-5 shadow-sm">
        <div class="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
          <div class="space-y-1">
            <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
              Next step
            </p>
            <p class="text-sm font-medium text-emerald-700">
              {if @linked_shipment,
                do: "Shipment advice has already been created for this invoice.",
                else:
                  "This invoice has been submitted. The next supplier action is to create shipment advice."}
            </p>
          </div>

          <div class="flex flex-wrap items-center gap-3">
            <.link
              :if={!LiveHelpers.blank?(@invoice.invoice_document_path)}
              href={@invoice.invoice_document_path}
              target="_blank"
              class="inline-flex items-center justify-center rounded-xl border border-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-700 transition hover:bg-slate-50"
            >
              Open invoice PDF
            </.link>
            <.link
              navigate={
                if @linked_shipment,
                  do: ~p"/supplier/shipments/#{@linked_shipment.id}",
                  else: ~p"/supplier/shipments/new/#{@invoice.id}"
              }
              class="inline-flex items-center justify-center rounded-xl bg-[#373896] px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-[#2d2d7a]"
            >
              {if @linked_shipment, do: "Open shipment advice", else: "Create shipment advice"}
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
                  <th class="w-28 pb-3 pr-6 text-right font-semibold">Qty delivered</th>
                  <th class="w-32 pb-3 pr-6 text-right font-semibold">Unit price</th>
                  <th class="w-28 pb-3 pr-6 text-right font-semibold">VAT</th>
                  <th class="w-32 pb-3 text-right font-semibold">Total</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-100">
                <tr :for={item <- @invoice_items} class="align-top hover:bg-slate-50/60">
                  <td class="py-4 pr-6">
                    <p
                      class="whitespace-normal break-words font-medium leading-6 text-slate-900"
                      title={item["description"]}
                    >
                      {item["description"]}
                    </p>
                  </td>
                  <td class="py-4 pr-6 text-right tabular-nums text-slate-600">
                    {item["quantity_delivered"]}
                  </td>
                  <td class="py-4 pr-6 text-right tabular-nums text-slate-600 whitespace-nowrap">
                    {LiveHelpers.money(item["unit_price"])}
                  </td>
                  <td class="py-4 pr-6 text-right tabular-nums text-slate-600 whitespace-nowrap">
                    {LiveHelpers.money(item["vat_amount"])}
                  </td>
                  <td class="py-4 text-right tabular-nums text-slate-700 whitespace-nowrap">
                    {LiveHelpers.money(item["total"])}
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
                Supplier PIN
              </p>
              <p class="mt-2 text-sm font-medium text-slate-800">
                {@invoice.supplier_pin || "N/A"}
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
      </div>
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <.portal_form_shell
      eyebrow="Invoice Builder"
      title={"Create invoice for #{@purchase_order.reference}"}
      subtitle="Capture partial delivery quantities, upload the supporting PDF, and submit the invoice for procurement review."
      cancel_path={~p"/supplier/purchase-orders/#{@purchase_order.id}"}
      max_width="max-w-[96rem]"
    >
      <div class="space-y-6">
        <.pipeline_tracker
          steps={pipeline_steps()}
          current={:invoice}
          document_ids={%{purchase_order: "/supplier/purchase-orders/#{@purchase_order.id}"}}
        />

        <form phx-change="change" phx-submit="submit" class="space-y-6">
          <div class="grid gap-6 xl:grid-cols-[minmax(0,1fr)_19rem]">
            <div class="overflow-hidden rounded-[2rem] border border-slate-200 bg-white shadow-sm">
              <div class="border-b border-slate-200 bg-gradient-to-r from-slate-50 via-white to-[#f5f4ff] px-6 py-5">
                <div class="flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
                  <div class="space-y-2">
                    <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
                      Invoice lines
                    </p>
                    <h2 class="text-xl font-semibold text-slate-900">Confirm delivered quantities</h2>
                    <p class="max-w-2xl text-sm leading-6 text-slate-500">
                      Work from the approved purchase order, adjust the delivered quantity where needed, and review the live VAT and line totals before you submit.
                    </p>
                  </div>

                  <div class="rounded-2xl bg-[#f4f1ff] px-4 py-3 text-sm text-[#373896]">
                    <span class="font-semibold">{length(@invoice_items)}</span> line item(s)
                  </div>
                </div>
              </div>

              <div class="overflow-x-auto px-4 pb-4 pt-3">
                <table class="w-full min-w-[1160px] table-auto text-left text-sm">
                  <colgroup>
                    <col class="w-[34%]" />
                    <col class="w-[13%]" />
                    <col class="w-[13%]" />
                    <col class="w-[11%]" />
                    <col class="w-[14%]" />
                    <col class="w-[15%]" />
                  </colgroup>
                  <thead>
                    <tr class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-400">
                      <th class="px-4 py-4">Description</th>
                      <th class="px-4 py-4 text-right">Qty delivered</th>
                      <th class="px-4 py-4 text-right">Unit price</th>
                      <th class="px-4 py-4 text-right">VAT rate</th>
                      <th class="px-4 py-4 text-right">VAT amount</th>
                      <th class="px-4 py-4 text-right">Line total</th>
                    </tr>
                  </thead>
                  <tbody class="divide-y divide-slate-100">
                    <tr
                      :for={{item, index} <- Enum.with_index(@invoice_items)}
                      class="align-top transition hover:bg-slate-50/80"
                    >
                      <td class="px-4 py-5">
                        <div class="space-y-2">
                          <div class="flex flex-wrap items-center gap-2">
                            <span class="inline-flex rounded-full bg-slate-100 px-2.5 py-1 text-[11px] font-semibold uppercase tracking-[0.18em] text-slate-500">
                              Line {item["position"] || index + 1}
                            </span>
                            <span
                              :if={!LiveHelpers.blank?(item["unit"])}
                              class="inline-flex rounded-full bg-emerald-50 px-2.5 py-1 text-[11px] font-semibold uppercase tracking-[0.18em] text-emerald-700"
                            >
                              {item["unit"]}
                            </span>
                          </div>

                          <p
                            class="whitespace-normal break-words font-medium leading-6 text-slate-900"
                            title={item["description"]}
                          >
                            {item["description"]}
                          </p>
                        </div>

                        <input
                          type="hidden"
                          name={"invoice[items][#{index}][purchase_order_item_id]"}
                          value={item["purchase_order_item_id"]}
                        />
                        <input
                          type="hidden"
                          name={"invoice[items][#{index}][inventory_received_id]"}
                          value={item["inventory_received_id"]}
                        />
                        <input
                          type="hidden"
                          name={"invoice[items][#{index}][position]"}
                          value={item["position"]}
                        />
                        <input
                          type="hidden"
                          name={"invoice[items][#{index}][description]"}
                          value={item["description"]}
                        />
                        <input
                          type="hidden"
                          name={"invoice[items][#{index}][unit]"}
                          value={item["unit"]}
                        />
                      </td>
                      <td class="px-4 py-5">
                        <input
                          name={"invoice[items][#{index}][quantity_delivered]"}
                          value={item["quantity_delivered"]}
                          inputmode="decimal"
                          placeholder="0.00"
                          class={invoice_table_input_classes()}
                        />
                      </td>
                      <td class="px-4 py-5">
                        <input
                          name={"invoice[items][#{index}][unit_price]"}
                          value={item["unit_price"]}
                          inputmode="decimal"
                          placeholder="0.00"
                          class={invoice_table_input_classes()}
                        />
                      </td>
                      <td class="px-4 py-5">
                        <input
                          name={"invoice[items][#{index}][vat_rate]"}
                          value={item["vat_rate"]}
                          inputmode="decimal"
                          placeholder="0.16"
                          class={invoice_table_input_classes()}
                        />
                      </td>
                      <td class="px-4 py-5">
                        <div class="rounded-2xl bg-slate-50 px-4 py-3 text-sm text-slate-600">
                          <p class="text-[11px] font-semibold uppercase tracking-[0.18em] text-slate-400">
                            Tax
                          </p>
                          <p class="mt-2 font-semibold text-slate-800">
                            {LiveHelpers.money(item["vat_amount"])}
                          </p>
                        </div>
                      </td>
                      <td class="px-4 py-5">
                        <div class="rounded-2xl bg-[#f5f4ff] px-4 py-3 text-sm text-[#373896]">
                          <p class="text-[11px] font-semibold uppercase tracking-[0.18em] text-[#6667ab]">
                            Total
                          </p>
                          <p class="mt-2 font-semibold">{LiveHelpers.money(item["total"])}</p>
                        </div>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>

            <div class="space-y-6 xl:sticky xl:top-4 xl:self-start">
              <div class="overflow-hidden rounded-[2rem] border border-slate-200 bg-white shadow-sm">
                <div class="border-b border-slate-200 bg-slate-50 px-6 py-5">
                  <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
                    Invoice details
                  </p>
                  <h2 class="mt-2 text-xl font-semibold text-slate-900">Commercial fields</h2>
                  <p class="mt-2 text-sm leading-6 text-slate-500">
                    Confirm the dates, billing information, and tax identity that should appear on the supplier invoice.
                  </p>
                </div>

                <div class="space-y-5 p-6">
                  <label class="block">
                    <span class="text-sm font-semibold text-slate-800">Invoice date</span>
                    <span class="mt-1 block text-xs text-slate-500">
                      Date printed on the invoice document.
                    </span>
                    <input
                      type="date"
                      name="invoice[invoice_date]"
                      value={@invoice_form["invoice_date"]}
                      class={invoice_panel_input_classes()}
                    />
                  </label>

                  <label class="block">
                    <span class="text-sm font-semibold text-slate-800">Due date</span>
                    <span class="mt-1 block text-xs text-slate-500">
                      Expected payment date for this invoice.
                    </span>
                    <input
                      type="date"
                      name="invoice[due_date]"
                      value={@invoice_form["due_date"]}
                      class={invoice_panel_input_classes()}
                    />
                  </label>

                  <label class="block">
                    <span class="text-sm font-semibold text-slate-800">Currency</span>
                    <span class="mt-1 block text-xs text-slate-500">
                      Invoice currency, for example KES or USD.
                    </span>
                    <input
                      name="invoice[currency]"
                      value={@invoice_form["currency"]}
                      placeholder="KES"
                      class={invoice_panel_input_classes()}
                    />
                  </label>

                  <label class="block">
                    <span class="text-sm font-semibold text-slate-800">Supplier PIN</span>
                    <span class="mt-1 block text-xs text-slate-500">
                      KRA or tax reference that appears on your invoice.
                    </span>
                    <input
                      name="invoice[supplier_pin]"
                      value={@invoice_form["supplier_pin"]}
                      placeholder="P051234567X"
                      class={invoice_panel_input_classes()}
                    />
                  </label>

                  <label class="block">
                    <span class="text-sm font-semibold text-slate-800">Bill to</span>
                    <span class="mt-1 block text-xs text-slate-500">
                      Billing entity or address from the purchase order.
                    </span>
                    <textarea
                      name="invoice[bill_to]"
                      rows="4"
                      class={invoice_panel_textarea_classes()}
                      placeholder="Billing name and address"
                    >{@invoice_form["bill_to"]}</textarea>
                  </label>
                </div>
              </div>

              <div class="overflow-hidden rounded-[2rem] border border-slate-200 bg-white shadow-sm">
                <div class="border-b border-slate-200 px-6 py-4">
                  <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
                    Supporting document
                  </p>
                  <h3 class="mt-2 text-lg font-semibold text-slate-900">Attach invoice PDF</h3>
                </div>

                <div class="space-y-4 p-6">
                  <label class="block">
                    <span class="text-sm font-semibold text-slate-800">Invoice PDF</span>
                    <span class="mt-1 block text-xs text-slate-500">
                      Upload one signed PDF file up to 10MB.
                    </span>

                    <div class="mt-3 rounded-2xl border border-dashed border-slate-300 bg-slate-50/70 p-4">
                      <.live_file_input
                        upload={@uploads.invoice_pdf}
                        class="block w-full text-sm text-slate-600"
                      />
                    </div>
                  </label>

                  <div
                    :for={entry <- @uploads.invoice_pdf.entries}
                    class="flex items-center justify-between rounded-2xl bg-slate-50 px-4 py-3 text-sm text-slate-600"
                  >
                    <span class="truncate pr-3 font-medium text-slate-700">{entry.client_name}</span>
                    <button
                      type="button"
                      phx-click="cancel-upload"
                      phx-value-ref={entry.ref}
                      class="font-semibold text-rose-600 transition hover:text-rose-700"
                    >
                      Remove
                    </button>
                  </div>
                </div>
              </div>

              <div class="overflow-hidden rounded-[2rem] border border-slate-200 bg-white shadow-sm">
                <div class="border-b border-slate-200 px-6 py-4">
                  <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
                    Totals
                  </p>
                  <h3 class="mt-2 text-lg font-semibold text-slate-900">Live invoice summary</h3>
                </div>

                <div class="space-y-4 p-6">
                  <div class="rounded-2xl bg-[#f5f4ff] px-4 py-4">
                    <p class="text-[11px] font-semibold uppercase tracking-[0.22em] text-[#6667ab]">
                      Estimated total
                    </p>
                    <p class="mt-2 text-3xl font-semibold tracking-tight text-[#373896]">
                      {LiveHelpers.money(@invoice_totals.total)}
                    </p>
                  </div>

                  <div class="space-y-3 text-sm text-slate-600">
                    <div class="grid grid-cols-[minmax(0,1fr)_auto] items-center gap-4">
                      <span>Subtotal</span>
                      <span class="whitespace-nowrap text-right font-medium text-slate-900">
                        {LiveHelpers.money(@invoice_totals.subtotal)}
                      </span>
                    </div>
                    <div class="grid grid-cols-[minmax(0,1fr)_auto] items-center gap-4">
                      <span>VAT</span>
                      <span class="whitespace-nowrap text-right font-medium text-slate-900">
                        {LiveHelpers.money(@invoice_totals.vat_amount)}
                      </span>
                    </div>
                    <div class="grid grid-cols-[minmax(0,1fr)_auto] items-center gap-4 border-t border-slate-200 pt-3 text-base font-semibold text-slate-900">
                      <span>Total</span>
                      <span class="whitespace-nowrap text-right">
                        {LiveHelpers.money(@invoice_totals.total)}
                      </span>
                    </div>
                  </div>
                </div>
              </div>

              <button
                type="submit"
                class="w-full rounded-2xl bg-[#373896] px-4 py-3.5 text-sm font-semibold text-white shadow-lg shadow-[#373896]/20 transition hover:bg-[#2d2d7a]"
              >
                Submit invoice
              </button>

              <p class="text-center text-xs leading-5 text-slate-400">
                Submitting will create your supplier invoice and move you to shipment advice.
              </p>
            </div>
          </div>
        </form>
      </div>
    </.portal_form_shell>
    """
  end
end
