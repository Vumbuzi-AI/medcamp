defmodule MedcampWeb.ReceptionistPatientLive.New do
  use MedcampWeb, :live_view

  alias Medcamp.Patients
  alias Medcamp.Patients.Patient

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Patients",
       patient: nil,
       patients: Patients.list_patients()
     )}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action)}
  end

  defp apply_action(socket, :new) do
    assign(socket, page_title: "Add Patient", patient: %Patient{})
  end

  defp apply_action(socket, :index) do
    assign(socket,
      page_title: "Patients",
      patient: nil,
      patients: Patients.list_patients()
    )
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-slate-50 px-4 py-8 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-7xl">
        <div class="mb-6 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <p class="text-sm font-semibold uppercase tracking-wider text-brand-primary">
              Reception
            </p>
            <h1 class="mt-1 text-2xl font-bold text-slate-900">All patients</h1>
            <p class="mt-1 text-sm text-slate-600">
              Adding a patient automatically places them in the triage queue.
            </p>
          </div>

          <div class="flex items-center gap-2">
            <.link patch={~p"/receptionist/patients/new"}>
              <.button class="inline-flex items-center gap-2">
                <.icon name="hero-user-plus" class="h-4 w-4" /> Add Patient
              </.button>
            </.link>
            <.link
              href={~p"/users/log_out"}
              method="delete"
              class="rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-100"
            >
              Log out
            </.link>
          </div>
        </div>

        <div class="rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
          <.blank_state
            :if={@patients == []}
            icon_path="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
            title="No patients"
            description="No patients have been registered yet."
          />
          <.table :if={@patients != []} id="receptionist-patients" rows={@patients}>
            <:col :let={patient} label="Name">{patient_name(patient)}</:col>
            <:col :let={patient} label="GSRN">{patient.gsrn}</:col>
            <:col :let={patient} label="Phone Number">{patient.phone_number}</:col>
            <:col :let={patient} label="National ID">{patient.national_id || "—"}</:col>
            <:col :let={patient} label="Gender">{patient.gender}</:col>
          </.table>
        </div>

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
            patch={~p"/receptionist/patients"}
          />
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
