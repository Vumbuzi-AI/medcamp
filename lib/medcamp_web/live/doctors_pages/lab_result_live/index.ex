defmodule MedcampWeb.DoctorsPagePatientLive.LabResultIndex do
  use MedcampWeb, :each_patient_live_view

  alias Medcamp.LabResults
  alias Medcamp.LabResults.LabResult
  alias Medcamp.Patients

  @per_page 10

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :lab_results)
     |> assign(:patient_id, id)
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> load_lab_results()}
  end

  defp load_lab_results(socket) do
    patient_id = socket.assigns.patient_id
    total_count = LabResults.count_lab_results_for_patient(patient_id)
    total_pages = Medcamp.Pagination.total_pages(total_count, socket.assigns.per_page)
    page = min(max(1, socket.assigns.page || 1), total_pages)

    lab_results =
      LabResults.list_lab_results_for_patient_paginated(patient_id, page, socket.assigns.per_page)

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:lab_results, lab_results)
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    patient = Patients.get_patient!(id)

    {:noreply,
     socket
     |> assign(:patient, patient)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Lab result")
    |> assign(:lab_result, LabResults.get_lab_result!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Lab result")
    |> assign(:lab_result, %LabResult{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Lab results")
    |> assign(:lab_result, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    lab_result = LabResults.get_lab_result!(id)
    {:ok, _} = LabResults.delete_lab_result(lab_result)

    {:noreply, load_lab_results(socket)}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, max(1, String.to_integer(page)))
     |> load_lab_results()}
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
              d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"
            />
          </svg>
          Listing Lab results for {[@patient.first_name, @patient.middle_name, @patient.last_name]
          |> Enum.filter(&(&1 != nil))
          |> Enum.join(" ")}
        </div>
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
              d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"
            />
          </svg>
          <h3 class="mt-2 text-sm font-medium text-gray-900">No lab results</h3>
          <p class="mt-1 text-sm text-gray-500">
            No lab results have been recorded for this patient yet.
          </p>
        </div>
      <% else %>
        <.table
          id="lab_results"
          rows={@lab_results}
          row_click={
            fn lab_result ->
              JS.navigate(~p"/doctor/patients/#{@patient.id}/lab_results/#{lab_result}")
            end
          }
          row_id={&"lab_results-#{&1.id}"}
        >
          <:col :let={lab_result} label="Patient">
            <div class="flex items-center py-3">
              <span class="px-2 py-1 text-xs rounded-full bg-[#e7e7ff] text-[#373896] font-medium">
                {[
                  lab_result.patient.first_name,
                  lab_result.patient.middle_name,
                  lab_result.patient.last_name
                ]
                |> Enum.filter(&(&1 != nil))
                |> Enum.join(" ")}
              </span>
            </div>
          </:col>

          <:col :let={lab_result} label="Doctor">
            <div class="flex items-center py-3">
              <span class="text-gray-700">
                Dr. {lab_result.doctor.name}
              </span>
            </div>
          </:col>

          <:col :let={lab_result} label="Urgency">
            <div class="py-3">
              <%= case lab_result.urgency do %>
                <% "Urgent" -> %>
                  <span class="px-2 py-1 text-xs rounded-full bg-red-100 text-red-800 font-medium">
                    Urgent
                  </span>
                <% "High" -> %>
                  <span class="px-2 py-1 text-xs rounded-full bg-orange-100 text-orange-800 font-medium">
                    High
                  </span>
                <% "Medium" -> %>
                  <span class="px-2 py-1 text-xs rounded-full bg-yellow-100 text-yellow-800 font-medium">
                    Medium
                  </span>
                <% "Low" -> %>
                  <span class="px-2 py-1 text-xs rounded-full bg-green-100 text-green-800 font-medium">
                    Low
                  </span>
                <% _ -> %>
                  <span class="px-2 py-1 text-xs rounded-full bg-blue-100 text-blue-800 font-medium">
                    {lab_result.urgency}
                  </span>
              <% end %>
            </div>
          </:col>

          <:col :let={lab_result} label="Requested">
            <p class="py-3 text-sm text-gray-700">
              {format_datetime_kenya(lab_result.inserted_at)}
            </p>
          </:col>

          <:col :let={lab_result} label="Status">
            <div class="py-3 flex items-start justify-start">
              <%= if lab_result.report_complete do %>
                <div class="flex items-start text-green-700">
                  <Heroicons.icon name="check-circle" type="solid" class="h-6 w-6 text-green-500" />
                  <span class="ml-1 text-sm">Complete</span>
                </div>
              <% else %>
                <div class="flex items-start text-red-700">
                  <Heroicons.icon name="x-circle" type="solid" class="h-6 w-6 text-red-500" />
                  <span class="ml-1 text-sm">Pending</span>
                </div>
              <% end %>
            </div>
          </:col>

          <:col :let={lab_result} label="Action">
            <.link
              navigate={~p"/doctor/patients/#{@patient.id}/lab_results/#{lab_result}"}
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
                  d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                />
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"
                />
              </svg>
              View
            </.link>
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
    """
  end
end
