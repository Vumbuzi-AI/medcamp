defmodule MedcampWeb.NursesPages.PatientVisitIndex do
  use MedcampWeb, :nurse_live_view

  alias Medcamp.PatientVisits
  alias Medcamp.PatientVisits.PatientVisit
  alias Medcamp.Accounts

  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    doctors = Accounts.list_all_doctors_for_selection()

    {:ok,
     socket
     |> assign(:doctors, doctors)
     |> assign(:active_tab, :visits)
     |> assign(:filters, default_filters())
     |> assign(:search, "")
     |> assign(:filter_params, %{})
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> load_patient_visits()}
  end

  defp load_patient_visits(socket) do
    filter_params = socket.assigns.filter_params
    total_count = PatientVisits.count_patient_visits(filter_params)
    total_pages = Medcamp.Pagination.total_pages(total_count, socket.assigns.per_page)
    page = min(max(1, socket.assigns.page || 1), total_pages)

    patient_visits =
      PatientVisits.filter_patient_visits_paginated(filter_params, page, socket.assigns.per_page)

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:patient_visits, patient_visits)
  end

  defp default_filters do
    %{
      date_from: "",
      date_to: "",
      time_from: "",
      time_to: "",
      age_group: nil,
      gender: nil,
      diagnosis: "",
      visit_type: nil
    }
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Patient visit")
    |> assign(:patient_visit, PatientVisits.get_patient_visit!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Patient visit")
    |> assign(:patient_visit, %PatientVisit{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Patient Visits")
    |> assign(:patient_visit, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    patient_visit = PatientVisits.get_patient_visit!(id)
    {:ok, _} = PatientVisits.delete_patient_visit(patient_visit)

    {:noreply, load_patient_visits(socket)}
  end

  # The search box and the filter drawer submit independently (two separate
  # <form>s), so a submission from either one only carries its own fields —
  # preserving the current search here keeps a drawer-only submit from
  # wiping it out.
  @impl true
  def handle_event("filter", %{"filters" => filters}, socket) do
    filter_params = %{
      search: socket.assigns.search,
      date_from: parse_date(filters["date_from"]),
      date_to: parse_date(filters["date_to"]),
      time_from: parse_time(filters["time_from"]),
      time_to: parse_time(filters["time_to"]),
      age_group: empty_to_nil(filters["age_group"]),
      gender: empty_to_nil(filters["gender"]),
      diagnosis: empty_to_nil(filters["diagnosis"]),
      visit_type: empty_to_nil(filters["visit_type"])
    }

    display_filters = %{
      date_from: filters["date_from"] || "",
      date_to: filters["date_to"] || "",
      time_from: filters["time_from"] || "",
      time_to: filters["time_to"] || "",
      age_group: filter_params.age_group,
      gender: filter_params.gender,
      diagnosis: filters["diagnosis"] || "",
      visit_type: filter_params.visit_type
    }

    {:noreply,
     socket
     |> assign(:filters, display_filters)
     |> assign(:filter_params, filter_params)
     |> assign(:page, 1)
     |> load_patient_visits()}
  end

  @impl true
  def handle_event("search", %{"search" => term}, socket) do
    filters = socket.assigns.filters

    filter_params = %{
      search: term,
      date_from: parse_date(filters[:date_from]),
      date_to: parse_date(filters[:date_to]),
      time_from: parse_time(filters[:time_from]),
      time_to: parse_time(filters[:time_to]),
      age_group: empty_to_nil(filters[:age_group]),
      gender: empty_to_nil(filters[:gender]),
      diagnosis: empty_to_nil(filters[:diagnosis]),
      visit_type: empty_to_nil(filters[:visit_type])
    }

    {:noreply,
     socket
     |> assign(:search, term)
     |> assign(:filter_params, filter_params)
     |> assign(:page, 1)
     |> load_patient_visits()}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply,
     socket
     |> assign(:filters, default_filters())
     |> assign(:search, "")
     |> assign(:filter_params, %{})
     |> assign(:page, 1)
     |> load_patient_visits()}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, max(1, String.to_integer(page)))
     |> load_patient_visits()}
  end

  @impl true
  def handle_event("clear_chip", %{"field" => field}, socket) do
    f = socket.assigns.filters

    current = %{
      "date_from" => f[:date_from] || "",
      "date_to" => f[:date_to] || "",
      "time_from" => f[:time_from] || "",
      "time_to" => f[:time_to] || "",
      "age_group" => f[:age_group] || "",
      "gender" => f[:gender] || "",
      "diagnosis" => f[:diagnosis] || "",
      "visit_type" => f[:visit_type] || ""
    }

    filters = Map.put(current, field, "")
    handle_event("filter", %{"filters" => filters}, socket)
  end

  defp empty_to_nil(""), do: nil
  defp empty_to_nil(nil), do: nil
  defp empty_to_nil(v), do: v

  defp parse_date(""), do: nil
  defp parse_date(nil), do: nil

  defp parse_date(s) do
    case Date.from_iso8601(s) do
      {:ok, d} -> d
      _ -> nil
    end
  end

  defp parse_time(""), do: nil
  defp parse_time(nil), do: nil

  defp parse_time(s) do
    case Time.from_iso8601(s <> ":00") do
      {:ok, t} -> t
      _ -> nil
    end
  end

  defp count_active_filters(filters) do
    Enum.count(filters, fn {_k, v} -> v not in [nil, ""] end)
  end

  @visit_type_labels [
    {"inpatient", "Inpatient"},
    {"outpatient", "Outpatient"},
    {"MCH", "MCH"},
    {"referral in", "Referral In"},
    {"referral out", "Referral Out"}
  ]

  defp filter_chips(filters) do
    [
      filter_chip(filters[:date_from], "date_from", "From #{filters[:date_from]}"),
      filter_chip(filters[:date_to], "date_to", "To #{filters[:date_to]}"),
      filter_chip(filters[:time_from], "time_from", "From #{filters[:time_from]}"),
      filter_chip(filters[:time_to], "time_to", "To #{filters[:time_to]}"),
      filter_chip(filters[:age_group], "age_group", filters[:age_group]),
      filter_chip(filters[:gender], "gender", filters[:gender]),
      filter_chip(filters[:diagnosis], "diagnosis", filters[:diagnosis]),
      filter_chip(filters[:visit_type], "visit_type", visit_type_label(filters[:visit_type]))
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp visit_type_label(nil), do: nil

  defp visit_type_label(value) do
    case Enum.find(@visit_type_labels, fn {v, _label} -> v == value end) do
      {_v, label} -> label
      nil -> value
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-slate-100 p-4">
      <.page_header
        icon_path="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
        title="Patient Visits"
        subtitle="Search, filter and manage patient visit records."
      />

      <div class="flex flex-wrap items-center gap-3 mb-4">
        <form phx-change="search" class="flex-1">
          <.search_input name="search" value={@search} placeholder="Search by patient name or GSRN" />
        </form>

        <.filter_drawer
          id="patient-visits-filters"
          title="Filter patient visits"
          apply_event="filter"
          active_count={count_active_filters(@filters)}
        >
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
            <.age_gender_fields
              age_group_value={@filters[:age_group] || ""}
              gender_value={@filters[:gender] || ""}
            />
          </:group>

          <:group label="Visit Details">
            <.diagnosis_visit_type_fields
              diagnosis_value={@filters[:diagnosis] || ""}
              visit_type_value={@filters[:visit_type] || ""}
            />
          </:group>

          <:chip
            :for={chip <- filter_chips(@filters)}
            label={chip.label}
            clear={JS.push("clear_chip", value: %{"field" => chip.field})}
          />
        </.filter_drawer>
      </div>

      <%= if @total_count == 0 do %>
        <.blank_state
          icon_path="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
          title="No patient visits"
          description={
            if @search != "" or count_active_filters(@filters) > 0,
              do: "No patient visits match the current filters.",
              else: "No patient visits have been recorded yet."
          }
        >
          <:actions :if={@search != "" or count_active_filters(@filters) > 0}>
            <button phx-click="clear_filters" class="text-xs text-brand-accent hover:underline">
              Clear filters
            </button>
          </:actions>
        </.blank_state>
      <% else %>
        <.data_table id="patient_visits" rows={@patient_visits} row_id={&"patient_visits-#{&1.id}"}>
          <:col :let={patient_visit} label="Patient">
            <div class="flex items-center py-3">
              <div class="h-8 w-8 rounded-full bg-brand-100 flex items-center justify-center text-brand-primary font-medium mr-2 text-sm">
                {String.first(patient_visit.patient.first_name || "")}
              </div>
              <span class="font-medium text-slate-900">
                {[
                  patient_visit.patient.first_name,
                  patient_visit.patient.middle_name
                ]
                |> Enum.filter(&(&1 != nil))
                |> Enum.join(" ")}
              </span>
            </div>
          </:col>

          <:col :let={patient_visit} label="Date">
            <div class="flex items-center py-3">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-4 w-4 mr-1 text-brand-accent"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
                />
              </svg>
              <span class="text-slate-700">{patient_visit.date}</span>
            </div>
          </:col>

          <:col :let={patient_visit} label="Time">
            <div class="flex items-center py-3">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-4 w-4 mr-1 text-brand-accent"
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
              <span class="text-slate-700">{patient_visit.time}</span>
            </div>
          </:col>

          <:col :let={patient_visit} label="Reason">
            <div class="max-w-xs py-3">
              <span class="text-slate-700 line-clamp-2">{patient_visit.reason}</span>
            </div>
          </:col>

          <:col :let={patient_visit} label="Receptionist">
            <div class="flex items-center py-3">
              <span class="px-2 py-1 text-xs rounded-full bg-brand-50 text-brand-primary">
                {patient_visit.creator.name}
              </span>
            </div>
          </:col>

          <:col :let={patient_visit} label="Doctor">
            <div class="flex items-center py-3">
              <%= if patient_visit.doctor && patient_visit.doctor.name do %>
                <span class="px-2 py-1 text-xs rounded-full bg-brand-100 text-brand-primary">
                  Dr. {patient_visit.doctor.name}
                </span>
              <% else %>
                <span class="px-2 py-1 text-xs rounded-full bg-slate-100 text-slate-500">
                  Not Assigned
                </span>
              <% end %>
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

      <.modal
        :if={@live_action in [:new, :edit]}
        id="nurse-modal"
        show
        on_cancel={JS.patch(~p"/nurse/visits")}
      >
        <.live_component
          module={MedcampWeb.NursesPages.FormComponent}
          id={@patient_visit.id || :new}
          title={@page_title}
          doctors={@doctors}
          action={@live_action}
          current_user={@current_user}
          patient_visit={@patient_visit}
          patch={~p"/nurse/visits"}
        />
      </.modal>
    </div>
    """
  end
end
