defmodule MedcampWeb.NursesPages.PatientIndex do
  use MedcampWeb, :nurse_live_view

  alias Medcamp.Patients
  alias Medcamp.Patients.Patient

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :patients)
     |> assign(:filters, default_filters())
     |> assign(:page, 1)
     |> assign(:per_page, 10)
     |> assign(:show_figures, false)
     |> assign_patients(Patients.list_patients())}
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
      visit_type: nil,
      search: ""
    }
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Patient")
    |> assign(:patient, Patients.get_patient!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Patient")
    |> assign(:patient, %Patient{})
  end

  defp apply_action(socket, :index, params) do
    socket
    |> assign(:page_title, "Patients")
    |> assign(:patient, nil)
    |> assign(:page, 1)
    |> assign_filters_from_params(params)
    |> load_patients()
  end

  defp assign_filters_from_params(socket, params) do
    filters = %{
      date_from: params["date_from"] || "",
      date_to: params["date_to"] || "",
      time_from: params["time_from"] || "",
      time_to: params["time_to"] || "",
      age_group: parse_empty(params["age_group"]),
      gender: parse_empty(params["gender"]),
      diagnosis: params["diagnosis"] || "",
      visit_type: parse_empty(params["visit_type"]),
      search: params["search"] || ""
    }

    assign(socket, :filters, filters)
  end

  defp parse_empty(""), do: nil
  defp parse_empty(nil), do: nil
  defp parse_empty(v), do: v

  defp load_patients(socket) do
    filters = socket.assigns.filters
    filter_params = build_filter_params(filters)

    patients =
      if has_visit_filters?(filter_params) do
        Patients.list_patients_by_visit_filters(Map.put(filter_params, :search, filters.search))
      else
        if filters.search != "" do
          Patients.search_patients(filters.search)
        else
          Patients.list_patients()
        end
      end

    assign_patients(socket, patients)
  end

  # The patients table is expandable, so it renders its rows eagerly rather than
  # under `phx-update="stream"` and must be fed a plain list assign. Track the
  # count as a normal assign too, so the empty state can't go stale.
  defp assign_patients(socket, patients) do
    total_count = length(patients)
    total_pages = Medcamp.Pagination.total_pages(total_count, socket.assigns.per_page)
    page = min(max(1, socket.assigns.page || 1), max(1, total_pages))

    page_entries =
      Enum.slice(patients, (page - 1) * socket.assigns.per_page, socket.assigns.per_page)

    figures = Medcamp.PatientVisits.patient_visit_figures(Enum.map(patients, & &1.id))

    socket
    |> assign(:patients_count, total_count)
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:figures, figures)
    |> assign(:patients, page_entries)
  end

  defp has_visit_filters?(params) do
    params[:date_from] || params[:date_to] || params[:time_from] || params[:time_to] ||
      params[:age_group] || params[:gender] || (params[:diagnosis] && params[:diagnosis] != "") ||
      params[:visit_type]
  end

  defp build_filter_params(filters) do
    %{
      date_from: parse_date(filters.date_from),
      date_to: parse_date(filters.date_to),
      time_from: parse_time(filters.time_from),
      time_to: parse_time(filters.time_to),
      age_group: filters.age_group,
      gender: filters.gender,
      diagnosis: (filters.diagnosis != "" && filters.diagnosis) || nil,
      visit_type: filters.visit_type
    }
  end

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

  defp filters_path(filters) do
    params =
      []
      |> maybe_add("date_from", filters.date_from)
      |> maybe_add("date_to", filters.date_to)
      |> maybe_add("time_from", filters.time_from)
      |> maybe_add("time_to", filters.time_to)
      |> maybe_add("age_group", filters.age_group)
      |> maybe_add("gender", filters.gender)
      |> maybe_add("diagnosis", filters.diagnosis)
      |> maybe_add("visit_type", filters.visit_type)
      |> maybe_add("search", filters.search)

    path = ~p"/nurse/patients"
    if params == [], do: path, else: path <> "?" <> URI.encode_query(params)
  end

  defp maybe_add(list, _key, ""), do: list
  defp maybe_add(list, _key, nil), do: list
  defp maybe_add(list, key, val), do: list ++ [{key, to_string(val)}]

  # The search box and the filter drawer submit independently (two separate
  # <form>s), so a submission from either one only carries its own fields.
  # Merging onto the stringified current filters means a key absent from
  # this submission is left unchanged rather than reset.
  defp stringify_filters(filters) do
    Map.new(filters, fn {key, value} -> {Atom.to_string(key), value || ""} end)
  end

  defp count_active_filters(filters) do
    filters
    |> Map.drop([:search])
    |> Map.values()
    |> Enum.count(&(&1 not in [nil, ""]))
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
      filter_chip(filters.date_from, "date_from", "From #{filters.date_from}"),
      filter_chip(filters.date_to, "date_to", "To #{filters.date_to}"),
      filter_chip(filters.time_from, "time_from", "From #{filters.time_from}"),
      filter_chip(filters.time_to, "time_to", "To #{filters.time_to}"),
      filter_chip(filters.age_group, "age_group", filters.age_group),
      filter_chip(filters.gender, "gender", filters.gender),
      filter_chip(filters.diagnosis, "diagnosis", filters.diagnosis),
      filter_chip(filters.visit_type, "visit_type", visit_type_label(filters.visit_type))
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

  defp figures_cards(figures) do
    [
      %{
        label: "New Patients",
        value: figures.new,
        helper: "Patients with exactly one visit",
        icon: "user-plus",
        color: "blue"
      },
      %{
        label: "Recurring Patients",
        value: figures.recurring,
        helper: "Patients with more than one visit",
        icon: "arrow-path",
        color: "violet"
      },
      %{
        label: "Total",
        value: figures.total,
        helper: "New + recurring patients",
        icon: "users",
        color: "indigo"
      }
    ]
  end

  @impl true
  def handle_event("filter", %{"filters" => form_filters}, socket) do
    form_filters = Map.merge(stringify_filters(socket.assigns.filters), form_filters)

    filters = %{
      date_from: form_filters["date_from"] || "",
      date_to: form_filters["date_to"] || "",
      time_from: form_filters["time_from"] || "",
      time_to: form_filters["time_to"] || "",
      age_group: parse_empty(form_filters["age_group"]),
      gender: parse_empty(form_filters["gender"]),
      diagnosis: form_filters["diagnosis"] || "",
      visit_type: parse_empty(form_filters["visit_type"]),
      search: form_filters["search"] || ""
    }

    path = filters_path(filters)
    {:noreply, push_patch(socket, to: path)}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/nurse/patients")}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, max(1, String.to_integer(page)))
     |> load_patients()}
  end

  @impl true
  def handle_event("clear_chip", %{"field" => field}, socket) do
    handle_event("filter", %{"filters" => %{field => ""}}, socket)
  end

  @impl true
  def handle_event("toggle_figures", _params, socket) do
    {:noreply, assign(socket, :show_figures, !socket.assigns.show_figures)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-[100%]">
      <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-4 mb-4">
        <.page_header
          icon_path="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
          title="Patients"
          subtitle="Search, filter and manage registered patients."
        />

        <div class="flex flex-wrap items-center gap-3">
          <form phx-change="filter" class="flex-1">
            <.search_input
              name="filters[search]"
              value={@filters.search}
              placeholder="Search by name, email, or phone number"
            />
          </form>

          <.filter_drawer
            id="patients-filters"
            title="Filter patients"
            apply_event="filter"
            active_count={count_active_filters(@filters)}
          >
            <:group label="Date and Time">
              <.date_range_fields
                from_name="filters[date_from]"
                to_name="filters[date_to]"
                from_value={@filters.date_from}
                to_value={@filters.date_to}
              />
              <.time_range_fields
                from_name="filters[time_from]"
                to_name="filters[time_to]"
                from_value={@filters.time_from}
                to_value={@filters.time_to}
              />
            </:group>

            <:group label="Patient Details">
              <.age_gender_fields
                age_group_value={@filters.age_group || ""}
                gender_value={@filters.gender || ""}
              />
            </:group>

            <:group label="Visit Details">
              <.diagnosis_visit_type_fields
                diagnosis_value={@filters.diagnosis}
                visit_type_value={@filters.visit_type || ""}
              />
            </:group>

            <:chip
              :for={chip <- filter_chips(@filters)}
              label={chip.label}
              clear={JS.push("clear_chip", value: %{"field" => chip.field})}
            />
          </.filter_drawer>
        </div>

        <label class="mt-3 inline-flex items-center gap-2 text-sm text-gray-700 cursor-pointer">
          <input
            type="checkbox"
            phx-click="toggle_figures"
            checked={@show_figures}
            class="h-4 w-4 rounded border-slate-300 text-[#373896] focus:ring-[#373896]"
          /> Show figures in table
        </label>
      </div>

      <div :if={@show_figures} class="mb-4">
        <.summary_card_grid cards={figures_cards(@figures)} />
      </div>

      <.patients_table_for_receptionists
        show_header={false}
        route_prefix="/nurse"
        new_patient_url="/nurse/patients/new"
        patients={@patients}
        count={@patients_count}
        show_view_link={false}
        show_new_link={false}
        filters_active={@filters.search != "" or count_active_filters(@filters) > 0}
      />

      <.pagination
        page={@page}
        total_pages={@total_pages}
        total_count={@total_count}
        per_page={@per_page}
      />

      <.modal
        :if={@live_action in [:new, :edit]}
        id="nurse-modal"
        show
        on_cancel={JS.patch(~p"/nurse/patients")}
      >
        <.live_component
          module={MedcampWeb.AddPatientComponent}
          id={:new}
          title={@page_title}
          current_user={@current_user}
          action={@live_action}
          patient={@patient}
          step="personal"
          patch={~p"/nurse/patients"}
          show_path={fn patient -> ~p"/nurse/#{patient.id}/patient_overview" end}
        />
      </.modal>
    </div>
    """
  end
end
