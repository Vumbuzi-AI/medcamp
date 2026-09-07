defmodule MedcampWeb.Procurement.QuoteComparisonLive do
  use MedcampWeb, :procurement_live_view

  import MedcampWeb.ProcurementComponents, only: [status_badge: 1, score_bar: 1]

  alias Medcamp.Procurement.{Quotes, Rfqs}
  alias MedcampWeb.Procurement.LiveHelpers

  @refresh_events ~w(quote_submitted quote_accepted quote_rejected rfq_closed)a

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Quote Comparison")
     |> assign(:sort_by, "score")}
  end

  @impl true
  def handle_params(%{"rfq_id" => rfq_id} = params, _uri, socket) do
    rfq = Rfqs.get_rfq!(rfq_id)
    selected_quote_id = params["quote_id"]

    {:noreply, assign_quotes(socket, rfq, socket.assigns.sort_by, selected_quote_id)}
  end

  @impl true
  def handle_event("sort", %{"by" => sort_by}, socket) do
    selected_quote_id = socket.assigns.selected_quote && socket.assigns.selected_quote.id

    {:noreply,
     socket
     |> assign(:sort_by, sort_by)
     |> assign_quotes(socket.assigns.rfq, sort_by, selected_quote_id)}
  end

  def handle_event("select_quote", %{"id" => id}, socket) do
    {:noreply, assign_selected_quote(socket, id)}
  end

  def handle_event("accept", %{"id" => id}, socket) do
    case Quotes.get_quote(id) do
      nil ->
        {:noreply, put_flash(socket, :error, "Quote not found.")}

      quote ->
        case Quotes.accept(quote, socket.assigns.current_user) do
          {:ok, _quote} ->
            {:noreply,
             socket
             |> put_flash(:info, "Quote accepted. Continue to purchase order creation.")
             |> push_navigate(to: "/procurement/purchase-orders/new/#{socket.assigns.rfq.id}")}

          _ ->
            {:noreply, put_flash(socket, :error, "Unable to accept that quote right now.")}
        end
    end
  end

  @impl true
  def handle_info({event, _payload}, socket) when event in @refresh_events do
    selected_quote_id = socket.assigns.selected_quote && socket.assigns.selected_quote.id

    {:noreply,
     assign_quotes(socket, socket.assigns.rfq, socket.assigns.sort_by, selected_quote_id)}
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  defp assign_quotes(socket, rfq, sort_by, selected_quote_id) do
    quotes = Quotes.compare_for_rfq(rfq.id) |> LiveHelpers.sort_quotes(sort_by)
    selected_quote = find_selected_quote(quotes, selected_quote_id)

    socket
    |> assign(:rfq, rfq)
    |> assign(:quotes, quotes)
    |> assign(:selected_quote, selected_quote)
    |> assign(:selected_quote_id, selected_quote && selected_quote.id)
    |> assign(:page_title, "Quote Comparison")
  end

  defp assign_selected_quote(socket, selected_quote_id) do
    selected_quote = find_selected_quote(socket.assigns.quotes, selected_quote_id)

    socket
    |> assign(:selected_quote, selected_quote)
    |> assign(:selected_quote_id, selected_quote && selected_quote.id)
  end

  defp find_selected_quote(quotes, selected_quote_id) do
    cond do
      LiveHelpers.blank?(selected_quote_id) ->
        List.first(quotes)

      true ->
        Enum.find(quotes, &("#{&1.id}" == "#{selected_quote_id}")) || List.first(quotes)
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
        <div class="space-y-2">
          <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
            Quote comparison
          </p>
          <h1 class="text-3xl font-semibold tracking-tight text-slate-900">{@rfq.reference}</h1>
          <p class="text-sm leading-6 text-slate-500">{@rfq.title}</p>
        </div>

        <div class="flex flex-wrap gap-3">
          <button
            type="button"
            phx-click="sort"
            phx-value-by="score"
            class={sort_button_classes(@sort_by, "score")}
          >
            Sort by score
          </button>
          <button
            type="button"
            phx-click="sort"
            phx-value-by="price"
            class={sort_button_classes(@sort_by, "price")}
          >
            Sort by price
          </button>
          <button
            type="button"
            phx-click="sort"
            phx-value-by="lead_time"
            class={sort_button_classes(@sort_by, "lead_time")}
          >
            Sort by lead time
          </button>
        </div>
      </div>

      <div class="rounded-2xl border border-emerald-200 bg-emerald-50 px-5 py-4 text-sm text-emerald-800">
        Simple rule: review the quotes for this request for quotation, accept one supplier, then the system takes you straight to purchase-order creation for that accepted quote.
      </div>

      <div class="overflow-hidden rounded-[2rem] border border-slate-200 bg-white shadow-sm">
        <div class="border-b border-slate-200 bg-gradient-to-r from-slate-50 via-white to-[#f6f3ff] px-6 py-5">
          <div class="flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
            <div>
              <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
                Supplier offers
              </p>
              <h2 class="mt-2 text-xl font-semibold text-slate-900">Review supplier quotes</h2>
              <p class="mt-2 text-sm leading-6 text-slate-500">
                Select a quote to inspect item pricing, batch details, expiry dates, and commercial notes before accepting it.
              </p>
            </div>

            <div class="rounded-2xl bg-[#f4f1ff] px-4 py-3 text-sm text-[#373896]">
              <span class="font-semibold">{length(@quotes)}</span> quote(s) received
            </div>
          </div>
        </div>

        <div class="overflow-x-auto px-6 py-5">
          <table class="min-w-full text-left text-sm">
            <thead class="border-b border-slate-200 text-slate-500">
              <tr>
                <th class="pb-3 pr-4 font-semibold">Supplier</th>
                <th class="pb-3 pr-4 font-semibold">Commercial snapshot</th>
                <th class="pb-3 pr-4 font-semibold">Score</th>
                <th class="pb-3 pr-4 font-semibold">Status</th>
                <th class="pb-3 font-semibold text-right">Action</th>
              </tr>
            </thead>
            <tbody class="divide-y  divide-slate-100">
              <tr
                :for={{quote, index} <- Enum.with_index(@quotes)}
                class={quote_row_classes(quote, @selected_quote_id, index)}
              >
                <td class="py-4 p-2 pr-4">
                  <p class="font-medium text-slate-900">
                    {quote.supplier && (quote.supplier.legal_name || quote.supplier.name)}
                  </p>
                  <p class="mt-1 text-xs text-slate-500">{quote.reference}</p>
                  <p class="mt-1 text-xs text-slate-400">
                    Valid until {LiveHelpers.format_date(quote.valid_until)}
                  </p>
                </td>
                <td class="py-4 pr-4">
                  <div class="grid gap-3 sm:grid-cols-2">
                    <div>
                      <p class="text-[11px] font-semibold uppercase tracking-[0.2em] text-slate-400">
                        Total
                      </p>
                      <p class="mt-1 font-semibold text-slate-900">
                        {LiveHelpers.money(quote.total)}
                      </p>
                    </div>
                    <div>
                      <p class="text-[11px] font-semibold uppercase tracking-[0.2em] text-slate-400">
                        Lead time
                      </p>
                      <p class="mt-1 font-semibold text-slate-900">
                        {quote.lead_time_days || 0} days
                      </p>
                    </div>
                    <div>
                      <p class="text-[11px] font-semibold uppercase tracking-[0.2em] text-slate-400">
                        Items
                      </p>
                      <p class="mt-1 text-slate-600">{length(quote.items)} lines quoted</p>
                    </div>
                    <div>
                      <p class="text-[11px] font-semibold uppercase tracking-[0.2em] text-slate-400">
                        VAT
                      </p>
                      <p class="mt-1 text-slate-600">{LiveHelpers.money(quote.vat_amount)}</p>
                    </div>
                  </div>
                </td>
                <td class="py-4 pr-4">
                  <.score_bar score={quote.score || 0} />
                </td>
                <td class="py-4  pr-4"><.status_badge status={quote.status} /></td>
                <td class="py-4 px-2 text-right">
                  <div class="flex justify-end gap-3">
                    <button
                      type="button"
                      phx-click="select_quote"
                      phx-value-id={quote.id}
                      class="rounded-xl border border-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-700 transition hover:bg-slate-50"
                    >
                      {if @selected_quote_id == quote.id, do: "Reviewing", else: "Review"}
                    </button>

                    <button
                      :if={quote.status in ["submitted", "under_review"]}
                      type="button"
                      phx-click="accept"
                      phx-value-id={quote.id}
                      class="rounded-xl bg-[#373896] px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-[#2d2d7a]"
                    >
                      Accept
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>

          <div
            :if={Enum.empty?(@quotes)}
            class="rounded-2xl border border-dashed border-slate-200 px-4 py-8 text-sm text-slate-500"
          >
            No supplier quotes have been submitted for this request for quotation yet.
          </div>
        </div>
      </div>

      <div
        :if={@selected_quote}
        class="space-y-6 rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm"
      >
        <div class="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
          <div>
            <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
              Selected quote
            </p>
            <h2 class="mt-2 text-2xl font-semibold text-slate-900">{@selected_quote.reference}</h2>
            <p class="mt-2 text-sm leading-6 text-slate-500">
              {selected_quote_supplier(@selected_quote)} quoted {length(@selected_quote.items)} line item(s) for this request for quotation.
            </p>
          </div>

          <div class="flex flex-wrap items-center gap-3">
            <.status_badge status={@selected_quote.status} />
            <button
              :if={@selected_quote.status in ["submitted", "under_review"]}
              type="button"
              phx-click="accept"
              phx-value-id={@selected_quote.id}
              class="rounded-xl bg-[#373896] px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-[#2d2d7a]"
            >
              Accept this quote
            </button>
          </div>
        </div>

        <div class="grid gap-4 sm:grid-cols-2 xl:grid-cols-6">
          <.detail_tile label="Supplier" value={selected_quote_supplier(@selected_quote)} />
          <.detail_tile label="Score" value={"#{@selected_quote.score || 0}%"} />
          <.detail_tile label="Lead time" value={"#{@selected_quote.lead_time_days || 0} days"} />
          <.detail_tile
            label="Valid until"
            value={LiveHelpers.format_date(@selected_quote.valid_until)}
          />
          <.detail_tile label="Total" value={LiveHelpers.money(@selected_quote.total)} />
          <.detail_tile label="Compliance" value={"#{@selected_quote.compliance_score || 0}%"} />
        </div>

        <div class="space-y-4">
          <div class="overflow-hidden rounded-[1.75rem] border border-slate-200 bg-white">
            <div class="border-b border-slate-200 bg-slate-50 px-5 py-4">
              <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
                Item breakdown
              </p>
              <h3 class="mt-2 text-lg font-semibold text-slate-900">
                Unit price, batch, and expiry review
              </h3>
            </div>

            <div class="overflow-x-auto px-5 py-4">
              <table class="w-full min-w-[1120px] table-auto text-left text-sm">
                <thead class="border-b border-slate-200 text-slate-500">
                  <tr>
                    <th class="pb-3 pr-6 font-semibold">Item</th>
                    <th class="w-28 pb-3 pr-6 text-right font-semibold">Requested</th>
                    <th class="w-28 pb-3 pr-6 text-right font-semibold">Quoted</th>
                    <th class="w-24 pb-3 pr-6 font-semibold">Unit</th>
                    <th class="w-32 pb-3 pr-6 text-right font-semibold">Unit price</th>
                    <th class="w-40 pb-3 pr-6 font-semibold">Batch/lot</th>
                    <th class="w-32 pb-3 pr-6 font-semibold">Expiry</th>
                    <th class="w-48 pb-3 pr-6 font-semibold">Brand/origin</th>
                    <th class="w-32 pb-3 text-right font-semibold">Line total</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-slate-100">
                  <tr :for={item <- @selected_quote.items} class="align-top hover:bg-slate-50/60">
                    <td class="py-4 pr-6">
                      <p
                        class="whitespace-normal break-words font-semibold text-slate-900"
                        title={quote_item_description(item)}
                      >
                        {quote_item_description(item)}
                      </p>
                      <p class="mt-1 text-xs text-slate-500">
                        {quote_item_category(item)}
                      </p>
                    </td>
                    <td class="py-4 pr-6 text-right tabular-nums text-slate-600">
                      {item.rfq_item && LiveHelpers.decimal_to_string(item.rfq_item.quantity_required)}
                    </td>
                    <td class="py-4 pr-6 text-right tabular-nums text-slate-600">
                      {LiveHelpers.decimal_to_string(item.quantity_available)}
                    </td>
                    <td class="py-4 pr-6 text-slate-600 whitespace-nowrap">{item.unit || "N/A"}</td>
                    <td class="py-4 pr-6 text-right tabular-nums text-slate-900 whitespace-nowrap">
                      {LiveHelpers.money(item.unit_price)}
                    </td>
                    <td class="py-4 pr-6 text-slate-600 whitespace-nowrap">
                      {item.batch_number || "Not provided"}
                    </td>
                    <td class="py-4 pr-6 text-slate-600 whitespace-nowrap">
                      {if item.expiry_date,
                        do: LiveHelpers.format_date(item.expiry_date),
                        else: "Not provided"}
                    </td>
                    <td class="py-4 pr-6 text-slate-600 whitespace-nowrap">
                      {item.brand_origin || "Not provided"}
                    </td>
                    <td class="py-4 text-right tabular-nums font-medium text-slate-900 whitespace-nowrap">
                      {LiveHelpers.money(item.total)}
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          <div class="grid gap-4 lg:grid-cols-3">
            <div class="rounded-[1.75rem] border border-slate-200 bg-slate-50 p-5">
              <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
                Commercial summary
              </p>
              <div class="mt-4 space-y-3 text-sm text-slate-600">
                <div class="flex items-center justify-between">
                  <span>Subtotal</span>
                  <span>{LiveHelpers.money(@selected_quote.subtotal)}</span>
                </div>
                <div class="flex items-center justify-between">
                  <span>VAT</span>
                  <span>{LiveHelpers.money(@selected_quote.vat_amount)}</span>
                </div>
                <div class="flex items-center justify-between border-t border-slate-200 pt-3 font-semibold text-slate-900">
                  <span>Total</span>
                  <span>{LiveHelpers.money(@selected_quote.total)}</span>
                </div>
              </div>
            </div>

            <div class="rounded-[1.75rem] border border-slate-200 bg-slate-50 p-5">
              <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
                Delivery terms
              </p>
              <p class="mt-3 text-sm leading-6 text-slate-600">
                {if LiveHelpers.blank?(@selected_quote.delivery_terms),
                  do: "No delivery terms supplied.",
                  else: @selected_quote.delivery_terms}
              </p>
            </div>

            <div class="rounded-[1.75rem] border border-slate-200 bg-slate-50 p-5">
              <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
                Supplier remarks
              </p>
              <p class="mt-3 text-sm leading-6 text-slate-600">
                {if LiveHelpers.blank?(@selected_quote.general_remarks),
                  do: "No extra supplier remarks were added to this quote.",
                  else: @selected_quote.general_remarks}
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp selected_quote_supplier(nil), do: nil

  defp selected_quote_supplier(quote) do
    quote.supplier && (quote.supplier.legal_name || quote.supplier.name)
  end

  defp quote_item_description(item) do
    (item.rfq_item && item.rfq_item.description) || "Quoted item"
  end

  defp quote_item_category(item) do
    (item.rfq_item && item.rfq_item.category) || "General"
  end

  defp sort_button_classes(current_sort, sort_by) do
    base =
      "rounded-xl border px-4 py-2.5 text-sm font-semibold transition"

    if current_sort == sort_by do
      base <> " border-[#373896] bg-[#f4f1ff] text-[#373896] shadow-sm"
    else
      base <> " border-slate-200 text-slate-700 hover:bg-slate-50"
    end
  end

  defp quote_row_classes(quote, selected_quote_id, index) do
    cond do
      quote.id == selected_quote_id ->
        "bg-[#f6f3ff] ring-1 ring-inset ring-[#d9d2ff]"

      index == 0 ->
        "bg-slate-50/70"

      true ->
        ""
    end
  end

  attr :label, :string, required: true
  attr :value, :any, default: nil

  defp detail_tile(assigns) do
    ~H"""
    <div class="rounded-2xl bg-slate-50 px-4 py-3">
      <p class="text-[11px] font-semibold uppercase tracking-[0.2em] text-slate-400">{@label}</p>
      <p class="mt-2 text-sm font-medium text-slate-800">
        {if LiveHelpers.blank?(@value), do: "Not provided", else: @value}
      </p>
    </div>
    """
  end
end
