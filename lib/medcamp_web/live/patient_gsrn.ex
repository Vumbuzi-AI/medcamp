defmodule MedcampWeb.PatientGSRNLive.Index do
  use MedcampWeb, :live_view

  alias Medcamp.Patients
  alias Medcamp.Triages
  alias Medcamp.DoctorNotes
  alias Medcamp.NurseProcedures
  alias Medcamp.PatientVisits
  alias Medcamp.LabResults
  alias Medcamp.DrugAllocations
  alias Medcamp.Referrals
  alias Medcamp.RadiologyResults
  alias Medcamp.AdmissionRequests
  alias Medcamp.WalletDeposits

  def mount(%{"gsrn" => gsrn}, _session, socket) do
    patient = Patients.get_patient_by_gsrn(gsrn)
    most_recent_triage = Triages.most_recent_triage(patient.id)

    {:ok,
     socket
     |> assign(:patient, patient)
     |> assign(:most_recent_triage, most_recent_triage)
     |> assign(:page_title, "Patient Details")
     |> assign(:show_pin_modal, true)
     |> assign(:pin_input, "")
     |> assign(:pin_error, nil)
     |> assign(:active_tab, :overview)
     |> assign(:mobile_menu_open, false)
     |> assign(:expanded_sections, MapSet.new())
     |> assign(:doctor_notes, DoctorNotes.doctor_notes_for_patient(patient.id))
     |> assign(:lab_results, LabResults.list_lab_results_for_patient(patient.id))
     |> assign(:triages, Triages.list_triages_by_patient(patient.id))
     |> assign(:nurse_procedures, NurseProcedures.list_nurse_procedures_for_patient(patient.id))
     |> assign(:patient_visits, PatientVisits.list_patient_visits_by_patient_id(patient.id))
     |> assign(:drug_allocations, DrugAllocations.list_drug_allocations_for_a_patient(patient.id))
     |> assign(:referrals, Referrals.list_referrals_for_a_patient(patient.id))
     |> assign(
       :radiology_results,
       RadiologyResults.list_radiology_results_by_patient_id(patient.id)
     )
     |> assign(
       :admission_requests,
       AdmissionRequests.list_admission_requests_by_patient_id(patient.id)
     )
     |> assign(
       :wallet_statistics,
       WalletDeposits.get_wallet_statistics_for_patient(patient.id)
     )
     |> assign(
       :wallet_deposits,
       WalletDeposits.list_wallet_deposits_with_usage_for_patient(patient.id)
     )}
  end

  def handle_event("pin-input", %{"pin" => pin}, socket) do
    {:noreply, assign(socket, :pin_input, pin)}
  end

  def handle_event("verify-pin", _, socket) do
    patient = socket.assigns.patient

    pin_input =
      socket.assigns.pin_input
      |> String.to_integer()

    if pin_input == patient.pin do
      {:noreply,
       socket
       |> assign(:show_pin_modal, false)}
    else
      {:noreply, assign(socket, :pin_error, "Incorrect PIN. Please try again.")}
    end
  end

  def handle_event("switch-tab", %{"tab" => tab}, socket) do
    {:noreply,
     socket
     |> assign(:active_tab, String.to_atom(tab))
     |> assign(:mobile_menu_open, false)}
  end

  def handle_event("toggle-mobile-menu", _, socket) do
    {:noreply, assign(socket, :mobile_menu_open, !socket.assigns.mobile_menu_open)}
  end

  def handle_event("toggle-section", %{"id" => id}, socket) do
    expanded = socket.assigns.expanded_sections

    new_expanded =
      if MapSet.member?(expanded, id) do
        MapSet.delete(expanded, id)
      else
        MapSet.put(expanded, id)
      end

    {:noreply, assign(socket, :expanded_sections, new_expanded)}
  end

  defp section_expanded?(assigns, id) do
    MapSet.member?(assigns.expanded_sections, id)
  end

  def render(assigns) do
    ~H"""
    <style>
      /* Custom scrollbar */
      .custom-scrollbar::-webkit-scrollbar {
        width: 6px;
        height: 6px;
      }
      .custom-scrollbar::-webkit-scrollbar-track {
        background: #f1f5f9;
        border-radius: 3px;
      }
      .custom-scrollbar::-webkit-scrollbar-thumb {
        background: #cbd5e1;
        border-radius: 3px;
      }
      .custom-scrollbar::-webkit-scrollbar-thumb:hover {
        background: #94a3b8;
      }

      /* Smooth transitions */
      .tab-transition {
        transition: all 0.2s ease-in-out;
      }

      /* Collapse animation */
      .collapsible-content {
        transition: max-height 0.3s ease-out, opacity 0.2s ease-out;
        overflow: hidden;
      }

      /* Card hover effect */
      .card-hover {
        transition: transform 0.2s ease, box-shadow 0.2s ease;
      }
      .card-hover:hover {
        transform: translateY(-2px);
        box-shadow: 0 8px 25px -5px rgba(0, 0, 0, 0.1);
      }

      /* Chevron rotation */
      .chevron-rotate {
        transition: transform 0.2s ease;
      }
      .chevron-rotate.expanded {
        transform: rotate(180deg);
      }

      /* Mobile tab indicator */
      @media (max-width: 768px) {
        .mobile-tab-active {
          background: linear-gradient(135deg, #6667ab 0%, #8384c9 100%);
        }
      }

      /* Pulse animation for status badges */
      @keyframes pulse-soft {
        0%, 100% { opacity: 1; }
        50% { opacity: 0.7; }
      }
      .pulse-badge {
        animation: pulse-soft 2s ease-in-out infinite;
      }
    </style>

    <div class="min-h-screen bg-gradient-to-br from-slate-50 via-white to-slate-100">
      <!-- PIN Modal -->
      <%= if @show_pin_modal do %>
        <div class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div class="bg-white p-6 sm:p-8 rounded-2xl shadow-2xl max-w-md w-full border border-slate-200">
            <div class="text-center mb-6">
              <div class="w-16 h-16 bg-gradient-to-br from-[#6667ab] to-[#8384c9] rounded-full flex items-center justify-center mx-auto mb-4">
                <svg class="w-8 h-8 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
                  />
                </svg>
              </div>
              <h2 class="text-2xl font-bold text-slate-800">Patient Verification</h2>
              <p class="text-slate-500 mt-2">Enter your PIN to access medical records</p>
            </div>

            <form phx-submit="verify-pin" class="space-y-4">
              <div>
                <label for="pin" class="block text-sm font-medium text-slate-700 mb-2">
                  Security PIN
                </label>
                <input
                  type="password"
                  inputmode="numeric"
                  id="pin"
                  name="pin"
                  placeholder="••••"
                  value={@pin_input}
                  phx-change="pin-input"
                  class="w-full px-4 py-3 text-center text-2xl tracking-[0.5em] border-2 border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#6667ab] focus:border-transparent transition-all"
                  maxlength="4"
                  required
                  autocomplete="off"
                />
                <%= if @pin_error do %>
                  <div class="mt-3 flex items-center justify-center text-red-500 text-sm">
                    <svg class="w-4 h-4 mr-1" fill="currentColor" viewBox="0 0 20 20">
                      <path
                        fill-rule="evenodd"
                        d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z"
                        clip-rule="evenodd"
                      />
                    </svg>
                    {@pin_error}
                  </div>
                <% end %>
              </div>

              <button
                type="submit"
                class="w-full bg-gradient-to-r from-[#6667ab] to-[#7a7bc4] text-white px-6 py-3 rounded-xl font-semibold hover:from-[#5556a0] hover:to-[#6a6bb4] transition-all shadow-lg shadow-[#6667ab]/25 active:scale-[0.98]"
              >
                Verify & Continue
              </button>
            </form>
          </div>
        </div>
      <% end %>

      <.navbar_user />

      <div class={"transition-all duration-300 #{if @show_pin_modal, do: "blur-md pointer-events-none", else: ""}"}>
        <!-- Main Content Container -->
        <div class="w-[90%] mx-auto  px-4 sm:px-6 lg:px-8 py-6">
          <.patient_overview_to_show_all
            most_recent_triage={@most_recent_triage}
            patient={@patient}
            back_url="/"
          />
          
    <!-- Tab Navigation Card -->
          <div class="bg-white rounded-2xl shadow-sm border border-slate-200 mt-6 overflow-hidden">
            <!-- Desktop Tab Navigation -->
            <div class="hidden md:block border-b border-slate-200">
              <nav class="flex overflow-x-auto custom-scrollbar" aria-label="Tabs">
                <.tab_button
                  active={@active_tab == :overview}
                  tab="overview"
                  icon="home"
                  label="Overview"
                />
                <.tab_button
                  active={@active_tab == :triages}
                  tab="triages"
                  icon="clipboard"
                  label="Triages"
                />
                <.tab_button
                  active={@active_tab == :doctor_notes}
                  tab="doctor_notes"
                  icon="document"
                  label="Doctor Notes"
                />
                <.tab_button
                  active={@active_tab == :nurse_procedures}
                  tab="nurse_procedures"
                  icon="medical"
                  label="Procedures"
                />
                <.tab_button
                  active={@active_tab == :lab_results}
                  tab="lab_results"
                  icon="beaker"
                  label="Lab Results"
                />
                <.tab_button
                  active={@active_tab == :patient_visits}
                  tab="patient_visits"
                  icon="calendar"
                  label="Visits"
                />
                <.tab_button
                  active={@active_tab == :drug_allocations}
                  tab="drug_allocations"
                  icon="pill"
                  label="Medications"
                />
                <.tab_button
                  active={@active_tab == :wallet}
                  tab="wallet"
                  icon="wallet"
                  label="Wallet"
                />
              </nav>
            </div>
            
    <!-- Mobile Tab Navigation -->
            <div class="md:hidden border-b border-slate-200">
              <button
                phx-click="toggle-mobile-menu"
                class="w-full px-4 py-4 flex items-center justify-between text-left"
              >
                <div class="flex items-center space-x-3">
                  <div class="w-10 h-10 rounded-xl bg-gradient-to-br from-[#6667ab] to-[#8384c9] flex items-center justify-center">
                    <.tab_icon icon={tab_icon_name(@active_tab)} class="w-5 h-5 text-white" />
                  </div>
                  <div>
                    <p class="text-sm text-slate-500">Current Section</p>
                    <p class="font-semibold text-slate-800">{tab_label(@active_tab)}</p>
                  </div>
                </div>
                <svg
                  class={"w-5 h-5 text-slate-400 chevron-rotate #{if @mobile_menu_open, do: "expanded"}"}
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M19 9l-7 7-7-7"
                  />
                </svg>
              </button>

              <%= if @mobile_menu_open do %>
                <div class="border-t border-slate-100 bg-slate-50 py-2">
                  <.mobile_tab_item
                    active={@active_tab == :overview}
                    tab="overview"
                    icon="home"
                    label="Overview"
                  />
                  <.mobile_tab_item
                    active={@active_tab == :triages}
                    tab="triages"
                    icon="clipboard"
                    label="Triages"
                  />
                  <.mobile_tab_item
                    active={@active_tab == :doctor_notes}
                    tab="doctor_notes"
                    icon="document"
                    label="Doctor Notes"
                  />
                  <.mobile_tab_item
                    active={@active_tab == :nurse_procedures}
                    tab="nurse_procedures"
                    icon="medical"
                    label="Procedures"
                  />
                  <.mobile_tab_item
                    active={@active_tab == :lab_results}
                    tab="lab_results"
                    icon="beaker"
                    label="Lab Results"
                  />
                  <.mobile_tab_item
                    active={@active_tab == :patient_visits}
                    tab="patient_visits"
                    icon="calendar"
                    label="Visits"
                  />
                  <.mobile_tab_item
                    active={@active_tab == :drug_allocations}
                    tab="drug_allocations"
                    icon="pill"
                    label="Medications"
                  />
                  <.mobile_tab_item
                    active={@active_tab == :wallet}
                    tab="wallet"
                    icon="wallet"
                    label="Wallet"
                  />
                </div>
              <% end %>
            </div>
            
    <!-- Tab Content -->
            <div class="p-4 sm:p-6">
              <%= case @active_tab do %>
                <% :overview -> %>
                  <.patient_detailed_overview
                    patient={@patient}
                    most_recent_triage={@most_recent_triage}
                  />
                <% :triages -> %>
                  <.triages_section
                    triages={@triages}
                    patient={@patient}
                    expanded_sections={@expanded_sections}
                  />
                <% :doctor_notes -> %>
                  <.doctor_notes_section
                    doctor_notes={@doctor_notes}
                    patient={@patient}
                    expanded_sections={@expanded_sections}
                    lab_results={@lab_results}
                    drug_allocations={@drug_allocations}
                    referrals={@referrals}
                    radiology_results={@radiology_results}
                    admission_requests={@admission_requests}
                  />
                <% :nurse_procedures -> %>
                  <.nurse_procedures_section nurse_procedures={@nurse_procedures} patient={@patient} />
                <% :lab_results -> %>
                  <.lab_results_section
                    lab_results={@lab_results}
                    patient={@patient}
                    expanded_sections={@expanded_sections}
                  />
                <% :patient_visits -> %>
                  <.patient_visits_section
                    patient_visits={@patient_visits}
                    patient={@patient}
                    expanded_sections={@expanded_sections}
                  />
                <% :drug_allocations -> %>
                  <.patient_drug_allocations_section
                    drug_allocations={@drug_allocations}
                    patient={@patient}
                    expanded_sections={@expanded_sections}
                  />
                <% :wallet -> %>
                  <.wallet_section
                    wallet_statistics={@wallet_statistics}
                    wallet_deposits={@wallet_deposits}
                  />
              <% end %>
            </div>
          </div>
        </div>
      </div>

      <.footer_user />
    </div>
    """
  end

  # Tab button component for desktop
  defp tab_button(assigns) do
    ~H"""
    <button
      phx-click="switch-tab"
      phx-value-tab={@tab}
      class={"flex items-center space-x-2 px-5 py-4 border-b-2 font-medium text-sm whitespace-nowrap tab-transition #{if @active, do: "border-[#6667ab] text-[#6667ab] bg-[#6667ab]/5", else: "border-transparent text-slate-500 hover:text-slate-700 hover:bg-slate-50"}"}
    >
      <.tab_icon icon={@icon} class="w-4 h-4" />
      <span>{@label}</span>
    </button>
    """
  end

  # Mobile tab item component
  defp mobile_tab_item(assigns) do
    ~H"""
    <button
      phx-click="switch-tab"
      phx-value-tab={@tab}
      class={"w-full flex items-center space-x-3 px-4 py-3 text-left transition-colors #{if @active, do: "bg-[#6667ab]/10 text-[#6667ab]", else: "text-slate-600 hover:bg-slate-100"}"}
    >
      <.tab_icon icon={@icon} class="w-5 h-5" />
      <span class="font-medium">{@label}</span>
      <%= if @active do %>
        <svg class="w-4 h-4 ml-auto" fill="currentColor" viewBox="0 0 20 20">
          <path
            fill-rule="evenodd"
            d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
            clip-rule="evenodd"
          />
        </svg>
      <% end %>
    </button>
    """
  end

  # Tab icon component
  defp tab_icon(assigns) do
    ~H"""
    <%= case @icon do %>
      <% "home" -> %>
        <svg class={@class} fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"
          />
        </svg>
      <% "clipboard" -> %>
        <svg class={@class} fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
          />
        </svg>
      <% "document" -> %>
        <svg class={@class} fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
          />
        </svg>
      <% "medical" -> %>
        <svg class={@class} fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"
          />
        </svg>
      <% "beaker" -> %>
        <svg class={@class} fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"
          />
        </svg>
      <% "calendar" -> %>
        <svg class={@class} fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
          />
        </svg>
      <% "pill" -> %>
        <svg class={@class} fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4"
          />
        </svg>
      <% "wallet" -> %>
        <svg class={@class} fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-2m0-6h4v6h-4a2 2 0 110-6z"
          />
        </svg>
      <% _ -> %>
        <svg class={@class} fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M4 6h16M4 12h16M4 18h16"
          />
        </svg>
    <% end %>
    """
  end

  # Helper functions for tab icons and labels
  defp tab_icon_name(:overview), do: "home"
  defp tab_icon_name(:triages), do: "clipboard"
  defp tab_icon_name(:doctor_notes), do: "document"
  defp tab_icon_name(:nurse_procedures), do: "medical"
  defp tab_icon_name(:lab_results), do: "beaker"
  defp tab_icon_name(:patient_visits), do: "calendar"
  defp tab_icon_name(:drug_allocations), do: "pill"
  defp tab_icon_name(:wallet), do: "wallet"
  defp tab_icon_name(_), do: "home"

  defp tab_label(:overview), do: "Overview"
  defp tab_label(:triages), do: "Triages"
  defp tab_label(:doctor_notes), do: "Doctor Notes"
  defp tab_label(:nurse_procedures), do: "Procedures"
  defp tab_label(:lab_results), do: "Lab Results"
  defp tab_label(:patient_visits), do: "Visits"
  defp tab_label(:drug_allocations), do: "Medications"
  defp tab_label(:wallet), do: "Wallet"
  defp tab_label(_), do: "Overview"

  # Collapsible card component
  defp collapsible_card(assigns) do
    ~H"""
    <div class="bg-white border border-slate-200 rounded-xl overflow-hidden card-hover">
      <button
        phx-click="toggle-section"
        phx-value-id={@id}
        class="w-full px-4 sm:px-6 py-4 flex items-center justify-between text-left bg-gradient-to-r from-slate-50 to-white hover:from-slate-100 hover:to-slate-50 transition-colors"
      >
        <div class="flex items-center space-x-3 min-w-0 flex-1">
          <div class={"w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0 #{@icon_bg}"}>
            {render_slot(@icon)}
          </div>
          <div class="min-w-0 flex-1">
            <h4 class="font-semibold text-slate-800 truncate">{@title}</h4>
            <p class="text-sm text-slate-500 truncate">{@subtitle}</p>
          </div>
        </div>
        <div class="flex items-center space-x-2 flex-shrink-0 ml-4">
          {render_slot(@badges)}
          <svg
            class={"w-5 h-5 text-slate-400 chevron-rotate #{if @expanded, do: "expanded"}"}
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
          </svg>
        </div>
      </button>

      <%= if @expanded do %>
        <div class="border-t border-slate-100">
          {render_slot(@inner_block)}
        </div>
      <% end %>
    </div>
    """
  end

  # Status badge component
  defp status_badge(assigns) do
    color_classes =
      case assigns[:color] do
        "green" -> "bg-emerald-100 text-emerald-700"
        "red" -> "bg-red-100 text-red-700"
        "yellow" -> "bg-amber-100 text-amber-700"
        "orange" -> "bg-orange-100 text-orange-700"
        "blue" -> "bg-blue-100 text-blue-700"
        "purple" -> "bg-purple-100 text-purple-700"
        _ -> "bg-slate-100 text-slate-700"
      end

    assigns = assign(assigns, :color_classes, color_classes)

    ~H"""
    <span class={"inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium #{@color_classes}"}>
      {@label}
    </span>
    """
  end

  # Info row component for details
  defp info_row(assigns) do
    ~H"""
    <div class="flex flex-col sm:flex-row sm:items-center py-2 border-b border-slate-100 last:border-0">
      <span class="text-sm font-medium text-slate-500 sm:w-40 flex-shrink-0">{@label}</span>
      <span class="text-sm text-slate-800 mt-1 sm:mt-0">{@value}</span>
    </div>
    """
  end

  # Empty state component
  defp empty_state(assigns) do
    ~H"""
    <div class="text-center py-12 px-4">
      <div class="w-16 h-16 mx-auto mb-4 rounded-full bg-slate-100 flex items-center justify-center">
        {render_slot(@icon)}
      </div>
      <h3 class="text-lg font-medium text-slate-800 mb-1">{@title}</h3>
      <p class="text-slate-500 max-w-sm mx-auto">{@description}</p>
    </div>
    """
  end

  # Component for detailed patient overview
  defp patient_detailed_overview(assigns) do
    ~H"""
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-4 sm:gap-6">
      <!-- Patient Information Card -->
      <div class="bg-gradient-to-br from-slate-50 to-slate-100 rounded-xl p-4 sm:p-6 border border-slate-200">
        <h3 class="text-lg font-semibold text-slate-800 mb-4 flex items-center">
          <div class="w-8 h-8 rounded-lg bg-[#6667ab] flex items-center justify-center mr-3">
            <svg class="h-4 w-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
              />
            </svg>
          </div>
          Patient Information
        </h3>
        <div class="space-y-1">
          <.info_row
            label="Full Name"
            value={
              [@patient.first_name, @patient.middle_name, @patient.last_name]
              |> Enum.filter(&(&1 != nil))
              |> Enum.join(" ")
            }
          />
          <.info_row label="GSRN" value={@patient.gsrn} />
          <.info_row label="Date of Birth" value={@patient.date_of_birth} />
          <%= if @patient.phone_number do %>
            <.info_row label="Phone" value={@patient.phone_number} />
          <% end %>
        </div>
      </div>
      
    <!-- Most Recent Triage Card -->
      <%= if @most_recent_triage do %>
        <div class="bg-gradient-to-br from-blue-50 to-indigo-50 rounded-xl p-4 sm:p-6 border border-blue-200">
          <h3 class="text-lg font-semibold text-slate-800 mb-4 flex items-center">
            <div class="w-8 h-8 rounded-lg bg-blue-500 flex items-center justify-center mr-3">
              <svg class="h-4 w-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
                />
              </svg>
            </div>
            Latest Triage
          </h3>
          <div class="grid grid-cols-2 gap-3">
            <%= if @most_recent_triage.blood_pressure do %>
              <div class="bg-white/60 rounded-lg p-3 text-center">
                <p class="text-xs text-slate-500 uppercase font-medium">Blood Pressure</p>
                <p class="text-lg font-semibold text-slate-800">
                  {@most_recent_triage.blood_pressure}
                </p>
              </div>
            <% end %>
            <%= if @most_recent_triage.temperature do %>
              <div class="bg-white/60 rounded-lg p-3 text-center">
                <p class="text-xs text-slate-500 uppercase font-medium">Temperature</p>
                <p class="text-lg font-semibold text-slate-800">
                  {@most_recent_triage.temperature}°C
                </p>
              </div>
            <% end %>
            <%= if @most_recent_triage.weight do %>
              <div class="bg-white/60 rounded-lg p-3 text-center">
                <p class="text-xs text-slate-500 uppercase font-medium">Weight</p>
                <p class="text-lg font-semibold text-slate-800">{@most_recent_triage.weight} kg</p>
              </div>
            <% end %>
            <%= if @most_recent_triage.height do %>
              <div class="bg-white/60 rounded-lg p-3 text-center">
                <p class="text-xs text-slate-500 uppercase font-medium">Height</p>
                <p class="text-lg font-semibold text-slate-800">{@most_recent_triage.height} cm</p>
              </div>
            <% end %>
          </div>
          <p class="text-xs text-slate-500 mt-4 text-center">
            Recorded: {Calendar.strftime(@most_recent_triage.inserted_at, "%B %d, %Y at %I:%M %p")}
          </p>
        </div>
      <% else %>
        <div class="bg-slate-50 rounded-xl p-6 border border-slate-200 flex items-center justify-center">
          <p class="text-slate-500">No triage information available</p>
        </div>
      <% end %>
    </div>
    """
  end

  # Component for triages section
  defp triages_section(assigns) do
    ~H"""
    <div>
      <div class="flex items-center justify-between mb-4">
        <h3 class="text-lg font-semibold text-slate-800 flex items-center">
          <div class="w-8 h-8 rounded-lg bg-[#6667ab] flex items-center justify-center mr-3">
            <svg class="h-4 w-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
              />
            </svg>
          </div>
          Triage History
        </h3>
        <span class="text-sm text-slate-500">{length(@triages)} records</span>
      </div>

      <%= if Enum.empty?(@triages) do %>
        <.empty_state
          title="No triage records"
          description="No triage records have been recorded for this patient yet."
        >
          <:icon>
            <svg class="w-8 h-8 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
              />
            </svg>
          </:icon>
        </.empty_state>
      <% else %>
        <!-- Desktop Table View -->
        <div class="hidden md:block overflow-hidden rounded-xl border border-slate-200">
          <table class="min-w-full divide-y divide-slate-200">
            <thead class="bg-slate-50">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">
                  Date
                </th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">
                  Blood Pressure
                </th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">
                  Temperature
                </th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">
                  Weight
                </th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">
                  Height
                </th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-slate-100">
              <%= for triage <- @triages do %>
                <tr class="hover:bg-slate-50 transition-colors">
                  <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-slate-800">
                    {Calendar.strftime(triage.inserted_at, "%b %d, %Y")}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-slate-600">
                    {triage.blood_pressure || "—"}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-slate-600">
                    {if triage.temperature, do: "#{triage.temperature}°C", else: "—"}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-slate-600">
                    {if triage.weight, do: "#{triage.weight} kg", else: "—"}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-slate-600">
                    {if triage.height, do: "#{triage.height} cm", else: "—"}
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
        
    <!-- Mobile Card View -->
        <div class="md:hidden space-y-3">
          <%= for {triage, index} <- Enum.with_index(@triages) do %>
            <.collapsible_card
              id={"triage-#{index}"}
              title={Calendar.strftime(triage.inserted_at, "%b %d, %Y")}
              subtitle="Triage Record"
              icon_bg="bg-blue-100"
              expanded={section_expanded?(assigns, "triage-#{index}")}
            >
              <:icon>
                <svg
                  class="w-5 h-5 text-blue-600"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
                  />
                </svg>
              </:icon>
              <:badges></:badges>
              <div class="p-4 grid grid-cols-2 gap-3">
                <div class="bg-slate-50 rounded-lg p-3 text-center">
                  <p class="text-xs text-slate-500 uppercase">Blood Pressure</p>
                  <p class="text-sm font-semibold text-slate-800">{triage.blood_pressure || "—"}</p>
                </div>
                <div class="bg-slate-50 rounded-lg p-3 text-center">
                  <p class="text-xs text-slate-500 uppercase">Temperature</p>
                  <p class="text-sm font-semibold text-slate-800">
                    {if triage.temperature, do: "#{triage.temperature}°C", else: "—"}
                  </p>
                </div>
                <div class="bg-slate-50 rounded-lg p-3 text-center">
                  <p class="text-xs text-slate-500 uppercase">Weight</p>
                  <p class="text-sm font-semibold text-slate-800">
                    {if triage.weight, do: "#{triage.weight} kg", else: "—"}
                  </p>
                </div>
                <div class="bg-slate-50 rounded-lg p-3 text-center">
                  <p class="text-xs text-slate-500 uppercase">Height</p>
                  <p class="text-sm font-semibold text-slate-800">
                    {if triage.height, do: "#{triage.height} cm", else: "—"}
                  </p>
                </div>
              </div>
            </.collapsible_card>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  # Component for lab results section with inline test results
  defp lab_results_section(assigns) do
    ~H"""
    <div>
      <div class="flex items-center justify-between mb-4">
        <h3 class="text-lg font-semibold text-slate-800 flex items-center">
          <div class="w-8 h-8 rounded-lg bg-emerald-500 flex items-center justify-center mr-3">
            <svg class="h-4 w-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"
              />
            </svg>
          </div>
          Lab Results
        </h3>
        <span class="text-sm text-slate-500">{length(@lab_results)} results</span>
      </div>

      <%= if Enum.empty?(@lab_results) do %>
        <.empty_state
          title="No lab results"
          description="No lab results have been recorded for this patient yet."
        >
          <:icon>
            <svg class="w-8 h-8 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"
              />
            </svg>
          </:icon>
        </.empty_state>
      <% else %>
        <div class="space-y-3">
          <%= for {lab_result, index} <- Enum.with_index(@lab_results) do %>
            <% test_entries = Medcamp.LabTestTemplates.list_entries_for_lab_result(lab_result.id) %>
            <.collapsible_card
              id={"lab-#{index}"}
              title={"Lab Result ##{lab_result.id}"}
              subtitle={"Requested: #{Calendar.strftime(lab_result.inserted_at, "%B %d, %Y")}"}
              icon_bg="bg-emerald-100"
              expanded={section_expanded?(assigns, "lab-#{index}")}
            >
              <:icon>
                <svg
                  class="w-5 h-5 text-emerald-600"
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
              </:icon>
              <:badges>
                <%= if lab_result.report_complete do %>
                  <.status_badge label="Complete" color="green" />
                <% else %>
                  <.status_badge label="Pending" color="yellow" />
                <% end %>
                <span class="text-xs text-slate-500">
                  {count_completed_tests(test_entries)}/{length(lab_result.tests)}
                </span>
              </:badges>
              <div class="p-4 space-y-4">
                <!-- Doctor & Urgency -->
                <div class="flex flex-wrap items-center gap-2 text-sm">
                  <span class="text-slate-500">Dr. {lab_result.doctor.name}</span>
                  <span class="text-slate-300">•</span>
                  <%= case lab_result.urgency do %>
                    <% "Urgent" -> %>
                      <.status_badge label="Urgent" color="red" />
                    <% "High" -> %>
                      <.status_badge label="High" color="orange" />
                    <% "Medium" -> %>
                      <.status_badge label="Medium" color="yellow" />
                    <% "Low" -> %>
                      <.status_badge label="Low" color="green" />
                    <% _ -> %>
                      <.status_badge label={lab_result.urgency} color="blue" />
                  <% end %>
                </div>
                
    <!-- Tests Requested -->
                <div>
                  <h5 class="text-sm font-semibold text-slate-700 mb-2">Tests Requested</h5>
                  <div class="flex flex-wrap gap-2">
                    <%= for test <- lab_result.tests do %>
                      <span class="px-2 py-1 text-xs bg-emerald-50 text-emerald-700 rounded-full border border-emerald-200">
                        {test.name}
                      </span>
                    <% end %>
                  </div>
                </div>
                
    <!-- Test Results -->
                <%= if has_test_entries?(test_entries) do %>
                  <div class="mt-4">
                    <h5 class="text-sm font-semibold text-slate-700 mb-3">Lab Test Results</h5>
                    <div class="space-y-3">
                      <%= for entry <- test_entries do %>
                        <%= if entry.status in ["completed", "verified"] do %>
                          <div class="border border-slate-200 rounded-lg overflow-hidden">
                            <!-- Test Entry Header -->
                            <div class="bg-slate-50 px-3 py-2 border-b border-slate-200 flex justify-between items-center">
                              <div class="flex items-center gap-2">
                                <div class>
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
                                  <h6 class="font-semibold text-sm text-slate-900">
                                    {entry.template.name}
                                  </h6>
                                  <%= if entry.template.short_name do %>
                                    <span class="text-xs text-slate-500">
                                      ({entry.template.short_name})
                                    </span>
                                  <% end %>
                                </div>
                              </div>
                              <span class={}>
                                {String.capitalize(entry.status)}
                              </span>
                            </div>
                            
    <!-- Test Results Grid -->
                            <%= if map_size(entry.results) > 0 do %>
                              <div class="p-3 bg-white">
                                <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
                                  <%= for {field_name, result_data} <- entry.results do %>
                                    <% field_def = find_field_def(entry.template, field_name) %>
                                    <div class="bg-slate-50 rounded p-2 border border-slate-200">
                                      <p class="text-xs text-slate-500 mb-1">
                                        {field_def["label"] || field_name}
                                      </p>
                                      <div class="flex items-baseline justify-between">
                                        <span class={[
                                          "font-semibold text-sm",
                                          case result_data["flag"] do
                                            "low" -> "text-blue-600"
                                            "high" -> "text-red-600"
                                            _ -> "text-slate-900"
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
                                        <p class="text-xs text-slate-500 mt-1">
                                          Range: {field_def["ref_range_text"]}
                                        </p>
                                      <% end %>
                                    </div>
                                  <% end %>
                                </div>
                                
    <!-- Remarks -->
                                <%= if entry.remarks && entry.remarks != "" do %>
                                  <div class="mt-3 pt-3 border-t border-slate-200">
                                    <p class="text-xs font-semibold text-slate-700 mb-1">Remarks</p>
                                    <p class="text-sm text-slate-600">{entry.remarks}</p>
                                  </div>
                                <% end %>
                                
    <!-- Performed/Verified Info -->
                                <div class="mt-3 pt-3 border-t border-slate-200 flex items-center justify-between text-xs text-slate-500">
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
            </.collapsible_card>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  # Helper function to find field definition
  defp find_field_def(template, field_name) do
    Enum.find(template.field_definitions, %{}, fn f ->
      f["name"] == field_name || f[:name] == field_name
    end)
  end

  # Helper functions for test entry status
  defp count_completed_tests(test_entries) when is_list(test_entries) do
    Enum.count(test_entries, &(&1.status in ["completed", "verified"]))
  end

  defp count_completed_tests(_), do: 0

  defp has_test_entries?(test_entries) when is_list(test_entries) do
    Enum.any?(test_entries, &(&1.status in ["completed", "verified"]))
  end

  defp has_test_entries?(_), do: false

  defp wallet_section(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="flex items-center justify-between">
        <h3 class="text-lg font-semibold text-slate-800 flex items-center">
          <div class="w-8 h-8 rounded-lg bg-emerald-500 flex items-center justify-center mr-3">
            <svg class="h-4 w-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-2m0-6h4v6h-4a2 2 0 110-6z"
              />
            </svg>
          </div>
          Wallet Balance
        </h3>
        <span class="text-sm text-slate-500">{length(@wallet_deposits)} deposits</span>
      </div>

      <div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
        <div class="rounded-xl border border-emerald-200 bg-gradient-to-br from-emerald-50 to-white p-4">
          <p class="text-xs font-semibold uppercase tracking-wide text-emerald-700">
            Remaining Balance
          </p>
          <p class="mt-2 text-2xl font-bold text-emerald-900">
            KES {format_currency(@wallet_statistics.available_balance)}
          </p>
          <p class="mt-1 text-sm text-emerald-700">Available for future payments</p>
        </div>

        <div class="rounded-xl border border-blue-200 bg-gradient-to-br from-blue-50 to-white p-4">
          <p class="text-xs font-semibold uppercase tracking-wide text-blue-700">Total Deposited</p>
          <p class="mt-2 text-2xl font-bold text-blue-900">
            KES {format_currency(@wallet_statistics.total_deposits)}
          </p>
          <p class="mt-1 text-sm text-blue-700">All successful wallet top-ups</p>
        </div>

        <div class="rounded-xl border border-amber-200 bg-gradient-to-br from-amber-50 to-white p-4">
          <p class="text-xs font-semibold uppercase tracking-wide text-amber-700">Amount Used</p>
          <p class="mt-2 text-2xl font-bold text-amber-900">
            KES {format_currency(@wallet_statistics.total_used)}
          </p>
          <p class="mt-1 text-sm text-amber-700">Already spent from the wallet</p>
        </div>

        <div class="rounded-xl border border-slate-200 bg-gradient-to-br from-slate-50 to-white p-4">
          <p class="text-xs font-semibold uppercase tracking-wide text-slate-700">Active Deposits</p>
          <p class="mt-2 text-2xl font-bold text-slate-900">{@wallet_statistics.active_wallets}</p>
          <p class="mt-1 text-sm text-slate-600">Deposits with money left</p>
        </div>
      </div>

      <%= if Enum.empty?(@wallet_deposits) do %>
        <.empty_state
          title="No wallet deposits yet"
          description="No paid wallet deposits have been recorded for this patient yet."
        >
          <:icon>
            <svg class="w-8 h-8 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-2m0-6h4v6h-4a2 2 0 110-6z"
              />
            </svg>
          </:icon>
        </.empty_state>
      <% else %>
        <div class="hidden md:block overflow-hidden rounded-xl border border-slate-200">
          <table class="min-w-full divide-y divide-slate-200">
            <thead class="bg-slate-50">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-500">
                  Date
                </th>
                <th class="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-500">
                  Reason
                </th>
                <th class="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-500">
                  Deposited
                </th>
                <th class="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-500">
                  Used
                </th>
                <th class="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-500">
                  Remaining
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-100 bg-white">
              <%= for deposit <- @wallet_deposits do %>
                <tr class="hover:bg-slate-50 transition-colors">
                  <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-slate-800">
                    {Calendar.strftime(deposit.inserted_at, "%b %d, %Y")}
                  </td>
                  <td class="px-6 py-4 text-sm text-slate-600">
                    {deposit.reason || "Wallet deposit"}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm font-semibold text-blue-700">
                    KES {format_currency(deposit.amount)}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm font-semibold text-amber-700">
                    KES {format_currency(deposit.amount_used)}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <span class={[
                      "inline-flex rounded-full px-3 py-1 text-sm font-semibold",
                      if(wallet_balance(deposit) > 0,
                        do: "bg-emerald-100 text-emerald-800",
                        else: "bg-slate-100 text-slate-700"
                      )
                    ]}>
                      KES {format_currency(wallet_balance(deposit))}
                    </span>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>

        <div class="space-y-3 md:hidden">
          <%= for deposit <- @wallet_deposits do %>
            <div class="rounded-xl border border-slate-200 bg-white p-4">
              <div class="flex items-start justify-between gap-3">
                <div>
                  <p class="font-semibold text-slate-800">
                    {deposit.reason || "Wallet deposit"}
                  </p>
                  <p class="text-sm text-slate-500">
                    {Calendar.strftime(deposit.inserted_at, "%b %d, %Y")}
                  </p>
                </div>
                <span class={[
                  "inline-flex rounded-full px-3 py-1 text-xs font-semibold",
                  if(wallet_balance(deposit) > 0,
                    do: "bg-emerald-100 text-emerald-800",
                    else: "bg-slate-100 text-slate-700"
                  )
                ]}>
                  KES {format_currency(wallet_balance(deposit))}
                </span>
              </div>

              <div class="mt-4 grid grid-cols-2 gap-3">
                <div class="rounded-lg bg-blue-50 p-3">
                  <p class="text-xs font-medium uppercase text-blue-600">Deposited</p>
                  <p class="mt-1 text-sm font-semibold text-blue-900">
                    KES {format_currency(deposit.amount)}
                  </p>
                </div>
                <div class="rounded-lg bg-amber-50 p-3">
                  <p class="text-xs font-medium uppercase text-amber-600">Used</p>
                  <p class="mt-1 text-sm font-semibold text-amber-900">
                    KES {format_currency(deposit.amount_used)}
                  </p>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  defp wallet_balance(deposit) do
    deposit.amount - (deposit.amount_used || 0)
  end

  defp format_currency(amount) when is_integer(amount),
    do: Number.Delimit.number_to_delimited(amount, delimiter: ",")

  defp format_currency(nil), do: "0"

  defp format_currency(amount) when is_float(amount),
    do: Number.Delimit.number_to_delimited(amount, precision: 2, delimiter: ",")

  defp format_currency(amount), do: to_string(amount)

  # Component for patient visits section
  defp patient_visits_section(assigns) do
    ~H"""
    <div>
      <div class="flex items-center justify-between mb-4">
        <h3 class="text-lg font-semibold text-slate-800 flex items-center">
          <div class="w-8 h-8 rounded-lg bg-indigo-500 flex items-center justify-center mr-3">
            <svg class="h-4 w-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
              />
            </svg>
          </div>
          Patient Visits
        </h3>
        <span class="text-sm text-slate-500">{length(@patient_visits)} visits</span>
      </div>

      <%= if Enum.empty?(@patient_visits) do %>
        <.empty_state
          title="No patient visits"
          description="No visits have been recorded for this patient yet."
        >
          <:icon>
            <svg class="w-8 h-8 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
              />
            </svg>
          </:icon>
        </.empty_state>
      <% else %>
        <div class="space-y-3">
          <%= for {patient_visit, index} <- Enum.with_index(@patient_visits) do %>
            <.collapsible_card
              id={"visit-#{index}"}
              title={"Visit on #{Calendar.strftime(patient_visit.date, "%B %d, %Y")}"}
              subtitle={"Time: #{Calendar.strftime(patient_visit.time, "%I:%M %p")}"}
              icon_bg="bg-indigo-100"
              expanded={section_expanded?(assigns, "visit-#{index}")}
            >
              <:icon>
                <svg
                  class="w-5 h-5 text-indigo-600"
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
              </:icon>
              <:badges>
                <.status_badge label={patient_visit.visit_type} color="blue" />
                <%= if patient_visit.has_paid do %>
                  <.status_badge label="Paid" color="green" />
                <% else %>
                  <.status_badge label="Not Paid" color="red" />
                <% end %>
              </:badges>
              <div class="p-4 space-y-4">
                <%= if patient_visit.reason do %>
                  <div class="bg-slate-50 rounded-lg p-3">
                    <p class="text-xs font-medium text-slate-500 uppercase mb-1">Reason for Visit</p>
                    <p class="text-sm text-slate-700">{patient_visit.reason}</p>
                  </div>
                <% end %>

                <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  <div class="bg-blue-50 rounded-lg p-3 border-l-4 border-blue-400">
                    <p class="text-xs font-medium text-blue-600 uppercase mb-1">Assigned Doctor</p>
                    <%= if patient_visit.doctor && patient_visit.doctor.name do %>
                      <p class="text-sm font-medium text-slate-800">
                        Dr. {patient_visit.doctor.name}
                      </p>
                    <% else %>
                      <p class="text-sm text-slate-500">Not Assigned</p>
                    <% end %>
                  </div>
                  <div class="bg-slate-50 rounded-lg p-3 border-l-4 border-purple-400">
                    <p class="text-xs font-medium text-purple-600 uppercase mb-1">Visit Type</p>
                    <p class="text-sm font-medium text-slate-800">{patient_visit.visit_type}</p>
                  </div>
                </div>
                
    <!-- Payment Info -->
                <div class="bg-slate-50 rounded-lg p-4">
                  <p class="text-xs font-medium text-slate-500 uppercase mb-3">Payment Information</p>
                  <div class="grid grid-cols-3 gap-3 text-center">
                    <div>
                      <p class="text-xs text-slate-500 mb-1">Type</p>
                      <.status_badge label={patient_visit.payment_type} color="purple" />
                    </div>
                    <div>
                      <p class="text-xs text-slate-500 mb-1">Status</p>
                      <%= if patient_visit.has_paid do %>
                        <.status_badge label="Paid" color="green" />
                      <% else %>
                        <.status_badge label="Not Paid" color="red" />
                      <% end %>
                    </div>
                    <div>
                      <p class="text-xs text-slate-500 mb-1">Amount</p>
                      <p class="text-sm font-semibold text-slate-800">
                        KSh {patient_visit.total_amount_paid}
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </.collapsible_card>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  # Component for doctor notes section
  defp doctor_notes_section(assigns) do
    ~H"""
    <div>
      <div class="flex items-center justify-between mb-4">
        <h3 class="text-lg font-semibold text-slate-800 flex items-center">
          <div class="w-8 h-8 rounded-lg bg-amber-500 flex items-center justify-center mr-3">
            <svg class="h-4 w-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
              />
            </svg>
          </div>
          Doctor Notes
        </h3>
        <span class="text-sm text-slate-500">{length(@doctor_notes)} notes</span>
      </div>

      <%= if Enum.empty?(@doctor_notes) do %>
        <.empty_state
          title="No doctor notes"
          description="No doctor notes have been recorded for this patient yet."
        >
          <:icon>
            <svg class="w-8 h-8 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
              />
            </svg>
          </:icon>
        </.empty_state>
      <% else %>
        <div class="space-y-3">
          <%= for {note, index} <- Enum.with_index(@doctor_notes) do %>
            <% note_refs = Enum.filter(@referrals, &(&1.doctor_note_id == note.id)) %>
            <% note_labs = Enum.filter(@lab_results, &(&1.doctor_note_id == note.id)) %>
            <% note_drugs = Enum.filter(@drug_allocations, &(&1.doctor_note_id == note.id)) %>
            <% note_radiology = Enum.filter(@radiology_results, &(&1.doctor_note_id == note.id)) %>
            <% note_admissions = Enum.filter(@admission_requests, &(&1.doctor_note_id == note.id)) %>
            <.collapsible_card
              id={"note-#{index}"}
              title={"Consultation - #{Calendar.strftime(note.date, "%B %d, %Y")}"}
              subtitle={"Dr. #{note.doctor.name} • #{Calendar.strftime(note.time, "%I:%M %p")}"}
              icon_bg="bg-amber-100"
              expanded={section_expanded?(assigns, "note-#{index}")}
            >
              <:icon>
                <svg
                  class="w-5 h-5 text-amber-600"
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
              </:icon>
              <:badges></:badges>
              <div class="p-4 space-y-4">
                <%= if note.reason_for_consulatation do %>
                  <div class="bg-slate-50 rounded-lg p-3">
                    <p class="text-xs font-medium text-slate-500 uppercase mb-1">
                      Reason for Consultation
                    </p>
                    <p class="text-sm text-slate-700">{note.reason_for_consulatation}</p>
                  </div>
                <% end %>

                <%= if note.symptoms do %>
                  <div class="bg-slate-50 rounded-lg p-3">
                    <p class="text-xs font-medium text-slate-500 uppercase mb-1">Symptoms</p>
                    <p class="text-sm text-slate-700">{note.symptoms}</p>
                  </div>
                <% end %>

                <%= if note.past_medical_history do %>
                  <div class="bg-slate-50 rounded-lg p-3">
                    <p class="text-xs font-medium text-slate-500 uppercase mb-1">
                      Past Medical History
                    </p>
                    <p class="text-sm text-slate-700">{note.past_medical_history}</p>
                  </div>
                <% end %>

                <%= if note.clinical_notes do %>
                  <div class="bg-slate-50 rounded-lg p-3">
                    <p class="text-xs font-medium text-slate-500 uppercase mb-1">Clinical Notes</p>
                    <p class="text-sm text-slate-700">{note.clinical_notes}</p>
                  </div>
                <% end %>

                <div class="bg-slate-50 rounded-lg p-3">
                  <p class="text-xs font-medium text-slate-500 uppercase mb-1">Investigations</p>
                  <p class="text-sm text-slate-700">{note.investigations || "—"}</p>
                </div>

                <div class="bg-slate-50 rounded-lg p-3">
                  <p class="text-xs font-medium text-slate-500 uppercase mb-1">Management</p>
                  <p class="text-sm text-slate-700">{note.management || "—"}</p>
                </div>

                <%= if note.lab_imaging_request do %>
                  <div class="bg-amber-50 rounded-lg p-3 border-l-4 border-amber-400">
                    <p class="text-xs font-medium text-amber-600 uppercase mb-1">
                      Lab/Imaging Requests
                    </p>
                    <p class="text-sm text-slate-700">{note.lab_imaging_request}</p>
                  </div>
                <% end %>

                <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  <%= if note.diagnosis do %>
                    <div class="bg-blue-50 rounded-lg p-3 border-l-4 border-blue-400">
                      <p class="text-xs font-medium text-blue-600 uppercase mb-1">Diagnosis</p>
                      <p class="text-sm text-slate-700">{note.diagnosis}</p>
                    </div>
                  <% end %>
                  <%= if note.impression do %>
                    <div class="bg-blue-50 rounded-lg p-3 border-l-4 border-blue-400">
                      <p class="text-xs font-medium text-blue-600 uppercase mb-1">
                        Clinical Impression
                      </p>
                      <p class="text-sm text-slate-700">{note.impression}</p>
                    </div>
                  <% end %>
                </div>

                <%= if note.prescribed_medication do %>
                  <div class="bg-emerald-50 rounded-lg p-3 border-l-4 border-emerald-400">
                    <p class="text-xs font-medium text-emerald-600 uppercase mb-1">
                      Prescribed Medication
                    </p>
                    <p class="text-sm text-slate-700">{note.prescribed_medication}</p>
                  </div>
                <% end %>

                <%= if note.lifestyle_recommendations do %>
                  <div class="bg-slate-50 rounded-lg p-3 border-l-4 border-purple-400">
                    <p class="text-xs font-medium text-purple-600 uppercase mb-1">
                      Lifestyle Recommendations
                    </p>
                    <p class="text-sm text-slate-700">{note.lifestyle_recommendations}</p>
                  </div>
                <% end %>

                <%= if note.last_period_date do %>
                  <div class="bg-pink-50 rounded-lg p-3">
                    <p class="text-xs font-medium text-pink-600 uppercase mb-1">Last Period Date</p>
                    <p class="text-sm text-slate-700">
                      {Calendar.strftime(note.last_period_date, "%B %d, %Y")}
                    </p>
                  </div>
                <% end %>

                <%= if note_refs != [] do %>
                  <div class="border-t border-slate-200 pt-4 mt-4">
                    <h5 class="text-sm font-semibold text-green-800 mb-2 flex items-center">
                      <svg class="w-4 h-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
                        />
                      </svg>
                      Referrals
                    </h5>
                    <div class="space-y-2">
                      <%= for ref <- note_refs do %>
                        <div class="bg-green-50 rounded-lg p-3 border border-green-100">
                          <p class="font-medium text-green-900">Referral to {ref.hospital}</p>
                          <p class="text-xs text-green-700 mt-1">
                            {Calendar.strftime(ref.date, "%d %b %Y")}
                            <%= if ref.time do %>
                              • {Calendar.strftime(ref.time, "%H:%M")}
                            <% end %>
                          </p>
                          <%= if ref.referral_note do %>
                            <p class="text-sm text-slate-700 mt-2">{ref.referral_note}</p>
                          <% end %>
                        </div>
                      <% end %>
                    </div>
                  </div>
                <% end %>

                <%= if note_labs != [] do %>
                  <div class="border-t border-slate-200 pt-4 mt-4">
                    <h5 class="text-sm font-semibold text-emerald-800 mb-2">Lab Results</h5>
                    <div class="space-y-2">
                      <%= for lab <- note_labs do %>
                        <div class="bg-emerald-50 rounded-lg p-2 border border-emerald-100 text-sm">
                          <span class="font-medium">Lab ##{lab.id}</span>
                          <span class="text-slate-600 ml-2">
                            {Calendar.strftime(lab.inserted_at, "%d %b %Y")}
                          </span>
                          <%= if lab.tests && length(lab.tests) > 0 do %>
                            <div class="mt-1 text-xs text-slate-600">
                              {Enum.map(lab.tests, & &1.name) |> Enum.join(", ")}
                            </div>
                          <% end %>
                        </div>
                      <% end %>
                    </div>
                  </div>
                <% end %>

                <%= if note_drugs != [] do %>
                  <div class="border-t border-slate-200 pt-4 mt-4">
                    <h5 class="text-sm font-semibold text-rose-800 mb-2">Medications</h5>
                    <div class="space-y-2">
                      <%= for da <- note_drugs do %>
                        <div class="bg-rose-50 rounded-lg p-3 border border-rose-100">
                          <%= if da.prescription do %>
                            <p class="text-sm text-slate-700">{da.prescription}</p>
                          <% end %>
                          <%= if da.drugs_assigned && da.drugs_assigned != [] do %>
                            <div class="mt-2 flex flex-wrap gap-1">
                              <%= for drug <- da.drugs_assigned do %>
                                <span class="px-2 py-0.5 bg-rose-100 text-rose-800 text-xs rounded">
                                  {drug.brand_name} {drug.quantity} {drug.unit_of_measurement} • {drug.frequency}
                                </span>
                              <% end %>
                            </div>
                          <% end %>
                          <p class="text-xs text-slate-500 mt-1">
                            {Calendar.strftime(da.inserted_at, "%d %b %Y")}
                          </p>
                        </div>
                      <% end %>
                    </div>
                  </div>
                <% end %>

                <%= if note_radiology != [] do %>
                  <div class="border-t border-slate-200 pt-4 mt-4">
                    <h5 class="text-sm font-semibold text-indigo-800 mb-2">Radiology</h5>
                    <div class="space-y-2">
                      <%= for rad <- note_radiology do %>
                        <div class="bg-indigo-50 rounded-lg p-2 border border-indigo-100 text-sm">
                          <%= if rad.scans && rad.scans != [] do %>
                            <span class="font-medium">
                              {Enum.map(rad.scans, & &1.name) |> Enum.join(", ")}
                            </span>
                          <% else %>
                            <span class="font-medium">Radiology ##{rad.id}</span>
                          <% end %>
                          <span class="text-slate-600 ml-2">
                            {Calendar.strftime(rad.inserted_at, "%d %b %Y")}
                          </span>
                        </div>
                      <% end %>
                    </div>
                  </div>
                <% end %>

                <%= if note_admissions != [] do %>
                  <div class="border-t border-slate-200 pt-4 mt-4">
                    <h5 class="text-sm font-semibold text-teal-800 mb-2">Admission Requests</h5>
                    <div class="space-y-2">
                      <%= for adm <- note_admissions do %>
                        <div class="bg-teal-50 rounded-lg p-2 border border-teal-100 text-sm">
                          <span class="font-medium">
                            {cond do
                              Map.get(adm, :date) ->
                                Calendar.strftime(adm.date, "%d %b %Y")

                              Map.get(adm, :start_date) ->
                                Calendar.strftime(adm.start_date, "%d %b %Y")

                              true ->
                                "Admission"
                            end}
                          </span>
                          <%= if Map.get(adm, :start_time) do %>
                            <span class="text-slate-600 ml-2">
                              {Calendar.strftime(adm.start_time, "%H:%M")}
                              <%= if Map.get(adm, :end_time) do %>
                                – {Calendar.strftime(adm.end_time, "%H:%M")}
                              <% end %>
                            </span>
                          <% end %>
                        </div>
                      <% end %>
                    </div>
                  </div>
                <% end %>
              </div>
            </.collapsible_card>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  # Component for drug allocations section
  defp patient_drug_allocations_section(assigns) do
    ~H"""
    <div>
      <div class="flex items-center justify-between mb-4">
        <h3 class="text-lg font-semibold text-slate-800 flex items-center">
          <div class="w-8 h-8 rounded-lg bg-rose-500 flex items-center justify-center mr-3">
            <svg class="h-4 w-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4"
              />
            </svg>
          </div>
          Drug Prescriptions
        </h3>
        <span class="text-sm text-slate-500">{length(@drug_allocations)} prescriptions</span>
      </div>

      <%= if Enum.empty?(@drug_allocations) do %>
        <.empty_state
          title="No drug prescriptions"
          description="No medications have been prescribed for this patient yet."
        >
          <:icon>
            <svg class="w-8 h-8 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4"
              />
            </svg>
          </:icon>
        </.empty_state>
      <% else %>
        <div class="space-y-3">
          <%= for {drug_allocation, index} <- Enum.with_index(@drug_allocations) do %>
            <.collapsible_card
              id={"drug-#{index}"}
              title="Drug Prescription"
              subtitle={"Prescribed: #{Calendar.strftime(drug_allocation.inserted_at, "%B %d, %Y")}"}
              icon_bg="bg-rose-100"
              expanded={section_expanded?(assigns, "drug-#{index}")}
            >
              <:icon>
                <svg
                  class="w-5 h-5 text-rose-600"
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
              </:icon>
              <:badges>
                <%= if drug_allocation.has_been_assigned do %>
                  <.status_badge label="Assigned" color="green" />
                <% else %>
                  <.status_badge label="Pending" color="yellow" />
                <% end %>
                <%= if drug_allocation.has_paid do %>
                  <.status_badge label="Paid" color="green" />
                <% else %>
                  <.status_badge label="Not Paid" color="red" />
                <% end %>
              </:badges>
              <div class="p-4 space-y-4">
                <%= if drug_allocation.pharmacist && drug_allocation.pharmacist.name do %>
                  <div class="bg-blue-50 rounded-lg p-3 border-l-4 border-blue-400">
                    <p class="text-xs font-medium text-blue-600 uppercase mb-1">
                      Assigned Pharmacist
                    </p>
                    <p class="text-sm font-medium text-slate-800">
                      {drug_allocation.pharmacist.name}
                    </p>
                  </div>
                <% end %>

                <%= if drug_allocation.prescription do %>
                  <div class="bg-slate-50 rounded-lg p-3">
                    <p class="text-xs font-medium text-slate-500 uppercase mb-1">
                      Doctor's Prescription
                    </p>
                    <p class="text-sm text-slate-700 whitespace-pre-line">
                      {drug_allocation.prescription}
                    </p>
                  </div>
                <% end %>
                
    <!-- Payment Info -->
                <div class="bg-slate-50 rounded-lg p-4">
                  <p class="text-xs font-medium text-slate-500 uppercase mb-3">Payment Information</p>
                  <div class="grid grid-cols-2 gap-3 text-center">
                    <div>
                      <p class="text-xs text-slate-500 mb-1">Type</p>
                      <.status_badge label={drug_allocation.payment_type} color="purple" />
                    </div>
                    <div>
                      <p class="text-xs text-slate-500 mb-1">Total</p>
                      <p class="text-sm font-semibold text-slate-800">
                        KSh {drug_allocation.total_amount_paid}
                      </p>
                    </div>
                  </div>
                </div>
                
    <!-- Assigned Medications -->
                <%= if drug_allocation.drugs_assigned && length(drug_allocation.drugs_assigned) > 0 do %>
                  <div>
                    <p class="text-xs font-medium text-slate-500 uppercase mb-3">
                      Assigned Medications
                    </p>
                    <div class="space-y-3">
                      <%= for drug_assigned <- drug_allocation.drugs_assigned do %>
                        <div class="border border-slate-200 rounded-lg p-4">
                          <div class="flex flex-wrap items-start justify-between gap-2 mb-3">
                            <div>
                              <h6 class="font-medium text-slate-800">{drug_assigned.brand_name}</h6>
                              <p class="text-sm text-slate-500">{drug_assigned.generic_name}</p>
                            </div>
                            <div class="flex flex-wrap gap-1">
                              <.status_badge
                                label={drug_assigned.route_of_administration}
                                color="purple"
                              />
                              <%= if drug_assigned.has_been_given do %>
                                <.status_badge label="Given" color="green" />
                              <% else %>
                                <.status_badge label="Pending" color="yellow" />
                              <% end %>
                            </div>
                          </div>

                          <div class="grid grid-cols-2 sm:grid-cols-4 gap-2">
                            <div class="bg-slate-50 rounded p-2 text-center">
                              <p class="text-xs text-slate-500">Quantity</p>
                              <p class="text-sm font-medium text-slate-800">
                                {drug_assigned.quantity} {drug_assigned.unit_of_measurement}
                              </p>
                            </div>
                            <div class="bg-slate-50 rounded p-2 text-center">
                              <p class="text-xs text-slate-500">Frequency</p>
                              <p class="text-sm font-medium text-slate-800">
                                {drug_assigned.frequency}
                              </p>
                            </div>
                            <div class="bg-slate-50 rounded p-2 text-center">
                              <p class="text-xs text-slate-500">Duration</p>
                              <p class="text-sm font-medium text-slate-800">
                                {drug_assigned.duration_in_days} days
                              </p>
                            </div>
                            <div class="bg-slate-50 rounded p-2 text-center">
                              <p class="text-xs text-slate-500">Price</p>
                              <p class="text-sm font-medium text-slate-800">
                                KSh {drug_assigned.price}
                              </p>
                            </div>
                          </div>

                          <%= if drug_assigned.prescription_note do %>
                            <div class="mt-3 bg-blue-50 rounded p-2 border-l-4 border-blue-400">
                              <p class="text-xs font-medium text-blue-600 mb-1">Doctor's Note</p>
                              <p class="text-sm text-slate-700">{drug_assigned.prescription_note}</p>
                            </div>
                          <% end %>

                          <%= if drug_assigned.pharmacist_note do %>
                            <div class="mt-2 bg-emerald-50 rounded p-2 border-l-4 border-emerald-400">
                              <p class="text-xs font-medium text-emerald-600 mb-1">
                                Pharmacist's Note
                              </p>
                              <p class="text-sm text-slate-700">{drug_assigned.pharmacist_note}</p>
                            </div>
                          <% end %>
                        </div>
                      <% end %>
                    </div>
                  </div>
                <% else %>
                  <div class="text-center py-6 bg-amber-50 rounded-lg border border-amber-200">
                    <svg
                      class="mx-auto h-8 w-8 text-amber-400 mb-2"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.732-.833-2.464 0L3.34 16.5c-.77.833.192 2.5 1.732 2.5z"
                      />
                    </svg>
                    <p class="text-sm text-amber-800">No drugs have been assigned yet.</p>
                  </div>
                <% end %>
                
    <!-- Dispensed Medications -->
                <%= if drug_allocation.drugs_given && length(drug_allocation.drugs_given) > 0 do %>
                  <div>
                    <p class="text-xs font-medium text-emerald-600 uppercase mb-3 flex items-center">
                      <svg class="w-4 h-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M5 13l4 4L19 7"
                        />
                      </svg>
                      Medications Dispensed
                    </p>
                    <div class="space-y-2">
                      <%= for drug_given <- drug_allocation.drugs_given do %>
                        <div class="bg-emerald-50 border border-emerald-200 rounded-lg p-3 flex justify-between items-center">
                          <div>
                            <h6 class="font-medium text-emerald-900">
                              {Medcamp.Drugs.get_drug!(drug_given.drug_id) &&
                                Medcamp.Drugs.get_drug!(drug_given.drug_id).brand_name}
                            </h6>
                            <p class="text-sm text-emerald-700">Qty: {drug_given.quantity}</p>
                            <p class="text-xs text-emerald-600">
                              {Calendar.strftime(drug_given.inserted_at, "%b %d, %Y")}
                            </p>
                          </div>
                          <.status_badge label="Dispensed" color="green" />
                        </div>
                      <% end %>
                    </div>
                  </div>
                <% end %>
              </div>
            </.collapsible_card>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  # Component for nurse procedures section
  defp nurse_procedures_section(assigns) do
    ~H"""
    <div>
      <div class="flex items-center justify-between mb-4">
        <h3 class="text-lg font-semibold text-slate-800 flex items-center">
          <div class="w-8 h-8 rounded-lg bg-cyan-500 flex items-center justify-center mr-3">
            <svg class="h-4 w-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"
              />
            </svg>
          </div>
          Nurse Procedures
        </h3>
        <span class="text-sm text-slate-500">{length(@nurse_procedures)} procedures</span>
      </div>

      <%= if Enum.empty?(@nurse_procedures) do %>
        <.empty_state
          title="No procedures"
          description="No nurse procedures have been recorded for this patient yet."
        >
          <:icon>
            <svg class="w-8 h-8 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"
              />
            </svg>
          </:icon>
        </.empty_state>
      <% else %>
        <!-- Desktop Table View -->
        <div class="hidden md:block overflow-hidden rounded-xl border border-slate-200">
          <table class="min-w-full divide-y divide-slate-200">
            <thead class="bg-slate-50">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">
                  Procedure
                </th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">
                  Payment Type
                </th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">
                  Status
                </th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">
                  Amount
                </th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">
                  Date
                </th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-slate-100">
              <%= for procedure <- @nurse_procedures do %>
                <tr class="hover:bg-slate-50 transition-colors">
                  <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-slate-800">
                    {procedure.procedure.name}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <.status_badge label={procedure.payment_type} color="purple" />
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <%= if procedure.has_paid do %>
                      <.status_badge label="Paid" color="green" />
                    <% else %>
                      <.status_badge label="Not Paid" color="red" />
                    <% end %>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm font-semibold text-slate-800">
                    KES {procedure.total_amount_paid}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-slate-600">
                    {Calendar.strftime(procedure.inserted_at, "%b %d, %Y")}
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
        
    <!-- Mobile Card View -->
        <div class="md:hidden space-y-3">
          <%= for procedure <- @nurse_procedures do %>
            <div class="bg-white border border-slate-200 rounded-xl p-4">
              <div class="flex items-start justify-between mb-3">
                <div class="flex items-center space-x-3">
                  <div class="w-10 h-10 rounded-xl bg-cyan-100 flex items-center justify-center flex-shrink-0">
                    <svg
                      class="w-5 h-5 text-cyan-600"
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
                    <h4 class="font-semibold text-slate-800">{procedure.procedure.name}</h4>
                    <p class="text-sm text-slate-500">
                      {Calendar.strftime(procedure.inserted_at, "%b %d, %Y")}
                    </p>
                  </div>
                </div>
                <%= if procedure.has_paid do %>
                  <.status_badge label="Paid" color="green" />
                <% else %>
                  <.status_badge label="Not Paid" color="red" />
                <% end %>
              </div>
              <div class="flex items-center justify-between pt-3 border-t border-slate-100">
                <.status_badge label={procedure.payment_type} color="purple" />
                <span class="text-sm font-semibold text-slate-800">
                  KES {procedure.total_amount_paid}
                </span>
              </div>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end
end
