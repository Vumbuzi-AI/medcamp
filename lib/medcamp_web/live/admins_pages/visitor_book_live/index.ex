defmodule MedcampWeb.AdminVisitorBookLive.Index do
  use MedcampWeb, :admin_live_view

  alias Medcamp.Visitors

  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :visitors_books)
     |> assign(:page_title, "Visitors Books")
     |> assign(:filter_date_from, "")
     |> assign(:filter_date_to, "")
     |> assign(:filter_search, "")
     |> assign(:today, Date.utc_today())
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> load_entries()}
  end

  # The search box and the filter drawer submit independently (two separate
  # <form>s), so a submission from either one only carries its own fields.
  # Merging onto the current filters means a key absent from this submission
  # is left unchanged rather than reset.
  @impl true
  def handle_event("filter", %{"filters" => filters}, socket) do
    current = %{
      "date_from" => socket.assigns.filter_date_from,
      "date_to" => socket.assigns.filter_date_to,
      "search" => socket.assigns.filter_search
    }

    filters = Map.merge(current, filters)

    {:noreply,
     socket
     |> assign(:filter_date_from, Map.get(filters, "date_from", "") |> String.trim())
     |> assign(:filter_date_to, Map.get(filters, "date_to", "") |> String.trim())
     |> assign(:filter_search, Map.get(filters, "search", "") |> String.trim())
     |> assign(:page, 1)
     |> load_entries()}
  end

  def handle_event("clear_filters", _params, socket) do
    {:noreply,
     socket
     |> assign(:filter_date_from, "")
     |> assign(:filter_date_to, "")
     |> assign(:filter_search, "")
     |> assign(:page, 1)
     |> load_entries()}
  end

  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, max(1, String.to_integer(page)))
     |> load_entries()}
  end

  def handle_event("clear_chip", %{"field" => field}, socket) do
    handle_event("filter", %{"filters" => %{field => ""}}, socket)
  end

  defp count_active_filters(assigns) do
    [assigns.filter_date_from != "", assigns.filter_date_to != ""]
    |> Enum.count(& &1)
  end

  defp filter_chips(assigns) do
    [
      filter_chip(assigns.filter_date_from, "date_from", "From #{assigns.filter_date_from}"),
      filter_chip(assigns.filter_date_to, "date_to", "To #{assigns.filter_date_to}")
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp load_entries(socket) do
    filters = [
      date_from: socket.assigns.filter_date_from,
      date_to: socket.assigns.filter_date_to,
      search: socket.assigns.filter_search
    ]

    today = socket.assigns.today
    total_count = Visitors.count_visitor_book_entries(filters)
    total_pages = Medcamp.Pagination.total_pages(total_count, socket.assigns.per_page)
    page = min(max(1, socket.assigns.page || 1), total_pages)
    entries = Visitors.list_visitor_book_entries_paginated(filters, page, socket.assigns.per_page)

    today_count =
      Visitors.count_visitor_book_entries(
        Keyword.merge(filters, date_from: today, date_to: today)
      )

    socket
    |> assign(:entries, entries)
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:total_entries, total_count)
    |> assign(:today_entries, today_count)
    |> assign(:recorded_by_count, Visitors.count_distinct_visitor_recorders(filters))
  end

  defp format_date(%Date{} = date), do: Calendar.strftime(date, "%d %b %Y")
  defp format_date(_), do: "-"

  defp format_time(%Time{} = time), do: Calendar.strftime(time, "%H:%M")
  defp format_time(_), do: "-"

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <section class="rounded-xl border border-gray-100 bg-white p-6 shadow-sm">
        <.page_header
          icon_path="M17 20h5v-2a4 4 0 00-3-3.87M9 20H4v-2a4 4 0 013-3.87m6-1.13a4 4 0 10-4-4 4 4 0 004 4zm6-2a4 4 0 11-4-4 4 4 0 014 4z"
          title="Visitors Books"
          subtitle="Admin oversight for visitor entries captured by reception."
        />

        <div class="mb-5 grid gap-4 md:grid-cols-3">
          <div class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm">
            <p class="text-sm text-gray-500">Visible entries</p>
            <p class="mt-2 text-3xl font-semibold text-[#373896]">{@total_entries}</p>
          </div>

          <div class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm">
            <p class="text-sm text-gray-500">Today's visitors</p>
            <p class="mt-2 text-3xl font-semibold text-[#373896]">{@today_entries}</p>
          </div>

          <div class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm">
            <p class="text-sm text-gray-500">Reception staff who recorded entries</p>
            <p class="mt-2 text-3xl font-semibold text-[#373896]">{@recorded_by_count}</p>
          </div>
        </div>

        <div class="flex flex-wrap items-center gap-3 mb-5">
          <form phx-change="filter" class="flex-1">
            <.search_input
              name="filters[search]"
              value={@filter_search}
              placeholder="Search by visitor, staff, purpose, or message"
            />
          </form>

          <.filter_drawer
            id="visitors-books-filters"
            title="Filter visitor entries"
            apply_event="filter"
            clear_event="clear_filters"
            active_count={count_active_filters(assigns)}
          >
            <:group label="Date Range">
              <.date_range_fields
                from_name="filters[date_from]"
                to_name="filters[date_to]"
                from_value={@filter_date_from}
                to_value={@filter_date_to}
              />
            </:group>

            <:chip
              :for={chip <- filter_chips(assigns)}
              label={chip.label}
              clear={JS.push("clear_chip", value: %{"field" => chip.field})}
            />
          </.filter_drawer>
        </div>

        <div class="overflow-x-auto">
          <.blank_state
            :if={@entries == []}
            icon_path="M17 20h5v-2a4 4 0 00-3-3.87M9 20H4v-2a4 4 0 013-3.87m6-1.13a4 4 0 10-4-4 4 4 0 004 4zm6-2a4 4 0 11-4-4 4 4 0 014 4z"
            title="No visitor entries found"
            description={
              if @filter_search != "" or count_active_filters(assigns) > 0,
                do: "No visitor entries match the current filters.",
                else: "No visitor entries have been recorded yet."
            }
          >
            <:actions :if={@filter_search != "" or count_active_filters(assigns) > 0}>
              <button phx-click="clear_filters" class="text-xs text-[#6667ab] hover:underline">
                Clear filters
              </button>
            </:actions>
          </.blank_state>
          <table :if={@entries != []} class="min-w-full divide-y divide-gray-200">
            <thead>
              <tr class="text-left text-xs font-semibold uppercase tracking-wider text-gray-500">
                <th class="px-3 py-3">Visitor</th>
                <th class="px-3 py-3">Visit</th>
                <th class="px-3 py-3">Purpose</th>
                <th class="px-3 py-3">Message</th>
                <th class="px-3 py-3">Recorded by</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100 bg-white text-sm text-gray-700">
              <%= for entry <- @entries do %>
                <tr>
                  <td class="px-3 py-4 align-top">
                    <div class="font-medium text-gray-900">{entry.visitor_name}</div>
                    <div :if={entry.phone_number not in [nil, ""]} class="text-xs text-gray-500">
                      {entry.phone_number}
                    </div>
                  </td>
                  <td class="px-3 py-4 align-top">
                    <div>{format_date(entry.visited_on)}</div>
                    <div class="text-xs text-gray-500">{format_time(entry.visited_at)}</div>
                  </td>
                  <td class="px-3 py-4 align-top">
                    <div>{entry.purpose || "-"}</div>
                    <div :if={entry.person_to_see not in [nil, ""]} class="text-xs text-gray-500">
                      For: {entry.person_to_see}
                    </div>
                  </td>
                  <td class="px-3 py-4 align-top max-w-md whitespace-pre-wrap">{entry.message}</td>
                  <td class="px-3 py-4 align-top">{(entry.user && entry.user.name) || "-"}</td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
        <.pagination
          page={@page}
          total_pages={@total_pages}
          total_count={@total_count}
          per_page={@per_page}
        />
      </section>
    </div>
    """
  end
end
