defmodule MedcampWeb.NursesPages.EachPatientNurseProcedureIndex do
  use MedcampWeb, :nurse_each_patient_live_view

  alias Medcamp.NurseProcedures
  alias Medcamp.Patients
  alias Medcamp.NurseProcedures.NurseProcedure

  @per_page 10

  @impl true
  def mount(%{"patient_id" => id}, _session, socket) do
    patient = Patients.get_patient!(id)

    {:ok,
     socket
     |> assign(:active_tab, :nurse_procedures)
     |> assign(:patient, patient)
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> load_nurse_procedures()}
  end

  defp load_nurse_procedures(socket) do
    patient_id = socket.assigns.patient.id
    total_count = NurseProcedures.count_nurse_procedures_for_patient(patient_id)
    total_pages = Medcamp.Pagination.total_pages(total_count, socket.assigns.per_page)
    page = min(max(1, socket.assigns.page || 1), total_pages)

    nurse_procedures =
      NurseProcedures.list_nurse_procedures_for_patient_paginated(
        patient_id,
        page,
        socket.assigns.per_page
      )

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:nurse_procedures, nurse_procedures)
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Nurse procedure")
    |> assign(:nurse_procedure, NurseProcedures.get_nurse_procedure!(id))
  end

  defp apply_action(socket, :trigger_payment, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Nurse procedure")
    |> assign(:nurse_procedure, NurseProcedures.get_nurse_procedure!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Nurse procedure")
    |> assign(:nurse_procedure, %NurseProcedure{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Nurse procedures")
    |> assign(:nurse_procedure, nil)
  end

  @impl true
  def handle_info(
        {MedcampWeb.NurseProcedureLive.FormComponent, {:saved, _nurse_procedure}},
        socket
      ) do
    {:noreply, load_nurse_procedures(socket)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    nurse_procedure = NurseProcedures.get_nurse_procedure!(id)
    {:ok, _} = NurseProcedures.delete_nurse_procedure(nurse_procedure)

    {:noreply, load_nurse_procedures(socket)}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, max(1, String.to_integer(page)))
     |> load_nurse_procedures()}
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
          Listing Nurse procedures for {[
            @patient.first_name,
            @patient.middle_name,
            @patient.last_name
          ]
          |> Enum.filter(&(&1 != nil))
          |> Enum.join(" ")}
        </div>
        <:actions>
          <.link patch={~p"/nurse/#{@patient.id}/nurse_procedures/new"}>
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
                New Nurse procedure
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
          <h3 class="mt-2 text-sm font-medium text-gray-900">No nurse procedures</h3>
          <p class="mt-1 text-sm text-gray-500">
            No nurse procedures have been recorded for this patient yet.
          </p>
        </div>
      <% else %>
        <.table id="nurse_procedures" rows={@nurse_procedures}
          row_id={&"nurse_procedures-#{&1.id}"}
        >
          <:col :let={nurse_procedure} label="Patient">
            <div class="flex items-center py-3">
              <div class="h-8 w-8 rounded-full bg-[#e7e7ff] flex items-center justify-center text-[#373896] font-medium mr-2 text-sm">
                {String.first(nurse_procedure.patient.first_name || "")}
              </div>
              <span class="font-medium text-gray-900">
                {[
                  nurse_procedure.patient.first_name,
                  nurse_procedure.patient.middle_name
                ]
                |> Enum.filter(&(&1 != nil))
                |> Enum.join(" ")}
              </span>
            </div>
          </:col>

          <:col :let={nurse_procedure} label="Procedure">
            <div class="flex items-center py-3">
              <span class="px-2 py-1 text-xs rounded-full bg-[#f0f0ff] text-[#373896]">
                {nurse_procedure.procedure.name}
              </span>
            </div>
          </:col>

          <:col :let={nurse_procedure} label="Payment type">
            <div class="flex items-center py-3">
              <span class="px-2 py-1 text-xs rounded-full bg-blue-100 text-blue-800">
                {nurse_procedure.payment_type}
              </span>
            </div>
          </:col>

          <:col :let={nurse_procedure} label="Payment Status">
            <div class="flex items-center py-3">
              <%= if nurse_procedure.has_paid do %>
                <span class="px-2 py-1 text-xs rounded-full bg-green-100 text-green-800 font-medium">
                  Paid
                </span>
              <% else %>
                <.link
                  :if={nurse_procedure.payment_type == "Mpesa"}
                  patch={
                    ~p"/nurse/#{@patient.id}/nurse_procedures/#{nurse_procedure.id}/trigger_payment"
                  }
                >
                  <.button class="bg-[#6667ab] hover:bg-[#5556a0] py-1 px-2 text-xs">
                    Prompt Patient
                  </.button>
                </.link>
              <% end %>
            </div>
          </:col>

          <:col :let={nurse_procedure} label="Amount paid">
            <div class="flex items-center py-3">
              <span class="font-medium text-gray-900">
                KES {nurse_procedure.total_amount_paid} /=
              </span>
            </div>
          </:col>
          <:col :let={nurse_procedure}>
            <div class="flex items-center justify-center">
              <.link
                :if={nurse_procedure.has_paid == false && nurse_procedure.payment_type == "Mpesa"}
                phx-click={JS.push("delete", value: %{id: nurse_procedure.id}) |> hide("#nurse_procedures-#{nurse_procedure.id}")}
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
      id="nurse_procedure-modal"
      show
      on_cancel={JS.patch(~p"/nurse/#{@patient.id}/nurse_procedures")}
    >
      <.live_component
        module={MedcampWeb.NurseProcedureLive.FormComponent}
        id={@nurse_procedure.id || :new}
        title={@page_title}
        action={@live_action}
        selected_patient={@patient}
        current_user={@current_user}
        nurse_procedure={@nurse_procedure}
        patch={~p"/nurse/#{@patient.id}/nurse_procedures"}
      />
    </.modal>

    <.modal
      :if={@live_action in [:trigger_payment]}
      id="patient_visit-modal"
      show
      on_cancel={JS.patch(~p"/nurse/#{@patient.id}/nurse_procedures")}
    >
      <.live_component
        module={MedcampWeb.TriggerPayment}
        id={@nurse_procedure.id || :new}
        title={@page_title}
        action={@live_action}
        action_to_perform="create_nurse_procedure"
        return_url={"/nurse/#{@patient.id}/nurse_procedures"}
        actionable_type={@nurse_procedure}
        patient={@nurse_procedure.patient}
        current_user={@current_user}
        patient_id={@nurse_procedure.patient_id}
        patch={"/nurse/#{@patient.id}/nurse_procedures"}
      />
    </.modal>
    """
  end
end
