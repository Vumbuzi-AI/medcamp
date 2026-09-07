defmodule MedcampWeb.ReceptionsPagePatientLive.Index do
  use MedcampWeb, :reception_live_view
  alias Medcamp.Patients
  alias Medcamp.Patients.Patient

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :patients)
     |> assign(:filters, %{})
     |> assign_patients(Patients.list_patients())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("search", %{"search" => search}, socket) do
    patients = Patients.search_patients(search)
    {:noreply, assign_patients(socket, patients)}
  end

  @impl true
  def handle_event("filter", %{"filters" => filters}, socket) do
    # Parse date filters
    date_from = parse_date(filters["date_from"])
    date_to = parse_date(filters["date_to"])
    age_group = if filters["age_group"] != "", do: filters["age_group"], else: nil
    gender = if filters["gender"] != "", do: filters["gender"], else: nil

    filter_params = %{
      date_from: date_from,
      date_to: date_to,
      age_group: age_group,
      gender: gender
    }

    # Store original string values for form display
    display_filters = %{
      date_from: filters["date_from"] || "",
      date_to: filters["date_to"] || "",
      age_group: age_group,
      gender: gender
    }

    patients = Patients.filter_patients(filter_params)

    {:noreply, socket |> assign(:filters, display_filters) |> assign_patients(patients)}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    patients = Patients.list_patients()

    {:noreply,
     socket
     |> assign(:filters, %{date_from: "", date_to: "", age_group: nil, gender: nil})
     |> assign_patients(patients)}
  end

  @impl true
  def handle_event("clear_chip", %{"field" => field}, socket) do
    current = %{
      "date_from" => socket.assigns.filters[:date_from] || "",
      "date_to" => socket.assigns.filters[:date_to] || "",
      "age_group" => socket.assigns.filters[:age_group] || "",
      "gender" => socket.assigns.filters[:gender] || ""
    }

    filters = Map.put(current, field, "")
    handle_event("filter", %{"filters" => filters}, socket)
  end

  @impl true
  def handle_event("send_pin", %{"patient_id" => patient_id}, socket) do
    case Patients.get_patient(patient_id) do
      nil ->
        {:noreply, put_flash(socket, :error, "Patient not found")}

      patient ->
        Medcamp.Postal.deliver_pin_to_patient(patient.email, patient.pin)

        Medcamp.Advanta.send_message(
          "Hello #{patient.first_name}, thank you for visiting GHCE. Your PIN is #{patient.pin}. Please use this PIN for your next visit.",
          patient.phone_number
        )

        {:noreply, put_flash(socket, :info, "PIN sent successfully")}
    end
  end

  # The patients table is expandable, so it renders its rows eagerly rather than
  # under `phx-update="stream"` and must be fed a plain list assign. Track the
  # count as a normal assign too, so the empty state can't go stale.
  defp assign_patients(socket, patients) do
    socket
    |> assign(:patients_count, length(patients))
    |> assign(:patients, patients)
  end

  defp parse_date(""), do: nil
  defp parse_date(nil), do: nil

  defp parse_date(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> date
      _ -> nil
    end
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Patient")
    |> assign(:patient, Patients.get_patient!(id))
  end

  defp apply_action(socket, :patient_code, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Patient")
    |> assign(:patient, Patients.get_patient!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Patient")
    |> assign(:patient, %Patient{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Patients")
    |> assign(:patient, nil)
  end

  defp count_active_filters(filters) do
    filters
    |> Map.take([:date_from, :date_to, :age_group, :gender])
    |> Map.values()
    |> Enum.count(&(&1 not in [nil, ""]))
  end

  defp filter_chips(filters) do
    [
      filter_chip(filters[:date_from], "date_from", "From #{filters[:date_from]}"),
      filter_chip(filters[:date_to], "date_to", "To #{filters[:date_to]}"),
      filter_chip(filters[:age_group], "age_group", filters[:age_group]),
      filter_chip(filters[:gender], "gender", filters[:gender])
    ]
    |> Enum.reject(&is_nil/1)
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
        >
          <:actions>
            <.link patch={~p"/reception/patients/new"}>
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
                  Add New Patient
                </div>
              </.button>
            </.link>
          </:actions>
        </.page_header>

        <div class="flex flex-wrap items-center gap-3">
          <form phx-change="search" class="flex-1">
            <.search_input name="search" placeholder="Search by name, email, or phone number" />
          </form>

          <.filter_drawer
            id="patients-filters"
            title="Filter patients"
            apply_event="filter"
            active_count={count_active_filters(@filters)}
          >
            <:group label="Date Range">
              <.date_range_fields
                from_name="filters[date_from]"
                to_name="filters[date_to]"
                from_value={@filters[:date_from] || ""}
                to_value={@filters[:date_to] || ""}
              />
            </:group>

            <:group label="Patient Details">
              <.age_gender_fields
                age_group_value={@filters[:age_group] || ""}
                gender_value={@filters[:gender] || ""}
              />
            </:group>

            <:chip
              :for={chip <- filter_chips(@filters)}
              label={chip.label}
              clear={JS.push("clear_chip", value: %{"field" => chip.field})}
            />
          </.filter_drawer>
        </div>
      </div>

      <.patients_table_for_receptionists
        show_header={false}
        route_prefix="/reception"
        new_patient_url="/reception/patients/new"
        patients={@patients}
        count={@patients_count}
        show_view_link={false}
        show_new_link={true}
        filters_active={count_active_filters(@filters) > 0}
      />

      <.modal
        :if={@live_action in [:new, :edit]}
        id="patient-modal"
        show
        on_cancel={JS.patch(~p"/reception/patients")}
      >
        <.live_component
          module={MedcampWeb.AddPatientComponent}
          id={:new}
          title={@page_title}
          current_user={@current_user}
          action={@live_action}
          patient={@patient}
          step="personal"
          patch={~p"/reception/patients"}
          show_path={fn patient -> ~p"/reception/#{patient.id}/patient_overview" end}
        />
      </.modal>

      <.modal
        :if={@live_action in [:patient_code]}
        id="patient-modal"
        show
        on_cancel={JS.patch(~p"/reception/patients")}
      >
        <.live_component
          module={MedcampWeb.ReceptionsPagePatientLive.ImageComponent}
          id={:new}
          title={@page_title}
          current_user={@current_user}
          action={@live_action}
          patient={@patient}
          patch={~p"/reception/patients"}
        />
      </.modal>
    </div>
    """
  end
end
