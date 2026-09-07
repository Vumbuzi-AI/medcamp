defmodule MedcampWeb.LabPagesLabResultLive.Index do
  use MedcampWeb, :lab_live_view

  alias Medcamp.LabResults
  alias Medcamp.LabResults.LabResult
  alias Medcamp.Accounts

  @per_page 10

  @impl true
  def mount(_, _session, socket) do
    doctors = Accounts.list_all_doctors()
    test_names = LabResults.list_unique_test_names()

    {:ok,
     socket
     |> assign(:active_tab, :lab_results)
     |> assign(:filters, %{})
     |> assign(:doctors, doctors)
     |> assign(:test_names, test_names)
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> assign(:total_count, 0)
     |> assign(:total_pages, 0)
     |> assign(:lab_results, [])
     |> assign_lab_results(%{}, 1)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> apply_action(socket.assigns.live_action, params)}
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
  def handle_event("delete", %{"id" => id}, socket) do
    lab_result = LabResults.get_lab_result!(id)
    {:ok, _} = LabResults.delete_lab_result(lab_result)

    {:noreply, assign_lab_results(socket, socket.assigns.filters, socket.assigns.page)}
  end

  @impl true
  def handle_event("filter", %{"filters" => filters}, socket) do
    {:noreply, apply_filter_updates(socket, filters)}
  end

  @impl true
  def handle_event("clear_chip", %{"field" => field}, socket) do
    {:noreply, apply_filter_updates(socket, %{field => ""})}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply,
     socket
     |> assign(:filters, %{
       search: "",
       date_from: "",
       date_to: "",
       time_from: "",
       time_to: "",
       age_group: nil,
       gender: nil,
       urgency: nil,
       report_complete: nil,
       doctor_id: nil,
       test_name: nil
     })
     |> assign_lab_results(%{}, 1)}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply, assign_lab_results(socket, socket.assigns.filters, page)}
  end

  defp apply_filter_updates(socket, updates) do
    filters = Map.merge(stringify_filters(socket.assigns.filters), updates)
    search = filters["search"] || ""
    # Parse date filters
    date_from = parse_date(filters["date_from"])
    date_to = parse_date(filters["date_to"])
    time_from = parse_time(filters["time_from"])
    time_to = parse_time(filters["time_to"])
    age_group = blank_to_nil(filters["age_group"])
    gender = blank_to_nil(filters["gender"])
    urgency = blank_to_nil(filters["urgency"])
    report_complete = blank_to_nil(filters["report_complete"])
    doctor_id = blank_to_nil(filters["doctor_id"])
    test_name = blank_to_nil(filters["test_name"])

    filter_params = %{
      search: search,
      date_from: date_from,
      date_to: date_to,
      time_from: time_from,
      time_to: time_to,
      age_group: age_group,
      gender: gender,
      urgency: urgency,
      report_complete: report_complete,
      doctor_id: doctor_id,
      test_name: test_name
    }

    # Store original string values for form display
    display_filters = %{
      search: search,
      date_from: filters["date_from"] || "",
      date_to: filters["date_to"] || "",
      time_from: filters["time_from"] || "",
      time_to: filters["time_to"] || "",
      age_group: age_group,
      gender: gender,
      urgency: urgency,
      report_complete: report_complete,
      doctor_id: doctor_id,
      test_name: test_name
    }

    socket
    |> assign(:filters, display_filters)
    |> assign_lab_results(filter_params, 1)
  end

  defp assign_lab_results(socket, filters, page) do
    page = normalize_page(page)
    total_count = LabResults.count_lab_results(filters)
    total_pages = max(1, div(total_count + @per_page - 1, @per_page))
    page = min(page, total_pages)

    lab_results = LabResults.filter_lab_results_paginated(filters, page, @per_page)

    socket
    |> assign(:page, page)
    |> assign(:per_page, @per_page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:lab_results, lab_results)
  end

  # The search box and the filter drawer submit independently (two separate
  # <form>s), so a submission from either one only carries its own fields.
  # Merging onto the raw string form of the currently-applied filters means a
  # key absent from this submission is left unchanged rather than cleared.
  @filter_keys ~w(search date_from date_to time_from time_to age_group gender
                  urgency report_complete doctor_id test_name)a

  defp stringify_filters(filters) do
    Map.new(@filter_keys, fn key -> {Atom.to_string(key), filters[key] || ""} end)
  end

  defp count_active_filters(filters) do
    filters
    |> Map.drop([:search])
    |> Map.values()
    |> Enum.count(&(&1 not in [nil, ""]))
  end

  defp filter_chips(filters, doctors) do
    [
      filter_chip(filters[:search], "search", "Search: #{filters[:search]}"),
      filter_chip(filters[:date_from], "date_from", "From #{filters[:date_from]}"),
      filter_chip(filters[:date_to], "date_to", "To #{filters[:date_to]}"),
      filter_chip(filters[:time_from], "time_from", "From #{filters[:time_from]}"),
      filter_chip(filters[:time_to], "time_to", "To #{filters[:time_to]}"),
      filter_chip(filters[:age_group], "age_group", age_group_label(filters[:age_group])),
      filter_chip(filters[:gender], "gender", filters[:gender]),
      filter_chip(filters[:urgency], "urgency", filters[:urgency]),
      filter_chip(
        filters[:report_complete],
        "report_complete",
        report_complete_label(filters[:report_complete])
      ),
      filter_chip(filters[:doctor_id], "doctor_id", doctor_label(filters[:doctor_id], doctors)),
      filter_chip(filters[:test_name], "test_name", filters[:test_name])
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp age_group_label("<5"), do: "<5 years"
  defp age_group_label("≥5"), do: "≥5 Years"
  defp age_group_label(other), do: other

  defp report_complete_label("true"), do: "Complete"
  defp report_complete_label("false"), do: "Pending"
  defp report_complete_label(other), do: other

  defp lab_result_status_badge(true), do: {"Complete", "bg-green-100 text-green-800"}
  defp lab_result_status_badge(_), do: {"Pending", "bg-amber-100 text-amber-800"}

  defp doctor_label(nil, _doctors), do: nil

  defp doctor_label(doctor_id, doctors) do
    case Enum.find(doctors, &(Integer.to_string(&1.id) == doctor_id)) do
      nil -> doctor_id
      doctor -> doctor.name
    end
  end

  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value

  defp parse_date(""), do: nil
  defp parse_date(nil), do: nil

  defp parse_date(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> date
      _ -> nil
    end
  end

  defp parse_time(""), do: nil
  defp parse_time(nil), do: nil

  defp parse_time(time_string) do
    # HTML time input returns "HH:MM" format, Time.from_iso8601 needs "HH:MM:SS"
    time_with_seconds = time_string <> ":00"

    case Time.from_iso8601(time_with_seconds) do
      {:ok, time} -> time
      _ -> nil
    end
  end

  defp format_datetime(datetime) do
    shifted_datetime = Timex.shift(datetime, hours: 3)
    Timex.format!(shifted_datetime, "{Mfull} {D}, {YYYY} at {h12}:{m} {AM}")
  end

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
    <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-4">
      <.page_header
        icon_path="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"
        title="Lab Results"
        subtitle="Search, filter and review patient laboratory records."
      />

      <div class="flex flex-wrap items-center gap-3 mb-4">
        <form phx-change="filter" class="flex-1">
          <.search_input
            name="filters[search]"
            value={@filters[:search] || ""}
            placeholder="Search by patient name, email, or GSRN"
          />
        </form>

        <.filter_drawer
          id="lab-filters-drawer"
          title="Filter lab results"
          apply_event="filter"
          active_count={count_active_filters(@filters)}
        >
          <:chip
            :for={chip <- filter_chips(@filters, @doctors)}
            label={chip.label}
            clear={JS.push("clear_chip", value: %{"field" => chip.field})}
          />
          <:group label="Date and Time">
            <.date_range_fields
              from_name="filters[date_from]"
              to_name="filters[date_to]"
              from_value={@filters[:date_from] || ""}
              to_value={@filters[:date_to] || ""}
            />
            <.time_range_fields
              from_name="filters[time_from]"
              to_name="filters[time_to]"
              from_value={@filters[:time_from] || ""}
              to_value={@filters[:time_to] || ""}
            />
          </:group>

          <:group label="Patient Details">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Age Group</label>
              <select
                name="filters[age_group]"
                class="w-full h-[40px] border-[1px] border-gray-300 focus:outline-none focus:ring-0 rounded-md p-2"
              >
                <option value="">All Ages</option>
                <option value="<5" selected={@filters[:age_group] == "<5"}>{"<"}5 years</option>
                <option value="≥5" selected={@filters[:age_group] == "≥5"}>≥5 Years</option>
              </select>
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Gender</label>
              <select
                name="filters[gender]"
                class="w-full h-[40px] border-[1px] border-gray-300 focus:outline-none focus:ring-0 rounded-md p-2"
              >
                <option value="">All Genders</option>
                <option value="Male" selected={@filters[:gender] == "Male"}>Male</option>
                <option value="Female" selected={@filters[:gender] == "Female"}>Female</option>
              </select>
            </div>
          </:group>

          <:group label="Lab Details">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Urgency</label>
              <select
                name="filters[urgency]"
                class="w-full h-[40px] border-[1px] border-gray-300 focus:outline-none focus:ring-0 rounded-md p-2"
              >
                <option value="">All Urgency Levels</option>
                <option value="Urgent" selected={@filters[:urgency] == "Urgent"}>Urgent</option>
                <option value="High" selected={@filters[:urgency] == "High"}>High</option>
                <option value="Medium" selected={@filters[:urgency] == "Medium"}>Medium</option>
                <option value="Low" selected={@filters[:urgency] == "Low"}>Low</option>
              </select>
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Report Status</label>
              <select
                name="filters[report_complete]"
                class="w-full h-[40px] border-[1px] border-gray-300 focus:outline-none focus:ring-0 rounded-md p-2"
              >
                <option value="">All Statuses</option>
                <option value="true" selected={@filters[:report_complete] == "true"}>Complete</option>
                <option value="false" selected={@filters[:report_complete] == "false"}>
                  Pending
                </option>
              </select>
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Doctor</label>
              <select
                name="filters[doctor_id]"
                class="w-full h-[40px] border-[1px] border-gray-300 focus:outline-none focus:ring-0 rounded-md p-2"
              >
                <option value="">All Doctors</option>
                <%= for doctor <- @doctors do %>
                  <option
                    value={doctor.id}
                    selected={@filters[:doctor_id] == Integer.to_string(doctor.id)}
                  >
                    {doctor.name}
                  </option>
                <% end %>
              </select>
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Test Name</label>
              <select
                name="filters[test_name]"
                class="w-full h-[40px] border-[1px] border-gray-300 focus:outline-none focus:ring-0 rounded-md p-2"
              >
                <option value="">All Tests</option>
                <%= for test_name <- @test_names do %>
                  <option value={test_name} selected={@filters[:test_name] == test_name}>
                    {test_name}
                  </option>
                <% end %>
              </select>
            </div>
          </:group>
        </.filter_drawer>
      </div>

      <.table
        id="lab_results"
        rows={@lab_results}
        row_id={fn lab_result -> "lab-result-#{lab_result.id}" end}
        row_click={fn lab_result -> JS.navigate(~p"/lab/lab_results/#{lab_result}") end}
      >
        <:empty_state>
          <tr>
            <td colspan="7" class="px-6 py-16 text-center">
              <div class="mx-auto flex max-w-md flex-col items-center">
                <div class="flex h-12 w-12 items-center justify-center rounded-xl border border-[#d9dcff] bg-[#f0f0ff] text-[#373896]">
                  <Heroicons.icon name="magnifying-glass" type="outline" class="h-6 w-6" />
                </div>
                <h3 class="mt-4 text-base font-semibold text-gray-900">
                  <%= if (@filters[:search] || "") != "" or count_active_filters(@filters) > 0 do %>
                    No matching lab results
                  <% else %>
                    No lab results available
                  <% end %>
                </h3>
                <p class="mt-2 text-sm text-gray-500">
                  <%= if (@filters[:search] || "") != "" or count_active_filters(@filters) > 0 do %>
                    No records match the current search or filters.
                  <% else %>
                    Lab results will appear here once they are recorded.
                  <% end %>
                </p>
                <button
                  :if={(@filters[:search] || "") != "" or count_active_filters(@filters) > 0}
                  type="button"
                  phx-click="clear_filters"
                  class="mt-5 rounded-lg border border-[#cdd0ff] bg-[#f0f0ff] px-4 py-2 text-sm font-semibold text-[#373896] hover:bg-[#e7e7ff]"
                >
                  Clear search and filters
                </button>
              </div>
            </td>
          </tr>
        </:empty_state>

        <:col :let={lab_result} label="Tests Requested">
          <div class="flex gap-2 items-center flex-wrap py-3">
            <%= for test <- lab_result.tests do %>
              <span class="px-2 py-1 text-xs rounded-full bg-[#f0f0ff] text-[#373896]">
                {test.name}
              </span>
            <% end %>
          </div>
        </:col>

        <:col :let={lab_result} label="Patient">
          <div class="flex items-center py-3">
            <div class="h-8 w-8 rounded-full bg-[#e7e7ff] flex items-center justify-center text-[#373896] font-medium mr-2 text-sm">
              {String.first(lab_result.patient.first_name || "")}
            </div>
            <span class="font-medium text-gray-900">
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
            <span class="px-2 py-1 text-xs rounded-full bg-[#e7e7ff] text-[#373896]">
              Dr. {lab_result.doctor.name}
            </span>
          </div>
        </:col>

        <:col :let={lab_result} label="Status">
          <div class="flex items-center py-3">
            <% {label, classes} = lab_result_status_badge(lab_result.report_complete) %>
            <span class={"px-2 py-1 text-xs rounded-full font-medium #{classes}"}>
              {label}
            </span>
          </div>
        </:col>

        <:col :let={lab_result} label="Date">
          <p class="">
            {format_datetime(lab_result.inserted_at)}
          </p>
        </:col>

        <:action :let={lab_result}>
          <div class="flex items-center justify-center">
            <.link
              navigate={~p"/lab/lab_results/#{lab_result}"}
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
      </.table>

      <.pagination
        page={@page}
        total_pages={@total_pages}
        total_count={@total_count}
        per_page={@per_page}
        show_when_empty={true}
      />
    </div>
    """
  end
end
