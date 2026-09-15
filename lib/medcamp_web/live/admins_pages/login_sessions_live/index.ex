defmodule MedcampWeb.LoginSessionsLive.Index do
  use MedcampWeb, :admin_live_view

  alias Medcamp.UserLoginSessions

  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :login_sessions)
     |> assign(:filters, %{search: "", active: ""})
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> load_sessions()}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  # The search box and the filter drawer submit independently (two separate
  # <form>s), so a submission from either one only carries its own fields.
  # Merging onto a stringified version of the current filters means a key
  # absent from this submission is left unchanged rather than reset.
  defp stringify_filters(filters), do: Map.new(filters, fn {k, v} -> {Atom.to_string(k), v} end)

  defp count_active_filters(filters) do
    filters
    |> Map.drop([:search])
    |> Map.values()
    |> Enum.count(&(&1 not in [nil, ""]))
  end

  defp filter_chips(filters) do
    [
      filter_chip(filters[:active], "active", active_label(filters[:active]))
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp active_label("active"), do: "Active (logged in)"
  defp active_label("inactive"), do: "Inactive (logged out)"
  defp active_label(other), do: other

  @impl true
  def handle_event("filter", params, socket) do
    params = Map.merge(stringify_filters(socket.assigns.filters), params)

    filters = %{
      search: params["search"] || "",
      active: params["active"] || ""
    }

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign(:page, 1)
     |> load_sessions()}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply,
     socket
     |> assign(:filters, %{search: "", active: ""})
     |> assign(:page, 1)
     |> load_sessions()}
  end

  @impl true
  def handle_event("clear_chip", %{"field" => field}, socket) do
    handle_event("filter", %{field => ""}, socket)
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply, socket |> assign(:page, max(1, String.to_integer(page))) |> load_sessions()}
  end

  defp format_duration(logged_in_at, nil) do
    diff = DateTime.diff(DateTime.utc_now(), logged_in_at, :second)
    format_seconds(diff) <> " (ongoing)"
  end

  defp format_duration(logged_in_at, logged_out_at) do
    diff = DateTime.diff(logged_out_at, logged_in_at, :second)
    format_seconds(diff)
  end

  defp format_seconds(secs) do
    hours = div(secs, 3600)
    minutes = div(rem(secs, 3600), 60)
    seconds = rem(secs, 60)

    cond do
      hours > 0 -> "#{hours}h #{minutes}m"
      minutes > 0 -> "#{minutes}m #{seconds}s"
      true -> "#{seconds}s"
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-slate-100 p-4">
      <.page_header
        icon_path="M11 16l-4-4m0 0l4-4m-4 4h14m-5 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h7a3 3 0 013 3v1"
        title="Login Sessions"
        subtitle="Search, filter and review user login sessions."
      />

      <div class="flex flex-wrap items-center gap-3 mb-4">
        <form phx-change="filter" class="flex-1">
          <.search_input
            name="search"
            value={@filters[:search]}
            placeholder="Search by name or email"
          />
        </form>

        <.filter_drawer
          id="login-sessions-filters"
          title="Filter login sessions"
          apply_event="filter"
          active_count={count_active_filters(@filters)}
        >
          <:group label="Status">
            <div>
              <label class="block text-xs font-medium text-slate-600 mb-1">Session Status</label>
              <select
                name="active"
                class="w-full h-9 border border-slate-300 rounded-md px-2 text-sm focus:ring-brand-accent focus:border-brand-accent"
              >
                <option value="">All</option>
                <option value="active" selected={@filters[:active] == "active"}>
                  Active (logged in)
                </option>
                <option value="inactive" selected={@filters[:active] == "inactive"}>
                  Inactive (logged out)
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
      
    <!-- Summary -->
      <div class="flex gap-3 mb-4">
        <div class="flex items-center gap-1.5 text-sm text-slate-500">
          <span class="inline-block w-2.5 h-2.5 rounded-full bg-green-500"></span>
          Active: {Enum.count(@sessions, fn s -> is_nil(s.logged_out_at) end)}
        </div>
        <div class="flex items-center gap-1.5 text-sm text-slate-500">
          <span class="inline-block w-2.5 h-2.5 rounded-full bg-slate-400"></span>
          Total shown: {length(@sessions)}
        </div>
      </div>
      
    <!-- Table -->
      <%= if Enum.empty?(@sessions) do %>
        <.blank_state
          icon_path="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
          title="No sessions found"
          description={
            if @filters.search != "" or count_active_filters(@filters) > 0,
              do: "No sessions match the current filters.",
              else: "Sessions will appear here once users log in."
          }
        >
          <:actions :if={@filters.search != "" or count_active_filters(@filters) > 0}>
            <button phx-click="clear_filters" class="text-xs text-brand-accent hover:underline">
              Clear filters
            </button>
          </:actions>
        </.blank_state>
      <% else %>
        <.data_table id="login-sessions" rows={@sessions}>
          <:col :let={session} label="User">
            <div class="py-2 flex items-center gap-2">
              <div class="h-7 w-7 rounded-full bg-brand-100 flex items-center justify-center text-brand-primary font-medium text-xs flex-shrink-0">
                {String.first(session.user.name || "?")}
              </div>
              <div>
                <p class="font-medium text-slate-900 text-sm">{session.user.name}</p>
                <p class="text-xs text-slate-500">{session.user.email}</p>
              </div>
            </div>
          </:col>

          <:col :let={session} label="Role">
            <div class="py-2">
              <span class="px-2 py-1 text-xs rounded-full bg-slate-100 text-slate-700 capitalize">
                {session.user.role}
              </span>
            </div>
          </:col>

          <:col :let={session} label="Logged In">
            <div class="py-2">
              <span class="text-sm text-slate-700">
                {format_datetime_kenya(session.logged_in_at)}
              </span>
            </div>
          </:col>

          <:col :let={session} label="Logged Out">
            <div class="py-2">
              <%= if session.logged_out_at do %>
                <span class="text-sm text-slate-700">
                  {format_datetime_kenya(session.logged_out_at)}
                </span>
              <% else %>
                <span class="inline-flex items-center gap-1 px-2 py-1 text-xs font-medium rounded-full bg-green-100 text-green-800">
                  <span class="w-1.5 h-1.5 rounded-full bg-green-500 animate-pulse"></span> Active
                </span>
              <% end %>
            </div>
          </:col>

          <:col :let={session} label="Duration">
            <div class="py-2">
              <span class="text-sm text-slate-600">
                {format_duration(session.logged_in_at, session.logged_out_at)}
              </span>
            </div>
          </:col>
        </.data_table>
        <.pagination
          page={@page}
          total_pages={@total_pages}
          total_count={@total_count}
          per_page={@per_page}
        />
      <% end %>
    </div>
    """
  end

  defp load_sessions(socket) do
    filters = socket.assigns.filters
    per_page = socket.assigns.per_page
    page = socket.assigns.page

    total_count = UserLoginSessions.count_sessions(filters)
    total_pages = Medcamp.Pagination.total_pages(total_count, per_page)
    page = min(max(1, page), total_pages)
    sessions = UserLoginSessions.list_sessions_paginated(filters, page, per_page)

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:sessions, sessions)
  end
end
