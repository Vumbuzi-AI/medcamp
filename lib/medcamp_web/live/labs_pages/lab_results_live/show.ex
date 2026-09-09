defmodule MedcampWeb.LabPagesLabResultLive.Show do
  use MedcampWeb, :lab_live_view

  alias Medcamp.LabResults
  alias Medcamp.LabTestTemplates
  alias Medcamp.Patients

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :lab_results)
     |> assign(:patient, nil)}
  end

  @impl true
  def handle_params(%{"id" => id, "complete" => "true"} = _params, _, socket) do
    lab_result = LabResults.get_lab_result!(id)
    test_entries = LabTestTemplates.list_entries_for_lab_result(id)
    patient = Patients.get_patient!(lab_result.patient_id) |> Patients.Patient.with_age()

    {:noreply,
     socket
     |> assign(:page_title, "Mark as Complete")
     |> assign(:live_action, :complete)
     |> assign(:lab_result, lab_result)
     |> maybe_subscribe_interpretation(lab_result.id)
     |> assign(:test_entries, test_entries)
     |> assign(:patient, patient)
     |> assign_new(:form, fn ->
       to_form(LabResults.change_lab_result(lab_result))
     end)}
  end

  def handle_params(%{"id" => id, "print_preview" => uuid} = _params, _, socket) do
    lab_result = LabResults.get_lab_result!(id)
    test_entries = LabTestTemplates.list_entries_for_lab_result(id)
    patient = Patients.get_patient!(lab_result.patient_id) |> Patients.Patient.with_age()

    {:noreply,
     socket
     |> assign(:page_title, "Print Preview")
     |> assign(:live_action, :print_preview)
     |> assign(:uuid, uuid)
     |> assign(:lab_result, lab_result)
     |> maybe_subscribe_interpretation(lab_result.id)
     |> assign(:test_entries, test_entries)
     |> assign(:patient, patient)
     |> assign_new(:form, fn ->
       to_form(LabResults.change_lab_result(lab_result))
     end)}
  end

  def handle_params(%{"id" => id} = params, _, socket) do
    lab_result = LabResults.get_lab_result!(id)
    test_entries = LabTestTemplates.list_entries_for_lab_result(id)
    patient = Patients.get_patient!(lab_result.patient_id) |> Patients.Patient.with_age()

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:lab_result, lab_result)
     |> maybe_subscribe_interpretation(lab_result.id)
     |> assign(:test_entries, test_entries)
     |> assign(:patient, patient)
     |> assign_new(:form, fn ->
       to_form(LabResults.change_lab_result(lab_result))
     end)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
  end

  defp apply_action(socket, :add_test, _params) do
    socket
  end

  defp apply_action(socket, :fill_results, %{"entry_id" => entry_id}) do
    entry = LabTestTemplates.get_entry!(entry_id)
    template = LabTestTemplates.get_template!(entry.template_id)

    socket
    |> assign(:current_entry, entry)
    |> assign(:current_template, template)
  end

  defp apply_action(socket, :view_results, %{"entry_id" => entry_id}) do
    entry = LabTestTemplates.get_entry!(entry_id)
    template = LabTestTemplates.get_template!(entry.template_id)

    socket
    |> assign(:current_entry, entry)
    |> assign(:current_template, template)
  end

  defp apply_action(socket, :print_gsrn, %{"test_index" => test_index}) do
    test_index = String.to_integer(test_index)
    test = Enum.at(socket.assigns.lab_result.tests, test_index)

    socket
    |> assign(:page_title, "Print GSRN")
    |> assign(:current_test, test)
    |> assign(:test_index, test_index)
  end

  defp apply_action(socket, :print_gsrn, _params) do
    socket
    |> assign(:page_title, "Print GSRN")
  end

  defp apply_action(socket, _, _params) do
    socket
  end

  @impl true
  def handle_info({:test_added, _entry}, socket) do
    # Refresh test entries list
    test_entries = LabTestTemplates.list_entries_for_lab_result(socket.assigns.lab_result.id)

    {:noreply,
     socket
     |> assign(:test_entries, test_entries)}
  end

  def handle_info({:interpretation_updated, %{id: id}}, socket) do
    if socket.assigns.lab_result && socket.assigns.lab_result.id == id do
      {:noreply, assign(socket, :lab_result, LabResults.get_lab_result!(id))}
    else
      {:noreply, socket}
    end
  end

  def handle_info(:close_modal, socket) do
    {:noreply,
     socket
     |> push_navigate(to: ~p"/lab/lab_results/#{socket.assigns.lab_result}")}
  end

  @impl true
  def handle_event("delete_entry", %{"id" => id}, socket) do
    entry = LabTestTemplates.get_entry!(id)

    case LabTestTemplates.delete_entry(entry) do
      {:ok, _} ->
        test_entries = LabTestTemplates.list_entries_for_lab_result(socket.assigns.lab_result.id)

        {:noreply,
         socket
         |> assign(:test_entries, test_entries)
         |> put_flash(:info, "Test removed")}

      {:error, :cannot_delete_completed} ->
        {:noreply,
         socket
         |> put_flash(:error, "Cannot delete a completed test")}
    end
  end

  def handle_event("mark-complete", _params, socket) do
    lab_result = socket.assigns.lab_result

    LabResults.update_lab_result(lab_result, %{"report_complete" => true})

    {:noreply,
     socket
     |> put_flash(:info, "Lab report marked as complete")
     |> push_navigate(to: ~p"/lab/lab_results/#{lab_result}")}
  end

  def handle_event("refresh-interpretation", _params, socket) do
    case LabResults.refresh_lab_result_interpretation(socket.assigns.lab_result) do
      {:ok, lab_result} ->
        {:noreply,
         socket
         |> assign(:lab_result, lab_result)
         |> maybe_subscribe_interpretation(lab_result.id)
         |> put_flash(:info, "Interpretation refreshed")}

      {:error, _reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Could not refresh the interpretation right now")}
    end
  end

  defp maybe_subscribe_interpretation(socket, lab_result_id) do
    if connected?(socket) and socket.assigns[:interpretation_subscription] != lab_result_id do
      LabResults.subscribe_to_interpretation(lab_result_id)
      assign(socket, :interpretation_subscription, lab_result_id)
    else
      socket
    end
  end

  defp page_title(:index), do: "Lab Result Details"
  defp page_title(:add_test), do: "Add Test"
  defp page_title(:fill_results), do: "Fill Results"
  defp page_title(:view_results), do: "View Results"
  defp page_title(:complete), do: "Mark as Complete"
  defp page_title(:print_preview), do: "Print Preview"
  defp page_title(:print_gsrn), do: "Print GSRN"
  defp page_title(_), do: "Lab Result"

  defp format_datetime(datetime) do
    shifted_datetime = Timex.shift(datetime, hours: 3)
    Timex.format!(shifted_datetime, "{Mfull} {D}, {YYYY} at {h12}:{m} {AM}")
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-slate-100 p-6">
      <div :if={@live_action not in [:view_results, :print_preview]}>
        <!-- Header -->
        <.header class="text-brand-primary border-b border-slate-100 pb-4 mb-6">
          <div class="flex items-center">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-6 w-6 mr-3 text-brand-accent"
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
            <div>
              <h1 class="text-xl font-semibold">Lab Result #{@lab_result.id}</h1>
              <p class="text-sm text-slate-600 mt-1">
                Requested: {format_datetime(@lab_result.inserted_at)}
              </p>
            </div>
          </div>
          <:actions>
            <div class="flex items-center gap-2">
              <!-- Mark as Complete Button (only if not already complete) -->
              <%= if !@lab_result.report_complete do %>
                <.button
                  class="bg-green-600 hover:bg-green-700"
                  phx-click="mark-complete"
                  data-confirm-message="Are you sure you want to mark this report as complete?"
                >
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
                        d="M5 13l4 4L19 7"
                      />
                    </svg>
                    Mark as Complete
                  </div>
                </.button>
              <% end %>
              
    <!-- Add Test Button -->
              <.link patch={~p"/lab/lab_results/#{@lab_result}/add_test"}>
                <.button class="bg-brand-accent hover:bg-brand-accent-dark">
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
                    Add Test & Results
                  </div>
                </.button>
              </.link>
            </div>
          </:actions>
        </.header>
        
    <!-- Patient & Doctor Info Cards -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
          <!-- Patient Card -->
          <div class="bg-blue-50 rounded-lg p-4 border border-blue-200">
            <div class="flex items-center">
              <div class="h-12 w-12 rounded-full bg-blue-100 flex items-center justify-center text-blue-600 font-bold text-lg mr-4">
                {String.first(@lab_result.patient.first_name || "?")}
              </div>
              <div>
                <p class="text-sm font-medium text-blue-600">Patient</p>
                <p class="text-lg font-semibold text-blue-900">
                  {format_patient_name(@lab_result.patient)}
                </p>
                <p class="text-sm text-blue-700">
                  {if @lab_result.patient.gender,
                    do: String.capitalize(@lab_result.patient.gender),
                    else: ""}
                  {if @lab_result.patient.date_of_birth,
                    do: " • #{calculate_age(@lab_result.patient.date_of_birth)} years",
                    else: ""}
                </p>
              </div>
            </div>
          </div>
          
    <!-- Doctor Card -->
          <div class="bg-slate-50 rounded-lg p-4 border border-purple-200">
            <div class="flex items-center">
              <div class="h-12 w-12 rounded-full bg-purple-100 flex items-center justify-center text-purple-600 font-bold text-lg mr-4">
                {String.first(@lab_result.doctor.name || "?")}
              </div>
              <div>
                <p class="text-sm font-medium text-purple-600">Referring Doctor</p>
                <p class="text-lg font-semibold text-purple-900">
                  Dr. {@lab_result.doctor.name}
                </p>
              </div>
            </div>
          </div>
        </div>
        
    <!-- Urgency & Status -->
        <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
          <div class="bg-slate-50 rounded-lg p-3 border border-slate-200">
            <p class="text-xs font-medium text-slate-500 uppercase">Urgency</p>
            <div class="mt-1">
              <%= case @lab_result.urgency do %>
                <% "Urgent" -> %>
                  <span class="px-2 py-1 text-sm rounded-full bg-red-100 text-red-800 font-medium">
                    Urgent
                  </span>
                <% "High" -> %>
                  <span class="px-2 py-1 text-sm rounded-full bg-orange-100 text-orange-800 font-medium">
                    High
                  </span>
                <% "Medium" -> %>
                  <span class="px-2 py-1 text-sm rounded-full bg-yellow-100 text-yellow-800 font-medium">
                    Medium
                  </span>
                <% _ -> %>
                  <span class="px-2 py-1 text-sm rounded-full bg-green-100 text-green-800 font-medium">
                    Low
                  </span>
              <% end %>
            </div>
          </div>

          <div class="bg-slate-50 rounded-lg p-3 border border-slate-200">
            <p class="text-xs font-medium text-slate-500 uppercase">Report Status</p>
            <div class="mt-1">
              <%= if @lab_result.report_complete do %>
                <span class="px-2 py-1 text-sm rounded-full bg-green-100 text-green-800 font-medium flex items-center w-fit">
                  <svg class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
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
                <span class="px-2 py-1 text-sm rounded-full bg-yellow-100 text-yellow-800 font-medium flex items-center w-fit">
                  <svg class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                    />
                  </svg>
                  Pending
                </span>
              <% end %>
            </div>
          </div>

          <div class="bg-slate-50 rounded-lg p-3 border border-slate-200">
            <p class="text-xs font-medium text-slate-500 uppercase">Tests Requested</p>
            <p class="mt-1 text-xl font-semibold text-slate-900">{length(@lab_result.tests)}</p>
          </div>

          <div class="bg-slate-50 rounded-lg p-3 border border-slate-200">
            <p class="text-xs font-medium text-slate-500 uppercase">Tests Completed</p>
            <p class="mt-1 text-xl font-semibold text-slate-900">
              {Enum.count(@test_entries, &(&1.status == "completed" || &1.status == "verified"))} / {length(
                @test_entries
              )}
            </p>
          </div>
        </div>
        
    <!-- Originally Requested Tests (from doctor) -->
        <div class="bg-amber-50 rounded-lg p-4 border border-amber-200 mb-6">
          <h3 class="text-sm font-semibold text-amber-800 uppercase tracking-wide mb-3 flex items-center">
            <svg class="h-4 w-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
              />
            </svg>
            Requested Tests (from Doctor)
          </h3>
          <div class="flex flex-wrap gap-2">
            <%= for {test, index} <- Enum.with_index(@lab_result.tests) do %>
              <div class="flex items-center gap-2 px-3 py-1.5 text-sm rounded-lg bg-amber-100 text-amber-800 border border-amber-300">
                <span>{test.name}</span>
                <.link
                  patch={~p"/lab/lab_results/#{@lab_result}/print_gsrn?test_index=#{index}"}
                  class="ml-2 p-1 hover:bg-amber-200 rounded transition-colors"
                  title="Print GSRN for {test.name}"
                >
                  <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z"
                    />
                  </svg>
                </.link>
              </div>
            <% end %>
          </div>
        </div>
        
    <!-- AI Interpretation -->
        <div class="bg-[#f8f8ff] rounded-lg p-4 border border-brand-100 mb-6">
          <div class="flex items-center justify-between mb-3">
            <h3 class="text-sm font-semibold text-brand-primary uppercase tracking-wide flex items-center">
              <svg class="h-4 w-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"
                />
              </svg>
              AI Interpretation
            </h3>
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
                :if={has_test_entries?(@test_entries)}
                phx-click="refresh-interpretation"
                phx-disable-with="Generating..."
                class="group inline-flex items-center px-3 py-1.5 text-xs font-medium text-white bg-brand-accent rounded-lg hover:bg-brand-accent-dark transition-colors disabled:opacity-60 disabled:cursor-not-allowed"
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
                <%= if interpretation_present?(@lab_result.interpretation_payload) do %>
                  Regenerate AI Lab Data
                <% else %>
                  Generate AI Lab Data
                <% end %>
              </button>
            </div>
          </div>

          <%= if interpretation_present?(@lab_result.interpretation_payload) do %>
            <% payload = @lab_result.interpretation_payload %>
            <div class="space-y-4">
              <%= if @lab_result.interpretation_generated_at do %>
                <p class="text-xs text-slate-500">
                  Generated: {format_datetime(@lab_result.interpretation_generated_at)}
                </p>
              <% end %>
              
    <!-- Patient & Clinical Context -->
              <% triage = Map.get(payload, "triage_context", %{}) %>
              <% note = Map.get(payload, "doctor_note_context", %{}) %>
              <div class="bg-white rounded p-3 border border-slate-200">
                <h4 class="text-xs font-semibold text-slate-700 uppercase mb-2">Clinical Context</h4>
                <div class="grid grid-cols-2 md:grid-cols-3 gap-x-4 gap-y-2">
                  <div>
                    <p class="text-xs text-slate-500">Age</p>
                    <p class="text-sm font-medium text-slate-900">
                      {calculate_age(@lab_result.patient.date_of_birth)} years
                    </p>
                  </div>
                  <div>
                    <p class="text-xs text-slate-500">Gender</p>
                    <p class="text-sm font-medium text-slate-900">
                      {if @lab_result.patient.gender,
                        do: String.capitalize(@lab_result.patient.gender),
                        else: "-"}
                    </p>
                  </div>
                  <.context_value label="Temperature" value={Map.get(triage, "temperature")} />
                  <.context_value label="Blood Pressure" value={Map.get(triage, "blood_pressure")} />
                  <.context_value label="Pulse Rate" value={Map.get(triage, "pulse_rate")} />
                  <.context_value
                    label="Oxygen Saturation"
                    value={Map.get(triage, "oxygen_saturation")}
                  />
                  <.context_value label="Emergency Scale" value={Map.get(triage, "emergency_scale")} />
                  <.context_value label="Allergies" value={Map.get(triage, "allergies")} />
                  <.context_value label="Diagnosis" value={Map.get(note, "diagnosis")} />
                </div>
                <%= if present_value?(Map.get(note, "symptoms")) do %>
                  <div class="mt-2 pt-2 border-t border-slate-100">
                    <p class="text-xs text-slate-500">Symptoms</p>
                    <p class="text-sm text-slate-700 whitespace-pre-line">
                      {Map.get(note, "symptoms")}
                    </p>
                  </div>
                <% end %>
              </div>

              <%= if Enum.any?(Map.get(payload, "abnormal_findings", [])) do %>
                <div>
                  <h4 class="text-xs font-semibold text-slate-700 uppercase mb-2">
                    Abnormal Findings
                  </h4>
                  <div class="space-y-2">
                    <%= for finding <- Map.get(payload, "abnormal_findings", []) do %>
                      <div class="bg-white rounded p-3 border border-slate-200">
                        <div class="flex items-center justify-between">
                          <span class="font-medium text-sm text-slate-900">{finding["test"]}</span>
                          <span class={[
                            "text-xs font-bold px-1.5 py-0.5 rounded",
                            case finding["flag"] do
                              "low" -> "bg-blue-100 text-blue-700"
                              "high" -> "bg-red-100 text-red-700"
                              "critical" -> "bg-red-100 text-red-700"
                              _ -> "bg-slate-100 text-slate-700"
                            end
                          ]}>
                            {finding["value"]} {finding["unit"]}
                            <%= if finding["flag"] do %>
                              · {String.upcase(finding["flag"])}
                            <% end %>
                          </span>
                        </div>
                        <%= if finding["reference_range"] do %>
                          <p class="text-xs text-slate-500 mt-1">
                            Range: {finding["reference_range"]}
                          </p>
                        <% end %>
                        <%= if finding["doctor_note"] && finding["doctor_note"] != "" do %>
                          <p class="text-xs text-slate-600 mt-1">{finding["doctor_note"]}</p>
                        <% end %>
                      </div>
                    <% end %>
                  </div>
                </div>
              <% end %>

              <%= if Enum.any?(Map.get(payload, "clinical_interpretation", [])) do %>
                <div>
                  <h4 class="text-xs font-semibold text-slate-700 uppercase mb-2">
                    Clinical Interpretation
                  </h4>
                  <ul class="list-disc list-inside space-y-1">
                    <%= for line <- Map.get(payload, "clinical_interpretation", []) do %>
                      <li class="text-sm text-slate-700">{line}</li>
                    <% end %>
                  </ul>
                </div>
              <% end %>

              <%= if Enum.any?(Map.get(payload, "recommended_attention", [])) do %>
                <div>
                  <h4 class="text-xs font-semibold text-slate-700 uppercase mb-2">
                    Recommended Attention
                  </h4>
                  <ul class="list-disc list-inside space-y-1">
                    <%= for line <- Map.get(payload, "recommended_attention", []) do %>
                      <li class="text-sm text-slate-700">{line}</li>
                    <% end %>
                  </ul>
                </div>
              <% end %>

              <%= if Map.get(payload, "disclaimer") do %>
                <p class="text-xs italic text-slate-500 pt-2 border-t border-brand-100">
                  {payload["disclaimer"]}
                </p>
              <% end %>
            </div>
          <% else %>
            <p class="text-sm text-slate-500">
              <%= if has_test_entries?(@test_entries) do %>
                No interpretation generated yet. Click "Generate AI Lab Data" to generate one.
              <% else %>
                Add lab results before generating AI lab data.
              <% end %>
            </p>
          <% end %>
        </div>
        
    <!-- Test Entries Section -->
        <div class="mt-6">
          <h3 class="text-lg font-semibold text-slate-900 mb-4 flex items-center">
            <svg
              class="h-5 w-5 mr-2 text-brand-accent"
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
            Lab Test Results
          </h3>

          <%= if Enum.empty?(@test_entries) do %>
            <div class="text-center py-8 bg-slate-50 rounded-lg border border-dashed border-slate-300">
              <svg
                class="mx-auto h-12 w-12 text-slate-400"
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
              <h3 class="mt-2 text-sm font-medium text-slate-900">No tests added yet</h3>
              <p class="mt-1 text-sm text-slate-500">
                Click "Add Test & Results" to select a test and record results.
              </p>
              <div class="mt-4">
                <.link patch={~p"/lab/lab_results/#{@lab_result}/add_test"}>
                  <.button class="bg-brand-accent hover:bg-brand-accent-dark">
                    Add First Test
                  </.button>
                </.link>
              </div>
            </div>
          <% else %>
            <div class="space-y-4">
              <%= for entry <- @test_entries do %>
                <.test_entry_card entry={entry} lab_result={@lab_result} />
              <% end %>
            </div>
          <% end %>
        </div>
        
    <!-- Back Link -->
        <div class="mt-6 pt-4 border-t border-slate-200">
          <.back navigate={~p"/lab/lab_results"}>
            Back to lab results
          </.back>
        </div>
      </div>
      
    <!-- Add Test Modal -->
      <.modal
        :if={@live_action == :add_test}
        id="add-test-modal"
        show
        on_cancel={JS.patch(~p"/lab/lab_results/#{@lab_result}")}
      >
        <.live_component
          module={MedcampWeb.LabPagesLabResultLive.TestSelectorComponent}
          id={:test_selector}
          lab_result_id={@lab_result.id}
          patient_name={format_patient_name(@lab_result.patient)}
          doctor_name={@lab_result.doctor.name}
          requested_on={format_datetime(@lab_result.inserted_at)}
          current_user={@current_user}
        />
      </.modal>
      
    <!-- Fill Results Modal -->
      <.modal
        :if={@live_action == :fill_results}
        id="fill-results-modal"
        show
        on_cancel={JS.patch(~p"/lab/lab_results/#{@lab_result}")}
      >
        <.live_component
          module={MedcampWeb.LabPagesLabResultLive.TestEntryFormComponent}
          id={:fill_results}
          entry={@current_entry}
          template={@current_template}
          lab_result_id={@lab_result.id}
          patient_name={format_patient_name(@lab_result.patient)}
          doctor_name={@lab_result.doctor.name}
          requested_on={format_datetime(@lab_result.inserted_at)}
          current_user={@current_user}
          return_to={~p"/lab/lab_results/#{@lab_result}"}
        />
      </.modal>
      
    <!-- Mark as Complete Modal -->
      <.modal
        :if={@live_action == :complete}
        id="complete-modal"
        show
        on_cancel={JS.patch(~p"/lab/lab_results/#{@lab_result}")}
      >
        <.live_component
          module={MedcampWeb.LabPagesLabResultLive.FormComponent}
          id={@lab_result.id || :new}
          title="Mark as Complete"
          action={@live_action}
          current_user={@current_user}
          lab_result={@lab_result}
          patch={~p"/lab/lab_results/#{@lab_result}"}
        />
      </.modal>
      
    <!-- Print Preview Modal -->
      <.modal
        :if={@live_action == :print_preview}
        id="print-preview-modal"
        show
        on_cancel={JS.patch(~p"/lab/lab_results/#{@lab_result}")}
      >
        <.live_component
          module={MedcampWeb.LabPagesLabResultLive.PrintPreviewComponent}
          id={@lab_result.id || :new}
          title="Print Preview"
          uuid={@uuid}
          action={@live_action}
          patient={@patient}
          current_user={@current_user}
          patch={~p"/lab/lab_results/#{@lab_result}"}
        />
      </.modal>
      
    <!-- Print GSRN Modal -->
      <.modal
        :if={@live_action == :print_gsrn && @current_test}
        id="print-gsrn-modal"
        show
        on_cancel={JS.patch(~p"/lab/lab_results/#{@lab_result}")}
      >
        <.live_component
          module={MedcampWeb.LabPagesLabResultLive.GsrnPrintComponent}
          id={:print_gsrn}
          patient={@patient}
          lab_result={@lab_result}
          test={@current_test}
        />
      </.modal>
    </div>

    <!-- View Results Modal (document view) -->
    <.live_component
      :if={@live_action == :view_results}
      module={MedcampWeb.LabPagesLabResultLive.TestResultDocumentComponent}
      id={:view_results}
      entry={@current_entry}
      template={@current_template}
      lab_result={@lab_result}
      patient={@lab_result.patient}
      doctor={@lab_result.doctor}
    />
    """
  end

  # Test Entry Card Component
  defp test_entry_card(assigns) do
    ~H"""
    <div class={[
      "bg-white border rounded-lg p-4 transition-all",
      case @entry.status do
        "completed" -> "border-green-200 bg-green-50/30"
        "verified" -> "border-blue-200 bg-blue-50/30"
        _ -> "border-slate-200"
      end
    ]}>
      <div class="flex items-start justify-between">
        <div class="flex-1">
          <div class="flex items-center gap-3">
            <!-- Status Icon -->
            <div class={[
              "p-2 rounded-lg",
              case @entry.status do
                "completed" -> "bg-green-100"
                "verified" -> "bg-blue-100"
                _ -> "bg-slate-100"
              end
            ]}>
              <%= case @entry.status do %>
                <% "completed" -> %>
                  <svg
                    class="h-5 w-5 text-green-600"
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
                <% "verified" -> %>
                  <svg
                    class="h-5 w-5 text-blue-600"
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
                <% _ -> %>
                  <svg
                    class="h-5 w-5 text-slate-400"
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
              <% end %>
            </div>

            <div>
              <h4 class="font-semibold text-slate-900">{@entry.template.name}</h4>
              <%= if @entry.template.short_name do %>
                <span class="text-xs text-slate-500">({@entry.template.short_name})</span>
              <% end %>
              <div class="flex items-center gap-2 mt-1">
                <span class={[
                  "px-2 py-0.5 text-xs rounded-full font-medium",
                  case @entry.status do
                    "completed" -> "bg-green-100 text-green-800"
                    "verified" -> "bg-blue-100 text-blue-800"
                    "in_progress" -> "bg-yellow-100 text-yellow-800"
                    _ -> "bg-slate-100 text-slate-800"
                  end
                ]}>
                  {String.capitalize(@entry.status)}
                </span>
                <span class="text-xs text-slate-500">
                  {length(@entry.template.field_definitions)} parameters
                </span>
              </div>
            </div>
          </div>
          
    <!-- Results Preview (if completed) -->
          <%= if @entry.status in ["completed", "verified"] && map_size(@entry.results) > 0 do %>
            <div class="mt-3 pt-3 border-t border-slate-100">
              <div class="grid grid-cols-2 md:grid-cols-4 gap-2">
                <%= for {field_name, result_data} <- Enum.take(@entry.results, 4) do %>
                  <% field_def = find_field_def(@entry.template, field_name)

                  has_ref_range? =
                    field_def["ref_range_min"] || field_def["ref_range_max"] ||
                      field_def["ref_range_text"] %>
                  <div class="text-sm">
                    <div>
                      <span class="text-slate-500">{field_def["label"] || field_name}:</span>
                      <span class={[
                        "font-medium ml-1",
                        case result_data["flag"] do
                          "low" -> "text-blue-600"
                          "high" -> "text-red-600"
                          "normal" -> "text-green-700"
                          _ -> "text-slate-900"
                        end
                      ]}>
                        {result_data["value"]}
                        <%= case result_data["flag"] do %>
                          <% "low" -> %>
                            <span class="text-xs ml-0.5 px-1 rounded bg-blue-100 text-blue-700 font-bold">
                              L
                            </span>
                          <% "high" -> %>
                            <span class="text-xs ml-0.5 px-1 rounded bg-red-100 text-red-700 font-bold">
                              H
                            </span>
                          <% "normal" -> %>
                            <%= if has_ref_range? do %>
                              <span class="text-xs ml-0.5 px-1 rounded bg-green-100 text-green-700 font-bold">
                                N
                              </span>
                            <% end %>
                          <% _ -> %>
                        <% end %>
                      </span>
                    </div>
                    <%= if result_data["note"] && result_data["note"] != "" do %>
                      <p class="text-xs italic text-slate-500 mt-0.5 line-clamp-2">
                        {result_data["note"]}
                      </p>
                    <% end %>
                  </div>
                <% end %>
                <%= if map_size(@entry.results) > 4 do %>
                  <div class="text-sm text-slate-500">
                    +{map_size(@entry.results) - 4} more...
                  </div>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>
        
    <!-- Actions -->
        <div class="flex items-center gap-2 ml-4">
          <%= if @entry.status == "pending" do %>
            <.link
              patch={~p"/lab/lab_results/#{@lab_result}/fill/#{@entry.id}"}
              class="px-3 py-1.5 text-sm font-medium text-white bg-brand-accent rounded-lg hover:bg-brand-accent-dark transition-colors flex items-center"
            >
              <svg class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
                />
              </svg>
              Fill Results
            </.link>
            <button
              phx-click="delete_entry"
              phx-value-id={@entry.id}
              data-confirm-message="Are you sure you want to remove this test?"
              class="p-1.5 text-slate-400 hover:text-red-600 rounded-lg hover:bg-red-50 transition-colors"
            >
              <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                />
              </svg>
            </button>
          <% else %>
            <!-- Print Button -->
            <.link
              patch={~p"/lab/lab_results/#{@lab_result}?print_preview=#{@entry.id}"}
              class="px-3 py-1.5 text-sm font-medium text-white bg-amber-600 rounded-lg hover:bg-amber-700 transition-colors flex items-center"
            >
              <svg class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z"
                />
              </svg>
              Print
            </.link>
            <!-- View as Document -->
            <.link
              patch={~p"/lab/lab_results/#{@lab_result}/view/#{@entry.id}"}
              class="px-3 py-1.5 text-sm font-medium text-white bg-teal-600 rounded-lg hover:bg-teal-700 transition-colors flex items-center"
            >
              <svg class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                />
              </svg>
              View Report
            </.link>
            <!-- Edit -->
            <.link
              patch={~p"/lab/lab_results/#{@lab_result}/fill/#{@entry.id}"}
              class="px-3 py-1.5 text-sm font-medium text-brand-accent bg-brand-accent/10 rounded-lg hover:bg-brand-accent/20 transition-colors flex items-center"
            >
              <svg class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
                />
              </svg>
              Edit
            </.link>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp find_field_def(template, field_name) do
    Enum.find(template.field_definitions, %{}, fn f ->
      f["name"] == field_name || f[:name] == field_name
    end)
  end

  defp format_patient_name(patient) do
    [patient.first_name, patient.middle_name, patient.last_name]
    |> Enum.filter(&(&1 != nil))
    |> Enum.join(" ")
  end

  attr :label, :string, required: true
  attr :value, :any, default: nil

  defp context_value(assigns) do
    ~H"""
    <div :if={present_value?(@value)}>
      <p class="text-xs text-slate-500">{@label}</p>
      <p class="text-sm font-medium text-slate-900">{@value}</p>
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

  defp has_test_entries?(test_entries) when is_list(test_entries) do
    Enum.any?(test_entries, &(&1.status in ["completed", "verified"]))
  end

  defp has_test_entries?(_), do: false

  defp calculate_age(nil), do: "-"

  defp calculate_age(date_of_birth) do
    Date.diff(Date.utc_today(), date_of_birth) |> div(365)
  end
end
