defmodule MedcampWeb.NursesPages.EachPatientAdmissionRequestIndex do
  use MedcampWeb, :nurse_each_patient_live_view

  alias Medcamp.Patients
  alias Medcamp.AdmissionRequests
  alias Medcamp.AdmissionRequests.LineItem

  @per_page 10

  @impl true
  def mount(%{"patient_id" => id}, _session, socket) do
    patient = Patients.get_patient!(id)

    {:ok,
     socket
     |> assign(:patient, patient)
     |> assign(:active_tab, :admission_requests)
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> load_admission_requests()}
  end

  defp load_admission_requests(socket) do
    patient_id = socket.assigns.patient.id
    total_count = AdmissionRequests.count_admission_requests_by_patient_id(patient_id)
    total_pages = Medcamp.Pagination.total_pages(total_count, socket.assigns.per_page)
    page = min(max(1, socket.assigns.page || 1), total_pages)

    admission_requests =
      AdmissionRequests.list_admission_requests_by_patient_id_paginated(
        patient_id,
        page,
        socket.assigns.per_page
      )

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:admission_requests, admission_requests)
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Admission Requests")
    |> assign(:nurse_note, nil)
    |> assign(:admission_request, nil)
    |> assign(:line_item_for_trigger, nil)
  end

  defp apply_action(socket, :trigger_payment, %{"id" => id}) do
    admission_request = AdmissionRequests.get_admission_request_with_line_items!(id)

    socket
    |> assign(:page_title, "Prompt payment – Admission")
    |> assign(:admission_request, admission_request)
    |> assign(:line_item_for_trigger, nil)
  end

  defp apply_action(socket, :trigger_payment, _params), do: apply_action(socket, :index, nil)

  defp apply_action(socket, :trigger_payment_line_item, %{
         "id" => _admission_id,
         "line_item_id" => line_item_id
       }) do
    line_item = AdmissionRequests.get_line_item_with_admission!(line_item_id)

    socket
    |> assign(
      :page_title,
      "Prompt payment – #{AdmissionRequests.LineItem.item_type_label(line_item.item_type)}"
    )
    |> assign(:line_item_for_trigger, line_item)
    |> assign(:admission_request, nil)
  end

  defp apply_action(socket, :trigger_payment_line_item, _params),
    do: apply_action(socket, :index, nil)

  defp apply_action(socket, :line_items, %{"id" => id}) do
    admission_request = AdmissionRequests.get_admission_request!(id)
    admission_request = Medcamp.Repo.preload(admission_request, :line_items)

    socket
    |> assign(:page_title, "Line items / costs")
    |> assign(:admission_request, admission_request)
    |> assign(:line_item_for_trigger, nil)
  end

  defp apply_action(socket, :line_items, _params), do: apply_action(socket, :index, nil)

  @impl true
  def handle_event("mark_discharged", %{"id" => id}, socket) do
    admission_request = AdmissionRequests.get_admission_request!(id)

    case AdmissionRequests.update_admission_request(admission_request, %{
           "discharged" => true,
           "discharge_date" => Date.utc_today()
         }) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Admission marked as discharged")
         |> load_admission_requests()}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to mark as discharged")}
    end
  end

  def handle_event("assign_room", %{"id" => id}, socket) do
    admission_request = AdmissionRequests.get_admission_request!(id)

    case AdmissionRequests.update_admission_request(admission_request, %{
           "has_been_assigned_room" => true,
           "nurse_id" => socket.assigns.current_user.id
         }) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Room assigned successfully")
         |> push_navigate(to: ~p"/nurse/#{socket.assigns.patient.id}/admission_requests")}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to assign room")}
    end
  end

  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, max(1, String.to_integer(page)))
     |> load_admission_requests()}
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
          Listing Admission requests for {[
            @patient.first_name,
            @patient.middle_name,
            @patient.last_name
          ]
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
              d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"
            />
          </svg>
          <h3 class="mt-2 text-sm font-medium text-gray-900">No admission requests</h3>
          <p class="mt-1 text-sm text-gray-500">
            No admission requests have been recorded for this patient yet.
          </p>
        </div>
      <% else %>
        <.table id="admission_requests" rows={@admission_requests}
          row_id={&"admission_requests-#{&1.id}"}
        >
          <:col :let={admission_request} label="Date">
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
              <span class="text-gray-700">
                {if admission_request.date,
                  do: Calendar.strftime(admission_request.date, "%d %b %Y"),
                  else: "—"}
              </span>
            </div>
          </:col>

          <:col :let={admission_request} label="Start time">
            <div class="flex items-center py-3">
              <span class="text-gray-700">
                {if admission_request.start_time,
                  do: Calendar.strftime(admission_request.start_time, "%H:%M"),
                  else: "—"}
              </span>
            </div>
          </:col>

          <:col :let={admission_request} label="End time">
            <div class="flex items-center py-3">
              <span class="text-gray-700">
                {if admission_request.end_time,
                  do: Calendar.strftime(admission_request.end_time, "%H:%M"),
                  else: "—"}
              </span>
            </div>
          </:col>

          <:col :let={admission_request} label="Payment type">
            <div class="flex items-center py-3">
              <span class="px-2 py-1 text-xs rounded-full bg-blue-100 text-blue-800">
                {admission_request.payment_type || "—"}
              </span>
            </div>
          </:col>

          <:col :let={admission_request} label="Line items">
            <div class="py-3 max-w-xs">
              <%= if Enum.empty?(admission_request.line_items || []) do %>
                <span class="text-gray-500">—</span>
              <% else %>
                <ul class="space-y-1 text-sm">
                  <%= for li <- (admission_request.line_items || []) do %>
                    <% paid = (li.amount_paid || 0) >= (li.price || 0) %>
                    <li class="flex justify-between items-center gap-2">
                      <span class="text-gray-700">{LineItem.item_type_label(li.item_type)}</span>
                      <span class="font-medium text-gray-900 shrink-0">KSh {li.price}</span>
                      <%= if paid do %>
                        <span class="px-1.5 py-0.5 bg-green-100 text-green-800 text-xs rounded shrink-0">
                          Paid
                        </span>
                      <% else %>
                        <span class="px-1.5 py-0.5 bg-amber-100 text-amber-800 text-xs rounded shrink-0">
                          Unpaid
                        </span>
                      <% end %>
                    </li>
                  <% end %>
                </ul>
                <p class="text-xs font-semibold text-teal-700 mt-1.5 pt-1.5 border-t border-gray-200">
                  Total: KSh {Enum.reduce(admission_request.line_items || [], 0, fn li, acc ->
                    acc + li.price
                  end)}
                </p>
              <% end %>
            </div>
          </:col>

          <:col :let={admission_request} label="Total amount paid">
            <div class="flex items-center py-3">
              <span class="font-medium text-gray-900">
                {if admission_request.total_amount_paid,
                  do: "KSh #{admission_request.total_amount_paid}",
                  else: "—"}
              </span>
            </div>
          </:col>

          <:col :let={admission_request} label="Payment status">
            <div class="flex justify-center items-center py-3">
              <%= if !admission_request.has_paid do %>
                <div class="flex items-center text-red-700">
                  <Heroicons.icon name="x-circle" type="solid" class="h-6 w-6 text-red-500" />
                  <span class="ml-1 text-sm">Not paid</span>
                </div>
              <% else %>
                <%= if admission_request.fully_paid do %>
                  <div class="flex items-center text-green-700">
                    <Heroicons.icon name="check-circle" type="solid" class="h-6 w-6 text-green-500" />
                    <span class="ml-1 text-sm">Fully paid</span>
                  </div>
                <% else %>
                  <div class="flex items-center text-amber-700">
                    <Heroicons.icon
                      name="exclamation-circle"
                      type="solid"
                      class="h-6 w-6 text-amber-500"
                    />
                    <span class="ml-1 text-sm">Partially paid</span>
                  </div>
                <% end %>
              <% end %>
            </div>
          </:col>

          <:col :let={admission_request} label="Discharge date">
            <div class="flex items-center py-3">
              <span class="text-gray-700">
                {if admission_request.discharge_date,
                  do: Calendar.strftime(admission_request.discharge_date, "%d %b %Y"),
                  else: "—"}
              </span>
            </div>
          </:col>

          <:col :let={admission_request} label="Discharged?">
            <div class="flex justify-center items-center py-3">
              <%= if admission_request.discharged do %>
                <div class="flex items-center text-slate-700">
                  <Heroicons.icon name="check-circle" type="solid" class="h-6 w-6 text-slate-500" />
                  <span class="ml-1 text-sm">Yes</span>
                </div>
              <% else %>
                <button
                  phx-click="mark_discharged"
                  data-confirm="Mark this admission as discharged?"
                  phx-value-id={admission_request.id}
                  class="inline-flex items-center px-2 py-1 text-xs font-medium rounded-md bg-slate-100 text-slate-700 hover:bg-slate-200"
                >
                  Mark discharged
                </button>
              <% end %>
            </div>
          </:col>

          <:col :let={admission_request} label="Room Assigned?">
            <div class="flex justify-center items-center py-3">
              <%= if admission_request.has_been_assigned_room do %>
                <div class="flex items-center text-green-700">
                  <Heroicons.icon name="check-circle" type="solid" class="h-6 w-6 text-green-500" />
                  <span class="ml-1 text-sm">Assigned</span>
                </div>
              <% else %>
                <.button
                  phx-click="assign_room"
                  data-confirm="Are you sure you have assigned a patient to this room?"
                  phx-value-id={admission_request.id}
                  class="bg-[#6667ab] hover:bg-[#5556a0] py-1 px-2 text-xs"
                >
                  <div class="flex items-center">
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
                        d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"
                      />
                    </svg>
                    Assign Room
                  </div>
                </.button>
              <% end %>
            </div>
          </:col>

          <:col :let={admission_request} label="Assigned By">
            <div class="flex items-center py-3">
              <%= if admission_request.nurse && admission_request.nurse.name do %>
                <span class="px-2 py-1 text-xs rounded-full bg-[#f0f0ff] text-[#373896]">
                  {admission_request.nurse.name}
                </span>
              <% else %>
                <span class="px-2 py-1 text-xs rounded-full bg-gray-100 text-gray-500">
                  Not Assigned
                </span>
              <% end %>
            </div>
          </:col>

          <:col :let={admission_request} label="Actions">
            <div class="flex items-center gap-2 py-3">
              <.link
                patch={
                  ~p"/nurse/#{@patient.id}/admission_requests/#{admission_request.id}/line_items"
                }
                class="text-sm text-[#373896] hover:text-[#2a2a70] font-medium"
              >
                Line items
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

      <.modal
        :if={@live_action == :line_items && @admission_request}
        id="admission-line-items-modal"
        show
        on_cancel={JS.patch(~p"/nurse/#{@patient.id}/admission_requests")}
      >
        <div class="px-4 py-2">
          <h3 class="text-lg font-semibold text-gray-900 mb-4">{@page_title}</h3>
          <.live_component
            module={MedcampWeb.NursesPages.AdmissionRequestLineItemsLive}
            id={"line-items-#{@admission_request.id}"}
            admission_request={@admission_request}
            line_item_trigger_prefix={
              ~p"/nurse/#{@patient.id}/admission_requests/#{@admission_request.id}/line_items"
            }
          />
          <div class="mt-4 flex justify-end">
            <.link
              patch={~p"/nurse/#{@patient.id}/admission_requests"}
              class="text-sm text-[#373896] hover:underline"
            >
              Done
            </.link>
          </div>
        </div>
      </.modal>

      <.modal
        :if={@live_action == :trigger_payment_line_item && @line_item_for_trigger}
        id="line-item-trigger-payment-modal"
        show
        on_cancel={
          JS.patch(
            ~p"/nurse/#{@patient.id}/admission_requests/#{@line_item_for_trigger.admission_request_id}/line_items"
          )
        }
      >
        <.live_component
          module={MedcampWeb.TriggerPayment}
          id={"line-item-trigger-#{@line_item_for_trigger.id}"}
          title={@page_title}
          action={@live_action}
          action_to_perform="admission_line_item"
          return_url={
            ~p"/nurse/#{@patient.id}/admission_requests/#{@line_item_for_trigger.admission_request_id}/line_items"
          }
          actionable_type={@line_item_for_trigger}
          patient={@line_item_for_trigger.admission_request.patient}
          current_user={@current_user}
          patient_id={@line_item_for_trigger.admission_request.patient_id}
          patch={
            ~p"/nurse/#{@patient.id}/admission_requests/#{@line_item_for_trigger.admission_request_id}/line_items"
          }
        />
      </.modal>
    </div>
    """
  end
end
