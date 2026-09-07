defmodule MedcampWeb.InPatientComponents do
  @moduledoc """
  Provides core UI components.

  """
  use Phoenix.Component
  use Gettext, backend: MedcampWeb.Gettext

  def inpatient_section(assigns) do
    assigns =
      assign_new(assigns, :note_path, fn ->
        "/doctor/patients/#{assigns.patient.id}/notes/#{assigns.doctor_note.id}"
      end)

    ~H"""
    <div class="space-y-6">
      <!-- Inpatient Sub-tabs -->
      <div class="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
        <div class="border-b border-gray-200 overflow-x-auto">
          <nav class="flex -mb-px" aria-label="Inpatient tabs">
            <%= for {subtab, label} <- [
              {"admission", "Admission Notes"},
              {"continuation", "Continuation Notes"},
              {"treatment", "Treatment Sheet"},
              {"vitals", "Vitals Chart"},
              {"cadex", "CaDex Notes"},
              {"discharge", "Discharge Summary"}
            ] do %>
              <button
                phx-click="change-inpatient-subtab"
                phx-value-subtab={subtab}
                class={"whitespace-nowrap py-3 px-4 border-b-2 font-medium text-sm #{if @inpatient_subtab == subtab, do: "border-[#6667ab] text-[#6667ab]", else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"}"}
              >
                {label}
              </button>
            <% end %>
          </nav>
        </div>
      </div>
      
    <!-- Current Admission Status Banner -->
      <%= if @current_admission do %>
        <div class="bg-green-50 border border-green-200 rounded-lg p-4">
          <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
            <div class="flex items-center">
              <div class="w-10 h-10 rounded-full bg-green-100 flex items-center justify-center mr-3 flex-shrink-0">
                <svg
                  class="w-5 h-5 text-green-600"
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
              </div>
              <div>
                <p class="font-semibold text-green-800">Patient Currently Admitted</p>
                <p class="text-sm text-green-600">
                  Ward: {@current_admission.ward || "N/A"} • Bed: {@current_admission.bed_number ||
                    "N/A"} •
                  Since: {Calendar.strftime(@current_admission.admission_date, "%b %d, %Y")}
                </p>
              </div>
            </div>
            <span class="px-3 py-1 text-xs rounded-full bg-green-100 text-green-800 font-medium self-start sm:self-center">
              Active
            </span>
          </div>
        </div>
      <% else %>
        <div class="bg-gray-50 border border-gray-200 rounded-lg p-4">
          <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
            <div class="flex items-center">
              <div class="w-10 h-10 rounded-full bg-gray-100 flex items-center justify-center mr-3 flex-shrink-0">
                <svg
                  class="w-5 h-5 text-gray-500"
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
              </div>
              <div>
                <p class="font-semibold text-gray-800">Patient Not Currently Admitted</p>
                <p class="text-sm text-gray-500">Create a new admission to start inpatient care</p>
              </div>
            </div>
            <.link
              patch={"#{@note_path}/new_admission?tab=inpatient&subtab=admission"}
              class="inline-flex items-center px-4 py-2 bg-[#6667ab] text-white rounded-lg text-sm font-medium hover:bg-[#5556a0] transition-colors"
            >
              <svg class="w-4 h-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 4v16m8-8H4"
                />
              </svg>
              New Admission
            </.link>
          </div>
        </div>
      <% end %>
      
    <!-- Sub-tab Content -->
      <%= case @inpatient_subtab do %>
        <% "admission" -> %>
          <.admission_notes_card
            admission_notes={@admission_notes}
            current_admission={@current_admission}
            patient={@patient}
            doctor_note={@doctor_note}
            inpatient_subtab={@inpatient_subtab}
            note_path={@note_path}
          />
        <% "continuation" -> %>
          <.continuation_notes_card
            continuation_notes={@continuation_notes}
            current_admission={@current_admission}
            patient={@patient}
            doctor_note={@doctor_note}
            inpatient_subtab={@inpatient_subtab}
            note_path={@note_path}
          />
        <% "treatment" -> %>
          <.treatment_sheet_card
            treatment_sheets={@treatment_sheets}
            current_admission={@current_admission}
            patient={@patient}
            doctor_note={@doctor_note}
            inpatient_subtab={@inpatient_subtab}
            note_path={@note_path}
          />
        <% "vitals" -> %>
          <.vitals_chart_card
            vital_records={@vital_records}
            current_admission={@current_admission}
            patient={@patient}
            doctor_note={@doctor_note}
            inpatient_subtab={@inpatient_subtab}
            note_path={@note_path}
          />
        <% "cadex" -> %>
          <.cadex_notes_card
            cadex_notes={@cadex_notes}
            current_admission={@current_admission}
            patient={@patient}
            doctor_note={@doctor_note}
            inpatient_subtab={@inpatient_subtab}
            note_path={@note_path}
          />
        <% "discharge" -> %>
          <.discharge_summary_card
            discharge_summary={@discharge_summary}
            current_admission={@current_admission}
            patient={@patient}
            doctor_note={@doctor_note}
            inpatient_subtab={@inpatient_subtab}
            note_path={@note_path}
          />
      <% end %>
    </div>
    """
  end

  # =============================================================================
  # ADMISSION NOTES CARD
  # =============================================================================
  def admission_notes_card(assigns) do
    assigns =
      assign_new(assigns, :note_path, fn ->
        "/doctor/patients/#{assigns.patient.id}/notes/#{assigns.doctor_note.id}"
      end)

    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-200">
      <div class="px-4 sm:px-6 py-4 border-b border-gray-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div class="flex items-center">
          <div class="w-8 h-8 rounded-lg bg-[#6667ab] flex items-center justify-center mr-3">
            <svg class="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
              />
            </svg>
          </div>
          <h3 class="text-lg font-semibold text-gray-800">Admission Notes</h3>
        </div>
        <.link
          patch={"#{@note_path}/new_admission?tab=inpatient&subtab=#{@inpatient_subtab || "admission"}"}
          class="inline-flex items-center px-3 py-1.5 bg-[#6667ab] text-white rounded-lg text-sm font-medium hover:bg-[#5556a0] transition-colors"
        >
          <svg class="w-4 h-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
          </svg>
          New Admission
        </.link>
      </div>

      <div class="p-4 sm:p-6">
        <%= if Enum.empty?(@admission_notes) do %>
          <div class="text-center py-8">
            <svg
              class="mx-auto h-12 w-12 text-gray-400"
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
            <p class="mt-2 text-gray-500">No admission records found</p>
          </div>
        <% else %>
          <div class="space-y-4">
            <%= for admission <- @admission_notes do %>
              <div class="border border-gray-200 rounded-lg p-4 hover:bg-gray-50 transition-colors">
                <div class="flex flex-col sm:flex-row sm:items-start justify-between gap-2 mb-3">
                  <div>
                    <p class="font-semibold text-gray-800">
                      {Calendar.strftime(admission.admission_date, "%B %d, %Y")} at {Calendar.strftime(
                        admission.admission_time,
                        "%I:%M %p"
                      )}
                    </p>
                    <p class="text-sm text-gray-500">
                      Ward: {admission.ward || "N/A"} • Bed: {admission.bed_number || "N/A"}
                    </p>
                  </div>
                  <span class="px-2 py-1 text-xs rounded-full bg-blue-100 text-blue-800 font-medium self-start">
                    Dr. {admission.doctor.name}
                  </span>
                </div>

                <%= if admission.complaints do %>
                  <div class="mb-2">
                    <p class="text-xs font-medium text-gray-500 uppercase">Complaints</p>
                    <p class="text-sm text-gray-700">{admission.complaints}</p>
                  </div>
                <% end %>

                <%= if admission.history_of_presenting_illness do %>
                  <div class="mb-2">
                    <p class="text-xs font-medium text-gray-500 uppercase">
                      History of Presenting Illness
                    </p>
                    <p class="text-sm text-gray-700">{admission.history_of_presenting_illness}</p>
                  </div>
                <% end %>

                <%= if admission.physical_examination do %>
                  <div class="mb-2">
                    <p class="text-xs font-medium text-gray-500 uppercase">Physical Examination</p>
                    <p class="text-sm text-gray-700">{admission.physical_examination}</p>
                  </div>
                <% end %>

                <%= if admission.management_plan do %>
                  <div class="mb-2">
                    <p class="text-xs font-medium text-gray-500 uppercase">Management Plan</p>
                    <p class="text-sm text-gray-700">{admission.management_plan}</p>
                  </div>
                <% end %>
                
    <!-- Vitals at admission -->
                <div class="mt-3 pt-3 border-t border-gray-100">
                  <p class="text-xs font-medium text-gray-500 uppercase mb-2">
                    Vital Signs at Admission
                  </p>
                  <div class="grid grid-cols-2 sm:grid-cols-5 gap-2">
                    <div class="bg-gray-50 rounded p-2 text-center">
                      <p class="text-xs text-gray-500">BP</p>
                      <p class="text-sm font-medium">{admission.blood_pressure || "-"}</p>
                    </div>
                    <div class="bg-gray-50 rounded p-2 text-center">
                      <p class="text-xs text-gray-500">Pulse</p>
                      <p class="text-sm font-medium">{admission.pulse_rate || "-"}</p>
                    </div>
                    <div class="bg-gray-50 rounded p-2 text-center">
                      <p class="text-xs text-gray-500">Temp</p>
                      <p class="text-sm font-medium">
                        {if admission.temperature, do: "#{admission.temperature}°C", else: "-"}
                      </p>
                    </div>
                    <div class="bg-gray-50 rounded p-2 text-center">
                      <p class="text-xs text-gray-500">SpO2</p>
                      <p class="text-sm font-medium">
                        {if admission.spo2, do: "#{admission.spo2}%", else: "-"}
                      </p>
                    </div>
                    <div class="bg-gray-50 rounded p-2 text-center col-span-2 sm:col-span-1">
                      <p class="text-xs text-gray-500">RR</p>
                      <p class="text-sm font-medium">{admission.respiratory_rate || "-"}</p>
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

  # =============================================================================
  # CONTINUATION NOTES CARD
  # =============================================================================
  def continuation_notes_card(assigns) do
    assigns =
      assign_new(assigns, :note_path, fn ->
        "/doctor/patients/#{assigns.patient.id}/notes/#{assigns.doctor_note.id}"
      end)

    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-200">
      <div class="px-4 sm:px-6 py-4 border-b border-gray-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div class="flex items-center">
          <div class="w-8 h-8 rounded-lg bg-blue-500 flex items-center justify-center mr-3">
            <svg class="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
              />
            </svg>
          </div>
          <h3 class="text-lg font-semibold text-gray-800">Continuation Notes</h3>
        </div>
        <%= if @current_admission do %>
          <.link
            patch={"#{@note_path}/new_continuation?tab=inpatient&subtab=#{@inpatient_subtab || "continuation"}"}
            class="inline-flex items-center px-3 py-1.5 bg-blue-500 text-white rounded-lg text-sm font-medium hover:bg-blue-600 transition-colors"
          >
            <svg class="w-4 h-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M12 4v16m8-8H4"
              />
            </svg>
            Add Note
          </.link>
        <% end %>
      </div>

      <div class="p-4 sm:p-6">
        <%= if is_nil(@current_admission) do %>
          <div class="text-center py-8 text-gray-500">
            <p>Patient must be admitted to add continuation notes</p>
          </div>
        <% else %>
          <%= if Enum.empty?(@continuation_notes) do %>
            <div class="text-center py-8">
              <svg
                class="mx-auto h-12 w-12 text-gray-400"
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
              <p class="mt-2 text-gray-500">No continuation notes yet</p>
            </div>
          <% else %>
            <div class="space-y-4">
              <%= for note <- @continuation_notes do %>
                <div class="border border-gray-200 rounded-lg p-4">
                  <div class="flex flex-col sm:flex-row sm:items-start justify-between gap-2 mb-3">
                    <div>
                      <p class="font-semibold text-gray-800">
                        {Calendar.strftime(note.review_date, "%B %d, %Y")} at {Calendar.strftime(
                          note.review_time,
                          "%I:%M %p"
                        )}
                      </p>
                      <span class={"inline-block mt-1 px-2 py-0.5 text-xs rounded-full font-medium #{case note.review_type do
                        "Major Ward Round" -> "bg-purple-100 text-purple-800"
                        "Ward Round" -> "bg-blue-100 text-blue-800"
                        _ -> "bg-gray-100 text-gray-800"
                      end}"}>
                        {note.review_type}
                      </span>
                    </div>
                    <span class="text-sm text-gray-500">Dr. {note.doctor.name}</span>
                  </div>

                  <%= if note.complaints do %>
                    <div class="mb-2">
                      <p class="text-xs font-medium text-gray-500 uppercase">Complaints</p>
                      <p class="text-sm text-gray-700">{note.complaints}</p>
                    </div>
                  <% end %>

                  <%= if note.physical_examination do %>
                    <div class="mb-2">
                      <p class="text-xs font-medium text-gray-500 uppercase">Physical Examination</p>
                      <p class="text-sm text-gray-700">{note.physical_examination}</p>
                    </div>
                  <% end %>

                  <%= if note.management_plan do %>
                    <div class="mb-2">
                      <p class="text-xs font-medium text-gray-500 uppercase">Management Plan</p>
                      <p class="text-sm text-gray-700">{note.management_plan}</p>
                    </div>
                  <% end %>
                  
    <!-- Vitals at review -->
                  <div class="mt-3 pt-3 border-t border-gray-100">
                    <p class="text-xs font-medium text-gray-500 uppercase mb-2">Vital Signs</p>
                    <div class="grid grid-cols-2 sm:grid-cols-5 gap-2">
                      <div class="bg-gray-50 rounded p-2 text-center">
                        <p class="text-xs text-gray-500">BP</p>
                        <p class="text-sm font-medium">{note.blood_pressure || "-"}</p>
                      </div>
                      <div class="bg-gray-50 rounded p-2 text-center">
                        <p class="text-xs text-gray-500">Pulse</p>
                        <p class="text-sm font-medium">{note.pulse_rate || "-"}</p>
                      </div>
                      <div class="bg-gray-50 rounded p-2 text-center">
                        <p class="text-xs text-gray-500">Temp</p>
                        <p class="text-sm font-medium">
                          {if note.temperature, do: "#{note.temperature}°C", else: "-"}
                        </p>
                      </div>
                      <div class="bg-gray-50 rounded p-2 text-center">
                        <p class="text-xs text-gray-500">SpO2</p>
                        <p class="text-sm font-medium">
                          {if note.spo2, do: "#{note.spo2}%", else: "-"}
                        </p>
                      </div>
                      <div class="bg-gray-50 rounded p-2 text-center col-span-2 sm:col-span-1">
                        <p class="text-xs text-gray-500">RR</p>
                        <p class="text-sm font-medium">{note.respiratory_rate || "-"}</p>
                      </div>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end

  # =============================================================================
  # TREATMENT SHEET CARD
  # =============================================================================
  def treatment_sheet_card(assigns) do
    assigns =
      assign_new(assigns, :note_path, fn ->
        "/doctor/patients/#{assigns.patient.id}/notes/#{assigns.doctor_note.id}"
      end)

    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-200">
      <div class="px-4 sm:px-6 py-4 border-b border-gray-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div class="flex items-center">
          <div class="w-8 h-8 rounded-lg bg-emerald-500 flex items-center justify-center mr-3">
            <svg class="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4"
              />
            </svg>
          </div>
          <h3 class="text-lg font-semibold text-gray-800">Treatment Sheet</h3>
        </div>
        <%= if @current_admission do %>
          <.link
            patch={"#{@note_path}/new_treatment?tab=inpatient&subtab=#{@inpatient_subtab || "treatment"}"}
            class="inline-flex items-center px-3 py-1.5 bg-emerald-500 text-white rounded-lg text-sm font-medium hover:bg-emerald-600 transition-colors"
          >
            <svg class="w-4 h-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M12 4v16m8-8H4"
              />
            </svg>
            Add Prescription
          </.link>
        <% end %>
      </div>

      <div class="p-4 sm:p-6">
        <%= if is_nil(@current_admission) do %>
          <div class="text-center py-8 text-gray-500">
            <p>Patient must be admitted to manage treatment sheet</p>
          </div>
        <% else %>
          <%= if Enum.empty?(@treatment_sheets) do %>
            <div class="text-center py-8">
              <svg
                class="mx-auto h-12 w-12 text-gray-400"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4"
                />
              </svg>
              <p class="mt-2 text-gray-500">No prescriptions yet</p>
            </div>
          <% else %>
            <!-- Desktop Table -->
            <div class="hidden md:block overflow-x-auto">
              <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                  <tr>
                    <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                      Date/Time
                    </th>
                    <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                      Drug
                    </th>
                    <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                      Route
                    </th>
                    <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                      Dose
                    </th>
                    <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                      Frequency
                    </th>
                    <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                      Prescriber
                    </th>
                    <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                      Given
                    </th>
                    <th class="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase">
                      Actions
                    </th>
                  </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-100">
                  <%= for treatment <- @treatment_sheets do %>
                    <tr class="hover:bg-gray-50">
                      <td class="px-4 py-3 text-sm text-gray-800">
                        {Calendar.strftime(treatment.prescription_date, "%b %d")}
                        <br />
                        <span class="text-xs text-gray-500">
                          {if treatment.prescription_time,
                            do: Calendar.strftime(treatment.prescription_time, "%I:%M %p"),
                            else: "-"}
                        </span>
                      </td>
                      <td class="px-4 py-3">
                        <span class="font-medium text-gray-800">{treatment.drug_name}</span>
                        <span class={"ml-2 px-2 py-0.5 text-xs rounded-full #{case treatment.prescription_type do
                          "Stat" -> "bg-red-100 text-red-800"
                          "Fluids" -> "bg-blue-100 text-blue-800"
                          _ -> "bg-gray-100 text-gray-800"
                        end}"}>
                          {treatment.prescription_type}
                        </span>
                      </td>
                      <td class="px-4 py-3 text-sm text-gray-600">{treatment.route}</td>
                      <td class="px-4 py-3 text-sm text-gray-600">
                        {treatment.dose} {treatment.units}
                      </td>
                      <td class="px-4 py-3 text-sm text-gray-600">{treatment.frequency}</td>
                      <td class="px-4 py-3 text-sm text-gray-600">{treatment.prescriber.name}</td>
                      <td class="px-4 py-3 text-sm">
                        <span class="px-2 py-1 bg-emerald-100 text-emerald-800 rounded-full text-xs font-medium">
                          {length(treatment.administrations || [])}x
                        </span>
                      </td>
                      <td class="px-4 py-3 text-right">
                        <.link
                          patch={"#{@note_path}/treatments/#{treatment.id}/edit?tab=inpatient&subtab=treatment"}
                          class="text-sm text-[#6667ab] hover:text-[#373896] font-medium"
                        >
                          Edit
                        </.link>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
            
    <!-- Mobile Cards -->
            <div class="md:hidden space-y-3">
              <%= for treatment <- @treatment_sheets do %>
                <div class="border border-gray-200 rounded-lg p-4">
                  <div class="flex items-start justify-between mb-2">
                    <div>
                      <p class="font-semibold text-gray-800">{treatment.drug_name}</p>
                      <p class="text-sm text-gray-500">
                        {treatment.dose} {treatment.units} • {treatment.route}
                      </p>
                    </div>
                    <span class={"px-2 py-0.5 text-xs rounded-full #{case treatment.prescription_type do
                      "Stat" -> "bg-red-100 text-red-800"
                      "Fluids" -> "bg-blue-100 text-blue-800"
                      _ -> "bg-gray-100 text-gray-800"
                    end}"}>
                      {treatment.prescription_type}
                    </span>
                  </div>
                  <div class="grid grid-cols-2 gap-2 text-sm">
                    <div>
                      <p class="text-xs text-gray-500">Frequency</p>
                      <p class="text-gray-700">{treatment.frequency}</p>
                    </div>
                    <div>
                      <p class="text-xs text-gray-500">Prescriber</p>
                      <p class="text-gray-700">{treatment.prescriber.name}</p>
                    </div>
                  </div>
                  <div class="mt-2 pt-2 border-t border-gray-100 flex items-center justify-between">
                    <span class="text-xs text-gray-500">
                      {Calendar.strftime(treatment.prescription_date, "%b %d, %Y")}
                    </span>
                    <div class="flex items-center gap-2">
                      <span class="px-2 py-1 bg-emerald-100 text-emerald-800 rounded-full text-xs font-medium">
                        {length(treatment.administrations || [])} administrations
                      </span>
                      <.link
                        patch={"#{@note_path}/treatments/#{treatment.id}/edit?tab=inpatient&subtab=treatment"}
                        class="text-sm text-[#6667ab] hover:text-[#373896] font-medium"
                      >
                        Edit
                      </.link>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end

  # =============================================================================
  # VITALS CHART CARD
  # =============================================================================
  def vitals_chart_card(assigns) do
    assigns =
      assign_new(assigns, :note_path, fn ->
        "/doctor/patients/#{assigns.patient.id}/notes/#{assigns.doctor_note.id}"
      end)

    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-200">
      <div class="px-4 sm:px-6 py-4 border-b border-gray-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div class="flex items-center">
          <div class="w-8 h-8 rounded-lg bg-rose-500 flex items-center justify-center mr-3">
            <svg class="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
              />
            </svg>
          </div>
          <h3 class="text-lg font-semibold text-gray-800">Vital Signs Chart</h3>
        </div>
        <%= if @current_admission do %>
          <.link
            patch={"#{@note_path}/new_vitals?tab=inpatient&subtab=#{@inpatient_subtab || "vitals"}"}
            class="inline-flex items-center px-3 py-1.5 bg-rose-500 text-white rounded-lg text-sm font-medium hover:bg-rose-600 transition-colors"
          >
            <svg class="w-4 h-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M12 4v16m8-8H4"
              />
            </svg>
            Record Vitals
          </.link>
        <% end %>
      </div>

      <div class="p-4 sm:p-6">
        <%= if is_nil(@current_admission) do %>
          <div class="text-center py-8 text-gray-500">
            <p>Patient must be admitted to record vitals</p>
          </div>
        <% else %>
          <%= if Enum.empty?(@vital_records) do %>
            <div class="text-center py-8">
              <svg
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
              <p class="mt-2 text-gray-500">No vital records yet</p>
            </div>
          <% else %>
            <!-- Desktop Table -->
            <div class="hidden md:block overflow-x-auto">
              <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                  <tr>
                    <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                      Date/Time
                    </th>
                    <th class="px-4 py-3 text-center text-xs font-medium text-gray-500 uppercase">
                      BP (mmHg)
                    </th>
                    <th class="px-4 py-3 text-center text-xs font-medium text-gray-500 uppercase">
                      Pulse (B/Min)
                    </th>
                    <th class="px-4 py-3 text-center text-xs font-medium text-gray-500 uppercase">
                      Temp (°C)
                    </th>
                    <th class="px-4 py-3 text-center text-xs font-medium text-gray-500 uppercase">
                      SpO2 (%)
                    </th>
                    <th class="px-4 py-3 text-center text-xs font-medium text-gray-500 uppercase">
                      RR (Br/Min)
                    </th>
                    <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                      Recorded By
                    </th>
                  </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-100">
                  <%= for vital <- @vital_records do %>
                    <tr class="hover:bg-gray-50">
                      <td class="px-4 py-3 text-sm text-gray-800">
                        {Calendar.strftime(vital.recorded_date, "%b %d, %Y")}
                        <br />
                        <span class="text-xs text-gray-500">
                          {Calendar.strftime(vital.recorded_time, "%I:%M %p")}
                        </span>
                      </td>
                      <td class="px-4 py-3 text-center text-sm font-medium">
                        {vital.blood_pressure || "-"}
                      </td>
                      <td class="px-4 py-3 text-center text-sm font-medium">
                        {vital.pulse_rate || "-"}
                      </td>
                      <td class="px-4 py-3 text-center text-sm font-medium">
                        {if vital.temperature, do: "#{vital.temperature}", else: "-"}
                      </td>
                      <td class="px-4 py-3 text-center text-sm font-medium">{vital.spo2 || "-"}</td>
                      <td class="px-4 py-3 text-center text-sm font-medium">
                        {vital.respiratory_rate || "-"}
                      </td>
                      <td class="px-4 py-3 text-sm text-gray-600">{vital.recorded_by.name}</td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
            
    <!-- Mobile Cards -->
            <div class="md:hidden space-y-3">
              <%= for vital <- @vital_records do %>
                <div class="border border-gray-200 rounded-lg p-4">
                  <div class="flex items-center justify-between mb-3">
                    <div>
                      <p class="font-semibold text-gray-800">
                        {Calendar.strftime(vital.recorded_date, "%b %d, %Y")}
                      </p>
                      <p class="text-sm text-gray-500">
                        {Calendar.strftime(vital.recorded_time, "%I:%M %p")}
                      </p>
                    </div>
                    <span class="text-xs text-gray-500">{vital.recorded_by.name}</span>
                  </div>
                  <div class="grid grid-cols-3 gap-2">
                    <div class="bg-rose-50 rounded p-2 text-center">
                      <p class="text-xs text-rose-600">BP</p>
                      <p class="text-sm font-semibold text-rose-800">{vital.blood_pressure || "-"}</p>
                    </div>
                    <div class="bg-blue-50 rounded p-2 text-center">
                      <p class="text-xs text-blue-600">Pulse</p>
                      <p class="text-sm font-semibold text-blue-800">{vital.pulse_rate || "-"}</p>
                    </div>
                    <div class="bg-amber-50 rounded p-2 text-center">
                      <p class="text-xs text-amber-600">Temp</p>
                      <p class="text-sm font-semibold text-amber-800">
                        {if vital.temperature, do: "#{vital.temperature}°", else: "-"}
                      </p>
                    </div>
                    <div class="bg-emerald-50 rounded p-2 text-center">
                      <p class="text-xs text-emerald-600">SpO2</p>
                      <p class="text-sm font-semibold text-emerald-800">
                        {if vital.spo2, do: "#{vital.spo2}%", else: "-"}
                      </p>
                    </div>
                    <div class="bg-slate-50 rounded p-2 text-center col-span-2">
                      <p class="text-xs text-purple-600">Respiratory Rate</p>
                      <p class="text-sm font-semibold text-purple-800">
                        {vital.respiratory_rate || "-"}
                      </p>
                    </div>
                  </div>
                  <%= if vital.remarks do %>
                    <div class="mt-2 pt-2 border-t border-gray-100">
                      <p class="text-xs text-gray-500">Remarks: {vital.remarks}</p>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end

  # =============================================================================
  # CADEX NOTES CARD
  # =============================================================================
  def cadex_notes_card(assigns) do
    assigns =
      assign_new(assigns, :note_path, fn ->
        "/doctor/patients/#{assigns.patient.id}/notes/#{assigns.doctor_note.id}"
      end)

    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-200">
      <div class="px-4 sm:px-6 py-4 border-b border-gray-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div class="flex items-center">
          <div class="w-8 h-8 rounded-lg bg-[#6667ab] flex items-center justify-center mr-3">
            <svg class="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
              />
            </svg>
          </div>
          <h3 class="text-lg font-semibold text-gray-800">CaDex Notes</h3>
        </div>
        <%= if @current_admission do %>
          <.link
            patch={"#{@note_path}/new_cadex?tab=inpatient&subtab=#{@inpatient_subtab || "cadex"}"}
            class="inline-flex items-center px-3 py-1.5 bg-[#6667ab] text-white rounded-lg text-sm font-medium hover:bg-[#5556a0] transition-colors"
          >
            <svg class="w-4 h-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M12 4v16m8-8H4"
              />
            </svg>
            Add CaDex Note
          </.link>
        <% end %>
      </div>

      <div class="p-4 sm:p-6">
        <%= if is_nil(@current_admission) do %>
          <div class="text-center py-8 text-gray-500">
            <p>Patient must be admitted to add CaDex notes</p>
          </div>
        <% else %>
          <%= if Enum.empty?(@cadex_notes) do %>
            <div class="text-center py-8">
              <svg
                class="mx-auto h-12 w-12 text-gray-400"
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
              <p class="mt-2 text-gray-500">No CaDex notes yet for this admission</p>
            </div>
          <% else %>
            <div class="space-y-4">
              <%= for note <- @cadex_notes do %>
                <div class="border border-gray-200 rounded-lg p-4 hover:bg-gray-50 transition-colors">
                  <div class="flex flex-col sm:flex-row sm:items-start justify-between gap-2 mb-3">
                    <div>
                      <p class="font-semibold text-gray-800">
                        {Calendar.strftime(note.note_date, "%B %d, %Y")} at {Calendar.strftime(
                          note.note_time,
                          "%I:%M %p"
                        )}
                      </p>
                      <span class="text-sm text-gray-500">Nurse: {note.nurse.name}</span>
                    </div>
                    <.link
                      patch={"#{@note_path}/cadex/#{note.id}/edit?tab=inpatient&subtab=#{@inpatient_subtab || "cadex"}"}
                      class="text-sm text-[#6667ab] hover:text-[#373896] font-medium"
                    >
                      Edit
                    </.link>
                  </div>
                  <p class="text-sm text-gray-700 whitespace-pre-wrap">{note.note}</p>
                </div>
              <% end %>
            </div>
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end

  # =============================================================================
  # DISCHARGE SUMMARY CARD
  # =============================================================================
  def discharge_summary_card(assigns) do
    assigns =
      assign_new(assigns, :note_path, fn ->
        "/doctor/patients/#{assigns.patient.id}/notes/#{assigns.doctor_note.id}"
      end)

    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-200">
      <div class="px-4 sm:px-6 py-4 border-b border-gray-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div class="flex items-center">
          <div class="w-8 h-8 rounded-lg bg-amber-500 flex items-center justify-center mr-3">
            <svg class="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
              />
            </svg>
          </div>
          <h3 class="text-lg font-semibold text-gray-800">Discharge Summary</h3>
        </div>
        <%= if @current_admission && is_nil(@discharge_summary) do %>
          <.link
            patch={"#{@note_path}/new_discharge?tab=inpatient&subtab=#{@inpatient_subtab || "discharge"}"}
            class="inline-flex items-center px-3 py-1.5 bg-amber-500 text-white rounded-lg text-sm font-medium hover:bg-amber-600 transition-colors"
          >
            <svg class="w-4 h-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M12 4v16m8-8H4"
              />
            </svg>
            Create Discharge
          </.link>
        <% end %>
      </div>

      <div class="p-4 sm:p-6">
        <%= if is_nil(@current_admission) do %>
          <div class="text-center py-8 text-gray-500">
            <p>Patient must be admitted to create discharge summary</p>
          </div>
        <% else %>
          <%= if is_nil(@discharge_summary) do %>
            <div class="text-center py-8">
              <svg
                class="mx-auto h-12 w-12 text-gray-400"
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
              <p class="mt-2 text-gray-500">No discharge summary yet</p>
              <p class="text-sm text-gray-400">Patient is still admitted</p>
            </div>
          <% else %>
            <div class="space-y-4">
              <!-- Header -->
              <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-4 border-b border-gray-100">
                <div>
                  <p class="font-semibold text-gray-800">
                    Discharged on {Calendar.strftime(@discharge_summary.discharge_date, "%B %d, %Y")}
                  </p>
                  <p class="text-sm text-gray-500">By Dr. {@discharge_summary.doctor.name}</p>
                </div>
                <button
                  type="button"
                  onclick="window.print()"
                  class="inline-flex items-center px-3 py-1.5 bg-gray-100 text-gray-700 rounded-lg text-sm font-medium hover:bg-gray-200 transition-colors"
                >
                  <svg class="w-4 h-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z"
                    />
                  </svg>
                  Print
                </button>
              </div>
              
    <!-- Diagnosis -->
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <%= if @discharge_summary.admission_diagnosis do %>
                  <div class="bg-blue-50 rounded-lg p-4 border-l-4 border-blue-400">
                    <p class="text-xs font-medium text-blue-600 uppercase mb-1">
                      Admission Diagnosis
                    </p>
                    <p class="text-sm text-gray-700">{@discharge_summary.admission_diagnosis}</p>
                  </div>
                <% end %>
                <div class="bg-emerald-50 rounded-lg p-4 border-l-4 border-emerald-400">
                  <p class="text-xs font-medium text-emerald-600 uppercase mb-1">
                    Discharge Diagnosis
                  </p>
                  <p class="text-sm text-gray-700">{@discharge_summary.discharge_diagnosis}</p>
                </div>
              </div>
              
    <!-- Clinical History -->
              <%= if @discharge_summary.clinical_history do %>
                <div class="bg-gray-50 rounded-lg p-4">
                  <p class="text-xs font-medium text-gray-500 uppercase mb-1">
                    Clinical History & Physical Examination
                  </p>
                  <p class="text-sm text-gray-700">{@discharge_summary.clinical_history}</p>
                </div>
              <% end %>
              
    <!-- Procedures & Investigations -->
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <%= if @discharge_summary.procedures_done do %>
                  <div class="bg-gray-50 rounded-lg p-4">
                    <p class="text-xs font-medium text-gray-500 uppercase mb-1">Procedures Done</p>
                    <p class="text-sm text-gray-700">{@discharge_summary.procedures_done}</p>
                  </div>
                <% end %>
                <%= if @discharge_summary.lab_investigations do %>
                  <div class="bg-gray-50 rounded-lg p-4">
                    <p class="text-xs font-medium text-gray-500 uppercase mb-1">Lab/Investigations</p>
                    <p class="text-sm text-gray-700">{@discharge_summary.lab_investigations}</p>
                  </div>
                <% end %>
              </div>
              
    <!-- Drugs -->
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <%= if @discharge_summary.drugs_given do %>
                  <div class="bg-slate-50 rounded-lg p-4 border-l-4 border-purple-400">
                    <p class="text-xs font-medium text-purple-600 uppercase mb-1">
                      Drugs & Fluids Given
                    </p>
                    <p class="text-sm text-gray-700">{@discharge_summary.drugs_given}</p>
                  </div>
                <% end %>
                <%= if @discharge_summary.discharge_drugs do %>
                  <div class="bg-amber-50 rounded-lg p-4 border-l-4 border-amber-400">
                    <p class="text-xs font-medium text-amber-600 uppercase mb-1">Discharge Drugs</p>
                    <p class="text-sm text-gray-700">{@discharge_summary.discharge_drugs}</p>
                  </div>
                <% end %>
              </div>
              
    <!-- Follow-up -->
              <%= if @discharge_summary.follow_up_date || @discharge_summary.follow_up_clinic do %>
                <div class="bg-rose-50 rounded-lg p-4 border-l-4 border-rose-400">
                  <p class="text-xs font-medium text-rose-600 uppercase mb-1">Follow-up (TCA)</p>
                  <div class="flex flex-wrap gap-4">
                    <%= if @discharge_summary.follow_up_date do %>
                      <p class="text-sm text-gray-700">
                        <span class="font-medium">Date:</span> {Calendar.strftime(
                          @discharge_summary.follow_up_date,
                          "%B %d, %Y"
                        )}
                      </p>
                    <% end %>
                    <%= if @discharge_summary.follow_up_clinic do %>
                      <p class="text-sm text-gray-700">
                        <span class="font-medium">Clinic:</span> {@discharge_summary.follow_up_clinic}
                      </p>
                    <% end %>
                  </div>
                </div>
              <% end %>
              
    <!-- Doctor Notes -->
              <%= if @discharge_summary.doctor_notes do %>
                <div class="bg-gray-50 rounded-lg p-4">
                  <p class="text-xs font-medium text-gray-500 uppercase mb-1">Additional Notes</p>
                  <p class="text-sm text-gray-700">{@discharge_summary.doctor_notes}</p>
                </div>
              <% end %>
            </div>
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end
end
