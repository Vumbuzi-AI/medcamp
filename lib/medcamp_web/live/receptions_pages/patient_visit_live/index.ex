defmodule MedcampWeb.ReceptionsPagePatientLive.PatientVisitIndex do
  use MedcampWeb, :reception_live_view

  alias Medcamp.PatientVisits
  alias Medcamp.PatientVisits.PatientVisit

  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :visits)
     |> assign(:filters, %{})
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

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Patient visit")
    |> assign(:patient_visit, PatientVisits.get_patient_visit!(id))
  end

  defp apply_action(socket, :trigger_payment, %{"id" => id}) do
    socket
    |> assign(:page_title, "Trigger Patient visit")
    |> assign(:patient_visit, PatientVisits.get_patient_visit!(id))
  end

  defp apply_action(socket, :trigger_payment_subsidized, %{"id" => id}) do
    socket
    |> assign(:page_title, "Trigger Patient visit (Subsidized Doctor Consultation for Students)")
    |> assign(:patient_visit, PatientVisits.get_patient_visit!(id))
  end

  defp apply_action(socket, :trigger_payment_triage, %{"id" => id}) do
    socket
    |> assign(:page_title, "Trigger Patient visit")
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
  def handle_info({MedcampWeb.PatientVisitLive.FormComponent, {:saved, _patient_visit}}, socket) do
    {:noreply, load_patient_visits(socket)}
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
    # Parse date filters
    date_from = parse_date(filters["date_from"])
    date_to = parse_date(filters["date_to"])
    time_from = parse_time(filters["time_from"])
    time_to = parse_time(filters["time_to"])
    age_group = if filters["age_group"] != "", do: filters["age_group"], else: nil
    gender = if filters["gender"] != "", do: filters["gender"], else: nil
    diagnosis = if filters["diagnosis"] != "", do: filters["diagnosis"], else: nil
    visit_type = if filters["visit_type"] != "", do: filters["visit_type"], else: nil

    filter_params = %{
      search: socket.assigns.search,
      date_from: date_from,
      date_to: date_to,
      time_from: time_from,
      time_to: time_to,
      age_group: age_group,
      gender: gender,
      diagnosis: diagnosis,
      visit_type: visit_type
    }

    # Store original string values for form display
    display_filters = %{
      date_from: filters["date_from"] || "",
      date_to: filters["date_to"] || "",
      time_from: filters["time_from"] || "",
      time_to: filters["time_to"] || "",
      age_group: age_group,
      gender: gender,
      diagnosis: diagnosis || "",
      visit_type: visit_type
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
      age_group: filters[:age_group],
      gender: filters[:gender],
      diagnosis: filters[:diagnosis],
      visit_type: filters[:visit_type]
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
     |> assign(:filters, %{
       date_from: "",
       date_to: "",
       time_from: "",
       time_to: "",
       age_group: nil,
       gender: nil,
       diagnosis: "",
       visit_type: nil
     })
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

  defp count_active_filters(filters) do
    filters
    |> Map.take([
      :date_from,
      :date_to,
      :time_from,
      :time_to,
      :age_group,
      :gender,
      :diagnosis,
      :visit_type
    ])
    |> Map.values()
    |> Enum.count(&(&1 not in [nil, ""]))
  end

  defp filter_chips(filters, visit_type_options) do
    [
      filter_chip(filters[:date_from], "date_from", "From #{filters[:date_from]}"),
      filter_chip(filters[:date_to], "date_to", "To #{filters[:date_to]}"),
      filter_chip(filters[:time_from], "time_from", "From #{filters[:time_from]}"),
      filter_chip(filters[:time_to], "time_to", "To #{filters[:time_to]}"),
      filter_chip(filters[:age_group], "age_group", filters[:age_group]),
      filter_chip(filters[:gender], "gender", filters[:gender]),
      filter_chip(filters[:diagnosis], "diagnosis", filters[:diagnosis]),
      filter_chip(
        filters[:visit_type],
        "visit_type",
        visit_type_label(filters[:visit_type], visit_type_options)
      )
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp visit_type_label(nil, _options), do: nil

  defp visit_type_label(value, options) do
    case Enum.find(options, fn {v, _label} -> v == value end) do
      {_v, label} -> label
      nil -> value
    end
  end

  @visit_type_options [
    {"inpatient", "Inpatient"},
    {"outpatient", "Outpatient"},
    {"MCH", "MCH"},
    {"referral in", "Referral In"},
    {"referral out", "Referral Out"},
    {"Doctor Consultation", "Doctor Consultation"},
    {"Triage Only", "Triage Only"},
    {"ANC", "ANC"},
    {"Lab Test", "Lab Test"},
    {"Pharmacy", "Pharmacy"},
    {"Other", "Other"}
  ]

  @impl true

  def render(assigns) do
    assigns = assign(assigns, :visit_type_options, @visit_type_options)

    ~H"""
    <div>
      <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-4">
        <.page_header
          icon_path="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
          title="Patient Visits"
          subtitle="Search, filter and manage patient visit records."
        >
          <:actions>
            <.link patch={~p"/reception/visits/new"}>
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
                  New Patient visit
                </div>
              </.button>
            </.link>
          </:actions>
        </.page_header>

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
                visit_type_options={@visit_type_options}
              />
            </:group>

            <:chip
              :for={chip <- filter_chips(@filters, @visit_type_options)}
              label={chip.label}
              clear={JS.push("clear_chip", value: %{"field" => chip.field})}
            />
          </.filter_drawer>
        </div>

        <.blank_state
          :if={@total_count == 0}
          icon_path="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
          title="No patient visits"
          description={
            if @search != "" or count_active_filters(@filters) > 0,
              do: "No patient visits match the current filters.",
              else: "No patient visits have been recorded yet."
          }
        >
          <:actions :if={@search != "" or count_active_filters(@filters) > 0}>
            <button phx-click="clear_filters" class="text-xs text-[#6667ab] hover:underline">
              Clear filters
            </button>
          </:actions>
        </.blank_state>
        <.table :if={@total_count > 0} id="patient_visits" rows={@patient_visits}
          row_id={&"patient_visits-#{&1.id}"}
        >
          <:col :let={patient_visit} label="Patient">
            <div class="flex items-center py-3">
              <div class="h-8 w-8 rounded-full bg-[#e7e7ff] flex items-center justify-center text-[#373896] font-medium mr-2 text-sm">
                {String.first(patient_visit.patient.first_name || "")}
              </div>
              <span class="font-medium text-gray-900">
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
                class="h-4 w-4 mr-1 text-[#6667ab]"
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
              <span class="text-gray-700">{patient_visit.date}</span>
            </div>
          </:col>

          <:col :let={patient_visit} label="Time">
            <div class="flex items-center py-3">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-4 w-4 mr-1 text-[#6667ab]"
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
              <span class="text-gray-700">{patient_visit.time}</span>
            </div>
          </:col>

          <:col :let={patient_visit} label="Reason">
            <div class="max-w-xs py-3">
              <span class="text-gray-700 line-clamp-2">{patient_visit.reason}</span>
            </div>
          </:col>

          <:col :let={patient_visit} label="Doctor">
            <div class="flex items-center py-3">
              <%= if patient_visit.doctor && patient_visit.doctor.name do %>
                <span class="px-2 py-1 text-xs rounded-full bg-[#e7e7ff] text-[#373896]">
                  Dr. {patient_visit.doctor.name}
                </span>
              <% else %>
                <span class="px-2 py-1 text-xs rounded-full bg-gray-100 text-gray-500">
                  Not Assigned
                </span>
              <% end %>
            </div>
          </:col>

          <:col :let={patient_visit} label="Payment Type">
            <div class="flex items-center py-3">
              <span class="px-2 py-1 text-xs rounded-full bg-[#f0f0ff] text-[#373896]">
                {patient_visit.payment_type}
              </span>
            </div>
          </:col>

          <:col :let={patient_visit} label="Visit Type">
            <div class="flex items-center py-3">
              <span class="px-2 py-1 text-xs rounded-full bg-blue-100 text-blue-800">
                {patient_visit.visit_type}
              </span>
            </div>
          </:col>

          <:col :let={patient_visit} label="Payment Status">
            <div class="flex items-center py-3">
              <%= if patient_visit.has_paid do %>
                <span class="px-2 py-1 text-xs rounded-full bg-green-100 text-green-800 font-medium">
                  Paid
                </span>
              <% else %>
                <.link patch={
                  cond do
                    patient_visit.visit_type == "Triage Only" ->
                      ~p"/reception/visits/#{patient_visit.id}/trigger_payment_triage"

                    patient_visit.visit_type in [
                      "Subsidized",
                      "Subsidized Doctor Consultation for Students"
                    ] ->
                      ~p"/reception/visits/#{patient_visit.id}/trigger_payment_subsidized"

                    true ->
                      ~p"/reception/visits/#{patient_visit.id}/trigger_payment"
                  end
                }>
                  <.button class="bg-[#6667ab] hover:bg-[#5556a0] py-1 px-2 text-xs">
                    Prompt Patient
                  </.button>
                </.link>
              <% end %>
            </div>
          </:col>

          <:col :let={patient_visit} label="Amount paid">
            <div class="flex items-center py-3">
              <span class="font-medium text-gray-900">
                KSh {patient_visit.total_amount_paid}
              </span>
            </div>
          </:col>

          <:action :let={patient_visit}>
            <div class="flex items-center justify-center">
              <.link
                patch={~p"/reception/visits/#{patient_visit}/edit"}
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

          <:action :let={patient_visit}>
            <div class="flex items-center justify-center">
              <.link
                phx-click={JS.push("delete", value: %{id: patient_visit.id}) |> hide("#patient_visits-#{patient_visit.id}")}
                data-confirm="Are you sure?"
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
      </div>

      <.modal
        :if={@live_action in [:new, :edit]}
        id="patient_visit-modal"
        show
        on_cancel={JS.patch(~p"/reception/visits")}
      >
        <.live_component
          module={MedcampWeb.PatientVisitLive.FormComponent}
          id={@patient_visit.id || :new}
          title={@page_title}
          action={@live_action}
          current_user={@current_user}
          selected_patient={nil}
          patient_visit={@patient_visit}
          patch={~p"/reception/visits"}
        />
      </.modal>

      <.modal
        :if={@live_action in [:trigger_payment]}
        id="patient_visit-modal"
        show
        on_cancel={JS.patch(~p"/reception/visits")}
      >
        <.live_component
          module={MedcampWeb.TriggerPayment}
          id={@patient_visit.id || :new}
          title={@page_title}
          action={@live_action}
          action_to_perform="create_patient_visit"
          return_url="/reception/visits"
          actionable_type={@patient_visit}
          patient={@patient_visit.patient}
          current_user={@current_user}
          patient_id={@patient_visit.patient_id}
          patch={~p"/reception/visits"}
        />
      </.modal>

      <.modal
        :if={@live_action in [:trigger_payment_subsidized]}
        id="patient_visit-modal"
        show
        on_cancel={JS.patch(~p"/reception/visits")}
      >
        <.live_component
          module={MedcampWeb.TriggerPayment}
          id={@patient_visit.id || :new}
          title={@page_title}
          action={@live_action}
          action_to_perform="create_patient_visit_subsidized"
          return_url="/reception/visits"
          actionable_type={@patient_visit}
          patient={@patient_visit.patient}
          current_user={@current_user}
          patient_id={@patient_visit.patient_id}
          patch={~p"/reception/visits"}
        />
      </.modal>

      <.modal
        :if={@live_action in [:trigger_payment_triage]}
        id="patient_visit-modal"
        show
        on_cancel={JS.patch(~p"/reception/visits")}
      >
        <.live_component
          module={MedcampWeb.TriggerPayment}
          id={@patient_visit.id || :new}
          title={@page_title}
          action={@live_action}
          action_to_perform="create_patient_visit_for_triage"
          return_url="/reception/visits"
          actionable_type={@patient_visit}
          patient={@patient_visit.patient}
          current_user={@current_user}
          patient_id={@patient_visit.patient_id}
          patch={~p"/reception/visits"}
        />
      </.modal>
    </div>
    """
  end
end
