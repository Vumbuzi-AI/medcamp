defmodule MedcampWeb.Procurement.RfqDetailLive do
  use MedcampWeb, :procurement_live_view

  import MedcampWeb.ProcurementComponents, only: [status_badge: 1, pipeline_tracker: 1]

  alias Medcamp.Procurement.{Quotes, Rfqs}
  alias MedcampWeb.Procurement.LiveHelpers

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Request for quotation detail")}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    {:noreply, assign_rfq(socket, id)}
  end

  defp assign_rfq(socket, id) do
    rfq = Rfqs.get_rfq!(id)

    socket
    |> assign(:page_title, rfq.reference)
    |> assign(:rfq, rfq)
    |> assign(:quote_stats, quote_stats(rfq.id))
  end

  defp quote_stats(rfq_id) do
    quotes = Quotes.list_for_rfq(rfq_id)
    accepted_quote = Enum.find(quotes, &(&1.status == "accepted"))

    %{
      total: length(quotes),
      submitted: Enum.count(quotes, &(&1.status in ["submitted", "under_review", "accepted"])),
      accepted_quote: accepted_quote
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
        <div class="space-y-2">
          <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
            Request for quotation detail
          </p>
          <h1 class="text-3xl font-semibold tracking-tight text-slate-900">{@rfq.reference}</h1>
          <p class="text-sm leading-6 text-slate-500">{@rfq.title}</p>
        </div>
        <.status_badge status={@rfq.status} />
      </div>

      <.pipeline_tracker
        steps={LiveHelpers.pipeline_steps()}
        current={:rfq}
        document_ids={%{rfq: "/procurement/rfqs/#{@rfq.id}"}}
      />

      <div class="rounded-[2rem] border border-slate-200 bg-white p-5 shadow-sm">
        <div class="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
          <div class="space-y-1">
            <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
              Next action
            </p>
            <p :if={@quote_stats.total == 0} class="text-sm font-medium text-amber-700">
              No supplier quote has been submitted yet. The next stop for this request for quotation will be quote comparison after responses come in.
            </p>
            <p
              :if={@quote_stats.total > 0 and is_nil(@quote_stats.accepted_quote)}
              class="text-sm font-medium text-emerald-700"
            >
              Quotes are available. Review them, accept one supplier, and the system will move you toward PO creation.
            </p>
            <p :if={@quote_stats.accepted_quote} class="text-sm font-medium text-violet-700">
              Quote <span class="font-semibold">{@quote_stats.accepted_quote.reference}</span>
              has already been accepted. The next step is creating the purchase order from that accepted quote.
            </p>
            <p class="text-xs text-slate-500">
              {length(@rfq.invitations)} suppliers invited · {@quote_stats.submitted} quotes received
            </p>
          </div>

          <div class="flex flex-wrap items-center gap-3">
            <.link
              navigate={~p"/procurement/quotes/#{@rfq.id}"}
              class="inline-flex items-center justify-center rounded-xl bg-[#373896] px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-[#2d2d7a]"
            >
              Review quotes
            </.link>
            <.link
              :if={@quote_stats.accepted_quote}
              navigate={~p"/procurement/purchase-orders/new/#{@rfq.id}"}
              class="inline-flex items-center justify-center rounded-xl border border-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-700 transition hover:bg-slate-50"
            >
              Create PO from accepted quote
            </.link>
          </div>
        </div>
      </div>

      <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
        <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
          Request summary
        </p>
        <div class="mt-5 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          <.detail_tile label="Department" value={@rfq.department} />
          <.detail_tile label="Priority" value={String.capitalize(@rfq.priority || "normal")} />
          <.detail_tile label="Issue date" value={LiveHelpers.format_date(@rfq.issue_date)} />
          <.detail_tile label="Deadline" value={LiveHelpers.format_date(@rfq.quote_deadline)} />
          <.detail_tile label="Delivery by" value={LiveHelpers.format_date(@rfq.delivery_by)} />
          <.detail_tile label="Currency" value={@rfq.currency || "KES"} />
        </div>

        <div
          :if={LiveHelpers.present?(@rfq.special_instructions)}
          class="mt-5 rounded-2xl bg-slate-50 px-4 py-4"
        >
          <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
            Special instructions
          </p>
          <p class="mt-2 text-sm leading-6 text-slate-600">{@rfq.special_instructions}</p>
        </div>
      </div>

      <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
        <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
          Invited suppliers
        </p>
        <div class="mt-4 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
          <div
            :for={invitation <- @rfq.invitations}
            class="rounded-2xl border border-slate-100 bg-slate-50 px-4 py-3"
          >
            <p class="text-sm font-semibold text-slate-800">
              {invitation.supplier && (invitation.supplier.legal_name || invitation.supplier.name)}
            </p>
            <p class="mt-1 text-xs text-slate-500">
              Sent {LiveHelpers.format_datetime(invitation.sent_at)}
            </p>
          </div>
        </div>
      </div>

      <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
        <div class="overflow-x-auto">
          <table class="w-full min-w-[820px] table-auto text-left text-sm">
            <thead class="border-b border-slate-200 text-slate-500">
              <tr>
                <th class="w-12 pb-3 pr-6 font-semibold">#</th>
                <th class="pb-3 pr-6 font-semibold">Description</th>
                <th class="w-24 pb-3 pr-6 text-right font-semibold">Qty</th>
                <th class="w-24 pb-3 pr-6 font-semibold">Unit</th>
                <th class="w-32 pb-3 text-right font-semibold">Estimate</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
              <tr :for={item <- @rfq.items} class="align-top hover:bg-slate-50/60">
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
                  {LiveHelpers.decimal_to_string(item.quantity_required)}
                </td>
                <td class="py-4 pr-6 text-slate-600 whitespace-nowrap">{item.unit}</td>
                <td class="py-4 text-right tabular-nums text-slate-600 whitespace-nowrap">
                  {LiveHelpers.money(item.estimated_unit_price)}
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
    """
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
