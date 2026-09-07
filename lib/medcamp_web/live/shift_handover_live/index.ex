defmodule MedcampWeb.ShiftHandoverLive.Index do
  use MedcampWeb, :shared_live_view

  alias MedcampWeb.RoleRouteHelpers
  alias Medcamp.ShiftHandovers
  alias Medcamp.ShiftHandovers.ShiftHandover

  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    {:ok,
     socket
     |> assign(:filter, "all")
     |> assign(:department_filter, "all")
     |> assign(:date_from, nil)
     |> assign(:date_to, nil)
     |> assign(:staff_filter, "all")
     |> assign(:search, "")
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> assign(:active_tab, :shift_handovers)
     |> assign(:can_see_all, current_user.role in ["admin", "doctor"])
     |> assign(:departments, get_departments())
     |> assign(:staff_members, get_staff_members())
     |> apply_filters()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Shift Handover")
    |> assign(:shift_handover, ShiftHandovers.get_shift_handover!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Shift Handover")
    |> assign(:shift_handover, %ShiftHandover{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Shift Handovers")
    |> assign(:shift_handover, nil)
  end

  @impl true
  def handle_info({MedcampWeb.ShiftHandoverLive.FormComponent, {:saved, _shift_handover}}, socket) do
    {:noreply, apply_filters(socket)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    shift_handover = ShiftHandovers.get_shift_handover!(id)
    {:ok, _} = ShiftHandovers.delete_shift_handover(shift_handover)

    {:noreply, apply_filters(socket)}
  end

  def handle_event("filter", %{"filters" => filters}, socket) do
    current = %{
      "status" => socket.assigns.filter,
      "department" => socket.assigns.department_filter,
      "staff" => socket.assigns.staff_filter,
      "date_from" => socket.assigns.date_from && Date.to_iso8601(socket.assigns.date_from),
      "date_to" => socket.assigns.date_to && Date.to_iso8601(socket.assigns.date_to)
    }

    filters = Map.merge(current, filters)
    date_from = parse_filter_date(filters["date_from"])
    date_to = parse_filter_date(filters["date_to"])

    {:noreply,
     socket
     |> assign(:filter, filters["status"] || "all")
     |> assign(:department_filter, filters["department"] || "all")
     |> assign(:staff_filter, filters["staff"] || "all")
     |> assign(:date_from, date_from)
     |> assign(:date_to, date_to)
     |> assign(:page, 1)
     |> apply_filters()}
  end

  def handle_event("clear_chip", %{"field" => field}, socket) do
    default = %{
      "status" => "all",
      "department" => "all",
      "staff" => "all",
      "date_from" => "",
      "date_to" => ""
    }

    handle_event("filter", %{"filters" => Map.take(default, [field])}, socket)
  end

  def handle_event("clear_filters", _params, socket) do
    {:noreply,
     socket
     |> assign(:filter, "all")
     |> assign(:department_filter, "all")
     |> assign(:date_from, nil)
     |> assign(:date_to, nil)
     |> assign(:staff_filter, "all")
     |> assign(:search, "")
     |> assign(:page, 1)
     |> apply_filters()}
  end

  def handle_event("search", %{"search" => query}, socket) do
    {:noreply,
     socket
     |> assign(:search, query)
     |> assign(:page, 1)
     |> apply_filters()}
  end

  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, max(1, String.to_integer(page)))
     |> apply_filters()}
  end

  # Apply search + all filters, then paginate the result
  defp apply_filters(socket) do
    current_user = socket.assigns.current_user
    query = socket.assigns.search

    handovers =
      if query != "" do
        if current_user.role in ["admin", "doctor"] do
          ShiftHandovers.search_shift_handovers(query)
        else
          ShiftHandovers.search_shift_handovers_by_role(query, current_user.role, current_user.id)
        end
      else
        if current_user.role in ["admin", "doctor"] do
          ShiftHandovers.list_shift_handovers()
        else
          ShiftHandovers.list_shift_handovers_by_role(current_user.role, current_user.id)
        end
      end

    handovers =
      handovers
      |> filter_by_status(socket.assigns.filter)
      |> filter_by_department(socket.assigns.department_filter)
      |> filter_by_staff(socket.assigns.staff_filter)
      |> filter_by_dates(socket.assigns.date_from, socket.assigns.date_to)

    total_count = length(handovers)
    total_pages = Medcamp.Pagination.total_pages(total_count, socket.assigns.per_page)
    page = min(max(1, socket.assigns.page || 1), total_pages)

    page_entries =
      Enum.slice(handovers, (page - 1) * socket.assigns.per_page, socket.assigns.per_page)

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:shift_handovers, page_entries)
  end

  defp filter_by_status(handovers, "all"), do: handovers

  defp filter_by_status(handovers, status) do
    Enum.filter(handovers, &(&1.status == status))
  end

  defp filter_by_department(handovers, filter) when filter in ["all", "", nil], do: handovers

  defp filter_by_department(handovers, department) do
    Enum.filter(handovers, fn handover ->
      case handover.department do
        nil -> false
        dept -> String.trim(dept) == String.trim(department)
      end
    end)
  end

  defp filter_by_staff(handovers, filter) when filter in ["all", "", nil], do: handovers

  defp filter_by_staff(handovers, staff) do
    staff_trimmed = String.trim(staff)

    Enum.filter(handovers, fn handover ->
      from_match =
        case handover.handover_from do
          nil -> false
          from -> String.trim(from) == staff_trimmed
        end

      to_match =
        case handover.handover_to do
          nil -> false
          to -> String.trim(to) == staff_trimmed
        end

      from_match || to_match
    end)
  end

  defp filter_by_dates(handovers, nil, nil), do: handovers

  defp filter_by_dates(handovers, date_from, date_to) do
    Enum.filter(handovers, fn handover ->
      shift_date = handover.shift_date || handover.shift_start

      cond do
        is_nil(shift_date) ->
          false

        date_from && date_to ->
          Date.compare(shift_date, date_from) != :lt && Date.compare(shift_date, date_to) != :gt

        date_from ->
          Date.compare(shift_date, date_from) != :lt

        date_to ->
          Date.compare(shift_date, date_to) != :gt

        true ->
          true
      end
    end)
  end

  defp parse_filter_date(""), do: nil
  defp parse_filter_date(nil), do: nil
  defp parse_filter_date(date_string), do: Date.from_iso8601!(date_string)

  # Helper to get unique departments from handovers
  defp get_departments do
    ShiftHandovers.list_unique_departments()
  end

  # Helper to get staff members - you can choose one of these options:
  defp get_staff_members do
    # Option 1: Get from active users
    Medcamp.Accounts.list_staff_names()

    # Option 2: Get from actual handovers (uncomment if preferred)
    # ShiftHandovers.list_unique_staff_from_handovers()
  end

  defp status_badge(status) do
    case status do
      "pending" -> {"Pending", "bg-yellow-100 text-yellow-800"}
      "acknowledged" -> {"Acknowledged", "bg-green-100 text-green-800"}
      "completed" -> {"Completed", "bg-blue-100 text-blue-800"}
      _ -> {status, "bg-gray-100 text-gray-800"}
    end
  end

  defp shift_type_badge(type) do
    case type do
      "morning" -> {"Morning", "bg-amber-100 text-amber-800", "☀️"}
      "afternoon" -> {"Afternoon", "bg-orange-100 text-orange-800", "🌤️"}
      "night" -> {"Night", "bg-indigo-100 text-indigo-800", "🌙"}
      "day" -> {"Day", "bg-sky-100 text-sky-800", "☀️"}
      _ -> {type, "bg-gray-100 text-gray-800", "⏰"}
    end
  end

  defp role_display_name(role) do
    case role do
      "nurse" -> "Nursing Staff"
      "doctor" -> "Medical Staff"
      "reception" -> "Reception Staff"
      "pharmacist" -> "Pharmacy Staff"
      "labtechnician" -> "Lab Staff"
      "radiologist" -> "Radiology Staff"
      "inventory_manager" -> "Inventory Staff"
      "support staff" -> "Support Staff"
      _ -> "All Staff"
    end
  end

  # Only counts the fields that live inside the filter drawer (department,
  # staff, date range) — status has its own always-visible button group with
  # its own selected-state indicator, so it isn't double-counted here.
  defp count_active_filters(assigns) do
    [
      assigns.filter != "all",
      assigns.department_filter != "all",
      assigns.staff_filter != "all",
      assigns.date_from != nil,
      assigns.date_to != nil
    ]
    |> Enum.count(& &1)
  end

  defp filter_chips(assigns) do
    {status_label, _} = status_badge(assigns.filter)

    [
      filter_chip(assigns.filter, "status", status_label, ["all"]),
      assigns.can_see_all &&
        filter_chip(assigns.department_filter, "department", assigns.department_filter, ["all"]),
      assigns.can_see_all &&
        filter_chip(assigns.staff_filter, "staff", assigns.staff_filter, ["all"]),
      assigns.can_see_all &&
        filter_chip(assigns.date_from, "date_from", "From #{assigns.date_from}"),
      assigns.can_see_all && filter_chip(assigns.date_to, "date_to", "To #{assigns.date_to}")
    ]
    |> Enum.reject(&(&1 in [nil, false]))
  end

  defp shift_handovers_path(current_user, suffix \\ "") do
    RoleRouteHelpers.role_path(current_user, "/shift_handovers" <> suffix)
  end

  @impl true
  def render(assigns) do
    header_title =
      if assigns.can_see_all do
        "Shift Handovers"
      else
        "Shift Handovers (#{role_display_name(assigns.current_user.role)})"
      end

    assigns = assign(assigns, :header_title, header_title)

    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-4">
      <.page_header
        icon_path="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4"
        title={@header_title}
        subtitle="Search, filter and manage shift handovers."
      >
        <:actions>
          <.link patch={shift_handovers_path(@current_user, "/new")}>
            <.button class="bg-[#6667ab] hover:bg-[#5556a0]">
              <div class="flex items-center">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-4 w-4 mr-2"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 4v16m8-8H4"
                  />
                </svg>
                New Handover
              </div>
            </.button>
          </.link>
        </:actions>
      </.page_header>
      
    <!-- Info Banner for Non-Admin Users -->
      <%= if !@can_see_all do %>
        <div class="mb-4 bg-blue-50 border border-blue-200 rounded-lg p-3">
          <div class="flex items-start">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-5 w-5 text-blue-600 mt-0.5 mr-2 flex-shrink-0"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
              />
            </svg>
            <div class="text-sm text-blue-800">
              <p class="font-medium">Role-Based View</p>
              <p class="mt-1">
                You're viewing handovers from {role_display_name(@current_user.role)} only.
              </p>
            </div>
          </div>
        </div>
      <% end %>
      
    <!-- Search, Status, and Advanced Filters -->
      <div class="flex flex-col sm:flex-row gap-3 mb-4">
        <form phx-change="search" class="flex-1">
          <.search_input name="search" placeholder="Search by department, staff name, or notes" />
        </form>

        <.filter_drawer
          id="shift-handover-filters"
          title="Filter shift handovers"
          apply_event="filter"
          clear_event="clear_filters"
          active_count={count_active_filters(assigns)}
        >
          <:group label="Status">
            <div>
              <label class="block text-xs font-medium text-gray-700 mb-1">Status</label>
              <select
                name="filters[status]"
                class="block w-full rounded-lg border-gray-300 text-sm focus:ring-[#6667ab] focus:border-[#6667ab]"
              >
                <option value="all" selected={@filter == "all"}>All</option>
                <option value="pending" selected={@filter == "pending"}>Pending</option>
                <option value="acknowledged" selected={@filter == "acknowledged"}>
                  Acknowledged
                </option>
              </select>
            </div>
          </:group>

          <:group :if={@can_see_all} label="Department and Staff">
            <div>
              <label class="block text-xs font-medium text-gray-700 mb-1">Department</label>
              <select
                name="filters[department]"
                class="block w-full rounded-lg border-gray-300 text-sm focus:ring-[#6667ab] focus:border-[#6667ab]"
              >
                <option value="all" selected={@department_filter == "all"}>All Departments</option>
                <%= for dept <- @departments do %>
                  <option value={dept} selected={@department_filter == dept}>{dept}</option>
                <% end %>
              </select>
            </div>
            <div>
              <label class="block text-xs font-medium text-gray-700 mb-1">Staff Member</label>
              <select
                name="filters[staff]"
                class="block w-full rounded-lg border-gray-300 text-sm focus:ring-[#6667ab] focus:border-[#6667ab]"
              >
                <option value="all" selected={@staff_filter == "all"}>All Staff</option>
                <%= for staff <- @staff_members do %>
                  <option value={staff} selected={@staff_filter == staff}>{staff}</option>
                <% end %>
              </select>
            </div>
          </:group>

          <:group :if={@can_see_all} label="Date Range">
            <.date_range_fields
              from_name="filters[date_from]"
              to_name="filters[date_to]"
              from_value={@date_from && Date.to_iso8601(@date_from)}
              to_value={@date_to && Date.to_iso8601(@date_to)}
              from_label="From Date"
              to_label="To Date"
            />
          </:group>

          <:chip
            :for={chip <- filter_chips(assigns)}
            label={chip.label}
            clear={JS.push("clear_chip", value: %{"field" => chip.field})}
          />
        </.filter_drawer>
      </div>

      <%= if @total_count == 0 do %>
        <.blank_state
          icon_path="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4"
          title="No shift handovers"
        >
          <:description_slot>
            <%= if @can_see_all do %>
              <%= if @filter != "all" or count_active_filters(assigns) > 0 do %>
                No handovers match your filters. Try adjusting your search criteria.
              <% else %>
                Get started by creating a new shift handover.
              <% end %>
            <% else %>
              No handovers found for {role_display_name(@current_user.role)}.
            <% end %>
          </:description_slot>
          <:actions :if={@can_see_all and (@filter != "all" or count_active_filters(assigns) > 0)}>
            <button phx-click="clear_filters" class="text-xs text-[#6667ab] hover:underline">
              Clear filters
            </button>
          </:actions>
        </.blank_state>
      <% else %>
        <.table
          id="shift_handovers"
          rows={@shift_handovers}
          row_click={
            fn shift_handover ->
              JS.navigate(shift_handovers_path(@current_user, "/#{shift_handover.id}"))
            end
          }
          row_id={&"shift_handovers-#{&1.id}"}
        >
          <:col :let={handover} label="Shift Details">
            <div class="flex flex-col items-start py-3">
              <div class="flex items-center gap-2 mb-1">
                <%= case shift_type_badge(handover.shift_type) do %>
                  <% {label, classes, emoji} -> %>
                    <span class={"px-2 py-1 text-xs font-medium rounded-full #{classes}"}>
                      {emoji} {label}
                    </span>
                <% end %>
                <span class="text-xs text-gray-500">
                  <span :if={handover.shift_start}>
                    {Calendar.strftime(handover.shift_start, "%b %d, %Y")}
                  </span>
                  to
                  <span :if={handover.shift_date}>
                    {Calendar.strftime(
                      handover.shift_date,
                      "%b %d, %Y"
                    )}
                  </span>
                </span>
              </div>
              <span class="font-medium text-gray-900">{handover.department}</span>
            </div>
          </:col>

          <:col :let={handover} label="Staff">
            <div class="flex flex-col py-3 text-sm">
              <div class="flex items-center text-gray-700 mb-1">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-3 w-3 mr-1 text-gray-400"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
                  />
                </svg>
                <span class="font-medium">From:</span>
                <span class="ml-1">{handover.handover_from}</span>
              </div>
              <div class="flex items-center text-gray-700">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-3 w-3 mr-1 text-gray-400"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
                  />
                </svg>
                <span class="font-medium">To:</span>
                <span class="ml-1">{handover.handover_to}</span>
              </div>
            </div>
          </:col>

          <:col :let={handover} label="Updates & Tasks">
            <div class="py-3 text-sm space-y-1">
              <%= if handover.patient_updates && handover.patient_updates != "" do %>
                <div class="flex items-start">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="h-4 w-4 mr-1 text-blue-500 flex-shrink-0 mt-0.5"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                    />
                  </svg>
                  <span class="text-gray-700 line-clamp-2">{handover.patient_updates}</span>
                </div>
              <% end %>
              <%= if handover.pending_tasks && handover.pending_tasks != "" do %>
                <div class="flex items-start">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="h-4 w-4 mr-1 text-yellow-500 flex-shrink-0 mt-0.5"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                    />
                  </svg>
                  <span class="text-gray-700 line-clamp-2">{handover.pending_tasks}</span>
                </div>
              <% end %>
              <%= if (!handover.patient_updates || handover.patient_updates == "") && (!handover.pending_tasks || handover.pending_tasks == "") do %>
                <span class="text-gray-400">No updates</span>
              <% end %>
            </div>
          </:col>

          <:col :let={handover} label="Status">
            <div class="py-3">
              <%= case status_badge(handover.status) do %>
                <% {label, classes} -> %>
                  <span class={"px-3 py-1 text-xs font-medium rounded-full #{classes}"}>
                    {label}
                  </span>
              <% end %>
              <%= if handover.submitted_at do %>
                <div class="text-xs text-gray-500 mt-1">
                  Submitted {Calendar.strftime(handover.submitted_at, "%H:%M")}
                </div>
              <% end %>
            </div>
          </:col>

          <:action :let={handover}>
            <div class="flex items-center justify-center">
              <.link
                navigate={shift_handovers_path(@current_user, "/#{handover.id}")}
                class="flex items-center text-[#6667ab] hover:text-[#373896]"
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
                View
              </.link>
            </div>
          </:action>

          <:action :let={handover}>
            <div class="flex items-center justify-center">
              <.link
                patch={shift_handovers_path(@current_user, "/#{handover.id}/edit")}
                class="flex items-center text-[#6667ab] hover:text-[#373896]"
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
                    d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
                  />
                </svg>
                Edit
              </.link>
            </div>
          </:action>

          <:action :let={handover}>
            <div class="flex items-center justify-center">
              <.link
                phx-click={JS.push("delete", value: %{id: handover.id}) |> hide("#shift_handovers-#{handover.id}")}
                data-confirm="Are you sure you want to delete this shift handover?"
                class="flex items-center text-red-600 hover:text-red-800"
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
                    d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                  />
                </svg>
                Delete
              </.link>
            </div>
          </:action>
        </.table>
        <.pagination
          page={@page}
          total_pages={@total_pages}
          total_count={@total_count}
          per_page={@per_page}
        />
      <% end %>

      <.modal
        :if={@live_action in [:new, :edit]}
        id="shift_handover-modal"
        show
        on_cancel={JS.patch(shift_handovers_path(@current_user))}
      >
        <.live_component
          module={MedcampWeb.ShiftHandoverLive.FormComponent}
          id={@shift_handover.id || :new}
          title={@page_title}
          action={@live_action}
          shift_handover={@shift_handover}
          current_user={@current_user}
          patch={shift_handovers_path(@current_user)}
        />
      </.modal>
    </div>
    """
  end
end
