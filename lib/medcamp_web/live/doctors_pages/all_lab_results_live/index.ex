defmodule MedcampWeb.DoctorsPagePatientLive.AllLabResultsLiveIndex do
  use MedcampWeb, :doctor_live_view

  alias Medcamp.LabResults
  alias Medcamp.LabResults.LabResult

  @per_page 10
  @default_filters %{"urgency" => "", "report_complete" => ""}

  @impl true
  def mount(_, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :lab_results)
     |> assign(:search, "")
     |> assign(:filters, @default_filters)
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> assign(:total_count, 0)
     |> assign(:total_pages, 0)
     |> assign_results(1)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, socket |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Lab result")
    |> assign(:lab_result, LabResults.get_lab_result!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Lab result")
    |> assign(:lab_result, %LabResult{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Lab results")
    |> assign(:lab_result, nil)
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply, assign_results(socket, page)}
  end

  @impl true
  def handle_event("search", %{"search" => term}, socket) do
    {:noreply, socket |> assign(:search, term) |> assign_results(1)}
  end

  @impl true
  def handle_event("apply_filters", %{"filters" => filters}, socket) do
    {:noreply, socket |> assign(:filters, filters) |> assign_results(1)}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply,
     socket
     |> assign(:filters, @default_filters)
     |> assign(:search, "")
     |> assign_results(1)}
  end

  @impl true
  def handle_event("clear_chip", %{"field" => field}, socket) do
    filters = Map.put(socket.assigns.filters, field, "")
    {:noreply, socket |> assign(:filters, filters) |> assign_results(1)}
  end

  defp filter_chips(filters) do
    [
      filter_chip(filters["urgency"], "urgency", filters["urgency"]),
      filter_chip(
        filters["report_complete"],
        "report_complete",
        report_complete_chip_label(filters["report_complete"])
      )
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp report_complete_chip_label("true"), do: "Complete"
  defp report_complete_chip_label("false"), do: "Pending"
  defp report_complete_chip_label(other), do: other

  defp count_active_filters(filters) do
    filters
    |> Map.values()
    |> Enum.count(&(&1 not in [nil, ""]))
  end

  defp assign_results(socket, page) do
    page = normalize_page(page)

    query_filters = %{
      search: socket.assigns.search,
      urgency: blank_to_nil(socket.assigns.filters["urgency"]),
      report_complete: blank_to_nil(socket.assigns.filters["report_complete"])
    }

    total_count = LabResults.count_lab_results(query_filters)
    total_pages = max(1, div(total_count + @per_page - 1, @per_page))
    page = min(page, total_pages)

    lab_results = LabResults.filter_lab_results_paginated(query_filters, page, @per_page)

    socket
    |> assign(:page, page)
    |> assign(:per_page, @per_page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:lab_results, lab_results)
  end

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(v), do: v

  defp normalize_page(page) when is_binary(page) do
    case Integer.parse(page) do
      {value, _} when value > 0 -> value
      _ -> 1
    end
  end

  defp normalize_page(page) when is_integer(page) and page > 0, do: page
  defp normalize_page(_), do: 1

  @impl true
  def render(assigns) do
    ~H"""
    <.list_page
      icon_path="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"
      title="Lab Results"
      subtitle="Search and manage all lab results."
    >
      <:toolbar>
        <form phx-change="search" class="flex-1">
          <.search_input
            name="search"
            value={@search}
            placeholder="Search by patient name, email, or GSRN"
          />
        </form>

        <.filter_drawer
          id="lab-results-filters"
          title="Filter lab results"
          apply_event="apply_filters"
          active_count={count_active_filters(@filters)}
        >
          <:group label="Urgency">
            <select
              name="filters[urgency]"
              class="w-full h-9 border border-slate-300 rounded-md px-2 text-sm focus:ring-brand-accent focus:border-brand-accent"
            >
              <option value="" selected={@filters["urgency"] == ""}>All</option>
              <option value="Urgent" selected={@filters["urgency"] == "Urgent"}>Urgent</option>
              <option value="High" selected={@filters["urgency"] == "High"}>High</option>
              <option value="Medium" selected={@filters["urgency"] == "Medium"}>Medium</option>
              <option value="Low" selected={@filters["urgency"] == "Low"}>Low</option>
            </select>
          </:group>

          <:group label="Report Status">
            <select
              name="filters[report_complete]"
              class="w-full h-9 border border-slate-300 rounded-md px-2 text-sm focus:ring-brand-accent focus:border-brand-accent"
            >
              <option value="" selected={@filters["report_complete"] == ""}>All</option>
              <option value="true" selected={@filters["report_complete"] == "true"}>Complete</option>
              <option value="false" selected={@filters["report_complete"] == "false"}>Pending</option>
            </select>
          </:group>

          <:chip
            :for={chip <- filter_chips(@filters)}
            label={chip.label}
            clear={JS.push("clear_chip", value: %{"field" => chip.field})}
          />
        </.filter_drawer>
      </:toolbar>

      <.blank_state
        :if={@lab_results == []}
        icon_path="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"
        title="No lab results"
        description={
          if @search != "" or count_active_filters(@filters) > 0,
            do: "No lab results match the current filters.",
            else: "No lab results have been recorded yet."
        }
      >
        <:actions :if={@search != "" or count_active_filters(@filters) > 0}>
          <button phx-click="clear_filters" class="text-xs text-brand-accent hover:underline">
            Clear filters
          </button>
        </:actions>
      </.blank_state>

      <.data_table :if={@lab_results != []} id="lab_results" rows={@lab_results}>
        <:col :let={lab_result} label="Patient">
          <div class="flex items-center py-3">
            <div class="h-8 w-8 rounded-full bg-brand-100 flex items-center justify-center text-brand-primary font-medium mr-2 text-sm">
              {String.first(lab_result.patient.first_name || "")}
            </div>
            <span class="font-medium text-slate-900">
              {[
                lab_result.patient.first_name,
                lab_result.patient.middle_name,
                lab_result.patient.last_name
              ]
              |> Enum.filter(&(&1 != nil))
              |> Enum.join(" ")}
            </span>
          </div>
        </:col>

        <:col :let={lab_result} label="Doctor">
          <div class="flex items-center py-3">
            <span class="px-2 py-1 text-xs rounded-full bg-brand-100 text-brand-primary">
              Dr. {lab_result.doctor.name}
            </span>
          </div>
        </:col>

        <:col :let={lab_result} label="Urgency">
          <div class="py-3">
            <%= case lab_result.urgency do %>
              <% "High" -> %>
                <span class="px-2 py-1 text-xs rounded-full bg-red-100 text-red-800 font-medium">
                  {lab_result.urgency}
                </span>
              <% "Medium" -> %>
                <span class="px-2 py-1 text-xs rounded-full bg-orange-100 text-orange-800 font-medium">
                  {lab_result.urgency}
                </span>
              <% _ -> %>
                <span class="px-2 py-1 text-xs rounded-full bg-blue-100 text-blue-800 font-medium">
                  {lab_result.urgency}
                </span>
            <% end %>
          </div>
        </:col>

        <:col :let={lab_result} label="Requested">
          <p class="py-3 text-sm text-slate-700">
            {format_datetime_kenya(lab_result.inserted_at)}
          </p>
        </:col>

        <:col :let={lab_result} label="Status">
          <div class="py-3">
            <%= if lab_result.report_complete do %>
              <div class="flex items-center">
                <Heroicons.icon name="check-circle" type="solid" class="h-6 w-6 text-green-500" />
                <span class="ml-2 text-green-600 text-sm font-medium">Complete</span>
              </div>
            <% else %>
              <div class="flex items-center">
                <Heroicons.icon name="clock" type="solid" class="h-6 w-6 text-amber-500" />
                <span class="ml-2 text-amber-600 text-sm font-medium">Pending</span>
              </div>
            <% end %>
          </div>
        </:col>
        <:footer>
          <.pagination
            page={@page}
            total_pages={@total_pages}
            total_count={@total_count}
            per_page={@per_page}
          />
        </:footer>
      </.data_table>
    </.list_page>
    """
  end
end
