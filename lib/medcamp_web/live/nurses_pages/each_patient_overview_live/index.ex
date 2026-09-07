defmodule MedcampWeb.NursesPages.EachPatientOverviewIndex do
  use MedcampWeb, :nurse_each_patient_live_view

  alias Medcamp.PatientFormRecords.PatientFormRecord
  alias Medcamp.Patients
  alias Medcamp.Triages
  alias Phoenix.LiveView.JS

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :patient_overview)
     |> assign(:show_edit_patient_modal, false)}
  end

  @impl true
  def handle_params(%{"patient_id" => id}, _url, socket) do
    patient = Patients.get_patient!(id)

    most_recent_triage = Triages.most_recent_triage(id)
    forms = Medcamp.PatientFormRecords.list_patient_form_records(id)

    {:noreply,
     socket
     |> assign(:page_title, "Patient Overview")
     |> assign(:patient, patient)
     |> assign(:most_recent_triage, most_recent_triage)
     |> assign(:forms, forms)
     |> assign(:form, to_form(Patients.change_patient(patient)))}
  end

  @impl true
  def handle_event("validate", %{"patient" => patient_params}, socket) do
    changeset =
      Patients.change_patient(socket.assigns.patient, patient_params)

    {:noreply, assign(socket, :form, to_form(changeset, action: :validate))}
  end

  @impl true
  def handle_event("edit_patient", _params, socket) do
    {:noreply, assign(socket, :show_edit_patient_modal, true)}
  end

  @impl true
  def handle_event("close_edit_patient_modal", _params, socket) do
    {:noreply, assign(socket, :show_edit_patient_modal, false)}
  end

  @impl true
  def handle_info({:patient_updated, patient}, socket) do
    patient = Patients.get_patient!(patient.id)

    {:noreply,
     socket
     |> assign(:patient, patient)
     |> assign(:form, to_form(Patients.change_patient(patient)))
     |> assign(:show_edit_patient_modal, false)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.patient_overview
        patient={@patient}
        form={@form}
        most_recent_triage={@most_recent_triage}
        back_url="/nurse/patients"
      />

      <div class="mt-6 rounded-lg border border-gray-100 bg-white p-5 shadow-sm">
        <div class="mb-4 flex items-center justify-between gap-3">
          <div>
            <h3 class="text-lg font-semibold text-[#373896]">
              Medical Forms
            </h3>

            <p class="text-sm text-gray-500">
              Forms recorded for this patient.
            </p>
          </div>

          <.link
            navigate={"/nurse/#{@patient.id}/forms"}
            class="inline-flex items-center gap-2 rounded-lg bg-[#373896] px-3 py-2 text-sm font-medium text-white hover:bg-[#2f327d]"
          >
            <Heroicons.icon name="clipboard-document-list" type="outline" class="h-4 w-4" />
            Open Forms
          </.link>
        </div>

        <%= if @forms == [] do %>
          <p class="text-sm text-gray-500">
            No forms recorded for this patient.
          </p>
        <% else %>
          <ul class="divide-y divide-gray-200">
            <%= for form <- @forms do %>
              <li class="py-3">
                <div class="flex items-start justify-between gap-4">
                  <div>
                    <p class="font-medium text-gray-900">
                      {PatientFormRecord.form_label(form.form_type)}
                    </p>

                    <p class="text-sm text-gray-500">
                      {Calendar.strftime(form.inserted_at, "%Y-%m-%d %H:%M")}
                    </p>

                    <%= if PatientFormRecord.form_notes(form) do %>
                      <div class="mt-1 text-sm text-gray-700">
                        {PatientFormRecord.form_notes(form)}
                      </div>
                    <% end %>
                  </div>
                </div>
              </li>
            <% end %>
          </ul>
        <% end %>
      </div>

      <.modal
        :if={@show_edit_patient_modal}
        id="edit-patient-modal"
        show
        on_cancel={JS.push("close_edit_patient_modal")}
      >
        <.live_component
          module={MedcampWeb.EditPatientComponent}
          id={"edit-patient-#{@patient.id}"}
          patient={@patient}
          current_user={@current_user}
        />
      </.modal>
    </div>
    """
  end
end
