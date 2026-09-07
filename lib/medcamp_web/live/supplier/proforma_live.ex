defmodule MedcampWeb.Supplier.ProformaLive do
  use MedcampWeb, :supplier_live_view

  import MedcampWeb.ProcurementComponents,
    only: [status_badge: 1, pipeline_tracker: 1, portal_form_shell: 1]

  alias Medcamp.Procurement.{ProformaInvoices, Quotes}
  alias MedcampWeb.Supplier.LiveHelpers

  @impl true
  def mount(_params, _session, socket) do
    case LiveHelpers.load_supplier(socket.assigns.current_user, create?: true) do
      {:ok, supplier, user} ->
        {:ok,
         socket
         |> LiveHelpers.maybe_assign_current_user(user)
         |> assign(:page_title, "Proforma Invoice")
         |> assign(:quote, nil)
         |> assign(:proforma, nil)
         |> assign(:proforma_form, %{})
         |> assign(:proforma_items, [])
         |> assign(:proforma_totals, %{
           subtotal: Decimal.new(0),
           vat_amount: Decimal.new(0),
           total: Decimal.new(0)
         })
         |> assign(:supplier, supplier)}

      {:error, :missing_supplier} ->
        {:ok, push_navigate(socket, to: LiveHelpers.registration_path(:company))}
    end
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("change", %{"proforma" => params}, socket) do
    items = proforma_items_from_params(params, socket.assigns.proforma_items)
    form = proforma_form_from_params(params, socket.assigns.proforma_form)

    {:noreply,
     socket
     |> assign(:proforma_form, form)
     |> assign(:proforma_items, items)
     |> assign(:proforma_totals, proforma_totals(items))}
  end

  def handle_event("submit", %{"proforma" => params}, socket) do
    items = proforma_items_from_params(params, socket.assigns.proforma_items)
    form = proforma_form_from_params(params, socket.assigns.proforma_form)

    attrs = %{
      valid_until: blank_to_nil(Map.get(form, "valid_until")),
      currency: Map.get(form, "currency"),
      bill_to: Map.get(form, "bill_to"),
      ship_to: Map.get(form, "ship_to"),
      payment_instructions: Map.get(form, "payment_instructions"),
      items: submit_proforma_items(items)
    }

    result =
      case socket.assigns.proforma do
        nil ->
          with {:ok, proforma} <-
                 ProformaInvoices.create_from_quote(
                   socket.assigns.quote,
                   Map.drop(attrs, [:items])
                 ),
               {:ok, proforma} <- ProformaInvoices.update(proforma, attrs),
               {:ok, proforma} <- ProformaInvoices.submit(proforma) do
            {:ok, proforma}
          end

        proforma ->
          with {:ok, proforma} <- ProformaInvoices.update(proforma, attrs),
               {:ok, proforma} <- ProformaInvoices.submit(proforma) do
            {:ok, proforma}
          end
      end

    case result do
      {:ok, proforma} ->
        {:noreply,
         socket
         |> put_flash(:info, "Proforma invoice submitted successfully.")
         |> push_navigate(to: ~p"/supplier/proforma-invoices/#{proforma.id}")}

      {:error, _reason} ->
        {:noreply,
         socket
         |> assign(:proforma_form, form)
         |> assign(:proforma_items, items)
         |> assign(:proforma_totals, proforma_totals(items))
         |> put_flash(:error, "We could not submit the proforma invoice right now.")}
    end
  end

  defp apply_action(socket, :new, %{"quote_id" => quote_id}) do
    quote = Quotes.get_quote!(quote_id)
    existing = existing_proforma(socket.assigns.supplier.id, quote.id)

    cond do
      quote.supplier_id != socket.assigns.supplier.id ->
        socket
        |> put_flash(:error, "That quote is not available to your supplier account.")
        |> push_navigate(to: ~p"/supplier/rfqs")

      quote.status != "accepted" and is_nil(existing) ->
        socket
        |> put_flash(:error, "A proforma invoice can only be created from an accepted quote.")
        |> push_navigate(to: ~p"/supplier/quotes/#{quote.id}")

      existing && existing.status != "draft" ->
        socket
        |> put_flash(:info, "A proforma invoice already exists for that quote.")
        |> push_navigate(to: ~p"/supplier/proforma-invoices/#{existing.id}")

      true ->
        socket
        |> assign(:page_title, "Create Proforma Invoice")
        |> assign(:quote, quote)
        |> assign(:proforma, existing)
        |> assign(:proforma_form, draft_proforma_form(quote, existing))
        |> assign(:proforma_items, draft_proforma_items(quote, existing))
        |> assign(:proforma_totals, proforma_totals(draft_proforma_items(quote, existing)))
    end
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    proforma = ProformaInvoices.get_proforma_invoice!(id)

    if proforma.supplier_id == socket.assigns.supplier.id do
      socket
      |> assign(:page_title, proforma.reference)
      |> assign(:quote, proforma.quote)
      |> assign(:proforma, proforma)
      |> assign(:proforma_form, show_proforma_form(proforma))
      |> assign(:proforma_items, show_proforma_items(proforma))
      |> assign(:proforma_totals, %{
        subtotal: proforma.subtotal,
        vat_amount: proforma.vat_amount,
        total: proforma.total
      })
    else
      socket
      |> put_flash(:error, "That proforma invoice is not available to your supplier account.")
      |> push_navigate(to: ~p"/supplier/rfqs")
    end
  end

  defp existing_proforma(supplier_id, quote_id) do
    ProformaInvoices.list_proforma_invoices(supplier_id: supplier_id)
    |> Enum.find(&(&1.quote_id == quote_id))
    |> case do
      nil -> nil
      proforma -> ProformaInvoices.get_proforma_invoice!(proforma.id)
    end
  end

  defp draft_proforma_form(quote, nil) do
    %{
      "valid_until" => quote.valid_until && Date.to_iso8601(quote.valid_until),
      "currency" => "KES",
      "bill_to" => "",
      "ship_to" => "",
      "payment_instructions" => ""
    }
  end

  defp draft_proforma_form(_quote, proforma), do: show_proforma_form(proforma)

  defp show_proforma_form(proforma) do
    %{
      "valid_until" => proforma.valid_until && Date.to_iso8601(proforma.valid_until),
      "currency" => proforma.currency || "KES",
      "bill_to" => proforma.bill_to,
      "ship_to" => proforma.ship_to,
      "payment_instructions" => proforma.payment_instructions
    }
  end

  defp draft_proforma_items(quote, nil) do
    Enum.map(quote.items, fn item ->
      gross =
        item.quantity_available
        |> LiveHelpers.decimal()
        |> Decimal.mult(LiveHelpers.decimal(item.unit_price))

      %{
        "rfq_item_id" => item.rfq_item_id,
        "inventory_received_id" =>
          item.inventory_received_id || (item.rfq_item && item.rfq_item.inventory_received_id),
        "position" => item.position,
        "description" => item.rfq_item && item.rfq_item.description,
        "unit" => item.unit || "",
        "quantity" => LiveHelpers.decimal_to_string(item.quantity_available),
        "unit_price" => LiveHelpers.decimal_to_string(item.unit_price),
        "discount_percent" => "0",
        "discount_amount" => "0",
        "total" => gross
      }
    end)
  end

  defp draft_proforma_items(_quote, proforma), do: show_proforma_items(proforma)

  defp show_proforma_items(proforma) do
    Enum.map(proforma.items, fn item ->
      %{
        "rfq_item_id" => item.rfq_item_id,
        "inventory_received_id" => item.inventory_received_id,
        "position" => item.position,
        "description" => item.description,
        "unit" => item.unit,
        "quantity" => LiveHelpers.decimal_to_string(item.quantity),
        "unit_price" => LiveHelpers.decimal_to_string(item.unit_price),
        "discount_percent" => LiveHelpers.decimal_to_string(item.discount_percent),
        "discount_amount" => LiveHelpers.decimal_to_string(item.discount_amount),
        "total" => item.total || Decimal.new(0)
      }
    end)
  end

  defp proforma_form_from_params(params, current),
    do:
      Map.merge(
        current,
        Map.take(params, ~w(valid_until currency bill_to ship_to payment_instructions))
      )

  defp proforma_items_from_params(params, current) do
    params
    |> Map.get("items", %{})
    |> LiveHelpers.listify_indexed_params()
    |> case do
      [] -> current
      items -> Enum.map(items, &normalize_proforma_item/1)
    end
  end

  defp normalize_proforma_item(item) do
    qty = LiveHelpers.decimal(Map.get(item, "quantity"))
    unit_price = LiveHelpers.decimal(Map.get(item, "unit_price"))
    gross = Decimal.mult(qty, unit_price)
    discount_percent = LiveHelpers.decimal(Map.get(item, "discount_percent"))
    discount_amount = LiveHelpers.decimal(Map.get(item, "discount_amount"))
    percent_discount = Decimal.mult(gross, Decimal.div(discount_percent, Decimal.new(100)))
    total = gross |> Decimal.sub(percent_discount) |> Decimal.sub(discount_amount)

    Map.put(item, "total", total)
  end

  defp submit_proforma_items(items) do
    Enum.map(items, fn item ->
      %{
        rfq_item_id: item["rfq_item_id"],
        inventory_received_id: blank_to_nil(item["inventory_received_id"]),
        position: item["position"],
        description: item["description"],
        unit: item["unit"],
        quantity: blank_to_nil(item["quantity"]),
        unit_price: blank_to_nil(item["unit_price"]),
        discount_percent: blank_to_nil(item["discount_percent"]),
        discount_amount: blank_to_nil(item["discount_amount"])
      }
    end)
  end

  defp proforma_totals(items) do
    subtotal =
      Enum.reduce(items, Decimal.new(0), fn item, acc ->
        Decimal.add(acc, LiveHelpers.decimal(Map.get(item, "total")))
      end)

    vat_amount = Decimal.mult(subtotal, Decimal.new("0.16"))
    %{subtotal: subtotal, vat_amount: vat_amount, total: Decimal.add(subtotal, vat_amount)}
  end

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value

  defp pipeline_steps,
    do: [:registration, :rfq, :quote, :proforma, :purchase_order, :invoice, :shipment, :grn]

  @impl true
  def render(%{live_action: :show} = assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
        <div class="space-y-2">
          <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
            Proforma invoice
          </p>
          <h1 class="text-3xl font-semibold tracking-tight text-slate-900">{@proforma.reference}</h1>
          <p class="text-sm leading-6 text-slate-500">Generated from quote {@quote.reference}.</p>
        </div>
        <.status_badge status={@proforma.status} />
      </div>

      <.pipeline_tracker
        steps={pipeline_steps()}
        current={:proforma}
        document_ids={
          %{
            quote: "/supplier/quotes/#{@quote.id}",
            proforma: "/supplier/proforma-invoices/#{@proforma.id}"
          }
        }
      />

      <div class="grid gap-6 xl:grid-cols-[1.2fr_0.8fr]">
        <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
          <div class="overflow-x-auto">
            <table class="w-full min-w-[820px] table-auto text-left text-sm">
              <thead class="border-b border-slate-200 text-slate-500">
                <tr>
                  <th class="pb-3 pr-6 font-semibold">Description</th>
                  <th class="w-24 pb-3 pr-6 text-right font-semibold">Qty</th>
                  <th class="w-32 pb-3 pr-6 text-right font-semibold">Unit price</th>
                  <th class="w-56 pb-3 pr-6 text-right font-semibold">Discount</th>
                  <th class="w-32 pb-3 text-right font-semibold">Total</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-100">
                <tr :for={item <- @proforma_items} class="align-top hover:bg-slate-50/60">
                  <td class="py-4 pr-6">
                    <p
                      class="whitespace-normal break-words font-medium leading-6 text-slate-900"
                      title={item["description"]}
                    >
                      {item["description"]}
                    </p>
                  </td>
                  <td class="py-4 pr-6 text-right tabular-nums text-slate-600">{item["quantity"]}</td>
                  <td class="py-4 pr-6 text-right tabular-nums text-slate-600 whitespace-nowrap">
                    {LiveHelpers.money(item["unit_price"])}
                  </td>
                  <td class="py-4 pr-6 text-right tabular-nums text-slate-600 whitespace-nowrap">
                    {item["discount_percent"]}% + {LiveHelpers.money(item["discount_amount"])}
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
          <div class="space-y-3 text-sm text-slate-600">
            <div class="flex items-center justify-between">
              <span>Valid until</span><span>{LiveHelpers.format_date(@proforma.valid_until)}</span>
            </div>
            <div class="flex items-center justify-between">
              <span>Bill to</span><span>{@proforma.bill_to || "N/A"}</span>
            </div>
            <div class="flex items-center justify-between">
              <span>Ship to</span><span>{@proforma.ship_to || "N/A"}</span>
            </div>
            <div class="flex items-center justify-between">
              <span>Subtotal</span><span>{LiveHelpers.money(@proforma.subtotal)}</span>
            </div>
            <div class="flex items-center justify-between">
              <span>VAT</span><span>{LiveHelpers.money(@proforma.vat_amount)}</span>
            </div>
            <div class="flex items-center justify-between border-t border-slate-200 pt-3 font-semibold text-slate-900">
              <span>Total</span><span>{LiveHelpers.money(@proforma.total)}</span>
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
      eyebrow="Proforma Builder"
      title="Create proforma invoice"
      subtitle="Discount changes are recalculated live per line and reflected in the totals instantly."
      cancel_path={~p"/supplier/quotes/#{@quote.id}"}
      max_width="max-w-7xl"
    >
      <div class="space-y-6">
        <.pipeline_tracker
          steps={pipeline_steps()}
          current={:proforma}
          document_ids={%{quote: "/supplier/quotes/#{@quote.id}"}}
        />

        <form phx-change="change" phx-submit="submit" class="space-y-6">
          <div class="grid gap-6 xl:grid-cols-[1.2fr_0.8fr]">
            <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
              <div class="overflow-x-auto">
                <table class="min-w-full text-left text-sm">
                  <thead class="border-b border-slate-200 text-slate-500">
                    <tr>
                      <th class="pb-3 pr-4 font-semibold">Description</th>
                      <th class="pb-3 pr-4 font-semibold">Qty</th>
                      <th class="pb-3 pr-4 font-semibold">Unit price</th>
                      <th class="pb-3 pr-4 font-semibold">% discount</th>
                      <th class="pb-3 pr-4 font-semibold">Fixed discount</th>
                      <th class="pb-3 font-semibold">Net total</th>
                    </tr>
                  </thead>
                  <tbody class="divide-y divide-slate-100">
                    <tr :for={{item, index} <- Enum.with_index(@proforma_items)}>
                      <td class="py-4 pr-4">
                        <span class="font-medium text-slate-900">{item["description"]}</span>
                        <input
                          type="hidden"
                          name={"proforma[items][#{index}][rfq_item_id]"}
                          value={item["rfq_item_id"]}
                        />
                        <input
                          type="hidden"
                          name={"proforma[items][#{index}][inventory_received_id]"}
                          value={item["inventory_received_id"]}
                        />
                        <input
                          type="hidden"
                          name={"proforma[items][#{index}][position]"}
                          value={item["position"]}
                        />
                        <input
                          type="hidden"
                          name={"proforma[items][#{index}][description]"}
                          value={item["description"]}
                        />
                      </td>
                      <td class="py-4 pr-4">
                        <input
                          name={"proforma[items][#{index}][quantity]"}
                          value={item["quantity"]}
                          class="w-24 rounded-xl border border-slate-200 px-3 py-2"
                        />
                      </td>
                      <td class="py-4 pr-4">
                        <input
                          name={"proforma[items][#{index}][unit_price]"}
                          value={item["unit_price"]}
                          class="w-28 rounded-xl border border-slate-200 px-3 py-2"
                        />
                      </td>
                      <td class="py-4 pr-4">
                        <input
                          name={"proforma[items][#{index}][discount_percent]"}
                          value={item["discount_percent"]}
                          class="w-24 rounded-xl border border-slate-200 px-3 py-2"
                        />
                      </td>
                      <td class="py-4 pr-4">
                        <input
                          name={"proforma[items][#{index}][discount_amount]"}
                          value={item["discount_amount"]}
                          class="w-24 rounded-xl border border-slate-200 px-3 py-2"
                        />
                      </td>
                      <td class="py-4 font-medium text-slate-700">
                        {LiveHelpers.money(item["total"])}
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>

            <div class="space-y-6">
              <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
                <div class="space-y-4">
                  <label class="block text-sm font-medium text-slate-700">
                    Valid until
                    <input
                      type="date"
                      name="proforma[valid_until]"
                      value={@proforma_form["valid_until"]}
                      class="mt-2 w-full rounded-xl border border-slate-200 px-3 py-2.5"
                    />
                  </label>
                  <label class="block text-sm font-medium text-slate-700">
                    Currency
                    <input
                      name="proforma[currency]"
                      value={@proforma_form["currency"]}
                      class="mt-2 w-full rounded-xl border border-slate-200 px-3 py-2.5"
                    />
                  </label>
                  <label class="block text-sm font-medium text-slate-700">
                    Bill to <textarea
                      name="proforma[bill_to]"
                      rows="3"
                      class="mt-2 w-full rounded-xl border border-slate-200 px-3 py-2.5"
                    >{@proforma_form["bill_to"]}</textarea>
                  </label>
                  <label class="block text-sm font-medium text-slate-700">
                    Ship to <textarea
                      name="proforma[ship_to]"
                      rows="3"
                      class="mt-2 w-full rounded-xl border border-slate-200 px-3 py-2.5"
                    >{@proforma_form["ship_to"]}</textarea>
                  </label>
                  <label class="block text-sm font-medium text-slate-700">
                    Payment instructions <textarea
                      name="proforma[payment_instructions]"
                      rows="4"
                      class="mt-2 w-full rounded-xl border border-slate-200 px-3 py-2.5"
                    >{@proforma_form["payment_instructions"]}</textarea>
                  </label>
                </div>
              </div>

              <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
                <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">Totals</p>
                <div class="mt-4 space-y-3 text-sm text-slate-600">
                  <div class="flex items-center justify-between">
                    <span>Subtotal</span><span>{LiveHelpers.money(@proforma_totals.subtotal)}</span>
                  </div>
                  <div class="flex items-center justify-between">
                    <span>VAT</span><span>{LiveHelpers.money(@proforma_totals.vat_amount)}</span>
                  </div>
                  <div class="flex items-center justify-between border-t border-slate-200 pt-3 text-base font-semibold text-slate-900">
                    <span>Total</span><span>{LiveHelpers.money(@proforma_totals.total)}</span>
                  </div>
                </div>
              </div>

              <button
                type="submit"
                class="w-full rounded-xl bg-[#373896] px-4 py-3 text-sm font-semibold text-white transition hover:bg-[#2d2d7a]"
              >
                Submit proforma invoice
              </button>
            </div>
          </div>
        </form>
      </div>
    </.portal_form_shell>
    """
  end
end
