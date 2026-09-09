defmodule MedcampWeb.AuditLogsLive.Index do
  use MedcampWeb, :admin_live_view

  alias Medcamp.Audit
  alias Medcamp.Tenancy

  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:active_tab, :audit_logs)
      |> assign(:tables, [])
      |> assign(:users, [])
      |> assign(:stats, empty_stats())
      |> assign(:stats_loading, true)
      |> assign(:audit_logs_loading, true)
      |> assign(:has_audit_logs, false)
      |> assign(:page, 1)
      |> assign(:per_page, @per_page)
      |> assign(:total_count, 0)
      |> assign(:total_pages, 1)
      |> assign(:filter_table, "all")
      |> assign(:filter_user, "all")
      |> assign(:filter_action, "all")
      |> assign(:date_from, nil)
      |> assign(:date_to, nil)
      |> assign(:search_query, "")
      |> assign(:audit_logs, [])

    if connected?(socket) do
      org_id = Tenancy.current_org_id()
      audit_logs = Audit.list_audit_logs(page: 1, page_size: @per_page)

      {:ok,
       socket
       |> assign(:audit_logs_loading, false)
       |> assign(:has_audit_logs, audit_logs != [])
       |> assign(:audit_logs, audit_logs)
       |> start_async(:audit_filter_options, fn ->
         Tenancy.with_org(org_id, fn ->
           %{tables: Audit.list_audited_tables(), users: Audit.list_audit_users()}
         end)
       end)
       |> start_async(:audit_stats, fn ->
         Tenancy.with_org(org_id, fn -> Audit.get_audit_stats() end)
       end)}
    else
      # Avoid running every audit query twice during LiveView's disconnected and
      # connected mounts. The connected mount above loads the first page.
      {:ok, socket}
    end
  end

  @impl true
  def handle_async(:audit_filter_options, {:ok, options}, socket) do
    {:noreply, assign(socket, tables: options.tables, users: options.users)}
  end

  def handle_async(:audit_filter_options, {:exit, _reason}, socket), do: {:noreply, socket}

  def handle_async(:audit_stats, {:ok, stats}, socket) do
    socket = assign(socket, stats: stats, stats_loading: false)

    socket =
      if String.trim(socket.assigns.search_query || "") == "" and
           count_active_filters(socket.assigns) == 0 do
        assign(socket,
          total_count: stats.total,
          total_pages: Medcamp.Pagination.total_pages(stats.total, socket.assigns.per_page)
        )
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_async(:audit_stats, {:exit, _reason}, socket) do
    {:noreply, assign(socket, :stats_loading, false)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    socket
    |> assign(:page_title, "Audit Log Details")
    |> assign(:audit_log, Audit.get_audit_log!(id))
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Audit Logs")
    |> assign(:audit_log, nil)
  end

  @impl true
  def handle_event("filter", params, socket) do
    filters = build_filters(params, socket)

    {:noreply,
     socket
     |> assign(:filter_table, params["table"] || "all")
     |> assign(:filter_user, params["user"] || "all")
     |> assign(:filter_action, params["action"] || "all")
     |> assign(:date_from, parse_date(params["date_from"]))
     |> assign(:date_to, parse_date(params["date_to"]))
     |> assign(:search_query, "")
     |> assign(:page, 1)
     |> assign(:audit_filters, filters)
     |> load_audit_logs()}
  end

  def handle_event("search", %{"search" => query}, socket) do
    {:noreply,
     socket
     |> assign(:search_query, query)
     |> assign(:page, 1)
     |> load_audit_logs()}
  end

  def handle_event("clear_filters", _params, socket) do
    {:noreply,
     socket
     |> assign(:filter_table, "all")
     |> assign(:filter_user, "all")
     |> assign(:filter_action, "all")
     |> assign(:date_from, nil)
     |> assign(:date_to, nil)
     |> assign(:search_query, "")
     |> assign(:page, 1)
     |> assign(:audit_filters, [])
     |> load_audit_logs()}
  end

  def handle_event("clear_chip", %{"field" => field}, socket) do
    current = %{
      "table" => socket.assigns.filter_table,
      "user" => socket.assigns.filter_user,
      "action" => socket.assigns.filter_action,
      "date_from" => socket.assigns.date_from && Date.to_iso8601(socket.assigns.date_from),
      "date_to" => socket.assigns.date_to && Date.to_iso8601(socket.assigns.date_to)
    }

    default = if field in ["date_from", "date_to"], do: nil, else: "all"
    params = Map.put(current, field, default)
    handle_event("filter", params, socket)
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, Medcamp.Pagination.normalize_page(page))
     |> load_audit_logs()}
  end

  defp build_filters(params, socket) do
    []
    |> maybe_add_filter(:table_name, params["table"] || socket.assigns.filter_table)
    |> maybe_add_filter(:user_id, parse_user_id(params["user"] || socket.assigns.filter_user))
    |> maybe_add_filter(:action, params["action"] || socket.assigns.filter_action)
    |> maybe_add_filter(
      :date_from,
      parse_date(Map.get(params, "date_from", socket.assigns.date_from))
    )
    |> maybe_add_filter(:date_to, parse_date(Map.get(params, "date_to", socket.assigns.date_to)))
  end

  defp maybe_add_filter(filters, _key, nil), do: filters
  defp maybe_add_filter(filters, _key, "all"), do: filters
  defp maybe_add_filter(filters, key, value), do: Keyword.put(filters, key, value)

  defp count_active_filters(assigns) do
    [
      assigns.filter_table != "all",
      assigns.filter_user != "all",
      assigns.filter_action != "all",
      assigns.date_from != nil,
      assigns.date_to != nil
    ]
    |> Enum.count(& &1)
  end

  defp filter_chips(assigns) do
    [
      filter_chip(assigns.filter_table, "table", format_table_name(assigns.filter_table), ["all"]),
      filter_chip(assigns.filter_user, "user", user_email(assigns.filter_user, assigns.users), [
        "all"
      ]),
      filter_chip(assigns.filter_action, "action", action_label(assigns.filter_action), ["all"]),
      filter_chip(
        assigns.date_from,
        "date_from",
        assigns.date_from && "From #{assigns.date_from}"
      ),
      filter_chip(assigns.date_to, "date_to", assigns.date_to && "To #{assigns.date_to}")
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp user_email(id, users) do
    case Enum.find(users, fn user -> to_string(user.id) == to_string(id) end) do
      nil -> id
      user -> user.email
    end
  end

  defp action_label("insert"), do: "Created"
  defp action_label("update"), do: "Updated"
  defp action_label("delete"), do: "Deleted"
  defp action_label(other), do: other

  defp parse_user_id("all"), do: "all"
  defp parse_user_id(nil), do: nil
  defp parse_user_id(""), do: nil

  defp parse_user_id(user_id) when is_binary(user_id) do
    case Integer.parse(user_id) do
      {id, _} -> id
      :error -> nil
    end
  end

  defp parse_user_id(user_id), do: user_id

  defp parse_date(nil), do: nil
  defp parse_date(""), do: nil

  defp parse_date(date_string) when is_binary(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> date
      {:error, _} -> nil
    end
  end

  defp parse_date(date), do: date

  defp load_audit_logs(socket) do
    per_page = socket.assigns.per_page
    search_query = String.trim(socket.assigns.search_query || "")
    filters = build_filters(%{}, socket) |> maybe_add_filter(:search, search_query)
    total_count = Audit.count_audit_logs(filters)
    total_pages = Medcamp.Pagination.total_pages(total_count, per_page)
    page = min(Medcamp.Pagination.normalize_page(socket.assigns.page), total_pages)
    audit_logs = Audit.list_audit_logs(filters: filters, page: page, page_size: per_page)

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:audit_logs_loading, false)
    |> assign(:has_audit_logs, audit_logs != [])
    |> assign(:audit_logs, audit_logs)
  end

  defp empty_stats do
    %{total: 0, by_action: %{}, top_tables: []}
  end

  defp action_badge(action) do
    case action do
      "insert" -> {"Created", "bg-green-100 text-green-800", "➕"}
      "update" -> {"Updated", "bg-blue-100 text-blue-800", "✏️"}
      "delete" -> {"Deleted", "bg-red-100 text-red-800", "🗑️"}
      _ -> {action, "bg-slate-100 text-slate-800", "📝"}
    end
  end

  defp format_table_name(table_name) do
    table_name
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-slate-100 p-4">
      <.page_header
        icon_path="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
        title="Audit Logs"
        subtitle="System activity trail — search, filter and review changes."
      />
      
    <!-- Statistics Cards -->
      <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
        <div class="bg-gradient-to-br from-blue-50 to-blue-100 rounded-lg p-4 border border-blue-200">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm font-medium text-blue-600">Total Changes</p>
              <p class="text-2xl font-bold text-blue-900">{@stats.total}</p>
            </div>
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-8 w-8 text-blue-400"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
              />
            </svg>
          </div>
        </div>

        <div class="bg-gradient-to-br from-green-50 to-green-100 rounded-lg p-4 border border-green-200">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm font-medium text-green-600">Created</p>
              <p class="text-2xl font-bold text-green-900">
                {Map.get(@stats.by_action, "insert", 0)}
              </p>
            </div>
            <span class="text-3xl">➕</span>
          </div>
        </div>

        <div class="bg-gradient-to-br from-yellow-50 to-yellow-100 rounded-lg p-4 border border-yellow-200">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm font-medium text-yellow-600">Updated</p>
              <p class="text-2xl font-bold text-yellow-900">
                {Map.get(@stats.by_action, "update", 0)}
              </p>
            </div>
            <span class="text-3xl">✏️</span>
          </div>
        </div>

        <div class="bg-gradient-to-br from-red-50 to-red-100 rounded-lg p-4 border border-red-200">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm font-medium text-red-600">Deleted</p>
              <p class="text-2xl font-bold text-red-900">
                {Map.get(@stats.by_action, "delete", 0)}
              </p>
            </div>
            <span class="text-3xl">🗑️</span>
          </div>
        </div>
      </div>
      
    <!-- Search and Filters -->
      <div class="flex flex-wrap items-center gap-3 mb-4">
        <form phx-change="search" class="flex-1">
          <.search_input
            name="search"
            value={@search_query}
            placeholder="Search by table name or record ID"
          />
        </form>

        <.filter_drawer
          id="audit-logs-filters"
          title="Filter audit logs"
          apply_event="filter"
          clear_event="clear_filters"
          active_count={count_active_filters(assigns)}
        >
          <:group label="Table and User">
            <div>
              <label class="block text-xs font-medium text-slate-600 mb-1">Table</label>
              <select
                name="table"
                class="w-full h-9 rounded-md border border-slate-300 px-2 text-sm focus:ring-brand-accent focus:border-brand-accent"
              >
                <option value="all" selected={@filter_table == "all"}>All Tables</option>
                <%= for table <- @tables do %>
                  <option value={table} selected={@filter_table == table}>
                    {format_table_name(table)}
                  </option>
                <% end %>
              </select>
            </div>
            <div>
              <label class="block text-xs font-medium text-slate-600 mb-1">User</label>
              <select
                name="user"
                class="w-full h-9 rounded-md border border-slate-300 px-2 text-sm focus:ring-brand-accent focus:border-brand-accent"
              >
                <option value="all" selected={@filter_user == "all"}>All Users</option>
                <%= for user <- @users do %>
                  <option value={user.id} selected={to_string(@filter_user) == to_string(user.id)}>
                    {user.email}
                  </option>
                <% end %>
              </select>
            </div>
          </:group>

          <:group label="Action">
            <div>
              <label class="block text-xs font-medium text-slate-600 mb-1">Action</label>
              <select
                name="action"
                class="w-full h-9 rounded-md border border-slate-300 px-2 text-sm focus:ring-brand-accent focus:border-brand-accent"
              >
                <option value="all" selected={@filter_action == "all"}>All Actions</option>
                <option value="insert" selected={@filter_action == "insert"}>Created</option>
                <option value="update" selected={@filter_action == "update"}>Updated</option>
                <option value="delete" selected={@filter_action == "delete"}>Deleted</option>
              </select>
            </div>
          </:group>

          <:group label="Date Range">
            <.date_range_fields
              from_name="date_from"
              to_name="date_to"
              from_value={@date_from && Date.to_iso8601(@date_from)}
              to_value={@date_to && Date.to_iso8601(@date_to)}
            />
          </:group>

          <:chip
            :for={chip <- filter_chips(assigns)}
            label={chip.label}
            clear={JS.push("clear_chip", value: %{"field" => chip.field})}
          />
        </.filter_drawer>
      </div>
      
    <!-- Audit Logs Table -->
      <div
        :if={@audit_logs_loading}
        class="my-8 flex items-center justify-center gap-3 text-sm text-slate-500"
      >
        <span class="h-5 w-5 animate-spin rounded-full border-2 border-slate-200 border-t-brand-accent">
        </span>
        Loading recent audit logs…
      </div>
      <.blank_state
        :if={!@audit_logs_loading and !@has_audit_logs}
        icon_path="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
        title="No audit logs found"
        description={
          if @search_query != "" or count_active_filters(assigns) > 0,
            do: "No changes match your current filters.",
            else: "No audit log entries have been recorded yet."
        }
      >
        <:actions :if={@search_query != "" or count_active_filters(assigns) > 0}>
          <button phx-click="clear_filters" class="text-xs text-brand-accent hover:underline">
            Clear filters
          </button>
        </:actions>
      </.blank_state>
      <%= if @has_audit_logs do %>
        <.data_table
          id="audit_logs"
          rows={@audit_logs}
          row_click={fn log -> JS.navigate(~p"/admin/audit_logs/#{log}") end}
          row_id={&"audit_logs-#{&1.id}"}
        >
          <:col :let={log} label="Action">
            <div class="flex flex-col py-3">
              <%= case action_badge(log.action) do %>
                <% {label, classes, emoji} -> %>
                  <span class={"px-2 py-1 text-xs font-medium rounded-full #{classes} inline-flex items-center w-fit"}>
                    <span class="mr-1">{emoji}</span>
                    {label}
                  </span>
              <% end %>
              <span class="text-xs text-slate-500 mt-1">
                {format_datetime_kenya(log.inserted_at)}
              </span>
            </div>
          </:col>

          <:col :let={log} label="Table & Record">
            <div class="flex flex-col py-3">
              <span class="font-medium text-slate-900">{format_table_name(log.table_name)}</span>
              <span class="text-xs text-slate-500">ID: {log.record_id}</span>
            </div>
          </:col>

          <:col :let={log} label="User">
            <div class="flex items-center py-3">
              <div class="flex-shrink-0 h-8 w-8 rounded-full bg-brand-accent flex items-center justify-center text-white font-medium text-sm">
                <%= if log.user do %>
                  {String.first(log.user.email) |> String.upcase()}
                <% else %>
                  ?
                <% end %>
              </div>
              <div class="ml-2">
                <p class="text-sm font-medium text-slate-900">
                  <%= if log.user do %>
                    {log.user.email}
                  <% else %>
                    <span class="text-slate-400">Unknown User</span>
                  <% end %>
                </p>
                <%= if log.user && log.user.role do %>
                  <p class="text-xs text-slate-500">{String.capitalize(log.user.role)}</p>
                <% end %>
              </div>
            </div>
          </:col>

          <:col :let={log} label="Changes">
            <div class="py-3 text-sm">
              <%= if log.changed_fields && length(log.changed_fields) > 0 do %>
                <div class="flex flex-wrap gap-1">
                  <%= for field <- Enum.take(log.changed_fields, 3) do %>
                    <span class="px-2 py-0.5 text-xs font-medium bg-purple-100 text-purple-800 rounded">
                      {String.replace(field, "_", " ") |> String.capitalize()}
                    </span>
                  <% end %>
                  <%= if length(log.changed_fields) > 3 do %>
                    <span class="px-2 py-0.5 text-xs font-medium bg-slate-100 text-slate-600 rounded">
                      +{length(log.changed_fields) - 3} more
                    </span>
                  <% end %>
                </div>
              <% else %>
                <span class="text-slate-400 text-xs">No field changes</span>
              <% end %>
            </div>
          </:col>

          <:action :let={log}>
            <div class="flex items-center justify-center">
              <.link
                navigate={~p"/admin/audit_logs/#{log}"}
                class="flex items-center text-brand-accent hover:text-brand-primary"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-4 w-4 mr-1"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                  />
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"
                  />
                </svg>
                View Details
              </.link>
            </div>
          </:action>
        </.data_table>
      <% end %>
      <.pagination
        page={@page}
        total_pages={@total_pages}
        total_count={@total_count}
        per_page={@per_page}
      />
    </div>
    """
  end
end
