defmodule MedcampWeb.DoctorsPagePatientLive.EachPatientDoctorProcedureIndex do
  use MedcampWeb, :each_patient_live_view

  alias Medcamp.DoctorProcedures
  alias Medcamp.Patients
  alias Medcamp.DoctorProcedures.DoctorProcedure

  @per_page 10

  @impl true
  def mount(%{"patient_id" => id}, _session, socket) do
    patient = Patients.get_patient!(id)

    {:ok,
     socket
     |> assign(:active_tab, :doctor_procedures)
     |> assign(:patient, patient)
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> load_doctor_procedures()}
  end

  defp load_doctor_procedures(socket) do
    patient_id = socket.assigns.patient.id
    total_count = DoctorProcedures.count_doctor_procedures_for_patient(patient_id)
    total_pages = Medcamp.Pagination.total_pages(total_count, socket.assigns.per_page)
    page = min(max(1, socket.assigns.page || 1), total_pages)

    doctor_procedures =
      DoctorProcedures.list_doctor_procedures_for_patient_paginated(
        patient_id,
        page,
        socket.assigns.per_page
      )

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:doctor_procedures, doctor_procedures)
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Doctor procedure")
    |> assign(:doctor_procedure, %DoctorProcedure{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Doctor procedure")
    |> assign(:doctor_procedure, DoctorProcedures.get_doctor_procedure!(id))
  end

  defp apply_action(socket, :trigger_payment, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit doctor procedure")
    |> assign(:doctor_procedure, DoctorProcedures.get_doctor_procedure!(id))
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Doctor procedures")
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    doctor_procedure = DoctorProcedures.get_doctor_procedure!(id)
    {:ok, _} = DoctorProcedures.delete_doctor_procedure(doctor_procedure)

    {:noreply, load_doctor_procedures(socket)}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, max(1, String.to_integer(page)))
     |> load_doctor_procedures()}
  end

  @impl true
  def render(assigns) do
    ~H"""
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
              d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"
            />
          </svg>
          Listing Doctor procedures for {[
            @patient.first_name,
            @patient.middle_name,
            @patient.last_name
          ]
          |> Enum.filter(&(&1 != nil))
          |> Enum.join(" ")}
        </div>

        <:actions>
          <.link patch={~p"/doctor/#{@patient.id}/doctor_procedures/new"}>
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
                New Doctor procedure
              </div>
            </.button>
          </.link>
        </:actions>
      </.header>

      <%= if @total_count == 0 do %>
        <div class="text-center py-8 bg-gray-50 rounded-lg border border-dashed border-gray-300">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="mx-auto h-12 w-12 text-gray-400"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"
            />
          </svg>
          <h3 class="mt-2 text-sm font-medium text-gray-900">No doctor procedures</h3>
          <p class="mt-1 text-sm text-gray-500">
            No doctor procedures have been recorded for this patient yet.
          </p>

          <.link patch={"/doctor/#{@patient.id}/doctor_procedures/new"}>
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
                New Doctor  procedure
              </div>
            </.button>
          </.link>
        </div>
      <% else %>
        <.table id="doctor_procedures" rows={@doctor_procedures}
          row_id={&"doctor_procedures-#{&1.id}"}
        >
          <:col :let={doctor_procedure} label="Patient">
            <div class="flex items-center py-3">
              <span class="px-2 py-1 text-xs rounded-full bg-[#e7e7ff] text-[#373896] font-medium">
                {[
                  doctor_procedure.patient.first_name,
                  doctor_procedure.patient.middle_name
                ]
                |> Enum.filter(&(&1 != nil))
                |> Enum.join(" ")}
              </span>
            </div>
          </:col>

          <:col :let={doctor_procedure} label="Procedure">
            <div class="py-3">
              <span class="text-gray-700">
                <%= if doctor_procedure.procedure do %>
                  {doctor_procedure.procedure.name}
                <% else %>
                  {doctor_procedure.subsidized_procedure.name}
                <% end %>
              </span>
            </div>
          </:col>

          <:col :let={doctor_procedure} label="Procedure Price">
            <div class="py-3">
              <span class="text-gray-700">
                <%= if doctor_procedure.procedure do %>
                  {doctor_procedure.procedure.price} KES /=
                <% else %>
                  {doctor_procedure.subsidized_procedure.price} KES /=
                <% end %>
              </span>
            </div>
          </:col>

          <:col :let={doctor_procedure} label="Payment type">
            <div class="py-3">
              <span class="px-2 py-1 text-xs rounded-full bg-[#f0f0ff] text-[#373896] font-medium">
                {doctor_procedure.payment_type}
              </span>
            </div>
          </:col>

          <:col :let={doctor_procedure} label="Payment Status">
            <div class="flex items-center py-3">
              <%= if doctor_procedure.has_paid do %>
                <span class="px-2 py-1 text-xs rounded-full bg-green-100 text-green-800 font-medium">
                  Paid
                </span>
              <% else %>
                <.link
                  :if={doctor_procedure.payment_type == "Mpesa"}
                  patch={
                    ~p"/doctor/#{@patient.id}/doctor_procedures/#{doctor_procedure.id}/trigger_payment"
                  }
                >
                  <.button class="bg-[#6667ab] hover:bg-[#5556a0] py-1 px-2 text-xs">
                    Prompt Patient
                  </.button>
                </.link>
              <% end %>
            </div>
          </:col>

          <:col :let={doctor_procedure} label="Amount paid">
            <div class="py-3">
              <span class="font-medium text-gray-900">
                KES {doctor_procedure.total_amount_paid} /=
              </span>
            </div>
          </:col>
        </.table>
        <.pagination
          page={@page}
          total_pages={@total_pages}
          total_count={@total_count}
          per_page={@per_page}
        />
      <% end %>
    </div>

    <.modal
      :if={@live_action in [:new, :edit]}
      id="doctor_procedure-modal"
      show
      on_cancel={JS.patch(~p"/doctor/#{@patient.id}/doctor_procedures")}
    >
      <.live_component
        module={MedcampWeb.DoctorProcedureLive.FormComponent}
        id={@doctor_procedure.id || :new}
        title={@page_title}
        action={@live_action}
        selected_patient={@patient}
        current_user={@current_user}
        doctor_procedure={@doctor_procedure}
        patch={~p"/doctor/#{@patient.id}/doctor_procedures"}
      />
    </.modal>

    <.modal
      :if={@live_action in [:trigger_payment]}
      id="patient_visit-modal"
      show
      on_cancel={JS.patch(~p"/doctor/doctor_procedures")}
    >
      <.live_component
        module={MedcampWeb.TriggerPayment}
        id={@doctor_procedure.id || :new}
        title={@page_title}
        action={@live_action}
        action_to_perform="create_doctor_procedure"
        return_url={"/doctor/#{@patient.id}/doctor_procedures"}
        actionable_type={@doctor_procedure}
        patient={@doctor_procedure.patient}
        current_user={@current_user}
        patient_id={@doctor_procedure.patient_id}
        patch={"/doctor/#{@patient.id}/doctor_procedures"}
      />
    </.modal>
    """
  end
end
