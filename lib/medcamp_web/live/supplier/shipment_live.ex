defmodule MedcampWeb.Supplier.ShipmentLive do
  use MedcampWeb, :supplier_live_view

  import MedcampWeb.ProcurementComponents,
    only: [status_badge: 1, pipeline_tracker: 1, portal_form_shell: 1, attachment_gallery: 1]

  alias Medcamp.Procurement.{Invoices, PurchaseOrders, Shipments}
  alias Medcamp.Repo
  alias MedcampWeb.Supplier.LiveHelpers

  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    socket =
      allow_upload(socket, :shipping_documents,
        accept: ~w(.pdf .jpg .jpeg .png),
        max_entries: 5,
        max_file_size: 10_000_000
      )

    case LiveHelpers.load_supplier(socket.assigns.current_user, create?: true) do
      {:ok, supplier, user} ->
        {:ok,
         socket
         |> LiveHelpers.maybe_assign_current_user(user)
         |> assign(:page_title, "Shipment Advice")
         |> assign(:supplier, supplier)
         |> assign(:invoice, nil)
         |> assign(:shipment, nil)
         |> assign(:shipments, [])
         |> assign(:page, 1)
         |> assign(:per_page, @per_page)
         |> assign(:total_count, 0)
         |> assign(:total_pages, 1)
         |> assign(:shipment_form, %{})
         |> assign(:shipment_items, [])
         |> assign(:shipment_attachments, [])}

      {:error, :missing_supplier} ->
        {:ok, push_navigate(socket, to: LiveHelpers.registration_path(:company))}
    end
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Shipment advice")
    |> load_shipments()
  end

  defp apply_action(socket, :new, %{"invoice_id" => invoice_id}) do
    invoice =
      Invoices.get_invoice!(invoice_id)
      |> with_loaded_purchase_order_items()

    existing = existing_shipment(socket.assigns.supplier.id, invoice.id)

    cond do
      invoice.supplier_id != socket.assigns.supplier.id ->
        socket
        |> put_flash(:error, "That invoice is not available to your supplier account.")
        |> push_navigate(to: ~p"/supplier/purchase-orders")

      existing ->
        socket
        |> put_flash(:info, "A shipment advice already exists for that invoice.")
        |> push_navigate(to: ~p"/supplier/shipments/#{existing.id}")

      true ->
        socket
        |> assign(:page_title, "Create Shipment Advice")
        |> assign(:invoice, invoice)
        |> assign(:shipment_form, draft_shipment_form(invoice))
        |> assign(:shipment_items, draft_shipment_items(invoice))
    end
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    shipment = Shipments.get_shipment!(id)

    if shipment.supplier_id == socket.assigns.supplier.id do
      socket
      |> assign(:page_title, shipment.reference)
      |> assign(:shipment, shipment)
      |> assign(:invoice, shipment.invoice)
      |> assign(:shipment_form, show_shipment_form(shipment))
      |> assign(:shipment_items, show_shipment_items(shipment))
      |> assign(
        :shipment_attachments,
        LiveHelpers.extract_attachments(shipment.delivery_instructions)
      )
    else
      socket
      |> put_flash(:error, "That shipment advice is not available to your supplier account.")
      |> push_navigate(to: ~p"/supplier/purchase-orders")
    end
  end

  defp load_shipments(socket) do
    all =
      Shipments.list_shipments(supplier_id: socket.assigns.supplier.id)
      |> Repo.preload([:invoice, :purchase_order])

    total_count = length(all)
    total_pages = Medcamp.Pagination.total_pages(total_count, socket.assigns.per_page)
    page = min(max(1, socket.assigns.page || 1), total_pages)
    shipments = Enum.slice(all, (page - 1) * socket.assigns.per_page, socket.assigns.per_page)

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:shipments, shipments)
  end

  @impl true
  def handle_event("change", %{"shipment" => params}, socket) do
    items = shipment_items_from_params(params, socket.assigns.shipment_items)
    form = shipment_form_from_params(params, socket.assigns.shipment_form)

    {:noreply,
     socket
     |> assign(:shipment_form, form)
     |> assign(:shipment_items, items)}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :shipping_documents, ref)}
  end

  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, max(1, String.to_integer(page)))
     |> load_shipments()}
  end

  def handle_event("submit", %{"shipment" => params}, socket) do
    items = shipment_items_from_params(params, socket.assigns.shipment_items)
    form = shipment_form_from_params(params, socket.assigns.shipment_form)

    uploaded_files =
      LiveHelpers.store_uploads(
        socket,
        :shipping_documents,
        "shipment_documents",
        "shipment_#{socket.assigns.supplier.id}"
      )

    attrs = %{
      purchase_order_id: socket.assigns.invoice.purchase_order_id,
      invoice_id: socket.assigns.invoice.id,
      supplier_id: socket.assigns.supplier.id,
      dispatch_date: blank_to_nil(Map.get(form, "dispatch_date")),
      estimated_delivery_date: blank_to_nil(Map.get(form, "estimated_delivery_date")),
      carrier: Map.get(form, "carrier"),
      waybill_number: Map.get(form, "waybill_number"),
      number_of_packages: blank_to_nil(Map.get(form, "number_of_packages")),
      total_weight_kg: blank_to_nil(Map.get(form, "total_weight_kg")),
      delivery_instructions:
        form
        |> Map.get("delivery_instructions")
        |> LiveHelpers.merge_attachments(uploaded_files),
      items: submit_shipment_items(items)
    }

    case Shipments.create(attrs) do
      {:ok, shipment} ->
        {:noreply,
         socket
         |> put_flash(:info, "Shipment advice submitted successfully.")
         |> push_navigate(to: ~p"/supplier/shipments/#{shipment.id}")}

      {:error, _reason} ->
        {:noreply,
         socket
         |> assign(:shipment_form, form)
         |> assign(:shipment_items, items)
         |> put_flash(:error, "We could not submit the shipment advice right now.")}
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

  defp with_loaded_purchase_order_items(invoice) do
    purchase_order = PurchaseOrders.get_purchase_order!(invoice.purchase_order_id)
    %{invoice | purchase_order: purchase_order}
  end

  defp draft_shipment_form(invoice) do
    %{
      "dispatch_date" => Date.utc_today() |> Date.to_iso8601(),
      "estimated_delivery_date" =>
        (invoice.purchase_order && invoice.purchase_order.expected_delivery_date &&
           Date.to_iso8601(invoice.purchase_order.expected_delivery_date)) || "",
      "carrier" => "",
      "waybill_number" => "",
      "number_of_packages" => "",
      "total_weight_kg" => "",
      "delivery_instructions" => ""
    }
  end

  defp show_shipment_form(shipment) do
    %{
      "dispatch_date" => shipment.dispatch_date && Date.to_iso8601(shipment.dispatch_date),
      "estimated_delivery_date" =>
        shipment.estimated_delivery_date && Date.to_iso8601(shipment.estimated_delivery_date),
      "carrier" => shipment.carrier,
      "waybill_number" => shipment.waybill_number,
      "number_of_packages" => to_string(shipment.number_of_packages || ""),
      "total_weight_kg" => LiveHelpers.decimal_to_string(shipment.total_weight_kg),
      "delivery_instructions" => LiveHelpers.plain_notes(shipment.delivery_instructions)
    }
  end

  defp draft_shipment_items(invoice) do
    invoice.purchase_order
    |> Map.get(:items, [])
    |> Enum.map(fn item ->
      %{
        "purchase_order_item_id" => item.id,
        "inventory_received_id" => item.inventory_received_id,
        "position" => item.position,
        "description" => item.description,
        "unit" => item.unit,
        "quantity_shipped" => LiveHelpers.decimal_to_string(item.quantity),
        "batch_number" => "",
        "expiry_date" => "",
        "temperature_requirement" => "ambient"
      }
    end)
  end

  defp show_shipment_items(shipment) do
    Enum.map(shipment.items, fn item ->
      %{
        "purchase_order_item_id" => item.purchase_order_item_id,
        "inventory_received_id" => item.inventory_received_id,
        "position" => item.position,
        "description" => item.description,
        "unit" => item.unit,
        "quantity_shipped" => LiveHelpers.decimal_to_string(item.quantity_shipped),
        "batch_number" => item.batch_number,
        "expiry_date" => item.expiry_date && Date.to_iso8601(item.expiry_date),
        "temperature_requirement" => item.temperature_requirement
      }
    end)
  end

  defp shipment_form_from_params(params, current),
    do:
      Map.merge(
        current,
        Map.take(
          params,
          ~w(dispatch_date estimated_delivery_date carrier waybill_number number_of_packages total_weight_kg delivery_instructions)
        )
      )

  defp shipment_items_from_params(params, current) do
    params
    |> Map.get("items", %{})
    |> LiveHelpers.listify_indexed_params()
    |> case do
      [] -> current
      items -> items
    end
  end

  defp submit_shipment_items(items) do
    Enum.map(items, fn item ->
      %{
        purchase_order_item_id: item["purchase_order_item_id"],
        inventory_received_id: blank_to_nil(item["inventory_received_id"]),
        position: item["position"],
        description: item["description"],
        unit: item["unit"],
        quantity_shipped: blank_to_nil(item["quantity_shipped"]),
        batch_number: item["batch_number"],
        expiry_date: blank_to_nil(item["expiry_date"]),
        temperature_requirement: item["temperature_requirement"]
      }
    end)
  end

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value

  defp pipeline_steps,
    do: [:registration, :rfq, :quote, :proforma, :purchase_order, :invoice, :shipment, :grn]

  defp shipment_table_input_classes do
    "h-11 w-full rounded-xl border border-slate-200 bg-white px-3 text-sm text-slate-700 shadow-sm outline-none transition placeholder:text-slate-300 focus:border-[#373896] focus:ring-4 focus:ring-[#d2d3ff]"
  end

  defp shipment_table_select_classes do
    "h-11 w-full rounded-xl border border-slate-200 bg-white px-3 text-sm text-slate-700 shadow-sm outline-none transition focus:border-[#373896] focus:ring-4 focus:ring-[#d2d3ff]"
  end

  defp shipment_panel_input_classes do
    "mt-3 h-12 w-full rounded-2xl border border-slate-200 bg-slate-50/70 px-4 text-sm text-slate-700 shadow-sm outline-none transition placeholder:text-slate-300 focus:border-[#373896] focus:bg-white focus:ring-4 focus:ring-[#d2d3ff]"
  end

  defp shipment_panel_textarea_classes do
    "mt-3 min-h-32 w-full rounded-2xl border border-slate-200 bg-slate-50/70 px-4 py-3 text-sm text-slate-700 shadow-sm outline-none transition placeholder:text-slate-300 focus:border-[#373896] focus:bg-white focus:ring-4 focus:ring-[#d2d3ff]"
  end

  @impl true
  def render(%{live_action: :index} = assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
        <div class="space-y-2">
          <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
            Shipment advice
          </p>
          <h1 class="text-3xl font-semibold tracking-tight text-slate-900">All shipment advice</h1>
          <p class="text-sm leading-6 text-slate-500">
            View shipment advice submitted against your invoices.
          </p>
        </div>

        <.link
          navigate={~p"/supplier/order-flow/invoices"}
          class="inline-flex items-center justify-center rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm font-semibold text-slate-700 shadow-sm transition hover:bg-slate-50"
        >
          View invoices
        </.link>
      </div>

      <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
        <%= if Enum.empty?(@shipments) do %>
          <div class="flex flex-col items-center justify-center gap-3 py-12 text-center">
            <Heroicons.icon name="truck" type="outline" class="h-12 w-12 text-slate-300" />
            <p class="text-sm font-semibold text-slate-900">No shipment advice yet</p>
            <p class="max-w-md text-sm text-slate-500">
              Open an invoice to create and submit shipment advice for dispatch.
            </p>
            <.link
              navigate={~p"/supplier/order-flow/invoices"}
              class="mt-2 inline-flex items-center justify-center rounded-2xl bg-[#373896] px-4 py-3 text-sm font-semibold text-white transition hover:bg-[#2d2d7a]"
            >
              Go to invoices
            </.link>
          </div>
        <% else %>
          <div class="overflow-x-auto">
            <table class="w-full min-w-[980px] table-auto text-left text-sm">
              <thead class="border-b border-slate-200 text-slate-500">
                <tr>
                  <th class="pb-3 pr-6 font-semibold">Shipment</th>
                  <th class="pb-3 pr-6 font-semibold">Invoice</th>
                  <th class="pb-3 pr-6 font-semibold">Dispatch date</th>
                  <th class="pb-3 pr-6 font-semibold">ETA</th>
                  <th class="pb-3 pr-6 font-semibold">Status</th>
                  <th class="pb-3 text-right font-semibold">Action</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-100">
                <tr :for={shipment <- @shipments} class="align-top hover:bg-slate-50/60">
                  <td class="py-4 pr-6 font-medium text-slate-900">{shipment.reference}</td>
                  <td class="py-4 pr-6 text-slate-600">
                    {(shipment.invoice && shipment.invoice.reference) || "—"}
                  </td>
                  <td class="py-4 pr-6 text-slate-600 whitespace-nowrap">
                    {LiveHelpers.format_date(shipment.dispatch_date)}
                  </td>
                  <td class="py-4 pr-6 text-slate-600 whitespace-nowrap">
                    {LiveHelpers.format_date(shipment.estimated_delivery_date)}
                  </td>
                  <td class="py-4 pr-6">
                    <.status_badge status={shipment.status} />
                  </td>
                  <td class="py-4 text-right">
                    <.link
                      navigate={~p"/supplier/shipments/#{shipment.id}"}
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
          <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
            Shipment advice
          </p>
          <h1 class="text-3xl font-semibold tracking-tight text-slate-900">{@shipment.reference}</h1>
          <p class="text-sm leading-6 text-slate-500">
            Submitted against invoice {@invoice.reference}.
          </p>
        </div>
        <.status_badge status={@shipment.status} />
      </div>

      <.pipeline_tracker
        steps={pipeline_steps()}
        current={:shipment}
        document_ids={
          %{
            invoice: "/supplier/invoices/#{@invoice.id}",
            shipment: "/supplier/shipments/#{@shipment.id}"
          }
        }
      />

      <div class="rounded-[2rem] border border-slate-200 bg-white p-5 shadow-sm">
        <div class="flex flex-col gap-2 lg:flex-row lg:items-center lg:justify-between">
          <div class="space-y-1">
            <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
              Status
            </p>
            <p class="text-sm font-medium text-emerald-700">
              Shipment advice has been submitted. Procurement will record goods received once delivery is confirmed — no further action is required from you.
            </p>
          </div>
        </div>
      </div>

      <div class="space-y-6">
        <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
          <div class="overflow-x-auto">
            <table class="w-full min-w-[860px] table-auto text-left text-sm">
              <thead class="border-b border-slate-200 text-slate-500">
                <tr>
                  <th class="pb-3 pr-6 font-semibold">Description</th>
                  <th class="w-28 pb-3 pr-6 text-right font-semibold">Qty shipped</th>
                  <th class="w-40 pb-3 pr-6 font-semibold">Batch</th>
                  <th class="w-32 pb-3 pr-6 font-semibold">Expiry</th>
                  <th class="w-40 pb-3 font-semibold">Temperature</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-100">
                <tr :for={item <- @shipment_items} class="align-top hover:bg-slate-50/60">
                  <td class="py-4 pr-6">
                    <p
                      class="whitespace-normal break-words font-medium leading-6 text-slate-900"
                      title={item["description"]}
                    >
                      {item["description"]}
                    </p>
                  </td>
                  <td class="py-4 pr-6 text-right tabular-nums text-slate-600">
                    {item["quantity_shipped"]}
                  </td>
                  <td class="py-4 pr-6 text-slate-600 whitespace-nowrap">
                    {item["batch_number"] || "N/A"}
                  </td>
                  <td class="py-4 pr-6 text-slate-600 whitespace-nowrap">
                    {item["expiry_date"] || "N/A"}
                  </td>
                  <td class="py-4 text-slate-600 whitespace-nowrap">
                    {String.replace(item["temperature_requirement"] || "ambient", "_", " ")}
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
          <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
            Shipment summary
          </p>
          <div class="mt-5 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            <div class="rounded-2xl bg-slate-50 px-4 py-3">
              <p class="text-xs font-semibold uppercase tracking-[0.22em] text-slate-400">
                Dispatch date
              </p>
              <p class="mt-2 text-sm font-medium text-slate-800">
                {LiveHelpers.format_date(@shipment.dispatch_date)}
              </p>
            </div>
            <div class="rounded-2xl bg-slate-50 px-4 py-3">
              <p class="text-xs font-semibold uppercase tracking-[0.22em] text-slate-400">
                Estimated delivery
              </p>
              <p class="mt-2 text-sm font-medium text-slate-800">
                {LiveHelpers.format_date(@shipment.estimated_delivery_date)}
              </p>
            </div>
            <div class="rounded-2xl bg-slate-50 px-4 py-3">
              <p class="text-xs font-semibold uppercase tracking-[0.22em] text-slate-400">
                Carrier
              </p>
              <p class="mt-2 text-sm font-medium text-slate-800">
                {@shipment.carrier || "N/A"}
              </p>
            </div>
            <div class="rounded-2xl bg-slate-50 px-4 py-3">
              <p class="text-xs font-semibold uppercase tracking-[0.22em] text-slate-400">
                Waybill
              </p>
              <p class="mt-2 text-sm font-medium text-slate-800">
                {@shipment.waybill_number || "N/A"}
              </p>
            </div>
            <div class="rounded-2xl bg-slate-50 px-4 py-3">
              <p class="text-xs font-semibold uppercase tracking-[0.22em] text-slate-400">
                Packages
              </p>
              <p class="mt-2 text-sm font-medium text-slate-800">
                {@shipment.number_of_packages || 0}
              </p>
            </div>
            <div class="rounded-2xl bg-slate-50 px-4 py-3">
              <p class="text-xs font-semibold uppercase tracking-[0.22em] text-slate-400">
                Total weight
              </p>
              <p class="mt-2 text-sm font-medium text-slate-800">
                {LiveHelpers.decimal_to_string(@shipment.total_weight_kg)} kg
              </p>
            </div>
          </div>
        </div>

        <div
          :if={!LiveHelpers.blank?(LiveHelpers.plain_notes(@shipment.delivery_instructions))}
          class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm"
        >
          <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
            Delivery instructions
          </p>
          <p class="mt-4 text-sm leading-6 text-slate-600">
            {LiveHelpers.plain_notes(@shipment.delivery_instructions)}
          </p>
        </div>

        <div
          :if={@shipment_attachments != []}
          class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm"
        >
          <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
            Attachments
          </p>
          <.attachment_gallery attachments={@shipment_attachments} />
        </div>
      </div>
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <.portal_form_shell
      eyebrow="Shipment Builder"
      title="Create shipment advice"
      subtitle="Capture dispatch details, per-item batch information, and upload supporting shipping documents in one submission."
      cancel_path={~p"/supplier/invoices/#{@invoice.id}"}
      max_width="max-w-[96rem]"
    >
      <div class="space-y-6">
        <.pipeline_tracker
          steps={pipeline_steps()}
          current={:shipment}
          document_ids={%{invoice: "/supplier/invoices/#{@invoice.id}"}}
        />

        <form phx-change="change" phx-submit="submit" class="space-y-6">
          <div class="grid gap-6 xl:grid-cols-[minmax(0,1fr)_20rem]">
            <div class="overflow-hidden rounded-[2rem] border border-slate-200 bg-white shadow-sm">
              <div class="border-b border-slate-200 bg-gradient-to-r from-slate-50 via-white to-[#f5f4ff] px-6 py-5">
                <div class="flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
                  <div class="space-y-2">
                    <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
                      Shipment items
                    </p>
                    <h2 class="text-xl font-semibold text-slate-900">Prepare dispatch details</h2>
                    <p class="max-w-2xl text-sm leading-6 text-slate-500">
                      Confirm quantities being shipped, add batch information, and mark any expiry or temperature handling needed for delivery.
                    </p>
                  </div>

                  <p class="text-sm font-medium text-[#373896]">
                    {length(@shipment_items)} items to dispatch
                  </p>
                </div>
              </div>

              <div class="overflow-x-auto px-4 pb-4 pt-3">
                <table class="w-full min-w-[980px] table-auto text-left text-sm">
                  <colgroup>
                    <col class="w-[32%]" />
                    <col class="w-[14%]" />
                    <col class="w-[18%]" />
                    <col class="w-[16%]" />
                    <col class="w-[20%]" />
                  </colgroup>
                  <thead class="border-b border-slate-200 text-slate-500">
                    <tr>
                      <th class="px-3 py-4 text-xs font-semibold uppercase tracking-[0.2em] text-slate-400">
                        Description
                      </th>
                      <th class="px-3 py-4 text-right text-xs font-semibold uppercase tracking-[0.2em] text-slate-400">
                        Qty shipped
                      </th>
                      <th class="px-3 py-4 text-xs font-semibold uppercase tracking-[0.2em] text-slate-400">
                        Batch number
                      </th>
                      <th class="px-3 py-4 text-xs font-semibold uppercase tracking-[0.2em] text-slate-400">
                        Expiry
                      </th>
                      <th class="px-3 py-4 text-xs font-semibold uppercase tracking-[0.2em] text-slate-400">
                        Temperature
                      </th>
                    </tr>
                  </thead>
                  <tbody class="divide-y divide-slate-100">
                    <tr
                      :for={{item, index} <- Enum.with_index(@shipment_items)}
                      class="align-top transition hover:bg-slate-50/80"
                    >
                      <td class="px-4 py-5">
                        <div class="pr-4">
                          <div class="flex flex-wrap items-center gap-2">
                            <span class="inline-flex h-8 w-8 items-center justify-center rounded-2xl bg-[#373896] text-xs font-semibold text-white">
                              {item["position"]}
                            </span>
                            <p
                              class="whitespace-normal break-words font-semibold leading-6 text-slate-900"
                              title={item["description"]}
                            >
                              {item["description"]}
                            </p>
                          </div>

                          <p class="mt-2 text-xs leading-5 text-slate-500">
                            Shipping unit: {item["unit"] || "units"}
                          </p>
                        </div>

                        <input
                          type="hidden"
                          name={"shipment[items][#{index}][purchase_order_item_id]"}
                          value={item["purchase_order_item_id"]}
                        />
                        <input
                          type="hidden"
                          name={"shipment[items][#{index}][inventory_received_id]"}
                          value={item["inventory_received_id"]}
                        />
                        <input
                          type="hidden"
                          name={"shipment[items][#{index}][position]"}
                          value={item["position"]}
                        />
                        <input
                          type="hidden"
                          name={"shipment[items][#{index}][description]"}
                          value={item["description"]}
                        />
                      </td>

                      <td class="px-4 py-5">
                        <input
                          name={"shipment[items][#{index}][quantity_shipped]"}
                          value={item["quantity_shipped"]}
                          inputmode="decimal"
                          placeholder="0.00"
                          class={[shipment_table_input_classes(), "text-right tabular-nums"]}
                        />
                      </td>

                      <td class="px-4 py-5">
                        <input
                          name={"shipment[items][#{index}][batch_number]"}
                          value={item["batch_number"]}
                          placeholder="Batch reference"
                          class={shipment_table_input_classes()}
                        />
                      </td>

                      <td class="px-4 py-5">
                        <input
                          type="date"
                          name={"shipment[items][#{index}][expiry_date]"}
                          value={item["expiry_date"]}
                          class={shipment_table_input_classes()}
                        />
                      </td>

                      <td class="px-4 py-5">
                        <select
                          name={"shipment[items][#{index}][temperature_requirement]"}
                          class={shipment_table_select_classes()}
                        >
                          <option
                            value="ambient"
                            selected={item["temperature_requirement"] == "ambient"}
                          >
                            Ambient
                          </option>
                          <option
                            value="cold_chain"
                            selected={item["temperature_requirement"] == "cold_chain"}
                          >
                            Cold chain
                          </option>
                        </select>
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
                    Dispatch details
                  </p>
                  <h2 class="mt-2 text-xl font-semibold text-slate-900">Logistics summary</h2>
                  <p class="mt-2 text-sm leading-6 text-slate-500">
                    Capture the transport and delivery information your receiving team will need.
                  </p>
                </div>

                <div class="space-y-5 p-6">
                  <label class="block">
                    <span class="text-sm font-semibold text-slate-800">Dispatch date</span>
                    <span class="mt-1 block text-xs text-slate-500">
                      Date the shipment leaves your facility.
                    </span>
                    <input
                      type="date"
                      name="shipment[dispatch_date]"
                      value={@shipment_form["dispatch_date"]}
                      class={shipment_panel_input_classes()}
                    />
                  </label>

                  <label class="block">
                    <span class="text-sm font-semibold text-slate-800">Estimated delivery date</span>
                    <span class="mt-1 block text-xs text-slate-500">
                      Expected arrival date at the buyer location.
                    </span>
                    <input
                      type="date"
                      name="shipment[estimated_delivery_date]"
                      value={@shipment_form["estimated_delivery_date"]}
                      class={shipment_panel_input_classes()}
                    />
                  </label>

                  <label class="block">
                    <span class="text-sm font-semibold text-slate-800">Carrier</span>
                    <span class="mt-1 block text-xs text-slate-500">
                      Courier, transporter, or delivery company.
                    </span>
                    <input
                      name="shipment[carrier]"
                      value={@shipment_form["carrier"]}
                      placeholder="e.g. G4S, DHL, in-house rider"
                      class={shipment_panel_input_classes()}
                    />
                  </label>

                  <label class="block">
                    <span class="text-sm font-semibold text-slate-800">Waybill number</span>
                    <span class="mt-1 block text-xs text-slate-500">
                      Tracking or consignment reference if available.
                    </span>
                    <input
                      name="shipment[waybill_number]"
                      value={@shipment_form["waybill_number"]}
                      placeholder="Optional"
                      class={shipment_panel_input_classes()}
                    />
                  </label>

                  <label class="block">
                    <span class="text-sm font-semibold text-slate-800">Number of packages</span>
                    <span class="mt-1 block text-xs text-slate-500">
                      Total cartons, pallets, or parcels in the shipment.
                    </span>
                    <input
                      name="shipment[number_of_packages]"
                      value={@shipment_form["number_of_packages"]}
                      inputmode="numeric"
                      placeholder="0"
                      class={shipment_panel_input_classes()}
                    />
                  </label>

                  <label class="block">
                    <span class="text-sm font-semibold text-slate-800">Total weight (kg)</span>
                    <span class="mt-1 block text-xs text-slate-500">
                      Approximate total shipment weight.
                    </span>
                    <input
                      name="shipment[total_weight_kg]"
                      value={@shipment_form["total_weight_kg"]}
                      inputmode="decimal"
                      placeholder="0.00"
                      class={shipment_panel_input_classes()}
                    />
                  </label>

                  <label class="block">
                    <span class="text-sm font-semibold text-slate-800">Delivery instructions</span>
                    <span class="mt-1 block text-xs text-slate-500">
                      Add any handling notes, contact details, or receiving instructions.
                    </span>
                    <textarea
                      name="shipment[delivery_instructions]"
                      rows="5"
                      class={shipment_panel_textarea_classes()}
                      placeholder="Optional delivery notes"
                    >{@shipment_form["delivery_instructions"]}</textarea>
                  </label>
                </div>
              </div>

              <div class="overflow-hidden rounded-[2rem] border border-slate-200 bg-white shadow-sm">
                <div class="border-b border-slate-200 px-6 py-4">
                  <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
                    Attachments
                  </p>
                  <h3 class="mt-2 text-lg font-semibold text-slate-900">Shipping documents</h3>
                </div>

                <div class="p-6">
                  <label class="block text-sm font-semibold text-slate-800">
                    Upload files
                    <span class="mt-1 block text-xs font-normal text-slate-500">
                      Add delivery notes, transport documents, or any supporting files.
                    </span>
                  </label>
                  <.live_file_input
                    upload={@uploads.shipping_documents}
                    class="mt-3 block w-full rounded-2xl border border-dashed border-slate-300 bg-slate-50 px-4 py-4 text-sm text-slate-600 transition file:mr-3 file:rounded-xl file:border-0 file:bg-[#373896] file:px-3 file:py-2 file:text-sm file:font-semibold file:text-white hover:border-[#373896] hover:bg-[#f5f4ff]"
                  />
                  <div
                    :for={entry <- @uploads.shipping_documents.entries}
                    class="mt-3 flex items-center justify-between rounded-2xl bg-slate-50 px-4 py-3 text-sm text-slate-600"
                  >
                    <span class="truncate pr-3">{entry.client_name}</span>
                    <button
                      type="button"
                      phx-click="cancel-upload"
                      phx-value-ref={entry.ref}
                      class="font-semibold text-rose-600"
                    >
                      Remove
                    </button>
                  </div>
                </div>
              </div>

              <button
                type="submit"
                class="w-full rounded-2xl bg-[#373896] px-4 py-3.5 text-sm font-semibold text-white shadow-lg shadow-[#373896]/20 transition hover:bg-[#2d2d7a]"
              >
                Submit shipment advice
              </button>
            </div>
          </div>
        </form>
      </div>
    </.portal_form_shell>
    """
  end
end
