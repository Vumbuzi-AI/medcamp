defmodule MedcampWeb.ReceptionistPatientLive.New do
  use MedcampWeb, :live_view

  alias Medcamp.Camps
  alias Medcamp.Patients
  alias Medcamp.Patients.Patient

  @per_page 15

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       page_title: "Patients",
       patient: nil,
       search: "",
       page: 1,
       per_page: @per_page,
       camp: safe_active_camp(),
       show_patient_code: false,
       code_patient: nil,
       registered_patient: nil
     )
     |> load_patients()}
  end

  defp safe_active_camp do
    Camps.get_active_camp()
  rescue
    _ -> nil
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action)}
  end

  defp apply_action(socket, :new) do
    assign(socket, page_title: "Add Patient", patient: %Patient{})
  end

  defp apply_action(socket, :index) do
    socket
    |> assign(page_title: "Patients", patient: nil)
    |> load_patients()
  end

  @impl true
  def handle_event("search", %{"search" => term}, socket) do
    {:noreply, socket |> assign(search: term, page: 1) |> load_patients()}
  end

  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket |> assign(:page, Medcamp.Pagination.normalize_page(page)) |> load_patients()}
  end

  def handle_event("clear_filters", _params, socket) do
    {:noreply, socket |> assign(search: "", page: 1) |> load_patients()}
  end

  def handle_event("show_patient_code", %{"patient_id" => id}, socket) do
    {:noreply,
     socket
     |> assign(:code_patient, Patients.get_patient!(id))
     |> assign(:show_patient_code, true)}
  end

  def handle_event("close_patient_code", _params, socket) do
    {:noreply, assign(socket, show_patient_code: false, code_patient: nil)}
  end

  def handle_event("dismiss_registered", _params, socket) do
    {:noreply,
     socket
     |> assign(:registered_patient, nil)
     |> push_patch(to: ~p"/receptionist/patients")}
  end

  @impl true
  def handle_info({:patient_registered, patient}, socket) do
    {:noreply,
     socket
     |> assign(:registered_patient, patient)
     |> assign(:patient, nil)
     |> load_patients()
     |> push_patch(to: ~p"/receptionist/patients")}
  end

  # Default view: just this camp's patients (a fresh camp starts empty). Once
  # the receptionist types in the search box we look across the whole
  # organisation, so a returning patient from an earlier camp is still findable.
  defp load_patients(socket) do
    filters = %{search: socket.assigns.search}
    per_page = socket.assigns.per_page
    searching? = socket.assigns.search != ""
    camp = socket.assigns.camp

    {count, list_fun} =
      if camp && not searching? do
        {Patients.count_camp_patients(camp.id, filters),
         fn page -> Patients.list_camp_patients_paginated(camp.id, filters, page, per_page) end}
      else
        {Patients.count_patients(filters),
         fn page -> Patients.list_patients_paginated(filters, page, per_page) end}
      end

    total_pages = Medcamp.Pagination.total_pages(count, per_page)
    page = min(max(1, socket.assigns.page), total_pages)

    socket
    |> assign(:page, page)
    |> assign(:scope, if(camp && not searching?, do: :camp, else: :organisation))
    |> assign(:patient_count, count)
    |> assign(:total_pages, total_pages)
    |> assign(:patients, list_fun.(page))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-slate-50 px-4 py-8 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-7xl">
        <.list_page
          icon_path="M15 19.128a9.38 9.38 0 0 0 2.625.372 9.337 9.337 0 0 0 4.121-.952 4.125 4.125 0 0 0-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 0 1 8.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0 1 11.964-3.07M12 6.375a3.375 3.375 0 1 1-6.75 0 3.375 3.375 0 0 1 6.75 0Zm8.25 2.25a2.625 2.625 0 1 1-5.25 0 2.625 2.625 0 0 1 5.25 0Z"
          title="Patients"
          subtitle={
            if @search != "",
              do: "Searching every patient in the organisation.",
              else: "New patients go straight to the triage queue."
          }
        >
          <:actions>
            <span
              :if={@camp}
              class="inline-flex items-center gap-1.5 rounded-full bg-[#e9f6fb] px-3 py-1.5 text-sm font-semibold text-[#0C2765]"
            >
              <.icon name="hero-map-pin" class="h-4 w-4" />
              <span class="max-w-[12rem] truncate">{@camp.name}</span>
            </span>
            <span
              :if={is_nil(@camp)}
              class="inline-flex items-center gap-1.5 rounded-full bg-amber-50 px-3 py-1.5 text-sm font-semibold text-amber-700"
            >
              <.icon name="hero-exclamation-triangle" class="h-4 w-4" /> No active camp
            </span>
            <.link patch={~p"/receptionist/patients/new"}>
              <button class="inline-flex items-center gap-2 rounded-lg bg-brand-primary px-4 py-2 text-sm font-medium text-white hover:bg-[#2d2d7a]">
                <.icon name="hero-user-plus" class="h-4 w-4" /> Add Patient
              </button>
            </.link>
            <.link
              href={~p"/users/log_out"}
              method="delete"
              class="rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm font-semibold text-slate-700 transition-colors hover:bg-slate-100"
            >
              Log out
            </.link>
          </:actions>

          <:toolbar>
            <form phx-change="search" class="flex-1">
              <.search_input
                name="search"
                value={@search}
                placeholder="Search any patient by name, phone, National ID or GSRN"
              />
              <p :if={@scope == :camp} class="mt-1.5 text-xs text-slate-400">
                Showing this camp only. Search to find a returning patient from anywhere in the organisation.
              </p>
            </form>
          </:toolbar>

          <.blank_state
            :if={@patients == []}
            icon_path="M15 19.128a9.38 9.38 0 0 0 2.625.372 9.337 9.337 0 0 0 4.121-.952 4.125 4.125 0 0 0-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 0 1 8.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0 1 11.964-3.07M12 6.375a3.375 3.375 0 1 1-6.75 0 3.375 3.375 0 0 1 6.75 0Zm8.25 2.25a2.625 2.625 0 1 1-5.25 0 2.625 2.625 0 0 1 5.25 0Z"
            title={
              cond do
                @search != "" -> "No patients match your search"
                @camp -> "No patients registered yet"
                true -> "No active camp"
              end
            }
            description={
              cond do
                @search != "" -> "Try a different name, phone number or ID."
                @camp -> "Register the first patient — they'll go straight to triage."
                true -> "Ask an admin to activate a camp, then register patients here."
              end
            }
          >
            <:actions :if={@search != ""}>
              <button phx-click="clear_filters" class="text-xs text-brand-accent hover:underline">
                Clear search
              </button>
            </:actions>
          </.blank_state>

          <.data_table
            :if={@patients != []}
            id="receptionist-patients"
            rows={@patients}
            row_id={&"patient-#{&1.id}"}
          >
            <:col :let={patient} label="Name">
              <span class="font-medium text-slate-900">{patient_name(patient)}</span>
              <span class="mt-0.5 block font-mono text-xs text-slate-400 md:hidden">
                {patient.gsrn}
              </span>
            </:col>
            <:col :let={patient} label="GSRN" hide_below="md">
              <span class="font-mono text-xs">{patient.gsrn}</span>
            </:col>
            <:col :let={patient} label="Phone number">{patient.phone_number}</:col>
            <:col :let={patient} label="National ID" hide_below="lg">
              {patient.national_id || "—"}
            </:col>
            <:col :let={patient} label="Gender" hide_below="sm">{patient.gender}</:col>
            <:action :let={patient}>
              <button
                type="button"
                phx-click="show_patient_code"
                phx-value-patient_id={patient.id}
                class="inline-flex items-center gap-1.5 rounded-lg border border-slate-300 bg-white px-3 py-1.5 text-sm font-semibold text-slate-700 transition-colors hover:bg-slate-100"
              >
                <.icon name="hero-qr-code" class="h-4 w-4" /> Print code
              </button>
            </:action>
            <:footer>
              <.pagination
                page={@page}
                total_pages={@total_pages}
                total_count={@patient_count}
                per_page={@per_page}
              />
            </:footer>
          </.data_table>
        </.list_page>

        <.modal
          :if={@live_action == :new}
          id="receptionist-patient-modal"
          show
          on_cancel={JS.patch(~p"/receptionist/patients")}
        >
          <.live_component
            module={MedcampWeb.AddPatientComponent}
            id={:receptionist_patient_registration}
            title="Add Patient"
            current_user={@current_user}
            action={:new}
            patient={@patient}
            step="personal"
            notify_parent_on_save={true}
            patch={~p"/receptionist/patients"}
          />
        </.modal>

        <.modal
          :if={@registered_patient}
          id="receptionist-registered-modal"
          show
          on_cancel={JS.push("dismiss_registered")}
        >
          <div class="text-center">
            <div class="mx-auto flex h-11 w-11 items-center justify-center rounded-full bg-emerald-100">
              <.icon name="hero-check" class="h-6 w-6 text-emerald-600" />
            </div>
            <h3 class="mt-3 text-base font-semibold text-[#0C2765]">
              {patient_name(@registered_patient)} is registered
            </h3>
            <p class="mt-1 text-sm text-slate-500">
              They're in the triage queue. Print the wristband to issue it now.
            </p>
          </div>

          <div class="mt-5">
            <.patient_code_card id="receptionist-registered-code" patient={@registered_patient} />
          </div>

          <div class="mt-5 flex justify-center">
            <button
              type="button"
              phx-click="dismiss_registered"
              class="rounded-full border border-slate-300 bg-white px-5 py-2 text-sm font-semibold text-slate-700 transition-colors hover:bg-slate-100"
            >
              Done
            </button>
          </div>
        </.modal>

        <.modal
          :if={@show_patient_code && @code_patient}
          id="receptionist-patient-code-modal"
          show
          on_cancel={JS.push("close_patient_code")}
        >
          <h3 class="text-base font-semibold text-[#0C2765]">Patient wristband</h3>
          <p class="mt-1 text-sm text-slate-500">
            Reprint the code for {patient_name(@code_patient)}.
          </p>
          <div class="mt-5">
            <.patient_code_card id="receptionist-reprint-code" patient={@code_patient} />
          </div>
        </.modal>
      </div>
    </div>
    """
  end

  defp patient_name(patient) do
    [patient.first_name, patient.middle_name, patient.last_name]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" ")
  end
end
