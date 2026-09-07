defmodule MedcampWeb.AdmissionRequestsComponents do
  use Phoenix.Component
  import MedcampWeb.CoreComponents
  alias Medcamp.AdmissionRequests.LineItem

  def admission_requests_card(assigns) do
    ~H"""
    <div class="bg-white mt-4 rounded-lg shadow border border-gray-200 overflow-hidden">
      <div class="px-6 py-4 bg-gradient-to-r from-teal-50 to-teal-100 border-b border-gray-200">
        <h2 class="text-xl font-semibold text-teal-800">Admission Requests</h2>
      </div>

      <div class="p-6">
        <div class="flex justify-between items-center mb-4">
          <h3 class="text-lg font-semibold text-teal-800">Patient Admissions</h3>

          <.link patch={"#{@note_path}/admit_patient?tab=admission&subtab=admission"}>
            <.button class="bg-teal-500 hover:bg-teal-600">
              <span class="flex items-center">
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
                    d="M12 4v16m8-8H4"
                  />
                </svg>
                Request Admission
              </span>
            </.button>
          </.link>
        </div>

        <%= if Enum.empty?(@admission_requests) do %>
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
                d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
              />
            </svg>
            <h3 class="mt-2 text-sm font-medium text-gray-900">No admission requests</h3>
            <p class="mt-1 text-sm text-gray-500">
              No admission requests have been created for this patient yet.
            </p>
          </div>
        <% else %>
          <div class="space-y-4">
            <%= for request <- @admission_requests do %>
              <div class="border border-gray-200 rounded-lg overflow-hidden">
                <div class="px-4 py-3 bg-gray-50 border-b border-gray-200 flex justify-between items-start">
                  <div>
                    <h4 class="font-medium text-gray-900">
                      Admission Request
                      <%= if request.date do %>
                        <% cmp = Date.compare(request.date, Date.utc_today()) %>
                        <%= if cmp == :gt do %>
                          <span class="ml-2 px-2 py-1 bg-blue-100 text-blue-800 text-xs rounded-full">
                            Upcoming
                          </span>
                        <% else %>
                          <%= if cmp == :lt do %>
                            <span class="ml-2 px-2 py-1 bg-gray-100 text-gray-800 text-xs rounded-full">
                              Past
                            </span>
                          <% else %>
                            <span class="ml-2 px-2 py-1 bg-green-100 text-green-800 text-xs rounded-full">
                              Today
                            </span>
                          <% end %>
                        <% end %>
                      <% end %>
                    </h4>
                    <div class="flex items-center mt-1 text-sm text-gray-500">
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
                          d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
                        />
                      </svg>
                      {if request.date, do: Calendar.strftime(request.date, "%d %b %Y"), else: "—"}

                      <%= if request.payment_type do %>
                        <span class="mx-2 text-gray-300">|</span>
                        <span class="px-2 py-0.5 bg-blue-100 text-blue-800 text-xs rounded-full">
                          {request.payment_type}
                        </span>
                      <% end %>

                      <%= if !request.has_paid do %>
                        <span class="ml-1 px-2 py-0.5 bg-red-100 text-red-800 text-xs rounded-full">
                          Not paid
                        </span>
                      <% else %>
                        <%= if request.fully_paid do %>
                          <span class="ml-1 px-2 py-0.5 bg-green-100 text-green-800 text-xs rounded-full">
                            Fully paid
                          </span>
                        <% else %>
                          <span class="ml-1 px-2 py-0.5 bg-amber-100 text-amber-800 text-xs rounded-full">
                            Partially paid
                          </span>
                        <% end %>
                      <% end %>
                      <%= if request.discharged do %>
                        <span class="ml-1 px-2 py-0.5 bg-slate-100 text-slate-800 text-xs rounded-full">
                          Discharged
                        </span>
                        <%= if request.discharge_date do %>
                          <span class="ml-1 text-gray-500">
                            ({Calendar.strftime(request.discharge_date, "%d %b %Y")})
                          </span>
                        <% end %>
                      <% end %>
                    </div>
                  </div>

                  <div class="flex items-center space-x-2">
                    <.link
                      :if={@note_path}
                      patch={"#{@note_path}/admission_requests/#{request.id}/line_items?tab=admission&subtab=admission"}
                      class="inline-flex items-center px-3 py-2 border border-teal-300 text-sm leading-4 font-medium rounded-md text-teal-700 bg-white hover:bg-teal-50"
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
                          d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"
                        />
                      </svg>
                      Line items
                    </.link>
                    <p class="inline-flex items-center px-3 py-2 border border-blue-300 text-sm leading-4 font-medium rounded-md text-blue-700 bg-white hover:bg-blue-50">
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
                          d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z"
                        />
                      </svg>
                      Print
                    </p>
                    <%= if !request.discharged do %>
                      <button
                        phx-click="mark_admission_discharged"
                        phx-value-id={request.id}
                        data-confirm="Mark this admission as discharged?"
                        class="inline-flex items-center px-3 py-2 border border-slate-300 text-sm leading-4 font-medium rounded-md text-slate-700 bg-white hover:bg-slate-50"
                      >
                        Mark discharged
                      </button>
                    <% end %>
                    <button
                      phx-click="delete_admission"
                      phx-value-id={request.id}
                      data-confirm="Are you sure you want to delete this admission request?"
                      class="inline-flex items-center px-3 py-2 border border-red-300 text-sm leading-4 font-medium rounded-md text-red-700 bg-white hover:bg-red-50"
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
                    </button>
                  </div>
                </div>

                <div class="p-4">
                  <div class="mb-4 rounded-lg border-2 border-teal-200 bg-teal-50/50 p-4">
                    <p class="text-xs text-teal-700 uppercase font-semibold mb-2">Line items</p>
                    <%= if Enum.empty?(request.line_items || []) do %>
                      <p class="text-sm text-gray-500">No line items</p>
                    <% else %>
                      <ul class="space-y-1.5 text-sm">
                        <%= for li <- (request.line_items || []) do %>
                          <% paid = (li.amount_paid || 0) >= (li.price || 0) %>
                          <li class="flex justify-between items-center gap-2">
                            <span class="text-gray-800">
                              {LineItem.item_type_label(li.item_type)}
                            </span>
                            <span class="font-semibold text-gray-900">KSh {li.price}</span>
                            <%= if paid do %>
                              <span class="px-2 py-0.5 bg-green-100 text-green-800 text-xs rounded-full shrink-0">
                                Paid
                              </span>
                            <% else %>
                              <span class="px-2 py-0.5 bg-amber-100 text-amber-800 text-xs rounded-full shrink-0">
                                Unpaid
                              </span>
                            <% end %>
                          </li>
                        <% end %>
                      </ul>
                      <p class="text-sm font-bold mt-3 pt-3 border-t border-teal-200 text-teal-800">
                        Total (line items): KSh {Enum.reduce(request.line_items || [], 0, fn li,
                                                                                             acc ->
                          acc + li.price
                        end)}
                      </p>
                    <% end %>
                  </div>

                  <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4 mb-4">
                    <div class="bg-gray-50 rounded p-3 border border-gray-100">
                      <p class="text-xs text-gray-500 uppercase font-semibold">Date</p>
                      <p class="font-medium text-gray-900">
                        {if request.date,
                          do: Calendar.strftime(request.date, "%A, %d %B %Y"),
                          else: "—"}
                      </p>
                    </div>
                    <div class="bg-gray-50 rounded p-3 border border-gray-100">
                      <p class="text-xs text-gray-500 uppercase font-semibold">Start time</p>
                      <p class="font-medium text-gray-900">
                        {if request.start_time,
                          do: Calendar.strftime(request.start_time, "%H:%M"),
                          else: "—"}
                      </p>
                    </div>
                    <div class="bg-gray-50 rounded p-3 border border-gray-100">
                      <p class="text-xs text-gray-500 uppercase font-semibold">End time</p>
                      <p class="font-medium text-gray-900">
                        {if request.end_time,
                          do: Calendar.strftime(request.end_time, "%H:%M"),
                          else: "—"}
                      </p>
                    </div>
                    <div class="bg-gray-50 rounded p-3 border border-gray-100">
                      <p class="text-xs text-gray-500 uppercase font-semibold">Discharge date</p>
                      <p class="font-medium text-gray-900">
                        {if request.discharge_date,
                          do: Calendar.strftime(request.discharge_date, "%A, %d %B %Y"),
                          else: "—"}
                      </p>
                    </div>
                    <div class="bg-gray-50 rounded p-3 border border-gray-100">
                      <p class="text-xs text-gray-500 uppercase font-semibold">Discharged</p>
                      <p class="font-medium text-gray-900">
                        {if request.discharged, do: "Yes", else: "No"}
                      </p>
                    </div>
                  </div>

                  <%= if request.total_amount_paid do %>
                    <div class="mt-4 bg-gray-50 rounded p-3 border border-gray-100 flex justify-between items-center">
                      <span class="text-sm font-medium text-gray-700">Total Amount Paid:</span>
                      <span class="font-medium text-gray-900">KSh {request.total_amount_paid}</span>
                    </div>
                  <% end %>

                  <div class="flex justify-between items-center text-sm text-gray-500 border-t border-gray-200 pt-3 mt-3">
                    <div>
                      Requested by: Dr. {request.doctor.name}
                    </div>
                    <div>
                      Created: {Calendar.strftime(request.inserted_at, "%d %b %Y, %H:%M")}
                    </div>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def admission_requests_card_for_nurse(assigns) do
    ~H"""
    <div class="bg-white mt-4 rounded-lg shadow border border-gray-200 overflow-hidden">
      <div class="px-6 py-4 bg-gradient-to-r from-teal-50 to-teal-100 border-b border-gray-200">
        <h2 class="text-xl font-semibold text-teal-800">Admission Requests</h2>
      </div>

      <div class="p-6">
        <div class="flex justify-between items-center mb-4">
          <h3 class="text-lg font-semibold text-teal-800">Patient Admissions</h3>
        </div>

        <%= if Enum.empty?(@admission_requests) do %>
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
                d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
              />
            </svg>
            <h3 class="mt-2 text-sm font-medium text-gray-900">No admission requests</h3>
            <p class="mt-1 text-sm text-gray-500">
              No admission requests have been created for this patient yet.
            </p>
          </div>
        <% else %>
          <div class="space-y-4">
            <%= for request <- @admission_requests do %>
              <div class="border border-gray-200 rounded-lg overflow-hidden">
                <div class="px-4 py-3 bg-gray-50 border-b border-gray-200 flex justify-between items-start">
                  <div>
                    <h4 class="font-medium text-gray-900">
                      Admission Request
                      <%= if request.date do %>
                        <% cmp = Date.compare(request.date, Date.utc_today()) %>
                        <%= if cmp == :gt do %>
                          <span class="ml-2 px-2 py-1 bg-blue-100 text-blue-800 text-xs rounded-full">
                            Upcoming
                          </span>
                        <% else %>
                          <%= if cmp == :lt do %>
                            <span class="ml-2 px-2 py-1 bg-gray-100 text-gray-800 text-xs rounded-full">
                              Past
                            </span>
                          <% else %>
                            <span class="ml-2 px-2 py-1 bg-green-100 text-green-800 text-xs rounded-full">
                              Today
                            </span>
                          <% end %>
                        <% end %>
                      <% end %>
                    </h4>
                    <div class="flex items-center mt-1 text-sm text-gray-500">
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
                          d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
                        />
                      </svg>
                      {if request.date, do: Calendar.strftime(request.date, "%d %b %Y"), else: "—"}

                      <%= if request.payment_type do %>
                        <span class="mx-2 text-gray-300">|</span>
                        <span class="px-2 py-0.5 bg-blue-100 text-blue-800 text-xs rounded-full">
                          {request.payment_type}
                        </span>
                      <% end %>

                      <%= if !request.has_paid do %>
                        <span class="ml-1 px-2 py-0.5 bg-red-100 text-red-800 text-xs rounded-full">
                          Not paid
                        </span>
                      <% else %>
                        <%= if request.fully_paid do %>
                          <span class="ml-1 px-2 py-0.5 bg-green-100 text-green-800 text-xs rounded-full">
                            Fully paid
                          </span>
                        <% else %>
                          <span class="ml-1 px-2 py-0.5 bg-amber-100 text-amber-800 text-xs rounded-full">
                            Partially paid
                          </span>
                        <% end %>
                      <% end %>
                      <%= if request.discharged do %>
                        <span class="ml-1 px-2 py-0.5 bg-slate-100 text-slate-800 text-xs rounded-full">
                          Discharged
                        </span>
                        <%= if request.discharge_date do %>
                          <span class="ml-1 text-gray-500">
                            ({Calendar.strftime(request.discharge_date, "%d %b %Y")})
                          </span>
                        <% end %>
                      <% end %>
                    </div>
                  </div>

                  <div class="flex items-center space-x-2">
                    <.link
                      navigate={"/nurse/#{@patient.id}/admission_requests/#{request.id}/line_items"}
                      class="inline-flex items-center px-3 py-2 border border-teal-300 text-sm leading-4 font-medium rounded-md text-teal-700 bg-white hover:bg-teal-50"
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
                          d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"
                        />
                      </svg>
                      Line items
                    </.link>
                    <p class="inline-flex items-center px-3 py-2 border border-blue-300 text-sm leading-4 font-medium rounded-md text-blue-700 bg-white hover:bg-blue-50">
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
                          d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z"
                        />
                      </svg>
                      Print
                    </p>
                    <%= if !request.discharged do %>
                      <button
                        phx-click="mark_admission_discharged"
                        phx-value-id={request.id}
                        data-confirm="Mark this admission as discharged?"
                        class="inline-flex items-center px-3 py-2 border border-slate-300 text-sm leading-4 font-medium rounded-md text-slate-700 bg-white hover:bg-slate-50"
                      >
                        Mark discharged
                      </button>
                    <% end %>
                    <button
                      phx-click="delete_admission"
                      phx-value-id={request.id}
                      data-confirm="Are you sure you want to delete this admission request?"
                      class="inline-flex items-center px-3 py-2 border border-red-300 text-sm leading-4 font-medium rounded-md text-red-700 bg-white hover:bg-red-50"
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
                    </button>
                  </div>
                </div>

                <div class="p-4">
                  <div class="mb-4 rounded-lg border-2 border-teal-200 bg-teal-50/50 p-4">
                    <p class="text-xs text-teal-700 uppercase font-semibold mb-2">Line items</p>
                    <%= if Enum.empty?(request.line_items || []) do %>
                      <p class="text-sm text-gray-500">No line items</p>
                    <% else %>
                      <ul class="space-y-1.5 text-sm">
                        <%= for li <- (request.line_items || []) do %>
                          <% paid = (li.amount_paid || 0) >= (li.price || 0) %>
                          <li class="flex justify-between items-center gap-2">
                            <span class="text-gray-800">
                              {LineItem.item_type_label(li.item_type)}
                            </span>
                            <span class="font-semibold text-gray-900">KSh {li.price}</span>
                            <%= if paid do %>
                              <span class="px-2 py-0.5 bg-green-100 text-green-800 text-xs rounded-full shrink-0">
                                Paid
                              </span>
                            <% else %>
                              <span class="px-2 py-0.5 bg-amber-100 text-amber-800 text-xs rounded-full shrink-0">
                                Unpaid
                              </span>
                            <% end %>
                          </li>
                        <% end %>
                      </ul>
                      <p class="text-sm font-bold mt-3 pt-3 border-t border-teal-200 text-teal-800">
                        Total (line items): KSh {Enum.reduce(request.line_items || [], 0, fn li,
                                                                                             acc ->
                          acc + li.price
                        end)}
                      </p>
                    <% end %>
                  </div>

                  <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4 mb-4">
                    <div class="bg-gray-50 rounded p-3 border border-gray-100">
                      <p class="text-xs text-gray-500 uppercase font-semibold">Date</p>
                      <p class="font-medium text-gray-900">
                        {if request.date,
                          do: Calendar.strftime(request.date, "%A, %d %B %Y"),
                          else: "—"}
                      </p>
                    </div>
                    <div class="bg-gray-50 rounded p-3 border border-gray-100">
                      <p class="text-xs text-gray-500 uppercase font-semibold">Start time</p>
                      <p class="font-medium text-gray-900">
                        {if request.start_time,
                          do: Calendar.strftime(request.start_time, "%H:%M"),
                          else: "—"}
                      </p>
                    </div>
                    <div class="bg-gray-50 rounded p-3 border border-gray-100">
                      <p class="text-xs text-gray-500 uppercase font-semibold">End time</p>
                      <p class="font-medium text-gray-900">
                        {if request.end_time,
                          do: Calendar.strftime(request.end_time, "%H:%M"),
                          else: "—"}
                      </p>
                    </div>
                    <div class="bg-gray-50 rounded p-3 border border-gray-100">
                      <p class="text-xs text-gray-500 uppercase font-semibold">Discharge date</p>
                      <p class="font-medium text-gray-900">
                        {if request.discharge_date,
                          do: Calendar.strftime(request.discharge_date, "%A, %d %B %Y"),
                          else: "—"}
                      </p>
                    </div>
                    <div class="bg-gray-50 rounded p-3 border border-gray-100">
                      <p class="text-xs text-gray-500 uppercase font-semibold">Discharged</p>
                      <p class="font-medium text-gray-900">
                        {if request.discharged, do: "Yes", else: "No"}
                      </p>
                    </div>
                  </div>

                  <%= if request.total_amount_paid do %>
                    <div class="mt-4 bg-gray-50 rounded p-3 border border-gray-100 flex justify-between items-center">
                      <span class="text-sm font-medium text-gray-700">Total Amount Paid:</span>
                      <span class="font-medium text-gray-900">KSh {request.total_amount_paid}</span>
                    </div>
                  <% end %>

                  <div class="flex justify-between items-center text-sm text-gray-500 border-t border-gray-200 pt-3 mt-3">
                    <div>
                      Requested by: Dr. {request.doctor.name}
                    </div>
                    <div>
                      Created: {Calendar.strftime(request.inserted_at, "%d %b %Y, %H:%M")}
                    </div>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
