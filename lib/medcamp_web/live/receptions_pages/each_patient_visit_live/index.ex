defmodule MedcampWeb.ReceptionsPagePatientLive.EachPatientVisitIndex do
  use MedcampWeb, :reception_each_patient_live_view

  alias Medcamp.PatientVisits
  alias Medcamp.PatientVisits.PatientVisit
  alias Medcamp.Patients

  @per_page 10

  @impl true
  def mount(%{"patient_id" => patient_id}, _session, socket) do
    patient =
      Patients.get_patient!(patient_id)

    {:ok,
     socket
     |> assign(:patient, patient)
     |> assign(:active_tab, :visits)
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> load_patient_visits()}
  end

  defp load_patient_visits(socket) do
    patient_id = socket.assigns.patient.id
    total_count = PatientVisits.count_patient_visits_by_patient_id(patient_id)
    total_pages = Medcamp.Pagination.total_pages(total_count, socket.assigns.per_page)
    page = min(max(1, socket.assigns.page || 1), total_pages)

    patient_visits =
      PatientVisits.list_patient_visits_by_patient_id_paginated(
        patient_id,
        page,
        socket.assigns.per_page
      )

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
    |> assign(:page_title, "Listing Patient visits")
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

  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, max(1, String.to_integer(page)))
     |> load_patient_visits()}
  end

  def handle_event("request_feedback", %{"id" => _id}, socket) do
    patient = socket.assigns.patient

    Medcamp.Postal.deliver_feedback_request_email(
      patient.first_name,
      patient.email,
      Date.utc_today() |> Date.to_string()
    )

    Medcamp.Advanta.send_message(
      "Hello #{patient.first_name}, thank you for visiting GHC today. We would appreciate your feedback on our services. Please fill out the form here https://glocalhealthcentre.com/feedback , thank you.",
      patient.phone_number
    )

    {:noreply,
     socket
     |> put_flash(:info, "Feedback request sent successfully")
     |> push_navigate(to: ~p"/reception/#{patient.id}/visits")}
  end

  @impl true

  def render(assigns) do
    ~H"""
    <div>
      <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-4">
        <.header class="text-[#373896] border-b border-gray-100 pb-4 mb-4">
          <div class="flex items-center">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-5 w-5 mr-2 text-[#6667ab]"
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
            Listing Patient visits for {[
              @patient.first_name,
              @patient.middle_name,
              @patient.last_name
            ]
            |> Enum.filter(&(&1 != nil))
            |> Enum.join(" ")}
          </div>
          <:actions>
            <.link patch={~p"/reception/#{@patient.id}/visits/new"}>
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
        </.header>

        <.table id="patient_visits" rows={@patient_visits}
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
                      ~p"/reception/#{@patient.id}/visits/#{patient_visit.id}/trigger_payment_triage"

                    patient_visit.visit_type in [
                      "Subsidized",
                      "Subsidized Doctor Consultation for Students"
                    ] ->
                      ~p"/reception/#{@patient.id}/visits/#{patient_visit.id}/trigger_payment_subsidized"

                    true ->
                      ~p"/reception/#{@patient.id}/visits/#{patient_visit.id}/trigger_payment"
                  end
                }>
                  <.button class="bg-[#6667ab] hover:bg-[#5556a0] py-1 px-2 text-xs">
                    Prompt Patient
                  </.button>
                </.link>
              <% end %>
            </div>
          </:col>

          <:col :let={patient_visit} label="Payment Status">
            <div class="flex items-center py-3">
              <.button
                phx-click="request_feedback"
                phx-value-id={patient_visit.id}
                data-confirm="Are you sure you want to request feedback?"
                class="bg-[#6667ab] hover:bg-[#5556a0] py-1 px-2 text-xs"
              >
                Request Feedback
              </.button>
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
        on_cancel={JS.patch(~p"/reception/#{@patient.id}/visits")}
      >
        <.live_component
          module={MedcampWeb.PatientVisitLive.FormComponent}
          id={@patient_visit.id || :new}
          title={@page_title}
          action={@live_action}
          current_user={@current_user}
          selected_patient={@patient}
          patient_visit={@patient_visit}
          patch={~p"/reception/#{@patient.id}/visits"}
        />
      </.modal>

      <.modal
        :if={@live_action in [:trigger_payment]}
        id="patient_visit-modal"
        show
        on_cancel={JS.patch(~p"/reception/#{@patient.id}/visits")}
      >
        <.live_component
          module={MedcampWeb.TriggerPayment}
          id={@patient_visit.id || :new}
          title={@page_title}
          action={@live_action}
          patient={@patient}
          action_to_perform="create_patient_visit"
          return_url={"/reception/#{@patient.id}/visits"}
          actionable_type={@patient_visit}
          current_user={@current_user}
          patient_id={@patient_visit.patient_id}
          patch={~p"/reception/#{@patient.id}/visits"}
        />
      </.modal>

      <.modal
        :if={@live_action in [:trigger_payment_subsidized]}
        id="patient_visit-modal"
        show
        on_cancel={JS.patch(~p"/reception/#{@patient.id}/visits")}
      >
        <.live_component
          module={MedcampWeb.TriggerPayment}
          id={@patient_visit.id || :new}
          title={@page_title}
          action={@live_action}
          patient={@patient}
          action_to_perform="create_patient_visit_subsidized"
          return_url={"/reception/#{@patient.id}/visits"}
          actionable_type={@patient_visit}
          current_user={@current_user}
          patient_id={@patient_visit.patient_id}
          patch={~p"/reception/#{@patient.id}/visits"}
        />
      </.modal>

      <.modal
        :if={@live_action in [:trigger_payment_triage]}
        id="patient_visit-modal"
        show
        on_cancel={JS.patch(~p"/reception/#{@patient.id}/visits")}
      >
        <.live_component
          module={MedcampWeb.TriggerPayment}
          id={@patient_visit.id || :new}
          title={@page_title}
          action={@live_action}
          patient={@patient}
          action_to_perform="create_patient_visit_for_triage"
          return_url={"/reception/#{@patient.id}/visits"}
          actionable_type={@patient_visit}
          current_user={@current_user}
          patient_id={@patient_visit.patient_id}
          patch={~p"/reception/#{@patient.id}/visits"}
        />
      </.modal>
    </div>
    """
  end
end
