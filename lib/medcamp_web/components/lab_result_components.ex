defmodule MedcampWeb.LabResultComponents do
  use Phoenix.Component
  use Gettext, backend: MedcampWeb.Gettext
  import MedcampWeb.CoreComponents

  def lab_results_card(assigns) do
    assigns =
      assigns
      |> assign_new(:note_path, fn -> nil end)
      |> assign_new(:patient, fn -> nil end)
      |> assign_new(:regenerate, fn -> false end)

    ~H"""
    <div class="p-6">
      <div class="flex justify-between items-center mb-4">
        <h3 class="text-lg font-semibold text-purple-800">Lab Results</h3>

        <.link :if={@note_path} patch={"#{@note_path}/request_lab?tab=lab_work&subtab=admission"}>
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
              Request Lab Test
            </span>
          </.button>
        </.link>
      </div>

      <%= if Enum.empty?(@lab_results) do %>
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
            No lab results have been added for this patient yet.
          </p>
        </div>
      <% else %>
        <div class="space-y-4">
          <%= for lab_result <- @lab_results do %>
            <.lab_result_card
              lab_result={lab_result}
              note_path={@note_path}
              patient={@patient}
              regenerate={@regenerate}
            />
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  def lab_results_card_for_nurse(assigns) do
    ~H"""
    <div class="p-6">
      <div class="flex justify-between items-center mb-4">
        <h3 class="text-lg font-semibold text-purple-800">Lab Results</h3>
      </div>

      <%= if Enum.empty?(@lab_results) do %>
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
            No lab results have been added for this patient yet.
          </p>
        </div>
      <% else %>
        <div class="space-y-4">
          <%= for lab_result <- @lab_results do %>
            <.lab_result_card lab_result={lab_result} />
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  def lab_result_card(assigns) do
    assigns =
      assigns
      |> assign_new(:note_path, fn -> nil end)
      |> assign_new(:patient, fn -> nil end)
      |> assign_new(:regenerate, fn -> false end)

    # Load test entries in the component itself
    test_entries = Medcamp.LabTestTemplates.list_entries_for_lab_result(assigns.lab_result.id)
    assigns = assign(assigns, :test_entries, test_entries)

    ~H"""
    <div class="border border-gray-200 rounded-lg overflow-hidden mb-4">
      <div class="px-4 py-3 bg-gray-50 border-b border-gray-200">
        <div class="flex justify-between items-start">
          <div>
            <h4 class="font-medium text-gray-900">
              Lab Result
              <span class={"ml-2 px-2 py-1 #{urgency_color_class(@lab_result.urgency)} text-xs rounded-full"}>
                {@lab_result.urgency}
              </span>
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
              <span>
                Requested: {Calendar.strftime(@lab_result.inserted_at, "%d %b %Y")}
              </span>
            </div>
          </div>
          
    <!-- Status Overview in Header -->
          <div class="flex items-center gap-3">
            <%= if @lab_result.report_complete do %>
              <span class="inline-flex items-center px-2 py-1 text-xs rounded-full bg-green-100 text-green-800 font-medium">
                <svg class="h-3 w-3 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M5 13l4 4L19 7"
                  />
                </svg>
                Complete
              </span>
            <% else %>
              <span class="inline-flex items-center px-2 py-1 text-xs rounded-full bg-yellow-100 text-yellow-800 font-medium">
                <svg class="h-3 w-3 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                  />
                </svg>fix t
                Pending
              </span>
            <% end %>
            <span class="text-sm font-semibold text-gray-700">
              {count_completed_tests(@test_entries)} / {length(@lab_result.tests)}
            </span>
          </div>
        </div>
      </div>

      <div class="p-4">
        <!-- Tests Requested -->
        <div class="mb-4">
          <h5 class="text-sm font-semibold text-[#373896] mb-2">Tests Requested</h5>
          <div class="flex flex-wrap gap-2">
            <%= for test <- @lab_result.tests do %>
              <span class="px-2 py-1 text-xs bg-[#f8f8ff] text-[#373896] rounded-full border border-[#e7e7ff]">
                {test.name}
              </span>
            <% end %>
          </div>
        </div>

        <.lab_interpretation_panel
          lab_result={@lab_result}
          patient={@patient}
          regenerate={@regenerate}
          can_generate_ai={has_test_entries?(@test_entries)}
        />
        
    <!-- Attached PDF Report (if uploaded) -->
        <%= if @lab_result.report_complete && @lab_result.lab_report &&
               String.trim(@lab_result.lab_report) != "" do %>
          <div class="mt-4 bg-[#f8f8ff] rounded-lg p-4 border border-[#e7e7ff]">
            <div class="flex items-center justify-between gap-3">
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
                    d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                  />
                </svg>
                <p class="text-sm font-semibold text-[#373896]">Lab Report (PDF)</p>
              </div>
              <a
                href={List.first(String.split(@lab_result.lab_report, ","))}
                target="_blank"
                class="text-sm font-medium text-[#373896] hover:underline"
              >
                Open in new tab
              </a>
            </div>

            <div class="mt-3 space-y-3">
              <%= for report <- String.split(@lab_result.lab_report, ",") do %>
                <div class="pdf-container h-[70vh] overflow-y-auto bg-gray-100 rounded border border-gray-200">
                  <object data={report} width="100%" height="100%" class="shadow-sm">
                    <div class="flex flex-col items-center justify-center h-full p-6 text-center">
                      <p class="text-gray-700 mb-3">
                        Unable to display PDF in this browser.
                      </p>

                      <a
                        href={"/uploads/#{Path.basename(report)}"}
                        download
                        class="inline-flex items-center px-3 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-purple-600 hover:bg-purple-700"
                      >
                        Download PDF
                      </a>
                    </div>
                  </object>
                </div>
              <% end %>
            </div>
          </div>
        <% end %>
        
    <!-- Test Results -->
        <%= if has_test_entries?(@test_entries) do %>
          <div class="mt-4">
            <h5 class="text-sm font-semibold text-[#373896] mb-3">Lab Results</h5>
            <div class="space-y-3">
              <%= for entry <- @test_entries do %>
                <%= if entry.status in ["completed", "verified"] do %>
                  <div class="border border-gray-200 rounded-lg overflow-hidden">
                    <!-- Test Entry Header -->
                    <div class="bg-gray-50 px-3 py-2 border-b border-gray-200 flex justify-between items-center">
                      <div class="flex items-center gap-2">
                        <div class="p-1 rounded">
                          <%= if entry.status == "verified" do %>
                            <svg
                              class="h-4 w-4 text-blue-600"
                              fill="none"
                              viewBox="0 0 24 24"
                              stroke="currentColor"
                            >
                              <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"
                              />
                            </svg>
                          <% else %>
                            <svg
                              class="h-4 w-4 text-green-600"
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
                          <% end %>
                        </div>
                        <div>
                          <h6 class="font-semibold text-sm text-gray-900">
                            {entry.template.name}
                          </h6>
                          <%= if entry.template.short_name do %>
                            <span class="text-xs text-gray-500">({entry.template.short_name})</span>
                          <% end %>
                        </div>
                      </div>
                      <div class="flex items-center gap-2">
                        <span class={[
                          "px-2 py-0.5 text-xs rounded-full font-medium",
                          case entry.status do
                            "verified" -> "bg-blue-100 text-blue-800"
                            "completed" -> "bg-green-100 text-green-800"
                            _ -> "bg-gray-100 text-gray-800"
                          end
                        ]}>
                          {String.capitalize(entry.status)}
                        </span>

                        <.link
                          :if={@note_path}
                          patch={"#{@note_path}?view_lab_report=#{entry.id}"}
                          class="px-3 py-1.5 text-xs font-medium text-white bg-teal-600 rounded-lg hover:bg-teal-700 transition-colors flex items-center"
                        >
                          <svg
                            class="h-4 w-4 mr-1"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke="currentColor"
                          >
                            <path
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              stroke-width="2"
                              d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                            />
                          </svg>
                          View Report
                        </.link>
                      </div>
                    </div>
                    
    <!-- Test Results Grid -->
                    <%= if map_size(entry.results) > 0 do %>
                      <div class="p-3 bg-white">
                        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
                          <%= for {field_name, result_data} <- entry.results do %>
                            <% field_def = find_field_def(entry.template, field_name) %>
                            <div class="bg-gray-50 rounded p-2 border border-gray-200">
                              <p class="text-xs text-gray-500 mb-1">
                                {field_def["label"] || field_name}
                              </p>
                              <div class="flex items-baseline justify-between">
                                <span class={[
                                  "font-semibold text-sm",
                                  case result_data["flag"] do
                                    "low" -> "text-blue-600"
                                    "high" -> "text-red-600"
                                    _ -> "text-gray-900"
                                  end
                                ]}>
                                  {result_data["value"]}
                                </span>
                                <%= if result_data["flag"] && result_data["flag"] != "normal" do %>
                                  <span class={[
                                    "text-xs font-bold px-1.5 py-0.5 rounded",
                                    case result_data["flag"] do
                                      "low" -> "bg-blue-100 text-blue-700"
                                      "high" -> "bg-red-100 text-red-700"
                                      _ -> ""
                                    end
                                  ]}>
                                    {String.upcase(result_data["flag"])}
                                  </span>
                                <% end %>
                              </div>
                              <%= if field_def["ref_range_text"] do %>
                                <p class="text-xs text-gray-500 mt-1">
                                  Range: {field_def["ref_range_text"]}
                                </p>
                              <% end %>
                            </div>
                          <% end %>
                        </div>
                        
    <!-- Remarks -->
                        <%= if entry.remarks && entry.remarks != "" do %>
                          <div class="mt-3 pt-3 border-t border-gray-200">
                            <p class="text-xs font-semibold text-gray-700 mb-1">Remarks</p>
                            <p class="text-sm text-gray-600">{entry.remarks}</p>
                          </div>
                        <% end %>
                        
    <!-- Performed/Verified Info -->
                        <div class="mt-3 pt-3 border-t border-gray-200 flex items-center justify-between text-xs text-gray-500">
                          <%= if entry.performed_by do %>
                            <span>Performed by: {entry.performed_by.name}</span>
                          <% end %>
                          <%= if entry.verified_by do %>
                            <span>Verified by: {entry.verified_by.name}</span>
                          <% end %>
                        </div>
                      </div>
                    <% end %>
                  </div>
                <% end %>
              <% end %>
            </div>
          </div>
        <% else %>
          <!-- No results yet -->
          <div class="bg-amber-50 rounded-lg p-4 border border-amber-200 mt-4">
            <div class="flex items-center">
              <svg
                class="h-5 w-5 text-amber-600 mr-2"
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
              <span class="text-sm font-medium text-amber-900">
                Awaiting lab results
              </span>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  attr :lab_result, :map, required: true
  attr :patient, :any, default: nil
  attr :regenerate, :boolean, default: false
  attr :can_generate_ai, :boolean, default: true

  def lab_interpretation_panel(assigns) do
    payload = assigns.lab_result.interpretation_payload || %{}

    assigns =
      assigns
      |> assign(:payload, payload)
      |> assign(:triage, Map.get(payload, "triage_context", %{}))
      |> assign(:note, Map.get(payload, "doctor_note_context", %{}))

    ~H"""
    <div class="bg-[#f8f8ff] rounded-lg p-4 border border-[#e7e7ff] mb-4">
      <div class="flex items-center justify-between mb-3">
        <h5 class="text-sm font-semibold text-[#373896] uppercase tracking-wide flex items-center">
          <svg class="h-4 w-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"
            />
          </svg>
          AI Analysis
        </h5>
        <div class="flex items-center gap-2">
          <span class={[
            "px-2 py-0.5 text-xs rounded-full font-medium",
            case @lab_result.interpretation_status do
              "completed" -> "bg-green-100 text-green-800"
              "failed" -> "bg-red-100 text-red-800"
              _ -> "bg-yellow-100 text-yellow-800"
            end
          ]}>
            {String.capitalize(@lab_result.interpretation_status || "pending")}
          </span>
          <button
            :if={@regenerate and @can_generate_ai}
            phx-click="refresh-interpretation"
            phx-value-id={@lab_result.id}
            phx-disable-with="Generating..."
            class="group inline-flex items-center px-3 py-1.5 text-xs font-medium text-white bg-[#6667ab] rounded-lg hover:bg-[#5556a0] transition-colors disabled:opacity-60 disabled:cursor-not-allowed"
          >
            <svg
              class="h-4 w-4 mr-1 group-disabled:animate-spin"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
              />
            </svg>
            <%= if interpretation_present?(@payload) do %>
              Regenerate AI Lab Data
            <% else %>
              Generate AI Lab Data
            <% end %>
          </button>
        </div>
      </div>

      <%= if interpretation_present?(@payload) do %>
        <div class="space-y-4">
          <p :if={@lab_result.interpretation_generated_at} class="text-xs text-gray-500">
            Generated: {format_datetime(@lab_result.interpretation_generated_at)}
          </p>
          
    <!-- Patient & Clinical Context -->
          <div class="bg-white rounded p-3 border border-gray-200">
            <h6 class="text-xs font-semibold text-gray-700 uppercase mb-2">Clinical Context</h6>
            <div class="grid grid-cols-2 md:grid-cols-3 gap-x-4 gap-y-2">
              <.context_value :if={@patient} label="Age" value={patient_age(@patient)} />
              <.context_value
                :if={@patient}
                label="Gender"
                value={@patient.gender && String.capitalize(@patient.gender)}
              />
              <.context_value label="Temperature" value={Map.get(@triage, "temperature")} />
              <.context_value label="Blood Pressure" value={Map.get(@triage, "blood_pressure")} />
              <.context_value label="Pulse Rate" value={Map.get(@triage, "pulse_rate")} />
              <.context_value label="Oxygen Saturation" value={Map.get(@triage, "oxygen_saturation")} />
              <.context_value label="Emergency Scale" value={Map.get(@triage, "emergency_scale")} />
              <.context_value label="Allergies" value={Map.get(@triage, "allergies")} />
              <.context_value label="Diagnosis" value={Map.get(@note, "diagnosis")} />
            </div>
            <div
              :if={present_value?(Map.get(@note, "symptoms"))}
              class="mt-2 pt-2 border-t border-gray-100"
            >
              <p class="text-xs text-gray-500">Symptoms</p>
              <p class="text-sm text-gray-700 whitespace-pre-line">{Map.get(@note, "symptoms")}</p>
            </div>
          </div>

          <%= if Enum.any?(Map.get(@payload, "abnormal_findings", [])) do %>
            <div>
              <h6 class="text-xs font-semibold text-gray-700 uppercase mb-2">Abnormal Findings</h6>
              <div class="space-y-2">
                <%= for finding <- Map.get(@payload, "abnormal_findings", []) do %>
                  <div class="bg-white rounded p-3 border border-gray-200">
                    <div class="flex items-center justify-between">
                      <span class="font-medium text-sm text-gray-900">{finding["test"]}</span>
                      <span class={[
                        "text-xs font-bold px-1.5 py-0.5 rounded",
                        case finding["flag"] do
                          "low" -> "bg-blue-100 text-blue-700"
                          "high" -> "bg-red-100 text-red-700"
                          "critical" -> "bg-red-100 text-red-700"
                          _ -> "bg-gray-100 text-gray-700"
                        end
                      ]}>
                        {finding["value"]} {finding["unit"]}
                        <%= if finding["flag"] do %>
                          · {String.upcase(finding["flag"])}
                        <% end %>
                      </span>
                    </div>
                    <p :if={finding["reference_range"]} class="text-xs text-gray-500 mt-1">
                      Range: {finding["reference_range"]}
                    </p>
                    <p
                      :if={finding["doctor_note"] && finding["doctor_note"] != ""}
                      class="text-xs text-gray-600 mt-1"
                    >
                      {finding["doctor_note"]}
                    </p>
                  </div>
                <% end %>
              </div>
            </div>
          <% end %>

          <%= if Enum.any?(Map.get(@payload, "clinical_interpretation", [])) do %>
            <div>
              <h6 class="text-xs font-semibold text-gray-700 uppercase mb-2">
                Clinical Interpretation
              </h6>
              <ul class="list-disc list-inside space-y-1">
                <li
                  :for={line <- Map.get(@payload, "clinical_interpretation", [])}
                  class="text-sm text-gray-700"
                >
                  {line}
                </li>
              </ul>
            </div>
          <% end %>

          <%= if Enum.any?(Map.get(@payload, "recommended_attention", [])) do %>
            <div>
              <h6 class="text-xs font-semibold text-gray-700 uppercase mb-2">
                Recommended Attention
              </h6>
              <ul class="list-disc list-inside space-y-1">
                <li
                  :for={line <- Map.get(@payload, "recommended_attention", [])}
                  class="text-sm text-gray-700"
                >
                  {line}
                </li>
              </ul>
            </div>
          <% end %>

          <p
            :if={Map.get(@payload, "disclaimer")}
            class="text-xs italic text-gray-500 pt-2 border-t border-[#e7e7ff]"
          >
            {@payload["disclaimer"]}
          </p>
        </div>
      <% else %>
        <p class="text-sm text-gray-500">
          <%= cond do %>
            <% @regenerate and @can_generate_ai -> %>
              No analysis generated yet. Click "Generate AI Lab Data" to generate one.
            <% @regenerate -> %>
              Add lab results before generating AI lab data.
            <% true -> %>
              No analysis generated yet.
          <% end %>
        </p>
      <% end %>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :value, :any, default: nil

  defp context_value(assigns) do
    ~H"""
    <div :if={present_value?(@value)}>
      <p class="text-xs text-gray-500">{@label}</p>
      <p class="text-sm font-medium text-gray-900">{@value}</p>
    </div>
    """
  end

  defp present_value?(nil), do: false
  defp present_value?(value) when is_binary(value), do: String.trim(value) != ""
  defp present_value?(_), do: true

  defp interpretation_present?(payload) when is_map(payload) do
    Enum.any?(Map.get(payload, "abnormal_findings", [])) ||
      Enum.any?(Map.get(payload, "clinical_interpretation", [])) ||
      Enum.any?(Map.get(payload, "recommended_attention", []))
  end

  defp interpretation_present?(_), do: false

  defp patient_age(%{date_of_birth: nil}), do: nil

  defp patient_age(%{date_of_birth: dob}) do
    "#{Date.diff(Date.utc_today(), dob) |> div(365)} years"
  end

  defp patient_age(_), do: nil

  # Helper function to find field definition
  defp find_field_def(template, field_name) do
    Enum.find(template.field_definitions, %{}, fn f ->
      f["name"] == field_name || f[:name] == field_name
    end)
  end

  # Helper functions - now work directly with test_entries list
  defp count_completed_tests(test_entries) when is_list(test_entries) do
    Enum.count(test_entries, &(&1.status in ["completed", "verified"]))
  end

  defp count_completed_tests(_), do: 0

  defp has_test_entries?(test_entries) when is_list(test_entries) do
    Enum.any?(test_entries, &(&1.status in ["completed", "verified"]))
  end

  defp has_test_entries?(_), do: false

  defp has_ai_source_data?(lab_result, test_entries) do
    has_test_entries?(test_entries) ||
      Enum.any?(lab_result.tests || [], fn test ->
        test
        |> Map.get(:result)
        |> present_value?()
      end)
  end

  # Helper function to determine urgency color class
  defp urgency_color_class(urgency) do
    case urgency do
      "Urgent" -> "bg-red-100 text-red-800"
      "High" -> "bg-orange-100 text-orange-800"
      "Medium" -> "bg-yellow-100 text-yellow-800"
      "Low" -> "bg-green-100 text-green-800"
      _ -> "bg-blue-100 text-blue-800"
    end
  end

  defp patient_overview_card(assigns) do
    ~H"""
    <div>
      <h2 class="text-lg font-semibold text-[#373896]">Patient Overview</h2>
      <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-4">
        <div>
          <p class="text-sm text-gray-500 mb-1">Name</p>
          <p class="font-medium">
            {[
              @patient.first_name,
              @patient.middle_name,
              @patient.last_name
            ]
            |> Enum.filter(&(&1 != nil))
            |> Enum.join(" ")}
          </p>
        </div>
        <div>
          <p class="text-sm text-gray-500 mb-1">Phone Number</p>
          <p class="font-medium">{@patient.phone_number}</p>
        </div>

        <div>
          <p class="text-sm text-gray-500 mb-1">Date of Birth</p>
          <p class="font-medium">{@patient.date_of_birth}</p>
        </div>

        <div>
          <p class="text-sm text-gray-500 mb-1">Gender</p>
          <p class="font-medium">{@patient.gender}</p>
        </div>

        <div>
          <p class="text-sm text-gray-500 mb-1">National ID</p>
          <p class="font-medium">{@patient.national_id}</p>
        </div>

        <div>
          <p class="text-sm text-gray-500 mb-1">Email</p>
          <p class="font-medium">{@patient.email}</p>
        </div>
      </div>
    </div>
    """
  end

  def incomplete_lab_result_card(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-4 mt-4">
      <.patient_overview_card patient={@patient} />
      <div class="flex items-center justify-between mb-4 pb-2 border-b border-gray-100">
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
          <h2 class="text-lg font-semibold text-[#373896]">
            Lab Work Requested
          </h2>
        </div>

        <.link navigate={"/lab/lab_results/#{@lab_result.id}?complete=true"}>
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
              Add Lab Result Details
            </div>
          </.button>
        </.link>
      </div>

      <div class="space-y-4">
        <div>
          <h3 class="text-sm font-semibold text-[#373896] mb-2">Tests Requested</h3>
          <div class="flex gap-2 items-center flex-wrap">
            <%= for test <- @lab_result.tests do %>
              <div class="border border-gray-200 flex gap-2 rounded-lg  p-4">
                <span class="px-2 py-1 text-xs items-center justify-center rounded-full bg-[#f0f0ff] text-[#373896]">
                  {test.name}
                </span>

                <.link
                  navigate={"/lab/lab_results/#{@lab_result.id}?print_preview=#{test.serial}"}
                  class="inline-flex items-center px-3 py-2 border border-blue-300 text-sm leading-4 font-medium rounded-md text-blue-700 bg-white hover:bg-blue-50"
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
                      d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z"
                    />
                  </svg>
                  Print
                </.link>
              </div>
            <% end %>
          </div>
        </div>

        <div class="bg-gray-50 rounded p-3 border border-gray-100">
          <p class="text-xs text-gray-500 uppercase font-semibold">Urgency</p>
          <p class="font-medium text-gray-900">
            <%= case @lab_result.urgency do %>
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
                  {@lab_result.urgency}
                </span>
            <% end %>
          </p>
        </div>

        <div class="bg-gray-50 rounded p-3 border border-gray-100">
          <p class="text-xs text-gray-500 uppercase font-semibold">Description</p>
          <p class="text-gray-900 whitespace-pre-line">{@lab_result.description}</p>
        </div>

        <div class="bg-gray-50 rounded p-3 border border-gray-100">
          <p class="text-xs text-gray-500 uppercase font-semibold">
            Date and Time Test Was Requested
          </p>
          <p class="text-gray-900 whitespace-pre-line">{format_datetime(@lab_result.inserted_at)}</p>
        </div>
      </div>
    </div>
    """
  end

  defp format_datetime(datetime) do
    shifted_datetime = Timex.shift(datetime, hours: 3)
    Timex.format!(shifted_datetime, "{Mfull} {D}, {YYYY} at {h12}:{m} {AM}")
  end

  def complete_lab_result_card(assigns) do
    test_entries = Medcamp.LabTestTemplates.list_entries_for_lab_result(assigns.lab_result.id)

    assigns =
      assigns
      |> assign(:test_entries, test_entries)
      |> assign(:can_generate_ai, has_ai_source_data?(assigns.lab_result, test_entries))

    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-4 mt-4">
      <div class="flex items-center justify-between mb-4 pb-2 border-b border-gray-100">
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
          <h2 class="text-lg font-semibold text-[#373896]">
            Lab Result
          </h2>
        </div>

        <.link navigate={"/lab/lab_results/#{@lab_result.id}?complete=true"}>
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
                  d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
                />
              </svg>
              Edit Lab Result
            </div>
          </.button>
        </.link>
      </div>

      <div class="space-y-4">
        <.patient_overview_card patient={@patient} />
        <div class="mb-4">
          <h3 class="text-sm font-semibold text-[#373896] mb-2">Tests Requested</h3>
          <div class="flex flex-wrap gap-2">
            <%= for test <- @lab_result.tests do %>
              <span class="px-2 py-1 text-xs rounded-full bg-[#f0f0ff] text-[#373896]">
                {test.name}
              </span>
              <.link
                navigate={"/lab/lab_results/#{@lab_result.id}?print_preview=#{test.serial}"}
                class="inline-flex items-center px-3 py-2 border border-blue-300 text-sm leading-4 font-medium rounded-md text-blue-700 bg-white hover:bg-blue-50"
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
                    d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z"
                  />
                </svg>
                Print
              </.link>
            <% end %>
          </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
          <div class="bg-gray-50 rounded p-3 border border-gray-100">
            <p class="text-xs text-gray-500 uppercase font-semibold">Urgency</p>
            <p class="font-medium text-gray-900">
              <%= case @form[:urgency].value do %>
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
                    {@form[:urgency].value}
                  </span>
              <% end %>
            </p>
          </div>

          <div class="bg-gray-50 rounded p-3 border border-gray-100">
            <p class="text-xs text-gray-500 uppercase font-semibold">
              Date and Time Test Was Requested
            </p>
            <p class="text-gray-900 whitespace-pre-line">
              {format_datetime(@lab_result.inserted_at)}
            </p>
          </div>

          <div class="bg-gray-50 rounded p-3 border border-gray-100">
            <p class="text-xs text-gray-500 uppercase font-semibold">Time test was requested</p>
            <div class="flex items-center mt-1">
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
              <span class="text-gray-700">{@form[:time].value}</span>
            </div>
          </div>

          <div class="bg-gray-50 rounded p-3 border border-gray-100">
            <p class="text-xs text-gray-500 uppercase font-semibold">Sample Collection Date</p>
            <div class="flex items-center mt-1">
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
              <span class="text-gray-700">{@form[:sample_collection_date].value}</span>
            </div>
          </div>

          <div class="bg-gray-50 rounded p-3 border border-gray-100">
            <p class="text-xs text-gray-500 uppercase font-semibold">Date of Test</p>
            <div class="flex items-center mt-1">
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
              <span class="text-gray-700">{@form[:date_of_test].value}</span>
            </div>
          </div>
        </div>

        <.lab_interpretation_panel
          lab_result={@lab_result}
          patient={@patient}
          regenerate={true}
          can_generate_ai={@can_generate_ai}
        />

        <div class="bg-[#f8f8ff] rounded-lg p-4 border border-[#e7e7ff] flex items-center">
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
              d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
            />
          </svg>
          <a href={@lab_result.lab_report} target="_blank" class="text-[#373896] hover:underline">
            View Lab Report
          </a>
        </div>

        <%= if @lab_result.lab_report do %>
          <%= for report <- String.split(@lab_result.lab_report, ",") do %>
            <div class="pdf-container h-[70vh] overflow-y-auto bg-gray-100">
              <object data={report} width="100%" height="100%" class="shadow-lg">
                <div class="flex flex-col items-center justify-center h-full p-6 text-center">
                  <i class="fas fa-file-pdf text-red-500 text-5xl mb-4"></i>
                  <p class="text-gray-700 mb-3">
                    Unable to display PDF. Your browser might not support embedded PDFs.
                  </p>

                  <a
                    href={"/uploads/#{Path.basename(report)}"}
                    download
                    class="inline-flex items-center px-3 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-purple-600 hover:bg-purple-700"
                  >
                    <i class="fas fa-download mr-1.5"></i> Download PDF
                  </a>
                </div>
              </object>
            </div>
          <% end %>
        <% end %>

        <div class="space-y-4">
          <div class="bg-gray-50 rounded p-3 border border-gray-100">
            <p class="text-xs text-gray-500 uppercase font-semibold">Description</p>
            <p class="text-gray-900 whitespace-pre-line">{@form[:description].value}</p>
          </div>

          <div class="bg-gray-50 rounded p-3 border border-gray-100">
            <p class="text-xs text-gray-500 uppercase font-semibold">Test Findings</p>
            <p class="text-gray-900 whitespace-pre-line">{@form[:test_findings].value}</p>
          </div>

          <div class="bg-gray-50 rounded p-3 border border-gray-100">
            <p class="text-xs text-gray-500 uppercase font-semibold">Sample Collection Description</p>
            <p class="text-gray-900 whitespace-pre-line">
              {@form[:sample_collection_description].value}
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
