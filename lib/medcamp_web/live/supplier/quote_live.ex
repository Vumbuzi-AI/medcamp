defmodule MedcampWeb.Supplier.QuoteLive do
  use MedcampWeb, :supplier_live_view

  import MedcampWeb.ProcurementComponents,
    only: [status_badge: 1, pipeline_tracker: 1, portal_form_shell: 1]

  alias Medcamp.Procurement.{Quotes, Rfqs}
  alias MedcampWeb.Supplier.LiveHelpers

  @impl true
  def mount(_params, _session, socket) do
    case LiveHelpers.load_supplier(socket.assigns.current_user, create?: true) do
      {:ok, supplier, user} ->
        {:ok,
         socket
         |> LiveHelpers.maybe_assign_current_user(user)
         |> assign(:page_title, "Supplier Quote")
         |> assign(:supplier, supplier)
         |> assign(:rfq, nil)
         |> assign(:quote, nil)
         |> assign(:quote_form, %{})
         |> assign(:quote_items, [])
         |> assign(:quote_totals, %{
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
  def handle_event("change", %{"quote" => params}, socket) do
    items = quote_items_from_params(params, socket.assigns.quote_items)
    form = quote_form_from_params(params, socket.assigns.quote_form)

    {:noreply,
     socket
     |> assign(:quote_form, form)
     |> assign(:quote_items, items)
     |> assign(:quote_totals, quote_totals(items, Map.get(form, "vat_rate")))}
  end

  def handle_event("submit", %{"quote" => params}, socket) do
    items = quote_items_from_params(params, socket.assigns.quote_items)
    form = quote_form_from_params(params, socket.assigns.quote_form)

    attrs = %{
      rfq_id: socket.assigns.rfq.id,
      supplier_id: socket.assigns.supplier.id,
      valid_until: blank_to_nil(Map.get(form, "valid_until")),
      lead_time_days: blank_to_nil(Map.get(form, "lead_time_days")),
      delivery_terms: Map.get(form, "delivery_terms"),
      general_remarks: Map.get(form, "general_remarks"),
      vat_rate: Map.get(form, "vat_rate"),
      items: submit_quote_items(items)
    }

    case Quotes.submit(attrs) do
      {:ok, quote} ->
        {:noreply,
         socket
         |> put_flash(:info, "Quote submitted successfully.")
         |> push_navigate(to: ~p"/supplier/quotes/#{quote.id}")}

      {:error, _reason} ->
        {:noreply,
         socket
         |> assign(:quote_form, form)
         |> assign(:quote_items, items)
         |> assign(:quote_totals, quote_totals(items, Map.get(form, "vat_rate")))
         |> put_flash(
           :error,
           "We could not submit that quote. Please review the line items and try again."
         )}
    end
  end

  defp apply_action(socket, :new, %{"rfq_id" => rfq_id}) do
    rfq = Rfqs.get_rfq!(rfq_id)

    cond do
      not invited_to_supplier?(rfq, socket.assigns.supplier.id) ->
        socket
        |> put_flash(
          :error,
          "That request for quotation is not available to your supplier account."
        )
        |> push_navigate(to: ~p"/supplier/rfqs")

      existing_quote = existing_quote(rfq.id, socket.assigns.supplier.id) ->
        socket
        |> put_flash(:info, "A quote already exists for this request for quotation.")
        |> push_navigate(to: ~p"/supplier/quotes/#{existing_quote.id}")

      true ->
        items = draft_quote_items(rfq)
        form = draft_quote_form(rfq)

        socket
        |> assign(:page_title, "Create Quote")
        |> assign(:rfq, rfq)
        |> assign(:quote, nil)
        |> assign(:quote_form, form)
        |> assign(:quote_items, items)
        |> assign(:quote_totals, quote_totals(items, Map.get(form, "vat_rate")))
    end
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    quote = Quotes.get_quote!(id)

    if quote.supplier_id == socket.assigns.supplier.id do
      socket
      |> assign(:page_title, quote.reference)
      |> assign(:rfq, quote.rfq)
      |> assign(:quote, quote)
      |> assign(:quote_form, show_quote_form(quote))
      |> assign(:quote_items, show_quote_items(quote))
      |> assign(:quote_totals, %{
        subtotal: quote.subtotal,
        vat_amount: quote.vat_amount,
        total: quote.total
      })
    else
      socket
      |> put_flash(:error, "That quote is not available to your supplier account.")
      |> push_navigate(to: ~p"/supplier/rfqs")
    end
  end

  defp invited_to_supplier?(rfq, supplier_id),
    do: Enum.any?(rfq.invitations, &(&1.supplier_id == supplier_id))

  defp existing_quote(rfq_id, supplier_id) do
    Quotes.list_quotes(rfq_id: rfq_id, supplier_id: supplier_id)
    |> List.first()
  end

  defp draft_quote_form(rfq) do
    %{
      "valid_until" => rfq.quote_deadline && Date.to_iso8601(rfq.quote_deadline),
      "lead_time_days" => "",
      "delivery_terms" => rfq.delivery_terms || "",
      "general_remarks" => "",
      "vat_rate" => "0.16"
    }
  end

  defp show_quote_form(quote) do
    %{
      "valid_until" => quote.valid_until && Date.to_iso8601(quote.valid_until),
      "lead_time_days" => to_string(quote.lead_time_days || ""),
      "delivery_terms" => quote.delivery_terms,
      "general_remarks" => quote.general_remarks,
      "vat_rate" => LiveHelpers.decimal_to_string(quote.vat_rate)
    }
  end

  defp draft_quote_items(rfq) do
    Enum.map(rfq.items, fn item ->
      %{
        "rfq_item_id" => item.id,
        "inventory_received_id" => item.inventory_received_id,
        "position" => item.position,
        "description" => item.description,
        "category" => item.category,
        "unit" => item.unit || "",
        "quantity_required" => LiveHelpers.decimal_to_string(item.quantity_required),
        "quantity_available" => LiveHelpers.decimal_to_string(item.quantity_required),
        "unit_price" => "0.00",
        "batch_number" => "",
        "brand_origin" => "",
        "expiry_date" => "",
        "total" => Decimal.new(0)
      }
    end)
  end

  defp show_quote_items(quote) do
    Enum.map(quote.items, fn item ->
      %{
        "rfq_item_id" => item.rfq_item_id,
        "inventory_received_id" =>
          item.inventory_received_id || (item.rfq_item && item.rfq_item.inventory_received_id),
        "position" => item.position,
        "description" => item.rfq_item && item.rfq_item.description,
        "category" => item.rfq_item && item.rfq_item.category,
        "unit" => item.unit || "",
        "quantity_required" =>
          item.rfq_item && LiveHelpers.decimal_to_string(item.rfq_item.quantity_required),
        "quantity_available" => LiveHelpers.decimal_to_string(item.quantity_available),
        "unit_price" => LiveHelpers.decimal_to_string(item.unit_price),
        "batch_number" => item.batch_number,
        "brand_origin" => item.brand_origin,
        "expiry_date" => item.expiry_date,
        "total" => item.total || Decimal.new(0)
      }
    end)
  end

  defp quote_form_from_params(params, current) do
    current
    |> Map.merge(
      Map.take(params, ~w(valid_until lead_time_days delivery_terms general_remarks vat_rate))
    )
    |> Map.put_new("vat_rate", "0.16")
  end

  defp quote_items_from_params(params, current) do
    params
    |> Map.get("items", %{})
    |> LiveHelpers.listify_indexed_params()
    |> case do
      [] -> current
      items -> Enum.map(items, &normalize_quote_item/1)
    end
  end

  defp normalize_quote_item(item) do
    total =
      item
      |> Map.get("quantity_available")
      |> LiveHelpers.decimal()
      |> Decimal.mult(LiveHelpers.decimal(Map.get(item, "unit_price")))

    Map.put(item, "total", total)
  end

  defp submit_quote_items(items) do
    Enum.map(items, fn item ->
      %{
        rfq_item_id: item["rfq_item_id"],
        inventory_received_id: blank_to_nil(item["inventory_received_id"]),
        position: item["position"],
        unit: item["unit"],
        quantity_available: blank_to_nil(item["quantity_available"]),
        unit_price: blank_to_nil(item["unit_price"]),
        batch_number: blank_to_nil(item["batch_number"]),
        brand_origin: item["brand_origin"],
        expiry_date: blank_to_nil(item["expiry_date"])
      }
    end)
  end

  defp quote_totals(items, vat_rate) do
    subtotal =
      Enum.reduce(items, Decimal.new(0), fn item, acc ->
        Decimal.add(acc, LiveHelpers.decimal(Map.get(item, "total")))
      end)

    vat_amount = Decimal.mult(subtotal, LiveHelpers.decimal(vat_rate || "0.16"))
    %{subtotal: subtotal, vat_amount: vat_amount, total: Decimal.add(subtotal, vat_amount)}
  end

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value

  defp pipeline_steps,
    do: [:registration, :rfq, :quote, :proforma, :purchase_order, :invoice, :shipment, :grn]

  defp quote_table_input_classes do
    "h-11 w-full rounded-xl border border-slate-200 bg-white px-3 text-sm text-slate-700 shadow-sm outline-none transition placeholder:text-slate-300 focus:border-[#373896] focus:ring-4 focus:ring-[#d2d3ff]"
  end

  defp quote_panel_input_classes do
    "mt-3 h-12 w-full rounded-2xl border border-slate-200 bg-slate-50/70 px-4 text-sm text-slate-700 shadow-sm outline-none transition placeholder:text-slate-300 focus:border-[#373896] focus:bg-white focus:ring-4 focus:ring-[#d2d3ff]"
  end

  defp quote_panel_textarea_classes do
    "mt-3 min-h-32 w-full rounded-2xl border border-slate-200 bg-slate-50/70 px-4 py-3 text-sm text-slate-700 shadow-sm outline-none transition placeholder:text-slate-300 focus:border-[#373896] focus:bg-white focus:ring-4 focus:ring-[#d2d3ff]"
  end

  @impl true
  def render(%{live_action: :show} = assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
        <div class="space-y-2">
          <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">Quote</p>
          <h1 class="text-3xl font-semibold tracking-tight text-slate-900">{@quote.reference}</h1>
          <p class="text-sm leading-6 text-slate-500">Submitted against {@rfq.reference}.</p>
        </div>
        <.status_badge status={@quote.status} />
      </div>

      <.pipeline_tracker
        steps={pipeline_steps()}
        current={:quote}
        document_ids={%{rfq: "/supplier/rfqs/#{@rfq.id}", quote: "/supplier/quotes/#{@quote.id}"}}
      />

      <div class="rounded-[2rem] border border-slate-200 bg-white p-5 shadow-sm">
        <div class="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
          <div class="space-y-1">
            <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
              Status
            </p>
            <p class="text-sm font-medium text-emerald-700">
              Quote submitted. Procurement is reviewing — watch for a purchase order in the Purchase Orders screen if your quote is accepted.
            </p>
          </div>
          <p class="text-sm font-semibold text-[#373896]">
            Total quote value: {LiveHelpers.money(@quote.total)}
          </p>
        </div>
      </div>

      <div class="space-y-6">
        <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
          <div class="overflow-x-auto">
            <table class="w-full min-w-[1120px] table-auto text-left text-sm">
              <thead class="border-b border-slate-200 text-slate-500">
                <tr>
                  <th class="w-12 pb-3 pr-6 font-semibold">#</th>
                  <th class="pb-3 pr-6 font-semibold">Description</th>
                  <th class="w-24 pb-3 pr-6 text-right font-semibold">Qty</th>
                  <th class="w-32 pb-3 pr-6 text-right font-semibold">Unit price</th>
                  <th class="w-40 pb-3 pr-6 font-semibold">Batch/lot</th>
                  <th class="w-48 pb-3 pr-6 font-semibold">Brand/origin</th>
                  <th class="w-32 pb-3 pr-6 font-semibold">Expiry</th>
                  <th class="w-32 pb-3 text-right font-semibold">Total</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-100">
                <tr :for={item <- @quote_items} class="align-top hover:bg-slate-50/60">
                  <td class="py-4 pr-6 text-slate-600">{item["position"]}</td>
                  <td class="py-4 pr-6">
                    <p
                      class="whitespace-normal break-words font-medium leading-6 text-slate-900"
                      title={item["description"]}
                    >
                      {item["description"]}
                    </p>
                  </td>
                  <td class="py-4 pr-6 text-right tabular-nums text-slate-600">
                    {item["quantity_available"]}
                  </td>
                  <td class="py-4 pr-6 text-right tabular-nums text-slate-600 whitespace-nowrap">
                    {LiveHelpers.money(item["unit_price"])}
                  </td>
                  <td class="py-4 pr-6 text-slate-600 whitespace-nowrap">
                    {item["batch_number"] || "N/A"}
                  </td>
                  <td class="py-4 pr-6 text-slate-600 whitespace-nowrap">
                    {item["brand_origin"] || "N/A"}
                  </td>
                  <td class="py-4 pr-6 text-slate-600 whitespace-nowrap">
                    {if item["expiry_date"],
                      do: LiveHelpers.format_date(item["expiry_date"]),
                      else: "N/A"}
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
            Quote summary
          </p>
          <div class="mt-5 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            <div class="rounded-2xl bg-slate-50 px-4 py-3">
              <p class="text-xs font-semibold uppercase tracking-[0.22em] text-slate-400">
                Valid until
              </p>
              <p class="mt-2 text-sm font-medium text-slate-800">
                {LiveHelpers.format_date(@quote.valid_until)}
              </p>
            </div>
            <div class="rounded-2xl bg-slate-50 px-4 py-3">
              <p class="text-xs font-semibold uppercase tracking-[0.22em] text-slate-400">
                Lead time
              </p>
              <p class="mt-2 text-sm font-medium text-slate-800">
                {@quote.lead_time_days || 0} days
              </p>
            </div>
            <div class="rounded-2xl bg-slate-50 px-4 py-3">
              <p class="text-xs font-semibold uppercase tracking-[0.22em] text-slate-400">
                Subtotal
              </p>
              <p class="mt-2 text-sm font-medium text-slate-800">
                {LiveHelpers.money(@quote.subtotal)}
              </p>
            </div>
            <div class="rounded-2xl bg-slate-50 px-4 py-3">
              <p class="text-xs font-semibold uppercase tracking-[0.22em] text-slate-400">
                VAT
              </p>
              <p class="mt-2 text-sm font-medium text-slate-800">
                {LiveHelpers.money(@quote.vat_amount)}
              </p>
            </div>
            <div class="rounded-2xl bg-[#f5f4ff] px-4 py-3 sm:col-span-2 lg:col-span-1">
              <p class="text-xs font-semibold uppercase tracking-[0.22em] text-[#6667ab]">
                Total
              </p>
              <p class="mt-2 text-base font-semibold text-[#373896]">
                {LiveHelpers.money(@quote.total)}
              </p>
            </div>
          </div>
        </div>

        <div
          :if={!LiveHelpers.blank?(@quote.general_remarks)}
          class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm"
        >
          <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">Remarks</p>
          <p class="mt-4 text-sm leading-6 text-slate-600">{@quote.general_remarks}</p>
        </div>
      </div>
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <.portal_form_shell
      eyebrow="Quote Builder"
      title={"Create quote for #{@rfq.reference}"}
      subtitle="All totals are calculated live on the server as you price each request for quotation line item."
      cancel_path={~p"/supplier/rfqs/#{@rfq.id}"}
      max_width="max-w-[96rem]"
    >
      <div class="space-y-6">
        <.pipeline_tracker
          steps={pipeline_steps()}
          current={:quote}
          document_ids={%{rfq: "/supplier/rfqs/#{@rfq.id}"}}
        />

        <form phx-change="change" phx-submit="submit" class="space-y-6">
          <div class="grid gap-6 xl:grid-cols-[minmax(0,1fr)_19rem]">
            <div class="overflow-hidden rounded-[2rem] border border-slate-200 bg-white shadow-sm">
              <div class="border-b border-slate-200 bg-gradient-to-r from-slate-50 via-white to-[#f5f4ff] px-6 py-5">
                <div class="flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
                  <div class="space-y-2">
                    <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
                      Line items
                    </p>
                    <h2 class="text-xl font-semibold text-slate-900">Build your quote</h2>
                    <p class="max-w-2xl text-sm leading-6 text-slate-500">
                      Enter the quantity you can supply, unit price, batch or lot, brand or origin, and expiry where applicable.
                    </p>
                  </div>

                  <p class="text-sm font-medium text-[#373896]">
                    {length(@quote_items)} items in this request for quotation
                  </p>
                </div>
              </div>

              <div class="overflow-x-auto px-4 pb-4 pt-3">
                <table class="w-full min-w-[1160px] table-auto text-left text-sm">
                  <colgroup>
                    <col class="w-[28%]" />
                    <col class="w-[11%]" />
                    <col class="w-[10%]" />
                    <col class="w-[14%]" />
                    <col class="w-[13%]" />
                    <col class="w-[14%]" />
                    <col class="w-[10%]" />
                  </colgroup>
                  <thead>
                    <tr class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-400">
                      <th class="px-3 py-4">Description</th>
                      <th class="px-3 py-4 text-right">Qty</th>
                      <th class="px-3 py-4">Unit</th>
                      <th class="px-3 py-4 text-right">Unit price</th>
                      <th class="px-3 py-4">Batch/lot</th>
                      <th class="px-3 py-4">Brand/origin</th>
                      <th class="px-3 py-4">Expiry</th>
                    </tr>
                  </thead>
                  <tbody class="divide-y divide-slate-100">
                    <tr
                      :for={{item, index} <- Enum.with_index(@quote_items)}
                      class="align-top transition hover:bg-slate-50/80"
                    >
                      <td class="px-3 py-5">
                        <div class="min-w-[18rem] pr-4">
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
                            {item["category"] || "General"} • Requested {item["quantity_required"]} {item[
                              "unit"
                            ] || "units"}
                          </p>
                          <p class="mt-2 text-sm font-semibold text-[#373896]">
                            Line total {LiveHelpers.money(item["total"])}
                          </p>
                        </div>

                        <input
                          type="hidden"
                          name={"quote[items][#{index}][rfq_item_id]"}
                          value={item["rfq_item_id"]}
                        />
                        <input
                          type="hidden"
                          name={"quote[items][#{index}][inventory_received_id]"}
                          value={item["inventory_received_id"]}
                        />
                        <input
                          type="hidden"
                          name={"quote[items][#{index}][position]"}
                          value={item["position"]}
                        />
                        <input
                          type="hidden"
                          name={"quote[items][#{index}][description]"}
                          value={item["description"]}
                        />
                        <input
                          type="hidden"
                          name={"quote[items][#{index}][category]"}
                          value={item["category"]}
                        />
                      </td>

                      <td class="px-3 py-5">
                        <input
                          name={"quote[items][#{index}][quantity_available]"}
                          value={item["quantity_available"]}
                          inputmode="decimal"
                          placeholder="0.00"
                          class={[quote_table_input_classes(), "text-right tabular-nums"]}
                        />
                      </td>

                      <td class="px-3 py-5">
                        <input
                          name={"quote[items][#{index}][unit]"}
                          value={item["unit"]}
                          placeholder="Box"
                          class={quote_table_input_classes()}
                        />
                      </td>

                      <td class="px-3 py-5">
                        <div class="relative">
                          <span class="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">
                            KSh
                          </span>
                          <input
                            name={"quote[items][#{index}][unit_price]"}
                            value={item["unit_price"]}
                            inputmode="decimal"
                            placeholder="0.00"
                            class={["pl-12", quote_table_input_classes(), "text-right tabular-nums"]}
                          />
                        </div>
                      </td>

                      <td class="px-3 py-5">
                        <input
                          name={"quote[items][#{index}][batch_number]"}
                          value={item["batch_number"]}
                          placeholder="Batch or lot"
                          class={quote_table_input_classes()}
                        />
                      </td>

                      <td class="px-3 py-5">
                        <input
                          name={"quote[items][#{index}][brand_origin]"}
                          value={item["brand_origin"]}
                          placeholder="Manufacturer or country"
                          class={quote_table_input_classes()}
                        />
                      </td>

                      <td class="px-3 py-5">
                        <input
                          type="date"
                          name={"quote[items][#{index}][expiry_date]"}
                          value={item["expiry_date"]}
                          class={quote_table_input_classes()}
                        />
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
                    Quote settings
                  </p>
                  <h2 class="mt-2 text-xl font-semibold text-slate-900">Commercial terms</h2>
                  <p class="mt-2 text-sm leading-6 text-slate-500">
                    Set the validity period, delivery details, and tax treatment that apply to this quote.
                  </p>
                </div>

                <div class="space-y-5 p-6">
                  <label class="block">
                    <span class="text-sm font-semibold text-slate-800">Valid until</span>
                    <span class="mt-1 block text-xs text-slate-500">
                      Date until which your quote remains active.
                    </span>
                    <input
                      type="date"
                      name="quote[valid_until]"
                      value={@quote_form["valid_until"]}
                      class={quote_panel_input_classes()}
                    />
                  </label>

                  <label class="block">
                    <span class="text-sm font-semibold text-slate-800">Lead time days</span>
                    <span class="mt-1 block text-xs text-slate-500">
                      Estimated number of days needed to deliver.
                    </span>
                    <input
                      name="quote[lead_time_days]"
                      value={@quote_form["lead_time_days"]}
                      inputmode="numeric"
                      placeholder="e.g. 7"
                      class={quote_panel_input_classes()}
                    />
                  </label>

                  <label class="block">
                    <span class="text-sm font-semibold text-slate-800">Delivery terms</span>
                    <span class="mt-1 block text-xs text-slate-500">
                      Briefly describe the delivery arrangement.
                    </span>
                    <input
                      name="quote[delivery_terms]"
                      value={@quote_form["delivery_terms"]}
                      placeholder="Delivery within Nairobi, weekdays only"
                      class={quote_panel_input_classes()}
                    />
                  </label>

                  <label class="block">
                    <span class="text-sm font-semibold text-slate-800">VAT rate</span>
                    <span class="mt-1 block text-xs text-slate-500">
                      Use a decimal value, for example 0.16.
                    </span>
                    <input
                      name="quote[vat_rate]"
                      value={@quote_form["vat_rate"]}
                      inputmode="decimal"
                      placeholder="0.16"
                      class={quote_panel_input_classes()}
                    />
                  </label>

                  <label class="block">
                    <span class="text-sm font-semibold text-slate-800">General remarks</span>
                    <span class="mt-1 block text-xs text-slate-500">
                      Add any commercial notes, assumptions, or special conditions.
                    </span>
                    <textarea
                      name="quote[general_remarks]"
                      rows="5"
                      class={quote_panel_textarea_classes()}
                      placeholder="Optional notes for procurement"
                    >{@quote_form["general_remarks"]}</textarea>
                  </label>
                </div>
              </div>

              <div class="overflow-hidden rounded-[2rem] border border-slate-200 bg-white shadow-sm">
                <div class="border-b border-slate-200 px-6 py-4">
                  <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
                    Totals
                  </p>
                  <h3 class="mt-2 text-lg font-semibold text-slate-900">Live quote summary</h3>
                </div>

                <div class="space-y-4 p-6">
                  <div class="rounded-2xl bg-[#f5f4ff] px-4 py-4">
                    <p class="text-[11px] font-semibold uppercase tracking-[0.22em] text-[#6667ab]">
                      Estimated total
                    </p>
                    <p class="mt-2 text-3xl font-semibold tracking-tight text-[#373896]">
                      {LiveHelpers.money(@quote_totals.total)}
                    </p>
                  </div>

                  <div class="space-y-3 text-sm text-slate-600">
                    <div class="flex items-center justify-between">
                      <span>Subtotal</span><span>{LiveHelpers.money(@quote_totals.subtotal)}</span>
                    </div>
                    <div class="flex items-center justify-between">
                      <span>VAT</span><span>{LiveHelpers.money(@quote_totals.vat_amount)}</span>
                    </div>
                    <div class="flex items-center justify-between border-t border-slate-200 pt-3 text-base font-semibold text-slate-900">
                      <span>Total</span><span>{LiveHelpers.money(@quote_totals.total)}</span>
                    </div>
                  </div>
                </div>
              </div>

              <button
                type="submit"
                class="w-full rounded-2xl bg-[#373896] px-4 py-3.5 text-sm font-semibold text-white shadow-lg shadow-[#373896]/20 transition hover:bg-[#2d2d7a]"
              >
                Submit quote
              </button>

              <p class="text-center text-xs leading-5 text-slate-400">
                Submitting will create your supplier quote against this request for quotation.
              </p>
            </div>
          </div>
        </form>
      </div>
    </.portal_form_shell>
    """
  end
end
