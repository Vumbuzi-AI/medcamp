defmodule MedcampWeb.ShiftHandoverLive.Show do
  use MedcampWeb, :shared_live_view

  alias MedcampWeb.RoleRouteHelpers
  alias Medcamp.ShiftHandovers

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :shift_handovers)}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:shift_handover, ShiftHandovers.get_shift_handover!(id))}
  end

  @impl true
  def handle_event("acknowledge", %{"id" => id}, socket) do
    shift_handover = ShiftHandovers.get_shift_handover!(id)

    case ShiftHandovers.update_shift_handover(shift_handover, %{
           status: "acknowledged",
           acknowledged_at: DateTime.utc_now()
         }) do
      {:ok, updated_handover} ->
        {:noreply,
         socket
         |> assign(:shift_handover, updated_handover)
         |> put_flash(:info, "Shift handover acknowledged successfully")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to acknowledge handover")}
    end
  end

  def handle_event("complete", %{"id" => id}, socket) do
    shift_handover = ShiftHandovers.get_shift_handover!(id)

    case ShiftHandovers.update_shift_handover(shift_handover, %{status: "completed"}) do
      {:ok, updated_handover} ->
        {:noreply,
         socket
         |> assign(:shift_handover, updated_handover)
         |> put_flash(:info, "Shift handover marked as completed")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to complete handover")}
    end
  end

  defp page_title(:show), do: "Shift Handover Details"
  defp page_title(:edit), do: "Edit Shift Handover"

  defp status_badge(status) do
    case status do
      "pending" -> {"Pending", "bg-yellow-100 text-yellow-800 border-yellow-200"}
      "acknowledged" -> {"Acknowledged", "bg-green-100 text-green-800 border-green-200"}
      "completed" -> {"Completed", "bg-blue-100 text-blue-800 border-blue-200"}
      _ -> {status, "bg-gray-100 text-gray-800 border-gray-200"}
    end
  end

  defp shift_type_badge(type) do
    case type do
      "morning" -> {"Morning Shift", "bg-amber-100 text-amber-800", "☀️"}
      "afternoon" -> {"Afternoon Shift", "bg-orange-100 text-orange-800", "🌤️"}
      "night" -> {"Night Shift", "bg-indigo-100 text-indigo-800", "🌙"}
      "day" -> {"Day Shift", "bg-sky-100 text-sky-800", "☀️"}
      _ -> {type, "bg-gray-100 text-gray-800", "⏰"}
    end
  end

  defp shift_handovers_path(current_user, suffix \\ "") do
    RoleRouteHelpers.role_path(current_user, "/shift_handovers" <> suffix)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <!-- Back Navigation -->
      <.back
        navigate={shift_handovers_path(@current_user)}
        class="text-[#6667ab] hover:text-[#373896]"
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="h-4 w-4 inline mr-1"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
        </svg>
        Back to Shift Handovers
      </.back>
      
    <!-- Header Card -->
      <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-6">
        <.header class="text-[#373896] border-b border-gray-100 pb-4 mb-6">
          <div class="flex items-center justify-between w-full">
            <div class="flex items-center gap-4">
              <div class="bg-[#6667ab] rounded-full p-3">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-6 w-6 text-white"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4"
                  />
                </svg>
              </div>
              <div>
                <h1 class="text-2xl font-bold">Shift Handover</h1>
                <p class="text-sm text-gray-600">
                  {Calendar.strftime(@shift_handover.shift_date, "%A, %B %d, %Y")}
                </p>
              </div>
            </div>
            <%= case status_badge(@shift_handover.status) do %>
              <% {label, classes} -> %>
                <span class={"px-4 py-2 text-sm font-semibold rounded-full border #{classes}"}>
                  {label}
                </span>
            <% end %>
          </div>
          <:actions>
            <%= if @shift_handover.status == "pending" do %>
              <.button
                phx-click="acknowledge"
                phx-value-id={@shift_handover.id}
                class="bg-green-600 hover:bg-green-700"
              >
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
                    d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
                  />
                </svg>
                Acknowledge Handover
              </.button>
            <% end %>
            <%= if @shift_handover.status == "acknowledged" do %>
              <.button
                phx-click="complete"
                phx-value-id={@shift_handover.id}
                class="bg-blue-600 hover:bg-blue-700"
              >
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
                    d="M5 13l4 4L19 7"
                  />
                </svg>
                Mark Complete
              </.button>
            <% end %>
            <.link
              patch={shift_handovers_path(@current_user, "/#{@shift_handover.id}/show/edit")}
              phx-click={JS.push_focus()}
            >
              <.button class="bg-[#6667ab] hover:bg-[#5556a0]">
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
                    d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
                  />
                </svg>
                Edit Handover
              </.button>
            </.link>
          </:actions>
        </.header>
        
    <!-- Shift & Department Info -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
          <div class="bg-gray-50 rounded-lg p-4">
            <h3 class="text-sm font-semibold text-gray-600 mb-3">Shift Information</h3>
            <div class="space-y-2">
              <div class="flex items-center">
                <%= case shift_type_badge(@shift_handover.shift_type) do %>
                  <% {label, classes, emoji} -> %>
                    <span class={"px-3 py-1 text-sm font-medium rounded-full #{classes}"}>
                      {emoji} {label}
                    </span>
                <% end %>
              </div>
              <div class="flex items-center text-gray-700">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-4 w-4 mr-2 text-gray-400"
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
                <span class="font-medium">Department:</span>
                <span class="ml-2">{@shift_handover.department}</span>
              </div>
            </div>
          </div>

          <div class="bg-gray-50 rounded-lg p-4">
            <h3 class="text-sm font-semibold text-gray-600 mb-3">Staff Handover</h3>
            <div class="space-y-2">
              <div class="flex items-start">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-4 w-4 mr-2 text-gray-400 mt-0.5"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
                  />
                </svg>
                <div>
                  <p class="text-xs text-gray-500">From (Outgoing)</p>
                  <p class="font-medium text-gray-900">{@shift_handover.handover_from}</p>
                </div>
              </div>
              <div class="flex items-start">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-4 w-4 mr-2 text-gray-400 mt-0.5"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
                  />
                </svg>
                <div>
                  <p class="text-xs text-gray-500">To (Incoming)</p>
                  <p class="font-medium text-gray-900">{@shift_handover.handover_to}</p>
                </div>
              </div>
            </div>
          </div>
        </div>
        
    <!-- Clinical Information -->
        <div class="space-y-4">
          <!-- Patient Updates -->
          <%= if @shift_handover.patient_updates && @shift_handover.patient_updates != "" do %>
            <div class="bg-blue-50 border border-blue-200 rounded-lg p-4">
              <h3 class="font-semibold text-blue-900 mb-2 flex items-center">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-5 w-5 mr-2"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                  />
                </svg>
                Patient Updates
              </h3>
              <p class="text-gray-700 whitespace-pre-wrap">{@shift_handover.patient_updates}</p>
            </div>
          <% end %>
          <!-- Pending Tasks -->
          <%= if @shift_handover.pending_tasks && @shift_handover.pending_tasks != "" do %>
            <div class="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
              <h3 class="font-semibold text-yellow-900 mb-2 flex items-center">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-5 w-5 mr-2"
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
                Pending Tasks
              </h3>
              <p class="text-gray-700 whitespace-pre-wrap">{@shift_handover.pending_tasks}</p>
            </div>
          <% end %>
          <!-- Equipment Issues -->
          <%= if @shift_handover.equipment_issues && @shift_handover.equipment_issues != "" do %>
            <div class="bg-orange-50 border border-orange-200 rounded-lg p-4">
              <h3 class="font-semibold text-orange-900 mb-2 flex items-center">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-5 w-5 mr-2"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
                  />
                </svg>
                Equipment Issues
              </h3>
              <p class="text-gray-700 whitespace-pre-wrap">{@shift_handover.equipment_issues}</p>
            </div>
          <% end %>
          <!-- Incidents -->
          <%= if @shift_handover.incidents && @shift_handover.incidents != "" do %>
            <div class="bg-red-50 border border-red-200 rounded-lg p-4">
              <h3 class="font-semibold text-red-900 mb-2 flex items-center">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-5 w-5 mr-2"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
                  />
                </svg>
                Incidents / Safety Concerns
              </h3>
              <p class="text-gray-700 whitespace-pre-wrap">{@shift_handover.incidents}</p>
            </div>
          <% end %>
          <!-- Additional Notes -->
          <%= if @shift_handover.notes && @shift_handover.notes != "" do %>
            <div class="bg-gray-50 border border-gray-200 rounded-lg p-4">
              <h3 class="font-semibold text-gray-900 mb-2 flex items-center">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-5 w-5 mr-2"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M7 8h10M7 12h4m1 8l-4-4H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-3l-4 4z"
                  />
                </svg>
                Additional Notes
              </h3>
              <p class="text-gray-700 whitespace-pre-wrap">{@shift_handover.notes}</p>
            </div>
          <% end %>

          <%= if @shift_handover.petty_cash_balance != nil do %>
            <div class="bg-green-50 border border-green-200 rounded-lg p-4">
              <h3 class="font-semibold text-green-900 mb-2 flex items-center">
                <i class="fa fa-money mr-2"></i> Petty Cash Balance
              </h3>
              <p class="text-green-700">
                {@shift_handover.petty_cash_balance} KES
              </p>
            </div>
          <% end %>
        </div>
        
    <!-- Timestamps -->
        <div class="mt-6 pt-6 border-t border-gray-200 grid grid-cols-1 md:grid-cols-2 gap-4 text-sm text-gray-600">
          <%= if @shift_handover.submitted_at do %>
            <div class="flex items-center">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-4 w-4 mr-2 text-gray-400"
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
              <span>
                Submitted: {Calendar.strftime(@shift_handover.submitted_at, "%b %d, %Y at %H:%M")}
              </span>
            </div>
          <% end %>
          <%= if @shift_handover.acknowledged_at do %>
            <div class="flex items-center">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-4 w-4 mr-2 text-green-500"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
              <span>
                Acknowledged: {Calendar.strftime(
                  @shift_handover.acknowledged_at,
                  "%b %d, %Y at %H:%M"
                )}
              </span>
            </div>
          <% end %>
        </div>
      </div>
    </div>

    <.modal
      :if={@live_action == :edit}
      id="shift_handover-modal"
      show
      on_cancel={JS.patch(shift_handovers_path(@current_user, "/#{@shift_handover.id}"))}
    >
      <.live_component
        module={MedcampWeb.ShiftHandoverLive.FormComponent}
        id={@shift_handover.id}
        title={@page_title}
        action={@live_action}
        shift_handover={@shift_handover}
        patch={shift_handovers_path(@current_user, "/#{@shift_handover.id}")}
      />
    </.modal>
    """
  end
end
