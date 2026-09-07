defmodule MedcampWeb.RadiologyComponents do
  use Phoenix.Component
  import MedcampWeb.CoreComponents

  def radiology_results_card(assigns) do
    ~H"""
    <div class="bg-white mt-4 rounded-lg shadow border border-gray-200 overflow-hidden">
      <div class="px-6 py-4 bg-gradient-to-r from-slate-50 to-purple-100 border-b border-gray-200">
        <h2 class="text-xl font-semibold text-purple-800">Radiology Results</h2>
      </div>

      <div class="p-6">
        <div class="flex justify-between items-center mb-4">
          <h3 class="text-lg font-semibold text-purple-800">Radiology Examinations</h3>

          <.link patch={"/doctor/patients/#{@patient.id}/notes/#{@doctor_note.id}/request_radiology_test?tab=radiology&subtab=admission"}>
            <.button class="bg-slate-500 hover:bg-purple-600">
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
                Request Radiology
              </span>
            </.button>
          </.link>
        </div>

        <%= if Enum.empty?(@radiology_results) do %>
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
                d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
              />
            </svg>
            <h3 class="mt-2 text-sm font-medium text-gray-900">No radiology results</h3>
            <p class="mt-1 text-sm text-gray-500">
              No radiology examinations have been requested for this patient yet.
            </p>
          </div>
        <% else %>
          <div class="space-y-4">
            <%= for result <- @radiology_results do %>
              <div class="border border-gray-200 rounded-lg overflow-hidden">
                <div class="px-4 py-3 bg-gray-50 border-b border-gray-200 flex justify-between items-start">
                  <div>
                    <div class="flex items-center">
                      <h4 class="font-medium text-gray-900">Radiology Examination</h4>
                      <%= if result.report_complete do %>
                        <span class="ml-2 px-2 py-1 bg-green-100 text-green-800 text-xs rounded-full">
                          Report Complete
                        </span>
                      <% else %>
                        <span class="ml-2 px-2 py-1 bg-yellow-100 text-yellow-800 text-xs rounded-full">
                          {result.urgency} - Pending
                        </span>
                      <% end %>
                    </div>
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
                      {Calendar.strftime(result.inserted_at, "%d %b %Y")}
                      <span class="ml-3 px-2 py-0.5 bg-blue-100 text-blue-800 text-xs rounded-full">
                        {result.payment_type}
                      </span>
                      <%= if result.has_paid do %>
                        <span class="ml-1 px-2 py-0.5 bg-green-100 text-green-800 text-xs rounded-full">
                          Paid
                        </span>
                      <% else %>
                        <span class="ml-1 px-2 py-0.5 bg-red-100 text-red-800 text-xs rounded-full">
                          Not Paid
                        </span>
                      <% end %>
                    </div>
                  </div>

                  <div class="flex items-center space-x-2">
                    <button
                      phx-click="delete_radiology"
                      phx-value-id={result.id}
                      data-confirm="Are you sure you want to delete this radiology request?"
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
                  <div class="mb-4">
                    <h5 class="text-sm font-medium text-gray-700 mb-2">Description</h5>
                    <div class="p-3 bg-gray-50 rounded-lg border border-gray-100 whitespace-pre-line">
                      {result.description}
                    </div>
                  </div>

                  <div class="mt-4">
                    <h5 class="text-sm font-medium text-gray-700 mb-2">Scans Requested</h5>
                    <div class="bg-gray-50 rounded-lg border border-gray-100 overflow-hidden">
                      <table class="min-w-full divide-y divide-gray-200">
                        <thead class="bg-gray-100">
                          <tr>
                            <th
                              scope="col"
                              class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                            >
                              Scan
                            </th>
                            <th
                              scope="col"
                              class="px-4 py-2 text-right text-xs font-medium text-gray-500 uppercase tracking-wider"
                            >
                              Price
                            </th>
                          </tr>
                        </thead>
                        <tbody class="bg-white divide-y divide-gray-200">
                          <%= for scan <- result.scans do %>
                            <tr>
                              <td class="px-4 py-2 whitespace-nowrap text-sm text-gray-900">
                                {scan.name}
                              </td>
                              <td class="px-4 py-2 whitespace-nowrap text-sm text-gray-900 text-right">
                                KSh {scan.price}
                              </td>
                            </tr>
                          <% end %>
                          <tr class="bg-gray-50">
                            <td class="px-4 py-2 whitespace-nowrap text-sm font-medium text-gray-900">
                              Total
                            </td>
                            <td class="px-4 py-2 whitespace-nowrap text-sm font-medium text-gray-900 text-right">
                              KSh {result.total_amount_paid ||
                                Enum.reduce(result.scans, 0, fn scan, acc -> acc + scan.price end)}
                            </td>
                          </tr>
                        </tbody>
                      </table>
                    </div>
                  </div>

                  <%= if result.report_complete do %>
                    <div class="mt-4 grid grid-cols-1 md:grid-cols-2 gap-4">
                      <div>
                        <h5 class="text-sm font-medium text-gray-700 mb-2">Findings</h5>
                        <div class="p-3 bg-gray-50 rounded-lg border border-gray-100 h-full whitespace-pre-line">
                          {result.findings || "No findings recorded."}
                        </div>
                      </div>

                      <div>
                        <h5 class="text-sm font-medium text-gray-700 mb-2">Radiology Report</h5>
                        <a href={result.radiology_report} target="_blank" download>
                          Download Report
                        </a>
                      </div>
                    </div>
                  <% end %>

                  <div class="flex justify-between items-center text-sm text-gray-500 border-t border-gray-200 pt-3 mt-3">
                    <div>
                      Requested by: Dr. {result.doctor.name}
                    </div>
                    <%= if result.radiologist do %>
                      <div>
                        Radiologist: Dr. {result.radiologist.name}
                      </div>
                    <% end %>
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

  def radiology_results_card_for_nurse(assigns) do
    ~H"""
    <div class="bg-white mt-4 rounded-lg shadow border border-gray-200 overflow-hidden">
      <div class="px-6 py-4 bg-gradient-to-r from-slate-50 to-purple-100 border-b border-gray-200">
        <h2 class="text-xl font-semibold text-purple-800">Radiology Results</h2>
      </div>

      <div class="p-6">
        <div class="flex justify-between items-center mb-4">
          <h3 class="text-lg font-semibold text-purple-800">Radiology Examinations</h3>
        </div>

        <%= if Enum.empty?(@radiology_results) do %>
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
                d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
              />
            </svg>
            <h3 class="mt-2 text-sm font-medium text-gray-900">No radiology results</h3>
            <p class="mt-1 text-sm text-gray-500">
              No radiology examinations have been requested for this patient yet.
            </p>
          </div>
        <% else %>
          <div class="space-y-4">
            <%= for result <- @radiology_results do %>
              <div class="border border-gray-200 rounded-lg overflow-hidden">
                <div class="px-4 py-3 bg-gray-50 border-b border-gray-200 flex justify-between items-start">
                  <div>
                    <div class="flex items-center">
                      <h4 class="font-medium text-gray-900">Radiology Examination</h4>
                      <%= if result.report_complete do %>
                        <span class="ml-2 px-2 py-1 bg-green-100 text-green-800 text-xs rounded-full">
                          Report Complete
                        </span>
                      <% else %>
                        <span class="ml-2 px-2 py-1 bg-yellow-100 text-yellow-800 text-xs rounded-full">
                          {result.urgency} - Pending
                        </span>
                      <% end %>
                    </div>
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
                      {Calendar.strftime(result.inserted_at, "%d %b %Y")}
                      <span class="ml-3 px-2 py-0.5 bg-blue-100 text-blue-800 text-xs rounded-full">
                        {result.payment_type}
                      </span>
                      <%= if result.has_paid do %>
                        <span class="ml-1 px-2 py-0.5 bg-green-100 text-green-800 text-xs rounded-full">
                          Paid
                        </span>
                      <% else %>
                        <span class="ml-1 px-2 py-0.5 bg-red-100 text-red-800 text-xs rounded-full">
                          Not Paid
                        </span>
                      <% end %>
                    </div>
                  </div>
                </div>

                <div class="p-4">
                  <div class="mb-4">
                    <h5 class="text-sm font-medium text-gray-700 mb-2">Description</h5>
                    <div class="p-3 bg-gray-50 rounded-lg border border-gray-100 whitespace-pre-line">
                      {result.description}
                    </div>
                  </div>

                  <div class="mt-4">
                    <h5 class="text-sm font-medium text-gray-700 mb-2">Scans Requested</h5>
                    <div class="bg-gray-50 rounded-lg border border-gray-100 overflow-hidden">
                      <table class="min-w-full divide-y divide-gray-200">
                        <thead class="bg-gray-100">
                          <tr>
                            <th
                              scope="col"
                              class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                            >
                              Scan
                            </th>
                            <th
                              scope="col"
                              class="px-4 py-2 text-right text-xs font-medium text-gray-500 uppercase tracking-wider"
                            >
                              Price
                            </th>
                          </tr>
                        </thead>
                        <tbody class="bg-white divide-y divide-gray-200">
                          <%= for scan <- result.scans do %>
                            <tr>
                              <td class="px-4 py-2 whitespace-nowrap text-sm text-gray-900">
                                {scan.name}
                              </td>
                              <td class="px-4 py-2 whitespace-nowrap text-sm text-gray-900 text-right">
                                KSh {scan.price}
                              </td>
                            </tr>
                          <% end %>
                          <tr class="bg-gray-50">
                            <td class="px-4 py-2 whitespace-nowrap text-sm font-medium text-gray-900">
                              Total
                            </td>
                            <td class="px-4 py-2 whitespace-nowrap text-sm font-medium text-gray-900 text-right">
                              KSh {result.total_amount_paid ||
                                Enum.reduce(result.scans, 0, fn scan, acc -> acc + scan.price end)}
                            </td>
                          </tr>
                        </tbody>
                      </table>
                    </div>
                  </div>

                  <%= if result.report_complete do %>
                    <div class="mt-4 grid grid-cols-1 md:grid-cols-2 gap-4">
                      <div>
                        <h5 class="text-sm font-medium text-gray-700 mb-2">Findings</h5>
                        <div class="p-3 bg-gray-50 rounded-lg border border-gray-100 h-full whitespace-pre-line">
                          {result.findings || "No findings recorded."}
                        </div>
                      </div>

                      <div>
                        <h5 class="text-sm font-medium text-gray-700 mb-2">Radiology Report</h5>
                        <a href={result.radiology_report} target="_blank" download>
                          Download Report
                        </a>
                      </div>
                    </div>
                  <% end %>

                  <div class="flex justify-between items-center text-sm text-gray-500 border-t border-gray-200 pt-3 mt-3">
                    <div>
                      Requested by: Dr. {result.doctor.name}
                    </div>
                    <%= if result.radiologist do %>
                      <div>
                        Radiologist: Dr. {result.radiologist.name}
                      </div>
                    <% end %>
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
