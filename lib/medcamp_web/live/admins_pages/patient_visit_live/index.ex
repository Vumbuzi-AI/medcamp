defmodule MedcampWeb.AdminPatientVisitLive.Index do
  use MedcampWeb, :admin_live_view

  alias Medcamp.PatientVisits
  alias Medcamp.PatientVisits.PatientVisit
  alias Medcamp.Accounts

  @per_page 10

  @default_filters %{
    search: "",
    date_from: nil,
    date_to: nil,
    visit_type: nil,
    status: nil,
    gender: nil,
    age_group: nil,
    doctor_id: nil
  }

  @visit_types [
    "Full",
    "Subsidized Doctor Consultation for Students",
    "Doctor Consultation",
    "Triage Only",
    "ANC",
    "Lab Test",
    "Pharmacy",
    "GHCE AT 1",
    "inpatient",
    "outpatient",
    "MCH",
    "referral in",
    "referral out",
    "Other"
  ]

  @impl true
  def mount(_, _session, socket) do
    doctors = Accounts.list_all_doctors_for_selection()

    {:ok,
     socket
     |> assign(:active_tab, :visits)
     |> assign(:filters, @default_filters)
     |> assign(:doctors, doctors)
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> assign(:visit_count, 0)
     |> load_visits()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Patient Visit")
    |> assign(:patient_visit, PatientVisits.get_patient_visit!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Patient Visit")
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
    {:noreply, load_visits(socket)}
  end

  @impl true
  def handle_event("apply_filters", params, socket) do
    # The search box and the filter drawer submit independently (two separate
    # <form>s), so a submission from either one only carries its own fields.
    # Merging onto the raw string form of the currently-applied filters means
    # a key absent from this submission is left unchanged rather than cleared.
    params = Map.merge(stringify_filters(socket.assigns.filters), params)

    filters = %{
      search: nilify(params["search"]),
      date_from: parse_date(params["date_from"]),
      date_to: parse_date(params["date_to"]),
      visit_type: nilify(params["visit_type"]),
      status: nilify(params["status"]),
      gender: nilify(params["gender"]),
      age_group: nilify(params["age_group"]),
      doctor_id: nilify(params["doctor_id"])
    }

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign(:page, 1)
     |> load_visits()}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply,
     socket
     |> assign(:filters, @default_filters)
     |> assign(:page, 1)
     |> load_visits()}
  end

  @impl true
  def handle_event("clear_chip", %{"field" => field}, socket) do
    handle_event("apply_filters", %{field => ""}, socket)
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply, socket |> assign(:page, max(1, String.to_integer(page))) |> load_visits()}
  end

  defp nilify(nil), do: nil
  defp nilify(""), do: nil
  defp nilify(val), do: val

  defp parse_date(nil), do: nil
  defp parse_date(""), do: nil

  defp parse_date(str) do
    case Date.from_iso8601(str) do
      {:ok, date} -> date
      _ -> nil
    end
  end

  @filter_keys ~w(search date_from date_to visit_type status
                  gender age_group doctor_id)a

  defp stringify_filters(filters) do
    Map.new(@filter_keys, fn key ->
      {Atom.to_string(key), stringify_filter_value(filters[key])}
    end)
  end

  defp stringify_filter_value(%Date{} = date), do: Date.to_iso8601(date)
  defp stringify_filter_value(value), do: value || ""

  defp count_active_filters(filters) do
    filters
    |> Map.drop([:search])
    |> Map.values()
    |> Enum.count(&(&1 not in [nil, ""]))
  end

  defp filter_chips(filters, doctors) do
    [
      filter_chip(
        filters.date_from,
        "date_from",
        filters.date_from && "From #{filters.date_from}"
      ),
      filter_chip(filters.date_to, "date_to", filters.date_to && "To #{filters.date_to}"),
      filter_chip(filters.visit_type, "visit_type", filters.visit_type),
      filter_chip(filters.status, "status", PatientVisit.status_label(filters.status)),
      filter_chip(filters.gender, "gender", filters.gender && String.capitalize(filters.gender)),
      filter_chip(filters.age_group, "age_group", age_group_label(filters.age_group)),
      filter_chip(filters.doctor_id, "doctor_id", doctor_name(filters.doctor_id, doctors))
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp age_group_label("<5"), do: "Under 5 years"
  defp age_group_label("5-17"), do: "5 - 17 years"
  defp age_group_label("18-59"), do: "18 - 59 years"
  defp age_group_label("60+"), do: "60 years and above"
  defp age_group_label(other), do: other

  defp doctor_name(nil, _doctors), do: nil

  defp doctor_name(id, doctors) do
    case Enum.find(doctors, fn {_name, doctor_id} -> to_string(doctor_id) == to_string(id) end) do
      {name, _id} -> "Dr. #{name}"
      nil -> id
    end
  end

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :visit_types, @visit_types)

    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-4">
      <.page_header
        icon_path="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
        title="Patient Visits"
        subtitle="Search, filter and manage patient visit records."
      />

      <div class="flex flex-wrap items-center gap-3 mb-4">
        <form phx-change="apply_filters" class="flex-1">
          <.search_input
            name="search"
            value={@filters.search || ""}
            placeholder="Search by patient name or GSRN"
          />
        </form>

        <.filter_drawer
          id="patient-visits-filters"
          title="Filter patient visits"
          apply_event="apply_filters"
          active_count={count_active_filters(@filters)}
        >
          <:group label="Date Range">
            <.date_range_fields
              from_name="date_from"
              to_name="date_to"
              from_value={@filters.date_from && Date.to_iso8601(@filters.date_from)}
              to_value={@filters.date_to && Date.to_iso8601(@filters.date_to)}
            />
          </:group>

          <:group label="Visit Details">
            <div>
              <label class="block text-xs font-medium text-gray-600 mb-1">Visit Type</label>
              <select
                name="visit_type"
                class="w-full rounded-lg border-gray-300 text-sm focus:border-[#6667ab] focus:ring-[#6667ab]"
              >
                <option value="">All Types</option>
                <%= for vt <- @visit_types do %>
                  <option value={vt} selected={@filters.visit_type == vt}>{vt}</option>
                <% end %>
              </select>
            </div>
            <div>
              <label class="block text-xs font-medium text-gray-600 mb-1">Status</label>
              <select
                name="status"
                class="w-full rounded-lg border-gray-300 text-sm focus:border-[#6667ab] focus:ring-[#6667ab]"
              >
                <option value="">All</option>
                <%= for status <- PatientVisit.statuses() do %>
                  <option value={status} selected={@filters.status == status}>
                    {PatientVisit.status_label(status)}
                  </option>
                <% end %>
              </select>
            </div>
            <div>
              <label class="block text-xs font-medium text-gray-600 mb-1">Doctor</label>
              <select
                name="doctor_id"
                class="w-full rounded-lg border-gray-300 text-sm focus:border-[#6667ab] focus:ring-[#6667ab]"
              >
                <option value="">All Doctors</option>
                <%= for {name, id} <- @doctors do %>
                  <option value={id} selected={@filters.doctor_id == to_string(id)}>
                    Dr. {name}
                  </option>
                <% end %>
              </select>
            </div>
          </:group>

          <:group label="Patient Details">
            <div>
              <label class="block text-xs font-medium text-gray-600 mb-1">Patient Gender</label>
              <select
                name="gender"
                class="w-full rounded-lg border-gray-300 text-sm focus:border-[#6667ab] focus:ring-[#6667ab]"
              >
                <option value="">All</option>
                <option value="male" selected={@filters.gender == "male"}>Male</option>
                <option value="female" selected={@filters.gender == "female"}>Female</option>
                <option value="other" selected={@filters.gender == "other"}>Other</option>
              </select>
            </div>
            <div>
              <label class="block text-xs font-medium text-gray-600 mb-1">Age Group</label>
              <select
                name="age_group"
                class="w-full rounded-lg border-gray-300 text-sm focus:border-[#6667ab] focus:ring-[#6667ab]"
              >
                <option value="">All Ages</option>
                <option value="<5" selected={@filters.age_group == "<5"}>Under 5 years</option>
                <option value="5-17" selected={@filters.age_group == "5-17"}>
                  5 - 17 years
                </option>
                <option value="18-59" selected={@filters.age_group == "18-59"}>
                  18 - 59 years
                </option>
                <option value="60+" selected={@filters.age_group == "60+"}>
                  60 years and above
                </option>
              </select>
            </div>
          </:group>

          <:chip
            :for={chip <- filter_chips(@filters, @doctors)}
            label={chip.label}
            clear={JS.push("clear_chip", value: %{"field" => chip.field})}
          />
        </.filter_drawer>
      </div>
      
    <!-- Table -->
      <.blank_state
        :if={@visit_count == 0}
        icon_path="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
        title="No patient visits"
        description={
          if (@filters.search || "") != "" or count_active_filters(@filters) > 0,
            do: "No patient visits match the current filters.",
            else: "No patient visits have been recorded yet."
        }
      >
        <:actions :if={(@filters.search || "") != "" or count_active_filters(@filters) > 0}>
          <button phx-click="clear_filters" class="text-xs text-[#6667ab] hover:underline">
            Clear filters
          </button>
        </:actions>
      </.blank_state>
      <.table :if={@visit_count > 0} id="patient_visits" rows={@patient_visits}
        row_id={&"patient_visits-#{&1.id}"}
      >
        <:col :let={pv} label="Patient">
          <div class="flex items-center py-2">
            <div class="h-8 w-8 rounded-full bg-[#e7e7ff] flex items-center justify-center text-[#373896] font-medium mr-2 text-sm shrink-0">
              {String.first(pv.patient.first_name || "?")}
            </div>
            <div>
              <p class="font-medium text-gray-900 text-sm">
                {[pv.patient.first_name, pv.patient.middle_name]
                |> Enum.filter(&(&1 != nil))
                |> Enum.join(" ")}
              </p>
              <%= if pv.patient.gender do %>
                <p class="text-xs text-gray-500 capitalize">{pv.patient.gender}</p>
              <% end %>
            </div>
          </div>
        </:col>

        <:col :let={pv} label="Date & Time">
          <div class="py-2">
            <p class="text-sm text-gray-900 font-medium">{pv.date}</p>
            <p class="text-xs text-gray-500">{pv.time}</p>
          </div>
        </:col>

        <:col :let={pv} label="Visit Type">
          <div class="py-2">
            <span class={[
              "px-2 py-1 text-xs font-medium rounded-full",
              cond do
                pv.visit_type in ["inpatient", "Full"] -> "bg-purple-100 text-purple-800"
                pv.visit_type == "Triage Only" -> "bg-yellow-100 text-yellow-800"
                pv.visit_type == "ANC" -> "bg-emerald-100 text-emerald-800"
                pv.visit_type in ["Lab Test", "Pharmacy"] -> "bg-blue-100 text-blue-800"
                pv.visit_type in ["referral in", "referral out"] -> "bg-orange-100 text-orange-800"
                true -> "bg-gray-100 text-gray-700"
              end
            ]}>
              {pv.visit_type || "—"}
            </span>
          </div>
        </:col>

        <:col :let={pv} label="Status">
          <div class="py-2">
            <span class="inline-block px-1.5 py-0.5 text-xs rounded-full font-medium bg-[#e7e7ff] text-[#373896]">
              {PatientVisit.status_label(pv.status)}
            </span>
          </div>
        </:col>

        <:col :let={pv} label="Doctor">
          <div class="py-2">
            <%= if pv.doctor && pv.doctor.name do %>
              <span class="px-2 py-1 text-xs rounded-full bg-[#e7e7ff] text-[#373896]">
                Dr. {pv.doctor.name}
              </span>
            <% else %>
              <span class="px-2 py-1 text-xs rounded-full bg-gray-100 text-gray-500">
                Not Assigned
              </span>
            <% end %>
          </div>
        </:col>

        <:col :let={pv} label="Receptionist">
          <div class="py-2">
            <span class="text-sm text-gray-700">{pv.creator.name}</span>
          </div>
        </:col>
      </.table>
      <.pagination
        page={@page}
        total_pages={@total_pages}
        total_count={@visit_count}
        per_page={@per_page}
      />
    </div>
    """
  end

  defp load_visits(socket) do
    filters = socket.assigns.filters
    per_page = socket.assigns.per_page
    page = socket.assigns.page

    visit_count = PatientVisits.count_patient_visits(filters)
    total_pages = Medcamp.Pagination.total_pages(visit_count, per_page)
    page = min(max(1, page), total_pages)
    visits = PatientVisits.filter_patient_visits_paginated(filters, page, per_page)

    socket
    |> assign(:page, page)
    |> assign(:visit_count, visit_count)
    |> assign(:total_pages, total_pages)
    |> assign(:patient_visits, visits)
  end

  # The table is expandable, so it renders eagerly rather than under
  # `phx-update="stream"` and must be fed a plain list. Replace the row in place
  # when it is already listed, otherwise prepend it.
  defp upsert(rows, row) do
    if Enum.any?(rows, &(&1.id == row.id)) do
      Enum.map(rows, &if(&1.id == row.id, do: row, else: &1))
    else
      [row | rows]
    end
  end
end
