defmodule MedcampWeb.Supplier.RfqInboxLive do
  use MedcampWeb, :supplier_live_view

  import MedcampWeb.ProcurementComponents,
    only: [status_badge: 1, deadline_alert: 1, pipeline_tracker: 1]

  alias Medcamp.Procurement.{Quotes, Rfq, Rfqs}
  alias MedcampWeb.Supplier.LiveHelpers

  @default_filters %{"search" => "", "status" => "", "priority" => ""}

  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    case LiveHelpers.load_supplier(socket.assigns.current_user, create?: true) do
      {:ok, supplier, user} ->
        all_rfqs = Rfqs.list_for_supplier(supplier.id)

        {:ok,
         socket
         |> LiveHelpers.maybe_assign_current_user(user)
         |> assign(:page_title, "Request for quotation inbox")
         |> assign(:supplier, supplier)
         |> assign(:quote, nil)
         |> assign(:rfq, nil)
         |> assign(:filters, @default_filters)
         |> assign(:statuses, ~w(sent closed))
         |> assign(:priorities, Rfq.priorities())
         |> assign(:page, 1)
         |> assign(:per_page, @per_page)
         |> assign(:all_rfqs, all_rfqs)
         |> paginate_rfqs()}

      {:error, :missing_supplier} ->
        {:ok, push_navigate(socket, to: LiveHelpers.registration_path(:company))}
    end
  end

  defp paginate_rfqs(socket) do
    filtered = apply_filters(socket.assigns.all_rfqs, socket.assigns.filters)
    total_count = length(filtered)
    total_pages = Medcamp.Pagination.total_pages(total_count, socket.assigns.per_page)
    page = min(max(1, socket.assigns.page || 1), total_pages)
    rfqs = Enum.slice(filtered, (page - 1) * socket.assigns.per_page, socket.assigns.per_page)

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:rfqs, rfqs)
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  # The search box and the filter drawer submit independently (two separate
  # <form>s), so a submission from either one only carries its own fields.
  # Merging onto the current filters (not the blank defaults) means a key
  # absent from this submission is left unchanged rather than reset.
  @impl true
  def handle_event("filter", %{"filters" => filters}, socket) do
    filters = Map.merge(socket.assigns.filters, filters)

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign(:page, 1)
     |> paginate_rfqs()}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, max(1, String.to_integer(page)))
     |> paginate_rfqs()}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply,
     socket
     |> assign(:filters, @default_filters)
     |> assign(:rfqs, socket.assigns.all_rfqs)}
  end

  @impl true
  def handle_event("clear_chip", %{"field" => field}, socket) do
    filters = Map.put(socket.assigns.filters, field, "")

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign(:rfqs, apply_filters(socket.assigns.all_rfqs, filters))}
  end

  @impl true
  def handle_info({_event, _payload}, socket) do
    all_rfqs = Rfqs.list_for_supplier(socket.assigns.supplier.id)

    socket =
      socket
      |> assign(:all_rfqs, all_rfqs)
      |> paginate_rfqs()
      |> maybe_refresh_current_rfq()

    {:noreply, socket}
  end

  defp apply_filters(rfqs, filters) do
    Enum.filter(rfqs, fn rfq ->
      matches_status?(rfq, filters["status"]) and
        matches_priority?(rfq, filters["priority"]) and
        matches_search?(rfq, filters["search"])
    end)
  end

  defp matches_status?(_rfq, ""), do: true
  defp matches_status?(_rfq, nil), do: true
  defp matches_status?(rfq, status), do: rfq.status == status

  defp matches_priority?(_rfq, ""), do: true
  defp matches_priority?(_rfq, nil), do: true
  defp matches_priority?(rfq, priority), do: (rfq.priority || "normal") == priority

  defp matches_search?(_rfq, ""), do: true
  defp matches_search?(_rfq, nil), do: true

  defp matches_search?(rfq, term) do
    search = term |> String.trim() |> String.downcase()

    [rfq.reference, rfq.title, rfq.department]
    |> Enum.reject(&is_nil/1)
    |> Enum.any?(fn value -> value |> String.downcase() |> String.contains?(search) end)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Request for quotation inbox")
    |> assign(:rfq, nil)
    |> assign(:quote, nil)
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    rfq = Rfqs.get_rfq!(id)

    if invited_to_supplier?(rfq, socket.assigns.supplier.id) do
      mark_invitation_viewed(rfq, socket.assigns.supplier.id)

      socket
      |> assign(:page_title, rfq.reference)
      |> assign(:rfq, Rfqs.get_rfq!(rfq.id))
      |> assign(:quote, existing_quote(rfq.id, socket.assigns.supplier.id))
    else
      socket
      |> put_flash(
        :error,
        "That request for quotation is not available to your supplier account."
      )
      |> push_navigate(to: ~p"/supplier/rfqs")
    end
  end

  defp maybe_refresh_current_rfq(
         %{assigns: %{live_action: :show, rfq: %{id: id}, supplier: supplier}} = socket
       ) do
    assign(socket, :rfq, Rfqs.get_rfq!(id))
    |> assign(:quote, existing_quote(id, supplier.id))
  end

  defp maybe_refresh_current_rfq(socket), do: socket

  defp invited_to_supplier?(rfq, supplier_id) do
    Enum.any?(rfq.invitations, &(&1.supplier_id == supplier_id))
  end

  defp mark_invitation_viewed(rfq, supplier_id) do
    rfq.invitations
    |> Enum.find(&(&1.supplier_id == supplier_id))
    |> case do
      nil -> :ok
      invitation -> Rfqs.mark_viewed(invitation)
    end
  end

  defp existing_quote(rfq_id, supplier_id) do
    Quotes.list_quotes(rfq_id: rfq_id, supplier_id: supplier_id)
    |> List.first()
    |> case do
      nil -> nil
      quote -> Quotes.get_quote!(quote.id)
    end
  end

  defp deadline_label(rfq) do
    case Rfqs.days_until_deadline(rfq) do
      nil -> "Deadline pending"
      days when days < 0 -> "Deadline passed"
      0 -> "Closes today"
      1 -> "Closes tomorrow"
      days -> "#{days} days left"
    end
  end

  defp document_ids(rfq, quote) do
    %{
      rfq: "/supplier/rfqs/#{rfq.id}",
      quote: quote && "/supplier/quotes/#{quote.id}"
    }
    |> Enum.reject(fn {_key, value} -> LiveHelpers.blank?(value) end)
    |> Map.new()
  end

  defp pipeline_steps,
    do: [:registration, :rfq, :quote, :proforma, :purchase_order, :invoice, :shipment, :grn]

  defp count_active_filters(filters) do
    filters
    |> Map.drop(["search"])
    |> Map.values()
    |> Enum.count(&(&1 not in [nil, ""]))
  end

  defp filter_chips(filters) do
    [
      filter_chip(
        filters["status"],
        "status",
        filters["status"] && String.capitalize(filters["status"])
      ),
      filter_chip(
        filters["priority"],
        "priority",
        filters["priority"] && String.capitalize(filters["priority"])
      )
    ]
    |> Enum.reject(&is_nil/1)
  end

  @impl true
  def render(%{live_action: :show} = assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
        <div class="space-y-2">
          <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
            Request for quotation detail
          </p>
          <h1 class="text-3xl font-semibold tracking-tight text-slate-900">{@rfq.reference}</h1>
          <p class="max-w-3xl text-sm leading-6 text-slate-500">{@rfq.title}</p>
        </div>

        <div class="flex flex-wrap gap-3">
          <.status_badge status={@rfq.status} />
          <span class={[
            "rounded-full bg-slate-100 px-3 py-2 text-sm font-semibold",
            LiveHelpers.deadline_tone(Rfqs.days_until_deadline(@rfq))
          ]}>
            {deadline_label(@rfq)}
          </span>
        </div>
      </div>

      <.pipeline_tracker
        steps={pipeline_steps()}
        current={:rfq}
        document_ids={document_ids(@rfq, @quote)}
      />

      <div class="rounded-2xl border border-sky-200 bg-sky-50 px-5 py-4 text-sm text-sky-800">
        This is the first commercial step. Read the request for quotation, submit your quote here, and wait for procurement to issue the purchase order if your quote is accepted.
      </div>

      <div class="rounded-[2rem] border border-slate-200 bg-white p-5 shadow-sm">
        <div class="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
          <div class="space-y-1">
            <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
              Next action
            </p>
            <p :if={@quote} class="text-sm font-medium text-emerald-700">
              Quote <span class="font-semibold">{@quote.reference}</span>
              has already been submitted. Watch for a purchase order in the Purchase Orders screen.
            </p>
            <p :if={!@quote} class="text-sm font-medium text-slate-700">
              Submit your quote for this request. Procurement cannot send a PO until one supplier quote has been accepted.
            </p>
          </div>

          <.link
            navigate={
              if @quote,
                do: ~p"/supplier/quotes/#{@quote.id}",
                else: ~p"/supplier/quotes/new/#{@rfq.id}"
            }
            class="inline-flex items-center justify-center rounded-xl bg-[#373896] px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-[#2d2d7a]"
          >
            {if @quote, do: "Open submitted quote", else: "Create quote"}
          </.link>
        </div>
      </div>

      <div class="space-y-6">
        <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
          <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
            Request summary
          </p>
          <div class="mt-5 grid gap-4 sm:grid-cols-2">
            <.info_tile label="Department" value={@rfq.department} />
            <.info_tile label="Priority" value={String.capitalize(@rfq.priority || "normal")} />
            <.info_tile label="Issue date" value={LiveHelpers.format_date(@rfq.issue_date)} />
            <.info_tile label="Quote deadline" value={LiveHelpers.format_date(@rfq.quote_deadline)} />
            <.info_tile label="Delivery by" value={LiveHelpers.format_date(@rfq.delivery_by)} />
            <.info_tile label="Currency" value={@rfq.currency || "KES"} />
            <.info_tile label="Delivery terms" value={@rfq.delivery_terms} />
            <.info_tile label="Payment terms" value={@rfq.payment_terms} />
          </div>

          <div
            :if={!LiveHelpers.blank?(@rfq.special_instructions)}
            class="mt-5 rounded-2xl bg-slate-50 px-4 py-4"
          >
            <p class="text-xs font-semibold uppercase tracking-[0.22em] text-slate-400">
              Special instructions
            </p>
            <p class="mt-2 text-sm leading-6 text-slate-600">{@rfq.special_instructions}</p>
          </div>
        </div>

        <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
          <div class="flex items-center justify-between gap-3">
            <div>
              <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
                Line items
              </p>
              <h2 class="mt-2 text-xl font-semibold text-slate-900">Quoted requirements</h2>
            </div>
            <span class="rounded-full bg-slate-100 px-3 py-2 text-sm font-semibold text-slate-700">
              {length(@rfq.items)} items
            </span>
          </div>

          <div class="mt-5 overflow-x-auto">
            <table class="w-full min-w-[860px] table-auto text-left text-sm">
              <thead class="border-b border-slate-200 text-slate-500">
                <tr>
                  <th class="w-12 pb-3 pr-6 font-semibold">#</th>
                  <th class="pb-3 pr-6 font-semibold">Description</th>
                  <th class="w-40 pb-3 pr-6 font-semibold">Category</th>
                  <th class="w-24 pb-3 pr-6 text-right font-semibold">Qty</th>
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
                  <td class="py-4 pr-6 text-slate-600 whitespace-nowrap">
                    {item.category || "General"}
                  </td>
                  <td class="py-4 pr-6 text-right tabular-nums text-slate-600">
                    {LiveHelpers.decimal_to_string(item.quantity_required)}
                  </td>
                  <td class="py-4 text-right tabular-nums text-slate-600 whitespace-nowrap">
                    {LiveHelpers.money(item.estimated_unit_price)}
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
      <div class="flex flex-col gap-3 lg:flex-row lg:items-end lg:justify-between">
        <div class="space-y-2">
          <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
            Request for quotation inbox
          </p>
          <h1 class="text-3xl font-semibold tracking-tight text-slate-900">
            Open procurement invitations
          </h1>
          <p class="max-w-3xl text-sm leading-6 text-slate-500">
            Review invited requests for quotation, keep an eye on closing dates, and open the detail view to submit a quote.
          </p>
        </div>
      </div>

      <.deadline_alert rfqs={@rfqs} />

      <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
        <div class="flex items-center justify-between gap-3">
          <div>
            <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
              Invitations
            </p>
            <h2 class="mt-2 text-xl font-semibold text-slate-900">
              Requests for quotation sorted by deadline
            </h2>
          </div>
          <span class="rounded-full bg-slate-100 px-3 py-2 text-sm font-semibold text-slate-700">
            {@total_count} of {length(@all_rfqs)} requests for quotation
          </span>
        </div>

        <div :if={!Enum.empty?(@all_rfqs)} class="mt-5 flex flex-wrap items-center gap-3">
          <form phx-change="filter" class="flex-1">
            <.search_input
              name="filters[search]"
              value={@filters["search"]}
              placeholder="Search by reference, title, or department"
            />
          </form>

          <.filter_drawer
            id="rfq-inbox-filters"
            title="Filter requests for quotation"
            apply_event="filter"
            active_count={count_active_filters(@filters)}
          >
            <:group label="Status and Priority">
              <div>
                <label class="block text-xs font-medium text-gray-600 mb-1">Status</label>
                <select
                  name="filters[status]"
                  class="w-full h-9 rounded-md border border-gray-300 px-2 text-sm focus:ring-[#6667ab] focus:border-[#6667ab]"
                >
                  <option value="">All statuses</option>
                  <option
                    :for={status <- @statuses}
                    value={status}
                    selected={@filters["status"] == status}
                  >
                    {String.capitalize(status)}
                  </option>
                </select>
              </div>
              <div>
                <label class="block text-xs font-medium text-gray-600 mb-1">Priority</label>
                <select
                  name="filters[priority]"
                  class="w-full h-9 rounded-md border border-gray-300 px-2 text-sm focus:ring-[#6667ab] focus:border-[#6667ab]"
                >
                  <option value="">All priorities</option>
                  <option
                    :for={priority <- @priorities}
                    value={priority}
                    selected={@filters["priority"] == priority}
                  >
                    {String.capitalize(priority)}
                  </option>
                </select>
              </div>
            </:group>

            <:chip
              :for={chip <- filter_chips(@filters)}
              label={chip.label}
              clear={JS.push("clear_chip", value: %{"field" => chip.field})}
            />
          </.filter_drawer>
        </div>

        <.blank_state
          :if={Enum.empty?(@all_rfqs)}
          icon_path="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
          title="No invitations yet"
          description="New invitations will appear here as procurement issues them to your supplier account."
        />

        <.blank_state
          :if={!Enum.empty?(@all_rfqs) and Enum.empty?(@rfqs)}
          icon_path="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
          title="No invitations found"
          description="No request for quotation invitations match the current filters."
        >
          <:actions>
            <button phx-click="clear_filters" class="text-xs text-[#6667ab] hover:underline">
              Clear filters
            </button>
          </:actions>
        </.blank_state>

        <div :if={!Enum.empty?(@rfqs)} class="mt-5 overflow-x-auto">
          <table class="min-w-full text-left text-sm">
            <thead class="border-b border-slate-200 text-slate-500">
              <tr>
                <th class="pb-3 pr-4 font-semibold">Reference</th>
                <th class="pb-3 pr-4 font-semibold">Title</th>
                <th class="pb-3 pr-4 font-semibold">Issued</th>
                <th class="pb-3 pr-4 font-semibold">Deadline</th>
                <th class="pb-3 pr-4 font-semibold">Priority</th>
                <th class="pb-3 pr-4 font-semibold">Status</th>
                <th class="pb-3 font-semibold text-right">Action</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
              <tr :for={rfq <- @rfqs}>
                <td class="py-4 pr-4 font-medium text-slate-900">{rfq.reference}</td>
                <td class="py-4 pr-4 text-slate-600">{rfq.title}</td>
                <td class="py-4 pr-4 text-slate-600 whitespace-nowrap">
                  {LiveHelpers.format_date(rfq.issue_date)}
                </td>
                <td class={[
                  "py-4 pr-4 font-medium",
                  LiveHelpers.deadline_tone(Rfqs.days_until_deadline(rfq))
                ]}>
                  {deadline_label(rfq)}
                </td>
                <td class="py-4 pr-4 text-slate-600">
                  {String.capitalize(rfq.priority || "normal")}
                </td>
                <td class="py-4 pr-4"><.status_badge status={rfq.status} /></td>
                <td class="py-4 text-right">
                  <.link
                    navigate={~p"/supplier/rfqs/#{rfq.id}"}
                    class="text-sm font-semibold text-[#373896] hover:text-[#2d2d7a]"
                  >
                    Review request for quotation
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
