defmodule MedcampWeb.RequisitionLive.Index do
  use MedcampWeb, :shared_live_view

  alias MedcampWeb.RoleRouteHelpers
  alias Medcamp.Requisitions
  alias Medcamp.Requisitions.Requisition
  alias Medcamp.Departments

  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    {:ok,
     socket
     |> assign(:filter, "all")
     |> assign(:search, "")
     |> assign(:department_filter, "")
     |> assign(:date_from, "")
     |> assign(:date_to, "")
     |> assign(:departments, Departments.list_departments_for_selection())
     |> assign(:selected_requisition_ids, MapSet.new())
     |> assign(:show_rfq_modal, false)
     |> assign(:rfq_requisition_ids, [])
     |> assign(:current_user, current_user)
     |> assign(:active_tab, :requisitions)
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> refresh_requisitions()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    requisition = Requisitions.get_requisition!(id)
    current_user = socket.assigns.current_user

    # Only allow editing if the user is the creator
    if requisition.requested_by_id == current_user.id do
      socket
      |> assign(:page_title, "Edit Requisition")
      |> assign(:requisition, requisition)
    else
      socket
      |> put_flash(:error, "You can only edit requisitions you created")
      |> push_patch(to: requisitions_path(socket.assigns.current_user))
    end
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Requisition")
    |> assign(:requisition, %Requisition{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Requisitions")
    |> assign(:requisition, nil)
  end

  @impl true
  def handle_info({MedcampWeb.RequisitionLive.FormComponent, {:saved, _requisition}}, socket) do
    {:noreply,
     socket
     |> refresh_requisitions()}
  end

  @impl true
  def handle_info({MedcampWeb.RequisitionLive.RfqModalComponent, :close}, socket) do
    {:noreply, socket |> assign(:show_rfq_modal, false) |> assign(:rfq_requisition_ids, [])}
  end

  def handle_info({MedcampWeb.RequisitionLive.RfqModalComponent, {:saved, rfq, :draft}}, socket) do
    {:noreply, put_flash(socket, :info, "RFQ #{rfq.reference} draft saved.")}
  end

  def handle_info({MedcampWeb.RequisitionLive.RfqModalComponent, {:saved, rfq, :sent}}, socket) do
    {:noreply,
     socket
     |> assign(:show_rfq_modal, false)
     |> assign(:rfq_requisition_ids, [])
     |> assign(:selected_requisition_ids, MapSet.new())
     |> put_flash(:info, "RFQ #{rfq.reference} sent to suppliers.")}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    requisition = Requisitions.get_requisition!(id)
    current_user = socket.assigns.current_user

    can_delete? =
      current_user.role in ["admin", "procurement_officer"] or
        requisition.requested_by_id == current_user.id

    if can_delete? do
      {:ok, _} = Requisitions.delete_requisition(requisition)
      selected = MapSet.delete(socket.assigns.selected_requisition_ids, requisition.id)

      {:noreply,
       socket
       |> assign(:selected_requisition_ids, selected)
       |> refresh_requisitions()}
    else
      {:noreply, put_flash(socket, :error, "You are not authorized to delete this requisition.")}
    end
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, Medcamp.Pagination.normalize_page(page))
     |> refresh_requisitions()}
  end

  # The search box and the filter drawer submit independently (two separate
  # <form>s), so a submission from either one only carries its own fields.
  # Merging onto the current filters means a key absent from this submission
  # is left unchanged rather than reset.
  @impl true
  def handle_event("filter", %{"filters" => filters}, socket) do
    current = %{
      "status" => socket.assigns.filter,
      "department_id" => socket.assigns.department_filter,
      "date_from" => socket.assigns.date_from,
      "date_to" => socket.assigns.date_to
    }

    merged = Map.merge(current, filters)

    {:noreply,
     socket
     |> assign(:filter, merged["status"] || "all")
     |> assign(:department_filter, merged["department_id"] || "")
     |> assign(:date_from, merged["date_from"] || "")
     |> assign(:date_to, merged["date_to"] || "")
     |> assign(:page, 1)
     |> refresh_requisitions()}
  end

  @impl true
  def handle_event("clear_chip", %{"field" => field}, socket) do
    default = %{"status" => "all", "department_id" => "", "date_from" => "", "date_to" => ""}
    handle_event("filter", %{"filters" => Map.take(default, [field])}, socket)
  end

  @impl true
  def handle_event("search", %{"search" => term}, socket) do
    {:noreply,
     socket
     |> assign(:search, term)
     |> assign(:page, 1)
     |> refresh_requisitions()}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply,
     socket
     |> assign(:filter, "all")
     |> assign(:department_filter, "")
     |> assign(:date_from, "")
     |> assign(:date_to, "")
     |> assign(:page, 1)
     |> refresh_requisitions()}
  end

  @impl true
  def handle_event("toggle_select", %{"id" => id}, socket) do
    id =
      case Integer.parse(to_string(id)) do
        {int, ""} -> int
        _ -> nil
      end

    {:noreply,
     if is_nil(id) do
       socket
     else
       selected =
         if MapSet.member?(socket.assigns.selected_requisition_ids, id) do
           MapSet.delete(socket.assigns.selected_requisition_ids, id)
         else
           MapSet.put(socket.assigns.selected_requisition_ids, id)
         end

       assign(socket, :selected_requisition_ids, selected)
     end}
  end

  def handle_event("clear_selection", _params, socket) do
    {:noreply, assign(socket, :selected_requisition_ids, MapSet.new())}
  end

  def handle_event("open_rfq_modal", _params, socket) do
    if socket.assigns.current_user.role in ["admin", "procurement_officer"] do
      ids = socket.assigns.selected_requisition_ids |> MapSet.to_list() |> Enum.sort()

      if ids == [] do
        {:noreply, put_flash(socket, :error, "Select at least one requisition first.")}
      else
        {:noreply,
         socket
         |> assign(:rfq_requisition_ids, ids)
         |> assign(:show_rfq_modal, true)}
      end
    else
      {:noreply, put_flash(socket, :error, "You are not authorized to create an RFQ.")}
    end
  end

  def handle_event("close_rfq_modal", _params, socket) do
    {:noreply, socket |> assign(:show_rfq_modal, false) |> assign(:rfq_requisition_ids, [])}
  end

  defp count_active_filters(assigns) do
    [
      assigns.filter != "all",
      assigns.department_filter != "",
      assigns.date_from != "",
      assigns.date_to != ""
    ]
    |> Enum.count(& &1)
  end

  defp filter_chips(assigns) do
    {status_label, _} = status_badge(assigns.filter)

    [
      filter_chip(assigns.filter, "status", status_label, ["all"]),
      filter_chip(
        assigns.department_filter,
        "department_id",
        department_name(assigns.department_filter, assigns.departments)
      ),
      filter_chip(assigns.date_from, "date_from", "From #{assigns.date_from}"),
      filter_chip(assigns.date_to, "date_to", "To #{assigns.date_to}")
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp department_name(id, departments) do
    case Enum.find(departments, fn {_name, dept_id} -> to_string(dept_id) == to_string(id) end) do
      {name, _id} -> name
      nil -> id
    end
  end

  defp refresh_requisitions(socket) do
    page =
      Requisitions.paginate_requisitions_for_user(
        socket.assigns.current_user,
        socket.assigns.filter,
        socket.assigns.search,
        socket.assigns.department_filter,
        socket.assigns.date_from,
        socket.assigns.date_to,
        socket.assigns[:page] || 1,
        socket.assigns[:per_page] || @per_page
      )

    socket
    |> assign_requisitions_state(page, socket.assigns.current_user)
    |> assign(:requisitions, page.entries)
  end

  defp requested_at_for_display(requisition) do
    requisition.requested_at || requisition.inserted_at
  end

  defp assign_requisitions_state(socket, page, current_user) do
    socket
    |> assign(:requisitions_snapshot, page.entries)
    |> assign(:requisitions_count, page.total_entries)
    |> assign(:total_count, page.total_entries)
    |> assign(:total_pages, page.total_pages)
    |> assign(:page, page.page_number)
    |> assign(:per_page, page.page_size)
    |> assign(:has_pending_requisitions, has_pending_requisitions?(page.entries, current_user))
  end

  defp status_badge(status) do
    case status do
      "pending" -> {"Pending", "bg-yellow-100 text-yellow-800"}
      "approved" -> {"Approved", "bg-green-100 text-green-800"}
      "rejected" -> {"Rejected", "bg-red-100 text-red-800"}
      _ -> {status, "bg-gray-100 text-gray-800"}
    end
  end

  defp urgency_badge(urgency) do
    case urgency do
      "critical" -> {"Critical", "bg-red-100 text-red-800 font-bold"}
      "urgent" -> {"Urgent", "bg-orange-100 text-orange-800"}
      "normal" -> {"Normal", "bg-blue-100 text-blue-800"}
      _ -> {urgency, "bg-gray-100 text-gray-800"}
    end
  end

  defp has_pending_requisitions?(stream_inserts, current_user) do
    Enum.any?(stream_inserts, fn
      {_id, _order, requisition} when is_map(requisition) ->
        can_respond?(current_user, requisition)

      {_id, requisition} when is_map(requisition) ->
        can_respond?(current_user, requisition)

      requisition when is_map(requisition) ->
        can_respond?(current_user, requisition)

      _ ->
        false
    end)
  end

  defp can_respond?(%{role: "admin"}, %{status: "pending"}), do: true

  defp can_respond?(current_user, requisition) do
    requisition.status == "pending" and
      (requisition.to_department_id == current_user.department_id or
         requisition.requested_from_id == current_user.id)
  end

  defp requisitions_path(current_user, suffix \\ "") do
    if current_user.role in ["procurement_officer", "stores_officer", "finance_officer"] do
      "/procurement/requisitions" <> suffix
    else
      RoleRouteHelpers.role_path(current_user, "/requisitions" <> suffix)
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-4">
      <.page_header
        icon_path="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
        title="Requisitions"
        subtitle="Search, filter and manage requisitions."
      >
        <:actions>
          <.link
            :if={@current_user.role in ["admin", "support staff"]}
            patch={requisitions_path(@current_user, "/new")}
            class="flex items-center gap-2 px-4 py-2 bg-[#6667ab] text-white rounded-lg hover:bg-[#373896] transition-colors font-medium text-sm"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-4 w-4"
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
            New Requisition
          </.link>
        </:actions>
      </.page_header>
      
    <!-- Search + Status + Filters -->
      <div class="flex flex-wrap items-center gap-3 mb-4 mt-4">
        <form id="requisition-search-form" phx-change="search" class="min-w-[240px] flex-1">
          <.search_input
            name="search"
            value={@search}
            placeholder="Search by title, description, requester, or department"
          />
        </form>

        <.filter_drawer
          id="requisitions-filters"
          title="Filter requisitions"
          apply_event="filter"
          clear_event="clear_filters"
          active_count={count_active_filters(assigns)}
        >
          <:group label="Status">
            <div>
              <label class="block text-xs font-medium text-gray-600 mb-1">Status</label>
              <select
                name="filters[status]"
                class="w-full h-9 rounded-md border border-gray-300 px-2 text-sm focus:ring-[#6667ab] focus:border-[#6667ab]"
              >
                <option value="all" selected={@filter == "all"}>All</option>
                <option value="pending" selected={@filter == "pending"}>Pending</option>
                <option value="approved" selected={@filter == "approved"}>Approved</option>
                <option value="rejected" selected={@filter == "rejected"}>Rejected</option>
              </select>
            </div>
          </:group>

          <:group :if={@current_user.role in ["admin", "procurement_officer"]} label="Department">
            <div>
              <label class="block text-xs font-medium text-gray-600 mb-1">Department</label>
              <select
                name="filters[department_id]"
                class="w-full h-9 rounded-md border border-gray-300 px-2 text-sm focus:ring-[#6667ab] focus:border-[#6667ab]"
              >
                <option value="" selected={@department_filter == ""}>All departments</option>
                <option
                  :for={{name, id} <- @departments}
                  value={id}
                  selected={to_string(id) == to_string(@department_filter)}
                >
                  {name}
                </option>
              </select>
            </div>
          </:group>

          <:group label="Date Range">
            <.date_range_fields
              from_name="filters[date_from]"
              to_name="filters[date_to]"
              from_value={@date_from}
              to_value={@date_to}
              from_label="Requested From"
              to_label="Requested To"
            />
          </:group>

          <:chip
            :for={chip <- filter_chips(assigns)}
            label={chip.label}
            clear={JS.push("clear_chip", value: %{"field" => chip.field})}
          />
        </.filter_drawer>
      </div>

      <div
        :if={@current_user.role in ["admin", "procurement_officer"]}
        class="mb-4 flex flex-wrap items-center justify-between gap-3 rounded-lg border border-slate-100 bg-slate-50 px-4 py-3"
      >
        <div class="text-sm text-slate-700">
          <span class="font-semibold">{MapSet.size(@selected_requisition_ids)}</span> selected
        </div>
        <div class="flex flex-wrap gap-2">
          <button
            type="button"
            phx-click="clear_selection"
            class="rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
            disabled={MapSet.size(@selected_requisition_ids) == 0}
          >
            Clear
          </button>
          <button
            type="button"
            phx-click="open_rfq_modal"
            class="rounded-lg bg-[#373896] px-4 py-2 text-sm font-semibold text-white transition hover:bg-[#2d2d7a] disabled:cursor-not-allowed disabled:bg-slate-300"
            disabled={MapSet.size(@selected_requisition_ids) == 0}
          >
            Create RFQ
          </button>
        </div>
      </div>
      
    <!-- Pending Requisitions Alert -->
      <%= if @has_pending_requisitions do %>
        <div class="mb-4 bg-yellow-50 border-l-4 border-yellow-400 p-4 rounded-lg">
          <div class="flex items-start">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-5 w-5 text-yellow-600 mt-0.5 mr-3 flex-shrink-0"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
              />
            </svg>
            <div>
              <h3 class="text-sm font-medium text-yellow-800">
                You have pending requisitions requiring your approval
              </h3>
              <p class="mt-1 text-sm text-yellow-700">
                Please review and respond to the requisitions marked with "Action Required".
              </p>
            </div>
          </div>
        </div>
      <% end %>

      <.blank_state
        :if={@requisitions_count == 0}
        icon_path="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
        title="No requisitions"
        description={
          if @filter != "all" or @search != "" or count_active_filters(assigns) > 0,
            do: "No requisitions match the current filters.",
            else: "Get started by creating a new requisition."
        }
      >
        <:actions :if={count_active_filters(assigns) > 0}>
          <button phx-click="clear_filters" class="text-xs text-[#6667ab] hover:underline">
            Clear filters
          </button>
        </:actions>
      </.blank_state>
      <%= if @requisitions_count > 0 do %>
        <.table
          id="requisitions"
          rows={@requisitions}
          row_click={
            if @current_user.role in ["admin", "procurement_officer"] do
              nil
            else
              fn requisition ->
                JS.navigate(requisitions_path(@current_user, "/#{requisition.id}"))
              end
            end
          }
        >
          <:col
            :let={requisition}
            :if={@current_user.role in ["admin", "procurement_officer"]}
            label=""
          >
            <div class="py-3">
              <input
                type="checkbox"
                phx-click="toggle_select"
                phx-value-id={requisition.id}
                checked={MapSet.member?(@selected_requisition_ids, requisition.id)}
                class="h-4 w-4 rounded border-slate-300 text-[#373896] focus:ring-[#373896]"
              />
            </div>
          </:col>
          <:col :let={requisition} label="Title">
            <div class="py-3">
              <div class="flex items-start gap-2">
                <span
                  class="block max-w-[14rem] whitespace-normal break-words font-medium text-gray-900 sm:max-w-[18rem] lg:max-w-[22rem] xl:max-w-[26rem]"
                  title={requisition.title}
                >
                  {requisition.title}
                </span>
                <%= if can_respond?(@current_user, requisition) do %>
                  <span class="px-2 py-0.5 text-xs font-medium rounded-full bg-yellow-200 text-yellow-900 animate-pulse">
                    Action Required
                  </span>
                <% end %>
              </div>
            </div>
          </:col>

          <:col :let={requisition} label="Description">
            <div class="max-w-[14rem] py-3 sm:max-w-[18rem] lg:max-w-[22rem] xl:max-w-[26rem]">
              <span
                class="block whitespace-normal break-words text-gray-700"
                title={requisition.description}
              >
                {requisition.description}
              </span>
            </div>
          </:col>

          <:col :let={requisition} label="Qty">
            <div class="py-3">
              <%= if requisition.quantity do %>
                <span class="px-2 py-1 text-xs font-medium rounded-full bg-blue-100 text-blue-800">
                  {requisition.quantity}
                </span>
              <% else %>
                <span class="text-gray-400 text-sm">—</span>
              <% end %>
            </div>
          </:col>

          <:col :let={requisition} label="Requested By">
            <div class="py-3">
              <span class="text-gray-700">{requisition.requested_by.name}</span>
            </div>
          </:col>

          <:col :let={requisition} label="Urgency">
            <div class="py-3">
              <%= case urgency_badge(requisition.urgency || "normal") do %>
                <% {label, classes} -> %>
                  <span class={"px-3 py-1 text-xs font-medium rounded-full #{classes}"}>
                    {label}
                  </span>
              <% end %>
            </div>
          </:col>

          <:col :let={requisition} label="Status">
            <div class="py-3">
              <div class="flex items-center gap-2">
                <%= case status_badge(requisition.status) do %>
                  <% {label, classes} -> %>
                    <span class={"px-3 py-1 text-xs font-medium rounded-full #{classes}"}>
                      {label}
                    </span>
                <% end %>
                <%= if requisition.needs_reorder do %>
                  <span class="px-2 py-0.5 text-xs font-semibold rounded-full bg-red-200 text-red-900 border border-red-300">
                    🔴 REORDER
                  </span>
                <% end %>
              </div>
            </div>
          </:col>

          <:col :let={requisition} label="Requested At">
            <div class="py-3">
              <%= if requested_at = requested_at_for_display(requisition) do %>
                <span class="text-sm text-gray-500">
                  {format_datetime_kenya(requested_at)}
                </span>
              <% else %>
                <span class="text-sm text-gray-400">-</span>
              <% end %>
            </div>
          </:col>

          <:action :let={requisition}>
            <div class="flex items-center justify-center">
              <.link
                navigate={requisitions_path(@current_user, "/#{requisition.id}")}
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

          <:action :let={requisition}>
            <div class="flex items-center justify-center">
              <%= if requisition.requested_by_id == @current_user.id do %>
                <.link
                  patch={requisitions_path(@current_user, "/#{requisition.id}/edit")}
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
              <% else %>
                <span class="text-gray-400 text-sm">-</span>
              <% end %>
            </div>
          </:action>

          <:action :let={requisition}>
            <div class="flex items-center justify-center">
              <.link
                phx-click={JS.push("delete", value: %{id: requisition.id})}
                data-confirm="Are you sure you want to delete this requisition?"
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
        id="requisition-modal"
        show
        on_cancel={JS.patch(requisitions_path(@current_user))}
      >
        <.live_component
          module={MedcampWeb.RequisitionLive.FormComponent}
          id={@requisition.id || :new}
          title={@page_title}
          action={@live_action}
          requisition={@requisition}
          current_user={@current_user}
          patch={requisitions_path(@current_user)}
        />
      </.modal>

      <.modal
        :if={@show_rfq_modal}
        id="rfq-from-requisitions-modal"
        show
        on_cancel={JS.push("close_rfq_modal")}
      >
        <.live_component
          module={MedcampWeb.RequisitionLive.RfqModalComponent}
          id="rfq-from-requisitions"
          requisition_ids={@rfq_requisition_ids}
          current_user={@current_user}
        />
      </.modal>
    </div>
    """
  end
end
