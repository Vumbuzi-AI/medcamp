defmodule MedcampWeb.AdminMedicalCampLive.Index do
  use MedcampWeb, :admin_live_view

  alias Medcamp.Patients
  alias Medcamp.Chatbot
  alias Medcamp.Triages
  alias Medcamp.DoctorNotes
  alias Medcamp.LabResults
  alias Medcamp.Camps
  alias Medcamp.Tenancy

  @per_page 10

  @impl true
  def mount(_params, session, socket) do
    report_path = Map.get(session, "report_path", "/admin/medical_camp/report")
    organisation_name = Map.get(session, "superadmin_organisation_name")
    back_path = Map.get(session, "superadmin_back_path")

    if org_id = Map.get(session, "superadmin_org_id"), do: Tenancy.put_org_id(org_id)

    camp = safe_active_camp()

    {:ok,
     socket
     |> assign(:active_tab, :medical_camp)
     |> assign(:page_title, "Medical Camp Dashboard")
     |> assign(:report_path, report_path)
     |> assign(:superadmin_organisation_name, organisation_name)
     |> assign(:superadmin_back_path, back_path)
     |> assign(:camp, camp)
     |> assign(:camp_days, (camp && Camps.Camp.days(camp)) || [])
     |> assign(:selected_date, nil)
     |> assign(:active_day_tab, :all)
     |> assign(:selected_patient, nil)
     |> assign(:patient_triage, nil)
     |> assign(:patient_doctor_notes, [])
     |> assign(:patient_lab_results, [])
     |> assign(:camp_triages, [])
     |> assign(:camp_doctor_notes, [])
     |> assign(:camp_lab_results, [])
     |> assign(:active_report_tab, :triage)
     |> assign(:active_dashboard_tab, :overview)
     |> assign(:camp_ai_question, "")
     |> assign(:camp_ai_response, nil)
     |> assign(:camp_ai_error, nil)
     |> assign(:camp_ai_loading, false)
     |> assign(:camp_ai_request_id, nil)
     |> assign(:patient_ai_question, "")
     |> assign(:patient_ai_response, nil)
     |> assign(:patient_ai_error, nil)
     |> assign(:patient_ai_loading, false)
     |> assign(:patient_ai_request_id, nil)
     |> assign(:patients_with_notes, 0)
     |> assign(:total_lab_tests, 0)
     |> assign(:financials, nil)
     |> assign(:reporting, empty_reporting())
     |> assign(:geographic_breakdown, [])
     |> assign(:patient_diagnoses, %{})
     |> assign(:preview_modal, nil)
     |> assign(:preview_page, 1)
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> load_all_data()}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    page_num =
      case Integer.parse(page) do
        {i, _} -> max(1, i)
        :error -> 1
      end

    {:noreply,
     socket
     |> assign(:page, page_num)
     |> paginate_patients()}
  end

  def handle_event("set_day_tab", %{"tab" => "all"}, socket) do
    {:noreply,
     socket
     |> assign(:page, 1)
     |> assign(:active_day_tab, :all)
     |> assign(:selected_date, nil)
     |> assign(:selected_patient, nil)
     |> load_all_data()}
  end

  def handle_event("set_day_tab", %{"tab" => iso}, socket) do
    with {:ok, date} <- Date.from_iso8601(iso),
         true <- date in socket.assigns.camp_days do
      {:noreply,
       socket
       |> assign(:page, 1)
       |> assign(:active_day_tab, date)
       |> assign(:selected_date, date)
       |> assign(:selected_patient, nil)
       |> load_data(date)}
    else
      _ -> {:noreply, socket}
    end
  end

  def handle_event("select_patient", %{"id" => id}, socket) do
    patient = Patients.get_patient!(id)
    triage = Triages.most_recent_triage(patient.id)
    doctor_notes = DoctorNotes.doctor_notes_for_patient(patient.id)
    lab_results = LabResults.list_lab_results_for_patient(patient.id)

    {:noreply,
     socket
     |> assign(:selected_patient, patient)
     |> assign(:patient_triage, triage)
     |> assign(:patient_doctor_notes, doctor_notes)
     |> assign(:patient_lab_results, lab_results)
     |> assign(:patient_ai_question, "")
     |> assign(:patient_ai_response, nil)
     |> assign(:patient_ai_error, nil)
     |> assign(:patient_ai_loading, false)
     |> assign(:patient_ai_request_id, nil)
     |> assign(:active_report_tab, :triage)}
  end

  def handle_event("close_patient", _params, socket) do
    {:noreply,
     socket
     |> assign(:selected_patient, nil)
     |> assign(:patient_ai_question, "")
     |> assign(:patient_ai_response, nil)
     |> assign(:patient_ai_error, nil)
     |> assign(:patient_ai_loading, false)
     |> assign(:patient_ai_request_id, nil)}
  end

  def handle_event("preview_export", %{"type" => type}, socket) do
    preview = build_preview(type, socket.assigns)
    {:noreply, socket |> assign(:preview_modal, preview) |> assign(:preview_page, 1)}
  end

  def handle_event("close_preview", _, socket) do
    {:noreply, socket |> assign(:preview_modal, nil) |> assign(:preview_page, 1)}
  end

  def handle_event("preview_page", %{"dir" => dir}, socket) do
    page = socket.assigns.preview_page
    total = length(socket.assigns.preview_modal.rows)
    total_pages = max(ceil(total / 20), 1)
    new_page = if dir == "next", do: min(page + 1, total_pages), else: max(page - 1, 1)
    {:noreply, assign(socket, :preview_page, new_page)}
  end

  def handle_event("set_report_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_report_tab, String.to_existing_atom(tab))}
  end

  def handle_event("set_dashboard_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_dashboard_tab, String.to_existing_atom(tab))}
  end

  def handle_event("update_camp_ai_question", %{"ai" => %{"question" => question}}, socket) do
    {:noreply, assign(socket, :camp_ai_question, question)}
  end

  def handle_event("set_camp_ai_question", %{"question" => question}, socket) do
    {:noreply,
     socket
     |> assign(:camp_ai_question, question)
     |> push_event("fill_camp_question", %{question: question})}
  end

  def handle_event("update_patient_ai_question", %{"ai" => %{"question" => question}}, socket) do
    {:noreply, assign(socket, :patient_ai_question, question)}
  end

  def handle_event("run_camp_ai", %{"ai" => params}, socket) do
    question = Map.get(params, "question", "")
    request_id = System.unique_integer([:positive])
    payload = build_camp_ai_payload(socket.assigns)
    pid = self()

    Task.start(fn ->
      send(
        pid,
        {:camp_ai_response, request_id, Chatbot.analyze_medical_camp(payload, question)}
      )
    end)

    {:noreply,
     socket
     |> assign(:camp_ai_question, question)
     |> assign(:camp_ai_loading, true)
     |> assign(:camp_ai_error, nil)
     |> assign(:camp_ai_request_id, request_id)}
  end

  def handle_event("run_patient_ai", %{"ai" => params}, socket) do
    question = Map.get(params, "question", "")

    case socket.assigns.selected_patient do
      nil ->
        {:noreply, socket}

      _patient ->
        request_id = System.unique_integer([:positive])
        payload = build_patient_ai_payload(socket.assigns)
        pid = self()

        Task.start(fn ->
          send(
            pid,
            {:patient_ai_response, request_id,
             Chatbot.analyze_medical_camp_patient(payload, question)}
          )
        end)

        {:noreply,
         socket
         |> assign(:patient_ai_question, question)
         |> assign(:patient_ai_loading, true)
         |> assign(:patient_ai_error, nil)
         |> assign(:patient_ai_request_id, request_id)}
    end
  end

  # Slices the full patients list (kept intact for stats/reporting) for the table
  defp paginate_patients(socket) do
    all_patients = socket.assigns.patients
    total_count = length(all_patients)
    total_pages = max(1, Medcamp.Pagination.total_pages(total_count, socket.assigns.per_page))
    page = min(max(1, socket.assigns.page || 1), total_pages)

    display =
      all_patients
      |> Enum.with_index(1)
      |> Enum.slice((page - 1) * socket.assigns.per_page, socket.assigns.per_page)

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:display_patients, display)
  end

  defp load_all_data(socket) do
    patients =
      case socket.assigns.camp do
        nil -> Patients.list_patients()
        camp -> Patients.list_patients_for_camp(camp.id)
      end

    stats = Patients.compute_camp_stats_for_patients(patients)
    load_from_patients(socket, patients, stats)
  end

  defp load_data(socket, date) do
    patients =
      case socket.assigns.camp do
        nil -> Patients.list_medical_camp_patients(date)
        camp -> Patients.list_patients_for_camp_on(camp.id, date)
      end

    stats = Patients.compute_camp_stats_for_patients(patients)
    load_from_patients(socket, patients, stats)
  end

  defp safe_active_camp do
    Camps.get_active_camp()
  rescue
    _ -> nil
  end

  defp load_from_patients(socket, patients, stats) do
    patient_ids = Enum.map(patients, & &1.id)

    triages = Triages.list_most_recent_triages_for_patients(patient_ids)
    triaged_ids = triages |> Enum.map(& &1.patient_id) |> MapSet.new()
    doctor_notes = DoctorNotes.list_doctor_notes_for_patients(patient_ids)
    lab_results = LabResults.list_lab_results_for_patients(patient_ids)

    patients_with_notes =
      doctor_notes |> Enum.map(& &1.patient_id) |> MapSet.new() |> MapSet.size()

    total_lab_tests = total_test_count(lab_results)
    financials = LabResults.camp_financials(patient_ids)
    reporting = build_reporting(patients, stats, triages, doctor_notes, lab_results, financials)

    geographic_breakdown = build_geographic_breakdown(patients)
    patient_diagnoses = build_patient_diagnoses(doctor_notes)

    socket
    |> assign(:patients, patients)
    |> assign(:camp_triages, triages)
    |> assign(:camp_doctor_notes, doctor_notes)
    |> assign(:camp_lab_results, lab_results)
    |> assign(:stats, stats)
    |> assign(:triaged_ids, triaged_ids)
    |> assign(:patients_with_notes, patients_with_notes)
    |> assign(:total_lab_tests, total_lab_tests)
    |> assign(:financials, financials)
    |> assign(:reporting, reporting)
    |> assign(:geographic_breakdown, geographic_breakdown)
    |> assign(:patient_diagnoses, patient_diagnoses)
    |> paginate_patients()
  end

  @impl true
  def handle_info({:camp_ai_response, request_id, {:ok, response}}, socket) do
    if socket.assigns.camp_ai_request_id == request_id do
      {:noreply,
       socket
       |> assign(:camp_ai_response, response)
       |> assign(:camp_ai_error, nil)
       |> assign(:camp_ai_loading, false)}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:camp_ai_response, request_id, {:error, error}}, socket) do
    if socket.assigns.camp_ai_request_id == request_id do
      {:noreply,
       socket
       |> assign(:camp_ai_error, error)
       |> assign(:camp_ai_loading, false)}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:patient_ai_response, request_id, {:ok, response}}, socket) do
    if socket.assigns.patient_ai_request_id == request_id do
      {:noreply,
       socket
       |> assign(:patient_ai_response, response)
       |> assign(:patient_ai_error, nil)
       |> assign(:patient_ai_loading, false)}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:patient_ai_response, request_id, {:error, error}}, socket) do
    if socket.assigns.patient_ai_request_id == request_id do
      {:noreply,
       socket
       |> assign(:patient_ai_error, error)
       |> assign(:patient_ai_loading, false)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="-m-4 min-h-screen bg-slate-50 p-4 sm:-m-6 sm:p-6">
      <div class="space-y-6">
        
    <!-- Header -->
        <div class="rounded-2xl bg-brand-primary p-6 text-white">
          <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
            <div>
              <.link
                :if={@superadmin_back_path}
                navigate={@superadmin_back_path}
                class="mb-4 inline-flex items-center gap-1.5 text-sm font-semibold text-white/70 transition-colors duration-150 hover:text-white"
              >
                <Heroicons.icon name="arrow-left" type="outline" class="h-4 w-4" />
                Back to organisations
              </.link>
              <h1 class="text-2xl font-bold tracking-[-0.01em]">Medical Camp Dashboard</h1>
              <p class="mt-1 text-sm text-white/70">
                <span :if={@superadmin_organisation_name} class="font-semibold text-white">
                  {@superadmin_organisation_name} ·
                </span>
                {@stats.total} patients
              </p>
            </div>
            <div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:gap-4">
              <.camp_switcher
                :if={is_nil(@superadmin_organisation_name)}
                tone="on_dark"
                camps={assigns[:camp_options] || []}
                camp_filter={assigns[:camp_filter]}
              />
              <.link
                navigate={@report_path}
                class="inline-flex shrink-0 items-center justify-center gap-2 rounded-full bg-white px-4 py-2 text-sm font-semibold text-brand-primary transition-colors duration-150 hover:bg-white/90"
              >
                <Heroicons.icon name="document-text" type="outline" class="h-4 w-4" /> View Report
              </.link>
            </div>
          </div>
        </div>

        <div
          :if={length(@camp_days) > 1}
          class="flex flex-wrap items-center gap-2 rounded-2xl border border-slate-200 bg-white p-2"
        >
          <span class="px-2 text-xs font-semibold uppercase tracking-wide text-slate-400">
            Camp day
          </span>
          <button
            type="button"
            phx-click="set_day_tab"
            phx-value-tab="all"
            class={[
              "rounded-full px-3 py-1.5 text-sm font-semibold transition-colors duration-150",
              (@active_day_tab == :all && "bg-brand-primary text-white") ||
                "text-slate-600 hover:bg-slate-100"
            ]}
          >
            All days
          </button>
          <button
            :for={day <- @camp_days}
            type="button"
            phx-click="set_day_tab"
            phx-value-tab={Date.to_iso8601(day)}
            class={[
              "rounded-full px-3 py-1.5 text-sm font-semibold transition-colors duration-150",
              (@active_day_tab == day && "bg-brand-primary text-white") ||
                "text-slate-600 hover:bg-slate-100"
            ]}
          >
            {Calendar.strftime(day, "%a, %d %b")}
          </button>
        </div>
        
    <!-- Top-level Tabs -->
        <div class="overflow-hidden rounded-2xl border border-slate-200 bg-white">
          <div class="overflow-x-auto">
            <div class="flex min-w-max sm:min-w-0">
              <button
                phx-click="set_dashboard_tab"
                phx-value-tab="overview"
                class={[
                  "min-w-[10rem] flex-1 flex items-center justify-center gap-2 px-5 py-4 text-sm font-semibold transition-colors border-b-2 sm:min-w-0 sm:px-6",
                  if(@active_dashboard_tab == :overview,
                    do: "border-brand-primary text-brand-primary bg-brand-50",
                    else: "border-transparent text-slate-500 hover:text-slate-700 hover:bg-slate-50"
                  )
                ]}
              >
                <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"
                  />
                </svg>
                Overview
              </button>
              <button
                phx-click="set_dashboard_tab"
                phx-value-tab="patient_data"
                class={[
                  "min-w-[10rem] flex-1 flex items-center justify-center gap-2 px-5 py-4 text-sm font-semibold transition-colors border-b-2 sm:min-w-0 sm:px-6",
                  if(@active_dashboard_tab == :patient_data,
                    do: "border-brand-primary text-brand-primary bg-brand-50",
                    else: "border-transparent text-slate-500 hover:text-slate-700 hover:bg-slate-50"
                  )
                ]}
              >
                <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z"
                  />
                </svg>
                Patient Data
              </button>
              <button
                phx-click="set_dashboard_tab"
                phx-value-tab="ai_analysis"
                class={[
                  "min-w-[10rem] flex-1 flex items-center justify-center gap-2 px-5 py-4 text-sm font-semibold transition-colors border-b-2 sm:min-w-0 sm:px-6",
                  if(@active_dashboard_tab == :ai_analysis,
                    do: "border-brand-primary text-brand-primary bg-brand-50",
                    else: "border-transparent text-slate-500 hover:text-slate-700 hover:bg-slate-50"
                  )
                ]}
              >
                <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-6.364l.707.707m2.287 10.657A8 8 0 1119 12a8 8 0 01-9.663 7z"
                  />
                </svg>
                AI Analysis
              </button>
              <button
                phx-click="set_dashboard_tab"
                phx-value-tab="financials"
                class={[
                  "min-w-[10rem] flex-1 flex items-center justify-center gap-2 px-5 py-4 text-sm font-semibold transition-colors border-b-2 sm:min-w-0 sm:px-6",
                  if(@active_dashboard_tab == :financials,
                    do: "border-brand-primary text-brand-primary bg-brand-50",
                    else: "border-transparent text-slate-500 hover:text-slate-700 hover:bg-slate-50"
                  )
                ]}
              >
                <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                  />
                </svg>
                Financials
              </button>
              <button
                phx-click="set_dashboard_tab"
                phx-value-tab="downloads"
                class={[
                  "min-w-[10rem] flex-1 flex items-center justify-center gap-2 px-5 py-4 text-sm font-semibold transition-colors border-b-2 sm:min-w-0 sm:px-6",
                  if(@active_dashboard_tab == :downloads,
                    do: "border-brand-primary text-brand-primary bg-brand-50",
                    else: "border-transparent text-slate-500 hover:text-slate-700 hover:bg-slate-50"
                  )
                ]}
              >
                <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"
                  />
                </svg>
                Downloads
              </button>
            </div>
          </div>
        </div>
        
    <!-- Overview Tab Content -->
        <%= if @active_dashboard_tab == :overview do %>
          
    <!-- Stats Grid -->
          <div class="grid grid-cols-2 sm:grid-cols-4 gap-4">
            <.camp_stat label="Total Patients" value={@stats.total} color="indigo" />
            <.camp_stat
              label="Triaged"
              value={MapSet.size(@triaged_ids)}
              color="blue"
              subtitle={Enum.at(@reporting.highlights, 0).value <> " completion"}
            />
            <.camp_stat
              label="Doctor Notes"
              value={@patients_with_notes}
              color="violet"
              subtitle={Enum.at(@reporting.highlights, 1).value <> " review rate"}
            />
            <.camp_stat label="Lab Tests" value={@total_lab_tests} color="teal" />
          </div>
          
    <!-- Executive Highlights -->


    <!-- Core Charts -->

          <div class="w-[100%]">
            <.camp_chart_panel
              title="Daily Camp Activity"
              subtitle="Simple daily totals for registrations, triage, doctor notes, and lab tests."
              config={daily_flow_chart(@reporting.daily_trend)}
              height="340px"
            />
          </div>

          <div class="grid grid-cols-1 gap-6">
            <.camp_chart_panel
              title="Patient Registration Timeline (EAT · UTC+3)"
              subtitle="Number of patients registered per hour on each camp day, in East Africa Time."
              config={registration_timeline_chart(@reporting.registration_timeline)}
              height="300px"
            />
          </div>

          <div class="grid grid-cols-1 xl:grid-cols-3 gap-6">
            <.camp_chart_panel
              title="Gender Distribution"
              subtitle="Overall patient mix by gender."
              config={camp_gender_chart(@reporting.gender_breakdown)}
            />

            <.camp_chart_panel
              title="Patient Type Mix"
              subtitle="Breakdown of the camp population by patient type."
              config={patient_type_chart(@reporting.patient_types)}
            />

            <.camp_chart_panel
              title="Age Distribution"
              subtitle="Age segmentation for outreach and service planning."
              config={age_group_chart(@reporting.age_groups)}
            />
          </div>

          <div class="grid grid-cols-1 xl:grid-cols-2 gap-6">
            <.camp_chart_panel
              title="Top Lab Tests"
              subtitle="Most requested tests in the selected medical camp window."
              config={test_volume_chart(@reporting.tests)}
              height="360px"
            />

            <.camp_chart_panel
              title="Tests Done by Gender"
              subtitle="Male versus female test volumes, with other or unspecified captured separately."
              config={test_gender_chart(@reporting.tests)}
              height="360px"
            />
          </div>

          <div class="grid grid-cols-1 gap-6">
            <.camp_chart_panel
              title="Top Diagnoses"
              subtitle="Most common doctor note diagnoses or impressions recorded during camp."
              config={diagnosis_chart(@reporting.diagnoses)}
              height="360px"
            />
          </div>
          
    <!-- Operational Breakdowns -->
          <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <div class="bg-white rounded-2xl border border-slate-200 p-6">
              <h3 class="text-sm font-semibold text-slate-700 uppercase tracking-wide mb-4">
                Age Group Breakdown
              </h3>
              <div class="space-y-3">
                <.age_bar
                  label="Under 5 yrs"
                  count={@stats.age_groups.under_5}
                  total={max(@stats.total, 1)}
                  color="amber"
                />
                <.age_bar
                  label="5 – 17 yrs"
                  count={@stats.age_groups.age_5_17}
                  total={max(@stats.total, 1)}
                  color="green"
                />
                <.age_bar
                  label="18 – 59 yrs"
                  count={@stats.age_groups.age_18_59}
                  total={max(@stats.total, 1)}
                  color="blue"
                />
                <.age_bar
                  label="60+ yrs"
                  count={@stats.age_groups.over_60}
                  total={max(@stats.total, 1)}
                  color="rose"
                />
              </div>
            </div>

            <div class="bg-white rounded-2xl border border-slate-200 p-6">
              <h3 class="text-sm font-semibold text-slate-700 uppercase tracking-wide mb-4">
                Patient Type Breakdown
              </h3>
              <%= if Enum.empty?(@stats.patient_types) do %>
                <p class="text-sm text-slate-400 text-center py-6">No data available</p>
              <% else %>
                <div class="space-y-3">
                  <%= for {type, count} <- @stats.patient_types do %>
                    <.age_bar label={type} count={count} total={max(@stats.total, 1)} color="indigo" />
                  <% end %>
                </div>
              <% end %>
            </div>
          </div>
          <!-- Geographic Spread -->
          <div class="bg-white rounded-2xl border border-slate-200 overflow-hidden">
            <div class="px-5 py-4 border-b border-slate-200 bg-slate-50/80 flex items-center justify-between">
              <div>
                <h3 class="text-base font-semibold text-slate-800">Geographic Spread</h3>
                <p class="text-sm text-slate-500 mt-1">
                  Patient distribution by home address / location.
                </p>
              </div>
              <div class="flex items-center gap-2">
                <span class="text-xs font-medium text-slate-500 bg-slate-100 px-3 py-1 rounded-full">
                  {length(@geographic_breakdown)} locations
                </span>
                <.link
                  href={"/admin/medical_camp/export/geography?day=#{@active_day_tab}"}
                  class="inline-flex items-center gap-1.5 text-xs font-semibold text-emerald-700 bg-emerald-50 hover:bg-emerald-100 px-3 py-1.5 rounded-full transition-colors"
                >
                  <svg class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"
                    />
                  </svg>
                  CSV
                </.link>
              </div>
            </div>
            <%= if Enum.empty?(@geographic_breakdown) do %>
              <div class="flex flex-col items-center justify-center py-12 text-slate-400">
                <p class="text-sm font-medium">No location data available</p>
              </div>
            <% else %>
              <div class="overflow-x-auto max-h-72 overflow-y-auto">
                <table class="min-w-full divide-y divide-slate-100 text-sm">
                  <thead class="bg-slate-50 sticky top-0">
                    <tr>
                      <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                        Location
                      </th>
                      <th class="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-slate-500">
                        Patients
                      </th>
                      <th class="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-slate-500">
                        % Share
                      </th>
                    </tr>
                  </thead>
                  <tbody class="divide-y divide-slate-50 bg-white">
                    <%= for loc <- @geographic_breakdown do %>
                      <tr class="hover:bg-slate-50">
                        <td class="px-4 py-3 text-slate-800">{loc.address}</td>
                        <td class="px-4 py-3 text-right font-semibold text-slate-800">{loc.count}</td>
                        <td class="px-4 py-3 text-right">
                          <div class="flex items-center justify-end gap-2">
                            <div class="w-16 h-1.5 bg-slate-100 rounded-full overflow-hidden">
                              <div
                                class="h-full bg-indigo-500 rounded-full"
                                style={"width: #{loc.pct}%"}
                              >
                              </div>
                            </div>
                            <span class="text-xs text-slate-500 w-8 text-right">{loc.pct}%</span>
                          </div>
                        </td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
              </div>
            <% end %>
          </div>
        <% end %>
        <!-- /Overview Tab -->

        <!-- Patient Data Tab Content -->
        <%= if @active_dashboard_tab == :patient_data do %>
          <div class="grid grid-cols-1 xl:grid-cols-2 gap-6">
            <div class="bg-white rounded-2xl border border-slate-200 overflow-hidden">
              <div class="px-5 py-4 border-b border-slate-200 bg-slate-50/80 flex items-center justify-between">
                <div>
                  <h3 class="text-base font-semibold text-slate-800">Doctor Notes by Doctor</h3>
                  <p class="text-sm text-slate-500 mt-1">
                    How many notes each doctor recorded in the selected camp window.
                  </p>
                </div>
                <span class="text-xs font-medium text-slate-500 bg-slate-100 px-3 py-1 rounded-full">
                  {length(@reporting.doctor_note_doctors)} doctors
                </span>
              </div>

              <%= if Enum.empty?(@reporting.doctor_note_doctors) do %>
                <div class="flex flex-col items-center justify-center py-16 text-slate-400">
                  <svg class="h-12 w-12 mb-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="1.5"
                      d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                    />
                  </svg>
                  <p class="text-sm font-medium">No doctor notes recorded for this slice</p>
                </div>
              <% else %>
                <div class="overflow-x-auto">
                  <table class="min-w-full divide-y divide-slate-100 text-sm">
                    <thead class="bg-slate-50">
                      <tr>
                        <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                          Doctor
                        </th>
                        <th class="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-slate-500">
                          Notes
                        </th>
                        <th class="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-slate-500">
                          Patients Reviewed
                        </th>
                      </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-50 bg-white">
                      <%= for doctor <- @reporting.doctor_note_doctors do %>
                        <tr>
                          <td class="px-4 py-3 font-medium text-slate-800">{doctor.name}</td>
                          <td class="px-4 py-3 text-right text-slate-800 font-semibold">
                            {doctor.notes_count}
                          </td>
                          <td class="px-4 py-3 text-right text-slate-600">{doctor.patients_count}</td>
                        </tr>
                      <% end %>
                    </tbody>
                  </table>
                </div>
              <% end %>
            </div>

            <div class="bg-white rounded-2xl border border-slate-200 overflow-hidden">
              <div class="px-5 py-4 border-b border-slate-200 bg-slate-50/80 flex items-center justify-between">
                <div>
                  <h3 class="text-base font-semibold text-slate-800">Top Diagnoses</h3>
                  <p class="text-sm text-slate-500 mt-1">
                    Most common diagnoses captured in doctor notes.
                  </p>
                </div>
                <span class="text-xs font-medium text-slate-500 bg-slate-100 px-3 py-1 rounded-full">
                  {length(@reporting.diagnoses)} tracked
                </span>
              </div>

              <%= if Enum.empty?(@reporting.diagnoses) do %>
                <div class="flex flex-col items-center justify-center py-16 text-slate-400">
                  <svg class="h-12 w-12 mb-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="1.5"
                      d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                    />
                  </svg>
                  <p class="text-sm font-medium">No diagnosis data for this slice</p>
                </div>
              <% else %>
                <div class="overflow-x-auto">
                  <table class="min-w-full divide-y divide-slate-100 text-sm">
                    <thead class="bg-slate-50">
                      <tr>
                        <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                          Diagnosis
                        </th>
                        <th class="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-slate-500">
                          Doctor Notes
                        </th>
                      </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-50 bg-white">
                      <%= for diagnosis <- @reporting.diagnoses do %>
                        <tr>
                          <td class="px-4 py-3 text-slate-800">{diagnosis.label}</td>
                          <td class="px-4 py-3 text-right text-slate-800 font-semibold">
                            {diagnosis.count}
                          </td>
                        </tr>
                      <% end %>
                    </tbody>
                  </table>
                </div>
              <% end %>
            </div>
          </div>
          
    <!-- Test Breakdown -->
          <div class="bg-white rounded-2xl border border-slate-200 overflow-hidden">
            <div class="px-5 py-4 border-b border-slate-200 bg-slate-50/80 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
              <div>
                <h3 class="text-base font-semibold text-slate-800">Lab Test Breakdown</h3>
                <p class="text-sm text-slate-500 mt-1">
                  Each test requested, split by gender and completion status.
                </p>
              </div>
              <span class="text-xs font-medium text-slate-500 bg-slate-100 px-3 py-1 rounded-full">
                {@reporting.metrics.tests_done} tests captured
              </span>
            </div>

            <%= if Enum.empty?(@reporting.tests) do %>
              <div class="flex flex-col items-center justify-center py-16 text-slate-400">
                <svg class="h-12 w-12 mb-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="1.5"
                    d="M9 17v-2m3 2v-4m3 4v-6m2 10H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                  />
                </svg>
                <p class="text-sm font-medium">No lab test data for this slice</p>
              </div>
            <% else %>
              <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-slate-100 text-sm">
                  <thead class="bg-slate-50">
                    <tr>
                      <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                        Test
                      </th>
                      <th class="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-slate-500">
                        Total
                      </th>
                      <th class="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-slate-500">
                        Male
                      </th>
                      <th class="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-slate-500">
                        Female
                      </th>
                    </tr>
                  </thead>
                  <tbody class="divide-y divide-slate-50 bg-white">
                    <%= for test <- @reporting.tests do %>
                      <tr>
                        <td class="px-4 py-3">
                          <div class="font-medium text-slate-800">{test.name}</div>
                          <div class="text-xs text-slate-400">{test.revenue_label}</div>
                        </td>
                        <td class="px-4 py-3 text-right font-semibold text-slate-800">
                          {test.total}
                        </td>
                        <td class="px-4 py-3 text-right text-blue-700">{test.male}</td>
                        <td class="px-4 py-3 text-right text-pink-700">{test.female}</td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
              </div>
            <% end %>
          </div>
          
    <!-- Patients Table -->
          <div class="bg-white rounded-2xl border border-slate-200 overflow-hidden">
            <div class="px-5 py-4 border-b border-slate-200 bg-slate-50/80 flex items-center justify-between gap-3 flex-wrap">
              <h3 class="text-base font-semibold text-slate-800">
                All Camp Patients
              </h3>
              <div class="flex items-center gap-2">
                <span class="text-xs font-medium text-slate-500 bg-slate-100 px-3 py-1 rounded-full">
                  {@stats.total} total
                </span>
                <.link
                  href={"/admin/medical_camp/export/patients?day=#{@active_day_tab}"}
                  class="inline-flex items-center gap-1.5 text-xs font-semibold text-emerald-700 bg-emerald-50 hover:bg-emerald-100 px-3 py-1.5 rounded-full transition-colors"
                >
                  <svg class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"
                    />
                  </svg>
                  CSV
                </.link>
              </div>
            </div>

            <%= if Enum.empty?(@patients) do %>
              <div class="flex flex-col items-center justify-center py-20 text-slate-400">
                <svg class="h-12 w-12 mb-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="1.5"
                    d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z"
                  />
                </svg>
                <p class="text-sm font-medium">No medical camp patients for this date</p>
              </div>
            <% else %>
              <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-slate-100 text-sm">
                  <thead class="bg-slate-50">
                    <tr>
                      <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                        #
                      </th>
                      <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                        Patient
                      </th>
                      <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                        Age/Gender
                      </th>
                      <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                        Age Group
                      </th>
                      <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                        Type
                      </th>
                      <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                        Diagnosis
                      </th>
                      <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                        Triaged
                      </th>
                      <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                        Time In
                      </th>
                    </tr>
                  </thead>
                  <tbody class="divide-y divide-slate-50">
                    <%= for {patient, index} <- @display_patients do %>
                      <tr
                        class={[
                          "cursor-pointer transition-colors",
                          if(@selected_patient && @selected_patient.id == patient.id,
                            do: "bg-indigo-50 border-l-2 border-indigo-500",
                            else: "hover:bg-slate-50"
                          )
                        ]}
                        phx-click="select_patient"
                        phx-value-id={patient.id}
                      >
                        <td class="px-4 py-3 text-slate-400 font-mono text-xs">{index}</td>
                        <td class="px-4 py-3">
                          <div class="font-medium text-slate-800">
                            {full_name(patient)}
                          </div>
                          <div class="text-xs text-slate-400">{patient.gsrn}</div>
                        </td>
                        <td class="px-4 py-3">
                          <span class="text-slate-700">{patient.age || "—"} yrs</span>
                          <span class={[
                            "ml-1 text-xs font-medium px-1.5 py-0.5 rounded",
                            gender_badge(patient.gender)
                          ]}>
                            {patient.gender || "—"}
                          </span>
                        </td>
                        <td class="px-4 py-3 text-xs text-slate-600">
                          {age_group_label(patient.age)}
                        </td>
                        <td class="px-4 py-3">
                          <span class="text-xs text-slate-600 bg-slate-100 px-2 py-1 rounded-full">
                            {patient.patient_type || "—"}
                          </span>
                        </td>
                        <td class="px-4 py-3 max-w-[160px]">
                          <span class="text-xs text-slate-700 truncate block">
                            {Map.get(@patient_diagnoses, patient.id) || "—"}
                          </span>
                        </td>
                        <td class="px-4 py-3">
                          <%= if MapSet.member?(@triaged_ids, patient.id) do %>
                            <span class="inline-flex items-center gap-1 text-xs font-medium text-emerald-700 bg-emerald-50 px-2 py-1 rounded-full">
                              <svg class="h-3 w-3" fill="currentColor" viewBox="0 0 20 20">
                                <path
                                  fill-rule="evenodd"
                                  d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                                  clip-rule="evenodd"
                                />
                              </svg>
                              Yes
                            </span>
                          <% else %>
                            <span class="text-xs text-slate-400 bg-slate-100 px-2 py-1 rounded-full">
                              No
                            </span>
                          <% end %>
                        </td>
                        <td class="px-4 py-3 text-xs text-slate-500">
                          {format_time(patient.inserted_at)}
                        </td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
                <.pagination
                  page={@page}
                  total_pages={@total_pages}
                  total_count={@total_count}
                  per_page={@per_page}
                  class="px-4 pb-4"
                />
              </div>
            <% end %>
          </div>
          
    <!-- Patient Detail Modal -->
          <%= if @selected_patient do %>
            <!-- Backdrop -->
            <div class="fixed inset-0 z-40 bg-black/50 backdrop-blur-sm" phx-click="close_patient">
            </div>
            
    <!-- Modal -->
            <div class="fixed inset-0 z-50 flex items-center justify-center p-4 pointer-events-none">
              <div
                class="bg-white rounded-2xl border border-slate-200 w-full max-w-2xl max-h-[90vh] flex flex-col pointer-events-auto"
                phx-click-away="close_patient"
              >
                <!-- Modal Header -->
                <div class="px-6 py-5 bg-brand-primary rounded-t-2xl text-white flex items-center justify-between shrink-0">
                  <div class="flex items-center gap-3">
                    <div class="h-10 w-10 rounded-full bg-white/20 flex items-center justify-center font-bold text-lg">
                      {String.first(@selected_patient.first_name || "?")}
                    </div>
                    <div>
                      <h3 class="font-bold text-lg leading-tight">{full_name(@selected_patient)}</h3>
                      <p class="text-white/70 text-xs mt-0.5 flex items-center gap-2">
                        <span>{@selected_patient.age || "—"} yrs</span>
                        <span>·</span>
                        <span>{@selected_patient.gender || "—"}</span>
                        <span>·</span>
                        <span class="font-mono">{@selected_patient.gsrn}</span>
                      </p>
                    </div>
                  </div>
                  <button
                    phx-click="close_patient"
                    class="p-2 rounded-xl hover:bg-white/20 transition-colors"
                  >
                    <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M6 18L18 6M6 6l12 12"
                      />
                    </svg>
                  </button>
                </div>
                
    <!-- Patient Info Bar -->
                <div class="px-6 py-3 bg-slate-50 border-b border-slate-200 flex items-center gap-4 text-xs text-slate-600 shrink-0">
                  <%= if @selected_patient.patient_type do %>
                    <span class="flex items-center gap-1">
                      <svg
                        class="h-3.5 w-3.5 text-slate-400"
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
                      <span class="font-medium">{@selected_patient.patient_type}</span>
                    </span>
                  <% end %>
                  <%= if @selected_patient.has_insurance do %>
                    <span class="flex items-center gap-1 text-emerald-600">
                      <svg class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"
                        />
                      </svg>
                      <span class="font-medium">Insured · {@selected_patient.insurance_scheme}</span>
                    </span>
                  <% end %>
                  <span class="ml-auto flex items-center gap-1 text-slate-400">
                    <svg class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                      />
                    </svg>
                    Registered {format_time(@selected_patient.inserted_at)}
                  </span>
                </div>
                
    <!-- Tabs -->
                <div class="overflow-x-auto border-b border-slate-200 bg-white shrink-0">
                  <div class="flex min-w-max">
                    <.report_tab
                      tab={:triage}
                      active={@active_report_tab}
                      label="Triage"
                      count={if @patient_triage, do: 1, else: 0}
                    />
                    <.report_tab
                      tab={:notes}
                      active={@active_report_tab}
                      label="Doctor Notes"
                      count={length(@patient_doctor_notes)}
                    />
                    <.report_tab
                      tab={:labs}
                      active={@active_report_tab}
                      label="Lab Tests"
                      count={length(@patient_lab_results)}
                    />
                    <.report_tab
                      tab={:ai}
                      active={@active_report_tab}
                      label="AI Analysis"
                      count={if(@patient_ai_response, do: 1, else: 0)}
                    />
                  </div>
                </div>
                
    <!-- Tab Content (scrollable) -->
                <div class="flex-1 overflow-y-auto p-6">
                  
    <!-- Triage Tab -->
                  <%= if @active_report_tab == :triage do %>
                    <%= if @patient_triage do %>
                      <div class="space-y-5">
                        <div class="grid grid-cols-2 sm:grid-cols-4 gap-3">
                          <.vital
                            label="Temperature"
                            value={"#{@patient_triage.temperature}°C"}
                            icon="thermometer"
                            color="red"
                          />
                          <.vital
                            label="Blood Pressure"
                            value={@patient_triage.blood_pressure || "—"}
                            icon="heart"
                            color="rose"
                          />
                          <.vital
                            label="Pulse Rate"
                            value={"#{@patient_triage.pulse_rate} bpm"}
                            icon="pulse"
                            color="blue"
                          />
                          <.vital
                            label="O₂ Saturation"
                            value={"#{@patient_triage.oxygen_saturation}%"}
                            icon="oxygen"
                            color="cyan"
                          />
                          <.vital
                            label="Weight"
                            value={"#{@patient_triage.weight} kg"}
                            icon="weight"
                            color="green"
                          />
                          <.vital
                            label="Height"
                            value={"#{@patient_triage.height} cm"}
                            icon="height"
                            color="indigo"
                          />
                          <%= if @patient_triage.bmi do %>
                            <.vital
                              label="BMI"
                              value={"#{@patient_triage.bmi}"}
                              icon="bmi"
                              color="purple"
                            />
                          <% end %>
                        </div>

                        <div class="bg-slate-50 rounded-xl p-4 space-y-3">
                          <p class="text-xs font-semibold text-slate-500 uppercase tracking-wide">
                            AVPU Scale
                          </p>
                          <div class="flex gap-2 flex-wrap">
                            <.avpu_badge label="Alert" active={@patient_triage.alert} />
                            <.avpu_badge label="Verbal" active={@patient_triage.verbal} />
                            <.avpu_badge label="Pain" active={@patient_triage.pain} />
                            <.avpu_badge label="Unresponsive" active={@patient_triage.unresponsive} />
                          </div>
                          <%= if @patient_triage.emergency_scale do %>
                            <div class="flex items-center gap-2">
                              <span class="text-xs text-slate-500">Emergency Scale:</span>
                              <span class={[
                                "text-xs font-bold px-2 py-0.5 rounded-full",
                                emergency_scale_style(@patient_triage.emergency_scale)
                              ]}>
                                Level {@patient_triage.emergency_scale}
                              </span>
                            </div>
                          <% end %>
                          <%= if @patient_triage.allergies do %>
                            <div class="flex items-start gap-2">
                              <span class="text-xs font-semibold text-slate-500 shrink-0 mt-0.5">
                                Allergies:
                              </span>
                              <span class="text-xs text-red-600 font-medium">
                                {@patient_triage.allergies}
                              </span>
                            </div>
                          <% end %>
                          <%= if @patient_triage.triage_notes do %>
                            <div>
                              <p class="text-xs font-semibold text-slate-500 mb-1">Triage Notes</p>
                              <p class="text-sm text-slate-700 bg-white rounded-lg p-3 border border-slate-200 leading-relaxed">
                                {@patient_triage.triage_notes}
                              </p>
                            </div>
                          <% end %>
                        </div>

                        <p class="text-xs text-slate-400 text-center">
                          Recorded: {format_datetime(@patient_triage.inserted_at)}
                        </p>
                      </div>
                    <% else %>
                      <.empty_state label="No triage recorded for this patient" />
                    <% end %>
                  <% end %>
                  
    <!-- Doctor Notes Tab -->
                  <%= if @active_report_tab == :notes do %>
                    <%= if Enum.empty?(@patient_doctor_notes) do %>
                      <.empty_state label="No doctor notes recorded" />
                    <% else %>
                      <div class="space-y-5">
                        <%= for note <- @patient_doctor_notes do %>
                          <div class="rounded-xl border border-slate-200 overflow-hidden">
                            <div class="bg-slate-50 px-4 py-3 flex items-center gap-3">
                              <div class="h-8 w-8 rounded-full bg-indigo-100 flex items-center justify-center text-indigo-700 font-bold text-sm shrink-0">
                                Dr
                              </div>
                              <div>
                                <p class="text-sm font-semibold text-slate-800">
                                  Dr. {(note.doctor && note.doctor.name) || "Unknown"}
                                </p>
                                <p class="text-xs text-slate-500">
                                  {note.date && Calendar.strftime(note.date, "%d %b %Y")} · {note.time &&
                                    Time.to_string(note.time)}
                                </p>
                              </div>
                            </div>
                            <div class="p-4 grid grid-cols-1 sm:grid-cols-2 gap-4">
                              <.note_row
                                label="Reason for Consultation"
                                value={note.reason_for_consulatation}
                              />
                              <.note_row label="Symptoms / Examination" value={note.symptoms} />
                              <.note_row label="Diagnosis" value={note.diagnosis} />
                              <.note_row label="ICD Code" value={note.diagnosis_icd_code} />
                              <.note_row label="Impression" value={note.impression} />
                              <.note_row label="Management Plan" value={note.management} />
                              <.note_row label="Clinical Notes" value={note.clinical_notes} />
                              <.note_row
                                label="Lab / Imaging Request"
                                value={note.lab_imaging_request}
                              />
                              <.note_row
                                label="Past Medical History"
                                value={note.past_medical_history}
                              />
                              <.note_row label="Investigations" value={note.investigations} />
                            </div>
                          </div>
                        <% end %>
                      </div>
                    <% end %>
                  <% end %>
                  
    <!-- Lab Tests Tab -->
                  <%= if @active_report_tab == :labs do %>
                    <%= if Enum.empty?(@patient_lab_results) do %>
                      <.empty_state label="No lab tests requested" />
                    <% else %>
                      <div class="space-y-3">
                        <%= for result <- @patient_lab_results do %>
                          <div class="rounded-xl border border-slate-200 p-4 space-y-2">
                            <div class="flex items-start justify-between gap-2">
                              <div>
                                <p class="text-sm font-semibold text-slate-800">
                                  {result.name || "Lab Test"}
                                </p>
                                <p class="text-xs text-slate-500">{result.description}</p>
                              </div>
                              <div class="flex flex-col items-end gap-1">
                                <span class={[
                                  "text-xs font-medium px-2 py-0.5 rounded-full",
                                  urgency_badge(result.urgency)
                                ]}>
                                  {result.urgency || "Normal"}
                                </span>
                                <span class={[
                                  "text-xs px-2 py-0.5 rounded-full",
                                  if(result.report_complete,
                                    do: "bg-emerald-50 text-emerald-700",
                                    else: "bg-amber-50 text-amber-700"
                                  )
                                ]}>
                                  {if result.report_complete, do: "Complete", else: "Pending"}
                                </span>
                              </div>
                            </div>
                            <%= if result.test_findings do %>
                              <div class="bg-slate-50 rounded-lg p-3 mt-2">
                                <p class="text-xs font-medium text-slate-500 mb-1">Findings</p>
                                <p class="text-sm text-slate-700">{result.test_findings}</p>
                              </div>
                            <% end %>
                            <div class="flex items-center gap-3 text-xs text-slate-400 mt-2">
                              <%= if result.date_of_test do %>
                                <span>
                                  Test date: {Calendar.strftime(result.date_of_test, "%d %b %Y")}
                                </span>
                              <% end %>
                              <%= if result.technician_name do %>
                                <span>By: {result.technician_name}</span>
                              <% end %>
                            </div>
                          </div>
                        <% end %>
                      </div>
                    <% end %>
                  <% end %>
                  
    <!-- AI Analysis Tab -->
                  <%= if @active_report_tab == :ai do %>
                    <div class="space-y-4">
                      <div class="rounded-2xl border border-slate-200 bg-white p-4 sm:p-5">
                        <div class="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
                          <div>
                            <h4 class="text-base font-semibold text-slate-900">
                              Patient AI Analysis
                            </h4>
                            <p class="text-sm text-slate-500">
                              Reviews triage, doctor notes, lab requests and recorded findings for this patient.
                            </p>
                          </div>
                          <span class="inline-flex items-center rounded-full bg-indigo-100 px-3 py-1 text-xs font-semibold text-indigo-700">
                            Medical camp patient context
                          </span>
                        </div>

                        <.form
                          for={%{}}
                          as={:ai}
                          phx-change="update_patient_ai_question"
                          phx-submit="run_patient_ai"
                          class="mt-4 space-y-3"
                        >
                          <textarea
                            name="ai[question]"
                            rows="4"
                            value={@patient_ai_question}
                            placeholder="Ask for a case summary, likely disease pattern, missing documentation, red flags, or follow-up advice."
                            class="w-full rounded-2xl border border-slate-300 px-4 py-3 text-sm text-slate-700 outline-none transition focus:border-brand-primary focus:ring-2 focus:ring-indigo-100"
                          ></textarea>

                          <div class="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
                            <p class="text-xs text-slate-500">
                              Example: What diagnosis pattern is suggested by the notes and what should be followed up?
                            </p>

                            <button
                              type="submit"
                              phx-disable-with="Analyzing..."
                              class="inline-flex items-center justify-center gap-2 rounded-2xl bg-brand-primary px-4 py-2.5 text-sm font-semibold text-white transition hover:opacity-90"
                            >
                              Analyze with AI
                            </button>
                          </div>
                        </.form>
                      </div>

                      <%= if @patient_ai_loading do %>
                        <div class="rounded-2xl border border-indigo-100 bg-indigo-50 px-4 py-5 text-sm text-indigo-700">
                          AI is reviewing the patient triage, doctor notes, and lab data.
                        </div>
                      <% end %>

                      <%= if @patient_ai_error do %>
                        <div class="rounded-2xl border border-rose-200 bg-rose-50 px-4 py-4 text-sm text-rose-700 whitespace-pre-line">
                          {@patient_ai_error}
                        </div>
                      <% end %>

                      <%= if @patient_ai_response do %>
                        <div class="rounded-2xl border border-slate-200 bg-white p-4 sm:p-5">
                          <div class="flex items-center gap-2 border-b border-slate-100 pb-3">
                            <Heroicons.icon
                              name="sparkles"
                              type="outline"
                              class="h-5 w-5 text-brand-primary"
                            />
                            <h4 class="text-sm font-semibold uppercase tracking-wide text-slate-700">
                              AI Findings
                            </h4>
                          </div>
                          <div class="pt-4 text-sm leading-7 text-slate-700 whitespace-pre-line">
                            {@patient_ai_response}
                          </div>
                        </div>
                      <% end %>
                    </div>
                  <% end %>
                </div>
                
    <!-- Modal Footer -->
                <div class="px-6 py-4 border-t border-slate-200 bg-slate-50/80 rounded-b-2xl flex items-center justify-between shrink-0">
                  <button
                    phx-click="close_patient"
                    class="text-sm text-slate-500 hover:text-slate-700 transition-colors"
                  >
                    Close
                  </button>
                  <a
                    href={"/admin/patients/#{@selected_patient.id}"}
                    class="flex items-center gap-2 text-sm font-semibold text-white bg-brand-primary hover:opacity-90 px-4 py-2 rounded-xl transition-colors"
                  >
                    <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"
                      />
                    </svg>
                    View Full Profile
                  </a>
                </div>
              </div>
            </div>
          <% end %>
        <% end %>
        <!-- /Patient Data Tab -->

        <%= if @active_dashboard_tab == :ai_analysis do %>
          <div class="grid grid-cols-1 gap-6 xl:grid-cols-[minmax(0,1.2fr)_minmax(320px,0.8fr)]">
            <div class="rounded-2xl border border-slate-200 bg-white p-4 sm:p-6">
              <div class="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
                <div>
                  <h3 class="text-lg font-semibold text-slate-900">Medical Camp AI Analysis</h3>
                  <p class="mt-1 text-sm text-slate-500">
                    Uses camp totals, doctor notes, diagnoses, triage trends and lab activity to answer questions such as how many had a disease pattern, what symptoms were most common, and where documentation gaps exist.
                  </p>
                </div>
              </div>

              <.form
                for={%{}}
                as={:ai}
                phx-change="update_camp_ai_question"
                phx-submit="run_camp_ai"
                class="mt-5 space-y-3"
              >
                <textarea
                  id="camp-ai-textarea"
                  phx-hook="FillQuestion"
                  name="ai[question]"
                  rows="5"
                  value={@camp_ai_question}
                  placeholder="Ask: how many had respiratory disease patterns, what were the most common diagnoses, which age groups carried most burden, what follow-up gaps exist, or summarize the whole camp."
                  class="w-full rounded-2xl border border-slate-300 px-4 py-3 text-sm text-slate-700 outline-none transition focus:border-brand-primary focus:ring-2 focus:ring-indigo-100"
                ></textarea>

                <button
                  type="submit"
                  phx-disable-with="Analyzing..."
                  class="flex w-fit items-center gap-2 rounded-xl bg-brand-primary px-5 py-2.5 text-sm font-semibold text-white transition hover:opacity-90"
                >
                  Analyze with AI
                </button>
              </.form>

              <%= if @camp_ai_loading do %>
                <div class="mt-4 rounded-2xl border border-indigo-100 bg-white p-5">
                  <div class="flex items-center gap-3 mb-5">
                    <span class="text-sm font-medium text-indigo-600">Analysing camp data…</span>
                  </div>
                  <div class="space-y-3 animate-pulse">
                    <div class="h-3.5 w-1/3 rounded-full bg-slate-200"></div>
                    <div class="h-2.5 w-full rounded-full bg-slate-100"></div>
                    <div class="h-2.5 w-5/6 rounded-full bg-slate-100"></div>
                    <div class="h-2.5 w-4/6 rounded-full bg-slate-100"></div>
                    <div class="mt-4 h-3.5 w-1/4 rounded-full bg-slate-200"></div>
                    <div class="h-2.5 w-full rounded-full bg-slate-100"></div>
                    <div class="h-2.5 w-3/4 rounded-full bg-slate-100"></div>
                    <div class="mt-4 h-3.5 w-2/5 rounded-full bg-slate-200"></div>
                    <div class="h-2.5 w-full rounded-full bg-slate-100"></div>
                    <div class="h-2.5 w-5/6 rounded-full bg-slate-100"></div>
                    <div class="h-2.5 w-2/3 rounded-full bg-slate-100"></div>
                  </div>
                </div>
              <% end %>

              <%= if @camp_ai_error do %>
                <div class="mt-4 rounded-2xl border border-rose-200 bg-rose-50 px-4 py-4 text-sm text-rose-700 whitespace-pre-line">
                  {@camp_ai_error}
                </div>
              <% end %>

              <%= if @camp_ai_response do %>
                <div class="mt-4 rounded-2xl border border-indigo-100 bg-white p-5">
                  <div class="flex items-center gap-2 border-b border-slate-200 pb-3 mb-1">
                    <Heroicons.icon name="sparkles" type="solid" class="h-4 w-4 text-indigo-500" />
                    <h4 class="text-sm font-semibold uppercase tracking-wide text-indigo-700">
                      Camp AI Findings
                    </h4>
                  </div>
                  <div class="camp-ai-body">
                    {raw(@camp_ai_response)}
                  </div>
                </div>
              <% end %>
            </div>

            <div class="space-y-4">
              <div class="rounded-2xl border border-slate-200 bg-white p-4 sm:p-5">
                <h4 class="text-sm font-semibold uppercase tracking-wide text-slate-600">
                  AI Input Snapshot
                </h4>
                <div class="mt-4 grid grid-cols-2 gap-3">
                  <.camp_stat label="Patients" value={@reporting.metrics.registered} color="indigo" />
                  <.camp_stat label="Triaged" value={@reporting.metrics.triaged} color="blue" />
                  <.camp_stat
                    label="Doctor Notes"
                    value={@reporting.metrics.doctor_reviewed}
                    color="violet"
                  />
                  <.camp_stat label="Lab Tests" value={@reporting.metrics.tests_done} color="teal" />
                </div>
              </div>

              <div class="rounded-2xl border border-slate-200 bg-white p-4 sm:p-5">
                <h4 class="text-sm font-semibold uppercase tracking-wide text-slate-600">
                  Suggested Questions
                </h4>
                <div class="mt-4 space-y-2 text-sm text-slate-600">
                  <%= for {question, icon} <- [
                    {"How many patients appeared to have respiratory disease patterns?", "heart"},
                    {"What were the top diagnoses and which age groups were most affected?", "chart-bar"},
                    {"Which conditions look under-investigated based on symptoms versus labs ordered?", "beaker"},
                    {"What follow-up actions should camp coordinators prioritize?", "clipboard-document-list"},
                    {"Summarise the overall health burden seen at this camp.", "document-text"},
                    {"Which patients had incomplete documentation or missing triage?", "exclamation-circle"},
                    {"What is the gender and age breakdown of patients seen?", "users"},
                    {"Were there any signs of communicable disease clusters?", "shield-exclamation"},
                    {"What were all the lab tests requested and their findings?", "beaker"},
                    {"Which diagnoses were most common among male versus female patients?", "chart-bar"},
                    {"Which patients had the most critical triage readings?", "exclamation-triangle"},
                    {"What were the most common symptoms recorded across doctor notes?", "clipboard-document-list"},
                    {"How many patients had both triage and doctor notes recorded?", "check-circle"},
                    {"Which doctors saw the most patients and what were their top diagnoses?", "user"},
                    {"Were there any patients seen on both days of the camp?", "calendar"},
                    {"What was the nutritional or chronic disease burden at this camp?", "heart"}
                  ] do %>
                    <button
                      type="button"
                      phx-click="set_camp_ai_question"
                      phx-value-question={question}
                      class="w-full text-left rounded-xl bg-slate-50 px-3 py-2.5 hover:bg-indigo-50 hover:text-indigo-700 border border-transparent hover:border-indigo-200 transition cursor-pointer flex items-start gap-2"
                    >
                      <Heroicons.icon
                        name={icon}
                        type="outline"
                        class="mt-0.5 h-3.5 w-3.5 shrink-0 text-indigo-400"
                      />
                      <span>{question}</span>
                    </button>
                  <% end %>
                </div>
              </div>
            </div>
          </div>
        <% end %>
        
    <!-- Financials Tab Content -->
        <%= if @active_dashboard_tab == :financials do %>
          <% f = @financials %>
          
    <!-- Summary stat cards -->
          <div class="grid grid-cols-2 sm:grid-cols-4 gap-4">
            <div class="bg-white rounded-2xl border border-slate-200 p-5 flex flex-col gap-1">
              <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">
                Total Revenue
              </p>
              <p class="text-2xl font-bold text-emerald-700 tabular-nums">
                KSh {Number.Delimit.number_to_delimited(f.total_revenue, precision: 0)}
              </p>
              <p class="text-xs text-slate-400">from lab tests</p>
            </div>
            <div class="bg-white rounded-2xl border border-slate-200 p-5 flex flex-col gap-1">
              <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">Collected</p>
              <p class="text-2xl font-bold text-blue-700 tabular-nums">
                KSh {Number.Delimit.number_to_delimited(f.total_paid, precision: 0)}
              </p>
              <p class="text-xs text-slate-400">marked as paid</p>
            </div>
            <div class="bg-white rounded-2xl border border-slate-200 p-5 flex flex-col gap-1">
              <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">Pending</p>
              <p class="text-2xl font-bold text-amber-600 tabular-nums">
                KSh {Number.Delimit.number_to_delimited(f.total_pending, precision: 0)}
              </p>
              <p class="text-xs text-slate-400">awaiting payment</p>
            </div>
            <div class="bg-white rounded-2xl border border-slate-200 p-5 flex flex-col gap-2">
              <div>
                <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">
                  Patients Billed
                </p>
                <p class="text-2xl font-bold text-indigo-700">{f.patient_count}</p>
              </div>
              <div>
                <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">
                  Tests Ordered
                </p>
                <p class="text-2xl font-bold text-violet-700">{f.test_count}</p>
              </div>
            </div>
          </div>
          
    <!-- Per-patient breakdown -->
          <div class="overflow-hidden rounded-2xl border border-slate-200 bg-white">
            
    <!-- Invoice-style header -->
            <div class="bg-brand-primary px-8 py-6 text-white">
              <div class="flex items-start justify-between">
                <div>
                  <p class="text-xs font-medium uppercase tracking-widest text-white/60 mb-1">
                    Medical Camp
                  </p>
                  <h2 class="text-xl font-bold">
                    Lab Tests Revenue — All Patients
                  </h2>
                </div>
                <div class="text-right">
                  <p class="text-xs text-white/60 uppercase tracking-wide">Grand Total</p>
                  <p class="text-3xl font-bold mt-0.5 tabular-nums">
                    KSh {Number.Delimit.number_to_delimited(f.total_revenue, precision: 0)}
                  </p>
                  <p class="text-xs text-white/60 mt-1">
                    {f.patient_count} patient{if f.patient_count != 1, do: "s", else: ""} · {f.test_count} test{if f.test_count !=
                                                                                                                     1,
                                                                                                                   do:
                                                                                                                     "s",
                                                                                                                   else:
                                                                                                                     ""}
                  </p>
                </div>
              </div>
            </div>

            <%= if Enum.empty?(f.patient_rows) do %>
              <div class="flex flex-col items-center justify-center py-20 text-slate-400">
                <svg class="h-12 w-12 mb-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="1.5"
                    d="M9 17v-2m3 2v-4m3 4v-6m2 10H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                  />
                </svg>
                <p class="text-sm font-medium">No lab test revenue for this date</p>
              </div>
            <% else %>
              <%= for {row, idx} <- Enum.with_index(f.patient_rows) do %>
                <div class={[
                  "px-8 py-6",
                  if(rem(idx, 2) == 0, do: "bg-white", else: "bg-slate-50/60")
                ]}>
                  <!-- Patient header -->
                  <div class="flex items-center justify-between mb-4">
                    <div class="flex items-center gap-3">
                      <div class="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-brand-primary text-white font-bold text-xs">
                        {idx + 1}
                      </div>
                      <div>
                        <p class="font-semibold text-slate-900">{full_name(row.patient)}</p>
                        <p class="text-xs text-slate-500 font-mono">
                          {row.patient.gsrn} · {row.patient.age || "—"} yrs · {row.patient.gender ||
                            "—"}
                        </p>
                      </div>
                    </div>
                    <div class="text-right">
                      <p class="text-xs text-slate-400 uppercase tracking-wide">Patient Total</p>
                      <p class="text-xl font-bold text-emerald-700 tabular-nums">
                        KSh {Number.Delimit.number_to_delimited(row.total_amount, precision: 0)}
                      </p>
                      <p class="text-xs text-slate-400 mt-0.5">
                        {length(row.lab_results)} order{if length(row.lab_results) != 1,
                          do: "s",
                          else: ""}
                      </p>
                    </div>
                  </div>
                  
    <!-- Lab orders table -->
                  <div class="rounded-xl overflow-hidden border border-slate-200">
                    <table class="min-w-full divide-y divide-slate-100 text-sm">
                      <thead class="bg-slate-100">
                        <tr>
                          <th class="px-4 py-2.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-500">
                            Tests
                          </th>
                          <th class="px-4 py-2.5 text-center text-xs font-semibold uppercase tracking-wider text-slate-500 w-24">
                            Status
                          </th>
                          <th class="px-4 py-2.5 text-center text-xs font-semibold uppercase tracking-wider text-slate-500 w-24">
                            Payment
                          </th>
                          <th class="px-4 py-2.5 text-right text-xs font-semibold uppercase tracking-wider text-slate-500 w-36">
                            Amount (KSh)
                          </th>
                        </tr>
                      </thead>
                      <tbody class="divide-y divide-slate-100 bg-white">
                        <%= for lr <- row.lab_results do %>
                          <tr>
                            <td class="px-4 py-3">
                              <%= if lr.tests && lr.tests != [] do %>
                                <div class="flex flex-wrap gap-1">
                                  <%= for test <- lr.tests do %>
                                    <span class="inline-flex items-center gap-1 text-xs bg-amber-50 text-amber-800 px-2 py-0.5 rounded-full font-medium">
                                      {test.name}
                                      <%= if test.price && test.price > 0 do %>
                                        <span class="text-amber-500">
                                          · {Number.Delimit.number_to_delimited(test.price,
                                            precision: 0
                                          )}
                                        </span>
                                      <% end %>
                                    </span>
                                  <% end %>
                                </div>
                              <% else %>
                                <span class="text-slate-400 text-xs italic">No tests listed</span>
                              <% end %>
                              <%= if lr.name do %>
                                <p class="text-xs text-slate-500 mt-1">{lr.name}</p>
                              <% end %>
                            </td>
                            <td class="px-4 py-3 text-center">
                              <span class={[
                                "text-xs px-2 py-0.5 rounded-full font-medium",
                                if(lr.report_complete,
                                  do: "bg-emerald-50 text-emerald-700",
                                  else: "bg-amber-50 text-amber-700"
                                )
                              ]}>
                                {if lr.report_complete, do: "Complete", else: "Pending"}
                              </span>
                            </td>
                            <td class="px-4 py-3 text-center">
                              <span class={[
                                "text-xs px-2 py-0.5 rounded-full font-medium",
                                if(lr.has_paid,
                                  do: "bg-blue-50 text-blue-700",
                                  else: "bg-rose-50 text-rose-700"
                                )
                              ]}>
                                {if lr.has_paid, do: "Paid", else: "Unpaid"}
                              </span>
                            </td>
                            <td class="px-4 py-3 text-right font-semibold text-slate-900 tabular-nums">
                              {Number.Delimit.number_to_delimited(lr.total_amount_paid || 0,
                                precision: 0
                              )}
                            </td>
                          </tr>
                        <% end %>
                      </tbody>
                      <tfoot class="bg-slate-50 border-t border-slate-200">
                        <tr>
                          <td
                            colspan="3"
                            class="px-4 py-2.5 text-right text-sm font-semibold text-slate-700"
                          >
                            Patient Subtotal
                          </td>
                          <td class="px-4 py-2.5 text-right font-bold text-emerald-700 tabular-nums text-sm">
                            {Number.Delimit.number_to_delimited(row.total_amount, precision: 0)}
                          </td>
                        </tr>
                      </tfoot>
                    </table>
                  </div>
                </div>

                <%= if idx < length(f.patient_rows) - 1 do %>
                  <div class="border-t border-dashed border-slate-300 mx-8" />
                <% end %>
              <% end %>
              
    <!-- Grand total footer -->
              <div class="border-t border-white/15 bg-brand-primary px-8 py-5 text-white">
                <div class="flex items-center justify-between">
                  <div>
                    <p class="text-sm font-medium text-white/70">
                      Grand Total — {day_tab_label(@active_day_tab)}
                    </p>
                    <div class="flex items-center gap-4 mt-1">
                      <span class="text-xs text-white/60">
                        <span class="font-semibold text-white">
                          KSh {Number.Delimit.number_to_delimited(f.total_paid, precision: 0)}
                        </span>
                        collected
                      </span>
                      <span class="text-blue-300">·</span>
                      <span class="text-xs text-white/60">
                        <span class="font-semibold text-amber-300">
                          KSh {Number.Delimit.number_to_delimited(f.total_pending, precision: 0)}
                        </span>
                        pending
                      </span>
                    </div>
                  </div>
                  <div class="text-right">
                    <p class="text-xs text-blue-300 uppercase tracking-wide">Total Revenue</p>
                    <p class="text-3xl font-bold mt-0.5 tabular-nums">
                      KSh {Number.Delimit.number_to_delimited(f.total_revenue, precision: 0)}
                    </p>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
        <!-- /Financials Tab -->

        <!-- Downloads Tab Content -->
        <%= if @active_dashboard_tab == :downloads do %>
          <div class="bg-white rounded-2xl border border-slate-200 overflow-hidden">
            <div class="px-5 py-5 border-b border-slate-200 bg-slate-50/80">
              <h3 class="text-base font-semibold text-slate-800">Export & Download</h3>
              <p class="text-sm text-slate-500 mt-1">
                Download camp data as CSV or open the printable PDF report.
                All exports respect the current day filter
                (<span class="font-medium">{day_tab_label(@active_day_tab)}</span>).
              </p>
            </div>

            <div class="p-6 grid grid-cols-1 sm:grid-cols-2 gap-4">
              
    <!-- Summary Stats -->
              <div class="bg-white border border-slate-200 rounded-2xl p-5 flex flex-col gap-3">
                <div class="flex items-center gap-3">
                  <div class="h-10 w-10 rounded-xl bg-brand-50 flex items-center justify-center shrink-0">
                    <svg
                      class="h-5 w-5 text-brand-primary"
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
                  </div>
                  <div>
                    <p class="text-sm font-semibold text-slate-800">Summary Statistics</p>
                    <p class="text-xs text-slate-500">
                      Total patients, sex disaggregation, age groups
                    </p>
                  </div>
                </div>
                <div class="flex gap-2 mt-1">
                  <button
                    phx-click="preview_export"
                    phx-value-type="summary"
                    class="flex-1 flex items-center justify-center gap-1.5 text-xs font-semibold text-slate-600 bg-slate-100 hover:bg-slate-200 px-3 py-2 rounded-xl transition-colors"
                  >
                    <svg class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
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
                    Preview
                  </button>
                  <.link
                    href={"/admin/medical_camp/export/summary?day=#{@active_day_tab}"}
                    class="flex-1 flex items-center justify-center gap-1.5 text-xs font-semibold text-white bg-brand-primary hover:opacity-90 px-3 py-2 rounded-xl transition-colors"
                  >
                    <svg class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"
                      />
                    </svg>
                    Download CSV
                  </.link>
                </div>
              </div>
              
    <!-- Complete Patient List -->
              <div class="bg-white border border-slate-200 rounded-2xl p-5 flex flex-col gap-3">
                <div class="flex items-center gap-3">
                  <div class="h-10 w-10 rounded-xl bg-brand-50 flex items-center justify-center shrink-0">
                    <svg
                      class="h-5 w-5 text-brand-primary"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z"
                      />
                    </svg>
                  </div>
                  <div>
                    <p class="text-sm font-semibold text-slate-800">Complete Patient List</p>
                    <p class="text-xs text-slate-500">
                      Name, GSRN, age group, gender, diagnosis, address
                    </p>
                  </div>
                </div>
                <div class="flex gap-2 mt-1">
                  <button
                    phx-click="preview_export"
                    phx-value-type="patients"
                    class="flex-1 flex items-center justify-center gap-1.5 text-xs font-semibold text-slate-600 bg-slate-100 hover:bg-slate-200 px-3 py-2 rounded-xl transition-colors"
                  >
                    <svg class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
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
                    Preview
                  </button>
                  <.link
                    href={"/admin/medical_camp/export/patients?day=#{@active_day_tab}"}
                    class="flex-1 flex items-center justify-center gap-1.5 text-xs font-semibold text-white bg-brand-primary hover:opacity-90 px-3 py-2 rounded-xl transition-colors"
                  >
                    <svg class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"
                      />
                    </svg>
                    Download CSV
                  </.link>
                </div>
              </div>
              
    <!-- Geographic Spread -->
              <div class="bg-white border border-slate-200 rounded-2xl p-5 flex flex-col gap-3">
                <div class="flex items-center gap-3">
                  <div class="h-10 w-10 rounded-xl bg-brand-50 flex items-center justify-center shrink-0">
                    <svg
                      class="h-5 w-5 text-brand-primary"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"
                      />
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"
                      />
                    </svg>
                  </div>
                  <div>
                    <p class="text-sm font-semibold text-slate-800">Geographic Spread</p>
                    <p class="text-xs text-slate-500">
                      Patient distribution by home address / location
                    </p>
                  </div>
                </div>
                <div class="flex gap-2 mt-1">
                  <button
                    phx-click="preview_export"
                    phx-value-type="geography"
                    class="flex-1 flex items-center justify-center gap-1.5 text-xs font-semibold text-slate-600 bg-slate-100 hover:bg-slate-200 px-3 py-2 rounded-xl transition-colors"
                  >
                    <svg class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
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
                    Preview
                  </button>
                  <.link
                    href={"/admin/medical_camp/export/geography?day=#{@active_day_tab}"}
                    class="flex-1 flex items-center justify-center gap-1.5 text-xs font-semibold text-white bg-brand-primary hover:opacity-90 px-3 py-2 rounded-xl transition-colors"
                  >
                    <svg class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"
                      />
                    </svg>
                    Download CSV
                  </.link>
                </div>
              </div>
              
    <!-- Diagnosis Data -->
              <div class="bg-white border border-slate-200 rounded-2xl p-5 flex flex-col gap-3">
                <div class="flex items-center gap-3">
                  <div class="h-10 w-10 rounded-xl bg-brand-50 flex items-center justify-center shrink-0">
                    <svg
                      class="h-5 w-5 text-brand-primary"
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
                  </div>
                  <div>
                    <p class="text-sm font-semibold text-slate-800">Diagnosis Data</p>
                    <p class="text-xs text-slate-500">
                      All diagnoses with sex disaggregation per condition
                    </p>
                  </div>
                </div>
                <div class="flex gap-2 mt-1">
                  <button
                    phx-click="preview_export"
                    phx-value-type="diagnoses"
                    class="flex-1 flex items-center justify-center gap-1.5 text-xs font-semibold text-slate-600 bg-slate-100 hover:bg-slate-200 px-3 py-2 rounded-xl transition-colors"
                  >
                    <svg class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
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
                    Preview
                  </button>
                  <.link
                    href={"/admin/medical_camp/export/diagnoses?day=#{@active_day_tab}"}
                    class="flex-1 flex items-center justify-center gap-1.5 text-xs font-semibold text-white bg-brand-primary hover:opacity-90 px-3 py-2 rounded-xl transition-colors"
                  >
                    <svg class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"
                      />
                    </svg>
                    Download CSV
                  </.link>
                </div>
              </div>
            </div>
            
    <!-- Quick stats preview -->
            <div class="px-6 pb-6">
              <div class="bg-slate-50 rounded-2xl p-5 border border-slate-200">
                <p class="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-4">
                  Current Data Snapshot — {day_tab_label(@active_day_tab)}
                </p>
                <div class="grid grid-cols-2 sm:grid-cols-4 gap-4">
                  <div class="text-center">
                    <p class="text-2xl font-bold text-indigo-700">{@stats.total}</p>
                    <p class="text-xs text-slate-500 mt-0.5">Total Patients</p>
                  </div>
                  <div class="text-center">
                    <p class="text-2xl font-bold text-blue-700">
                      {@stats.male} <span class="text-pink-700">/ {@stats.female}</span>
                    </p>
                    <p class="text-xs text-slate-500 mt-0.5">Male / Female</p>
                  </div>
                  <div class="text-center">
                    <p class="text-2xl font-bold text-emerald-700">{length(@geographic_breakdown)}</p>
                    <p class="text-xs text-slate-500 mt-0.5">Locations</p>
                  </div>
                  <div class="text-center">
                    <p class="text-2xl font-bold text-rose-700">{length(@reporting.diagnoses)}</p>
                    <p class="text-xs text-slate-500 mt-0.5">Diagnoses Tracked</p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        <% end %>
        <!-- /Downloads Tab -->

      </div>
    </div>

    <!-- Export Preview Modal -->
    <%= if @preview_modal do %>
      <% page_size = 10
      total_rows = length(@preview_modal.rows)
      total_pages = max(ceil(total_rows / page_size), 1)
      page = min(@preview_page, total_pages)
      page_rows = Enum.slice(@preview_modal.rows, (page - 1) * page_size, page_size)
      from = (page - 1) * page_size + 1
      to = min(page * page_size, total_rows) %>
      <!-- Backdrop -->
      <div class="fixed inset-0 z-40 bg-black/50 backdrop-blur-sm" phx-click="close_preview"></div>
      <!-- Modal container -->
      <div class="fixed inset-0 z-50 flex items-center justify-center p-4 pointer-events-none">
        <div class="bg-white rounded-2xl border border-slate-200 w-full max-w-5xl max-h-[85vh] flex flex-col pointer-events-auto">
          <!-- Header -->
          <div class="px-6 py-4 border-b border-slate-200 flex items-center justify-between shrink-0">
            <div>
              <h3 class="text-base font-semibold text-slate-800">{@preview_modal.title}</h3>
              <p class="text-xs text-slate-400 mt-0.5">
                Showing {from}–{to} of {total_rows} rows
              </p>
            </div>
            <button
              phx-click="close_preview"
              class="text-slate-400 hover:text-slate-600 transition-colors"
            >
              <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M6 18L18 6M6 6l12 12"
                />
              </svg>
            </button>
          </div>
          <!-- Table body -->
          <div class="overflow-auto flex-1">
            <table class="w-full text-sm border-collapse">
              <thead>
                <tr class="bg-slate-50 sticky top-0 z-10">
                  <%= for h <- @preview_modal.headers do %>
                    <th class="px-3 py-2.5 text-left text-xs font-semibold text-slate-500 uppercase tracking-wide border-b border-slate-200 whitespace-nowrap">
                      {h}
                    </th>
                  <% end %>
                </tr>
              </thead>
              <tbody>
                <%= for row <- page_rows do %>
                  <tr class="border-b border-slate-100 hover:bg-slate-50 transition-colors">
                    <%= for cell <- row do %>
                      <td class="px-3 py-2 text-slate-700 text-xs whitespace-nowrap">{cell}</td>
                    <% end %>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
          <!-- Footer: pagination + close -->
          <div class="px-6 py-4 border-t border-slate-200 flex items-center justify-between shrink-0">
            <div class="flex items-center gap-2">
              <button
                phx-click="preview_page"
                phx-value-dir="prev"
                disabled={page <= 1}
                class="px-3 py-1.5 text-xs font-semibold rounded-lg border border-slate-200 text-slate-600 hover:bg-slate-50 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
              >
                ← Prev
              </button>
              <span class="text-xs text-slate-500">Page {page} of {total_pages}</span>
              <button
                phx-click="preview_page"
                phx-value-dir="next"
                disabled={page >= total_pages}
                class="px-3 py-1.5 text-xs font-semibold rounded-lg border border-slate-200 text-slate-600 hover:bg-slate-50 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
              >
                Next →
              </button>
            </div>
            <button
              phx-click="close_preview"
              class="px-4 py-2 text-sm font-semibold text-white bg-slate-700 hover:bg-slate-800 rounded-xl transition-colors"
            >
              Close
            </button>
          </div>
        </div>
      </div>
    <% end %>
    <!-- /Export Preview Modal -->
    """
  end

  defp build_patient_diagnoses(doctor_notes) do
    doctor_notes
    |> Enum.group_by(& &1.patient_id)
    |> Map.new(fn {patient_id, notes} ->
      diagnosis =
        notes
        |> Enum.find_value(fn note ->
          [note.diagnosis, note.impression, note.reason_for_consulatation]
          |> Enum.find_value(fn value ->
            case value do
              nil ->
                nil

              "" ->
                nil

              v ->
                v
                |> String.trim()
                |> case do
                  "" ->
                    nil

                  trimmed ->
                    trimmed
                    |> String.split(~r/[\n;,]/, parts: 2)
                    |> List.first()
                    |> String.trim()
                    |> then(fn s ->
                      if String.length(s) > 50, do: String.slice(s, 0, 47) <> "...", else: s
                    end)
                end
            end
          end)
        end)

      {patient_id, diagnosis}
    end)
  end

  defp build_geographic_breakdown(patients) do
    total = length(patients)

    patients
    |> Enum.group_by(fn p ->
      case p.home_address do
        nil ->
          "Not Specified"

        "" ->
          "Not Specified"

        addr ->
          addr
          |> String.trim()
          |> case do
            "" -> "Not Specified"
            v -> v
          end
      end
    end)
    |> Enum.map(fn {address, pts} ->
      count = length(pts)
      pct = if total > 0, do: round(count / total * 100), else: 0
      %{address: address, count: count, pct: pct}
    end)
    |> Enum.sort_by(& &1.count, :desc)
  end

  # ---- Sub-components ----

  attr :label, :string, required: true
  attr :value, :any, required: true
  attr :color, :string, required: true
  attr :subtitle, :string, default: nil

  defp camp_stat(assigns) do
    ~H"""
    <div class={[
      "rounded-2xl border p-4 flex flex-col gap-1",
      camp_stat_style(@color)
    ]}>
      <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">{@label}</p>
      <p class={["text-3xl font-bold", camp_stat_value_color(@color)]}>{@value}</p>
      <%= if @subtitle do %>
        <p class={["text-sm font-semibold", camp_stat_value_color(@color)]}>{@subtitle}</p>
      <% end %>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :count, :integer, required: true
  attr :total, :integer, required: true
  attr :color, :string, required: true

  defp age_bar(assigns) do
    assigns = assign(assigns, :pct, trunc(assigns.count / assigns.total * 100))

    ~H"""
    <div class="flex items-center gap-3">
      <span class="text-xs text-slate-600 w-24 shrink-0">{@label}</span>
      <div class="flex-1 h-2.5 bg-slate-100 rounded-full overflow-hidden">
        <div
          class={["h-full rounded-full transition-all duration-500", bar_color(@color)]}
          style={"width: #{@pct}%"}
        >
        </div>
      </div>
      <span class="text-xs font-semibold text-slate-700 w-6 text-right">{@count}</span>
    </div>
    """
  end

  attr :tab, :atom, required: true
  attr :active, :atom, required: true
  attr :label, :string, required: true
  attr :count, :integer, required: true

  defp report_tab(assigns) do
    ~H"""
    <button
      phx-click="set_report_tab"
      phx-value-tab={@tab}
      class={[
        "flex-1 px-3 py-3 text-xs font-medium transition-colors border-b-2",
        if(@tab == @active,
          do: "border-brand-primary text-brand-primary bg-white",
          else: "border-transparent text-slate-500 hover:text-slate-700"
        )
      ]}
    >
      {@label}
      <span class={[
        "ml-1 px-1.5 py-0.5 rounded-full text-xs font-semibold",
        if(@tab == @active, do: "bg-indigo-100 text-indigo-700", else: "bg-slate-200 text-slate-500")
      ]}>
        {@count}
      </span>
    </button>
    """
  end

  attr :label, :string, required: true
  attr :value, :any, required: true
  attr :icon, :string, required: true
  attr :color, :string, required: true

  defp vital(assigns) do
    ~H"""
    <div class={["rounded-xl p-3 border", vital_style(@color)]}>
      <p class="text-xs text-slate-500 mb-0.5">{@label}</p>
      <p class="text-sm font-bold text-slate-800">{@value || "—"}</p>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :active, :boolean, required: true

  defp avpu_badge(assigns) do
    ~H"""
    <span class={[
      "text-xs font-medium px-2 py-1 rounded-full",
      if(@active, do: "bg-blue-100 text-blue-700", else: "bg-slate-100 text-slate-400 line-through")
    ]}>
      {@label}
    </span>
    """
  end

  attr :label, :string, required: true
  attr :value, :any, required: true

  defp note_row(assigns) do
    ~H"""
    <%= if @value && @value != "" do %>
      <div>
        <p class="text-xs font-semibold text-slate-500 uppercase tracking-wide">{@label}</p>
        <p class="text-sm text-slate-700 mt-0.5">{@value}</p>
      </div>
    <% end %>
    """
  end

  attr :label, :string, required: true

  defp empty_state(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center py-16 text-slate-400">
      <svg class="h-10 w-10 mb-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          stroke-width="1.5"
          d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
        />
      </svg>
      <p class="text-sm font-medium">{@label}</p>
    </div>
    """
  end

  attr :title, :string, required: true
  attr :subtitle, :string, default: nil
  attr :config, :map, required: true
  attr :height, :string, default: "320px"

  defp camp_chart_panel(assigns) do
    assigns =
      assigns
      |> assign(:config_json, Jason.encode!(assigns.config))
      |> assign(:dom_id, chart_dom_id(assigns.title))

    ~H"""
    <div class="bg-white rounded-2xl border border-slate-200 p-6 h-full">
      <div class="mb-4">
        <h3 class="text-sm font-semibold text-slate-700 uppercase tracking-wide">{@title}</h3>
        <p :if={@subtitle} class="text-sm text-slate-500 mt-1 leading-relaxed">{@subtitle}</p>
      </div>

      <div class="w-full" style={"height: #{@height}"}>
        <div id={@dom_id} phx-hook="ChartJS" data-chart={@config_json} class="h-full w-full">
          <canvas class="h-full w-full"></canvas>
        </div>
      </div>
    </div>
    """
  end

  # ---- Helpers ----

  defp build_camp_ai_payload(assigns) do
    %{
      medical_camp_scope: current_scope_label(assigns.active_day_tab),
      filters: %{
        active_day_tab: to_string(assigns.active_day_tab),
        selected_date: assigns.selected_date && to_string(assigns.selected_date)
      },
      summary: %{
        stats: assigns.stats,
        metrics: assigns.reporting.metrics,
        highlights: assigns.reporting.highlights,
        financials: camp_financials_payload(assigns.financials)
      },
      break_downs: %{
        gender: assigns.reporting.gender_breakdown,
        age_groups: assigns.reporting.age_groups,
        patient_types: assigns.reporting.patient_types,
        diagnoses: assigns.reporting.diagnoses,
        tests: assigns.reporting.tests,
        doctor_note_doctors: assigns.reporting.doctor_note_doctors,
        daily_trend: assigns.reporting.daily_trend
      },
      patients:
        Enum.map(assigns.patients, fn patient ->
          %{
            id: patient.id,
            name: full_name(patient),
            gsrn: patient.gsrn,
            age: patient.age,
            gender: patient.gender,
            patient_type: patient.patient_type,
            has_insurance: patient.has_insurance,
            insurance_scheme: patient.insurance_scheme,
            medical_camp_name: Map.get(patient, :medical_camp_name)
          }
        end),
      triages: Enum.map(assigns.camp_triages, &triage_payload/1),
      doctor_notes: Enum.map(assigns.camp_doctor_notes, &doctor_note_payload/1),
      lab_results: Enum.map(assigns.camp_lab_results, &lab_result_payload/1)
    }
  end

  defp build_patient_ai_payload(assigns) do
    %{
      medical_camp_scope: current_scope_label(assigns.active_day_tab),
      patient: patient_payload(assigns.selected_patient),
      triage: triage_payload(assigns.patient_triage),
      doctor_notes: Enum.map(assigns.patient_doctor_notes, &doctor_note_payload/1),
      lab_results: Enum.map(assigns.patient_lab_results, &lab_result_payload/1)
    }
  end

  defp current_scope_label(:all), do: "All camp days"
  defp current_scope_label(%Date{} = date), do: Calendar.strftime(date, "%A, %d %b %Y")
  defp current_scope_label(_), do: "All camp days"

  defp day_tab_label(:all), do: "All days"
  defp day_tab_label(%Date{} = date), do: Calendar.strftime(date, "%a, %d %b")
  defp day_tab_label(_), do: "All days"

  defp patient_payload(nil), do: nil

  defp patient_payload(patient) do
    %{
      id: patient.id,
      name: full_name(patient),
      gsrn: patient.gsrn,
      age: patient.age,
      gender: patient.gender,
      patient_type: patient.patient_type,
      has_insurance: patient.has_insurance,
      insurance_scheme: patient.insurance_scheme,
      medical_camp_name: Map.get(patient, :medical_camp_name)
    }
  end

  defp triage_payload(nil), do: nil

  defp triage_payload(triage) do
    %{
      date: triage.date,
      temperature: triage.temperature,
      blood_pressure: triage.blood_pressure,
      pulse_rate: triage.pulse_rate,
      oxygen_saturation: triage.oxygen_saturation,
      height: triage.height,
      weight: triage.weight,
      bmi: triage.bmi,
      allergies: triage.allergies,
      emergency_scale: triage.emergency_scale,
      triage_notes: triage.triage_notes,
      avpu: %{
        alert: triage.alert,
        verbal: triage.verbal,
        pain: triage.pain,
        unresponsive: triage.unresponsive
      },
      recorded_at: triage.inserted_at
    }
  end

  defp doctor_note_payload(note) do
    %{
      doctor: (note.doctor && note.doctor.name) || "Unknown",
      date: note.date,
      time: note.time,
      reason_for_consultation: note.reason_for_consulatation,
      symptoms: note.symptoms,
      diagnosis: note.diagnosis,
      diagnosis_icd_code: note.diagnosis_icd_code,
      impression: note.impression,
      investigations: note.investigations,
      management: note.management,
      clinical_notes: note.clinical_notes,
      lab_imaging_request: note.lab_imaging_request,
      past_medical_history: note.past_medical_history,
      recorded_at: note.inserted_at
    }
  end

  defp lab_result_payload(result) do
    %{
      name: result.name,
      description: result.description,
      urgency: result.urgency,
      date_of_test: result.date_of_test,
      has_paid: result.has_paid,
      total_amount_paid: result.total_amount_paid,
      test_findings: result.test_findings,
      technician_name: result.technician_name,
      tests:
        Enum.map(result.tests || [], fn test ->
          %{
            name: Map.get(test, :name) || Map.get(test, "name"),
            price: Map.get(test, :price) || Map.get(test, "price")
          }
        end),
      recorded_at: result.inserted_at
    }
  end

  defp camp_financials_payload(nil), do: nil

  defp camp_financials_payload(financials) do
    %{
      total_revenue: financials.total_revenue,
      total_paid: financials.total_paid,
      total_pending: financials.total_pending,
      patient_count: financials.patient_count,
      test_count: financials.test_count
    }
  end

  defp empty_reporting do
    %{
      metrics: %{
        registered: 0,
        triaged: 0,
        doctor_reviewed: 0,
        lab_patients: 0,
        tests_done: 0,
        completed_tests: 0,
        pending_tests: 0
      },
      highlights: [
        %{
          label: "Triage Coverage",
          value: "0%",
          detail: "0 of 0 registered patients have been triaged.",
          tone: "indigo"
        },
        %{
          label: "Doctor Review Rate",
          value: "0%",
          detail: "0 patients have doctor notes recorded.",
          tone: "violet"
        },
        %{
          label: "Lab Completion",
          value: "0%",
          detail: "No lab test activity recorded yet.",
          tone: "teal"
        },
        %{
          label: "Collection Rate",
          value: "0%",
          detail: "No billed lab revenue has been collected yet.",
          tone: "emerald"
        }
      ],
      daily_trend: [],
      funnel: [],
      gender_breakdown: [
        %{label: "Male", count: 0},
        %{label: "Female", count: 0},
        %{label: "Unspecified", count: 0}
      ],
      doctor_note_doctors: [],
      patient_types: [],
      age_groups: [],
      tests: [],
      diagnoses: [],
      registration_timeline: %{labels: [], day1: [], day2: []}
    }
  end

  defp build_reporting(patients, stats, triages, doctor_notes, lab_results, financials) do
    triaged_patient_ids = triages |> Enum.map(& &1.patient_id) |> MapSet.new()
    note_patient_ids = doctor_notes |> Enum.map(& &1.patient_id) |> MapSet.new()
    lab_patient_ids = lab_results |> Enum.map(& &1.patient_id) |> MapSet.new()

    patient_lookup =
      patients
      |> Enum.map(fn patient -> {patient.id, patient} end)
      |> Map.new()

    test_entries = Enum.flat_map(lab_results, &expand_lab_tests(&1, patient_lookup))

    tests_done = length(test_entries)
    completed_tests = Enum.count(test_entries, & &1.report_complete)
    pending_tests = max(tests_done - completed_tests, 0)

    gender_breakdown = [
      %{label: "Male", count: stats.male},
      %{label: "Female", count: stats.female},
      %{label: "Unspecified", count: max(stats.total - stats.male - stats.female, 0)}
    ]

    age_groups = [
      %{label: "Under 5", count: stats.age_groups.under_5},
      %{label: "5 - 17", count: stats.age_groups.age_5_17},
      %{label: "18 - 59", count: stats.age_groups.age_18_59},
      %{label: "60+", count: stats.age_groups.over_60}
    ]

    patient_types =
      Enum.map(stats.patient_types, fn {label, count} ->
        %{label: label, count: count}
      end)

    doctor_note_doctors = build_doctor_note_doctor_breakdown(doctor_notes)
    test_breakdown = build_test_breakdown(test_entries, tests_done)
    diagnoses = build_diagnosis_breakdown(doctor_notes)
    daily_trend = build_daily_trend(patients, triages, doctor_notes, test_entries)
    registration_timeline = build_registration_timeline(patients)

    triaged_count = MapSet.size(triaged_patient_ids)
    doctor_reviewed_count = MapSet.size(note_patient_ids)
    lab_patient_count = MapSet.size(lab_patient_ids)

    triage_rate = percent(triaged_count, stats.total)
    doctor_rate = percent(doctor_reviewed_count, stats.total)
    lab_completion_rate = percent(completed_tests, tests_done)
    collection_rate = percent(financials.total_paid, financials.total_revenue)

    %{
      metrics: %{
        registered: stats.total,
        triaged: triaged_count,
        doctor_reviewed: doctor_reviewed_count,
        lab_patients: lab_patient_count,
        tests_done: tests_done,
        completed_tests: completed_tests,
        pending_tests: pending_tests
      },
      highlights: [
        %{
          label: "Triage Coverage",
          value: "#{triage_rate}%",
          detail: "#{triaged_count} of #{stats.total} registered patients received triage.",
          tone: "indigo"
        },
        %{
          label: "Doctor Review Rate",
          value: "#{doctor_rate}%",
          detail: "#{doctor_reviewed_count} patients have doctor notes captured.",
          tone: "violet"
        },
        %{
          label: "Lab Completion",
          value: "#{lab_completion_rate}%",
          detail: "#{completed_tests} complete versus #{pending_tests} pending test entries.",
          tone: "teal"
        },
        %{
          label: "Collection Rate",
          value: "#{collection_rate}%",
          detail:
            "KSh #{delimited(financials.total_paid)} collected out of KSh #{delimited(financials.total_revenue)} billed.",
          tone: "emerald"
        }
      ],
      daily_trend: daily_trend,
      funnel: [
        %{label: "Registered", count: stats.total},
        %{label: "Triaged", count: triaged_count},
        %{label: "Doctor Reviewed", count: doctor_reviewed_count},
        %{label: "Lab Patients", count: lab_patient_count},
        %{label: "Completed Tests", count: completed_tests}
      ],
      gender_breakdown: gender_breakdown,
      doctor_note_doctors: doctor_note_doctors,
      patient_types: patient_types,
      age_groups: age_groups,
      tests: test_breakdown,
      diagnoses: diagnoses,
      registration_timeline: registration_timeline
    }
  end

  defp build_doctor_note_doctor_breakdown(doctor_notes) do
    # The notes are already scoped to this camp's patients, so every one counts;
    # group them by the authoring doctor.
    doctor_notes
    |> Enum.filter(fn note -> note.doctor && note.doctor.name end)
    |> Enum.group_by(fn note ->
      note.doctor.name
    end)
    |> Enum.map(fn {name, notes} ->
      %{
        name: name,
        notes_count: length(notes),
        patients_count: notes |> Enum.map(& &1.patient_id) |> Enum.uniq() |> length()
      }
    end)
    |> Enum.sort_by(
      fn doctor -> {doctor.notes_count, doctor.patients_count, doctor.name} end,
      :desc
    )
  end

  defp build_daily_trend(patients, triages, doctor_notes, test_entries) do
    patient_counts =
      group_counts_by_date(patients, fn patient -> date_from_datetime(patient.inserted_at) end)

    triage_counts = group_counts_by_date(triages, &date_from_record/1)
    note_counts = group_counts_by_date(doctor_notes, &date_from_record/1)
    test_counts = group_counts_by_date(test_entries, & &1.date)

    completed_test_counts =
      group_counts_by_date(Enum.filter(test_entries, & &1.report_complete), & &1.date)

    dates =
      (Enum.map(patients, &date_from_datetime(&1.inserted_at)) ++
         Enum.map(triages, &date_from_record/1) ++
         Enum.map(doctor_notes, &date_from_record/1) ++
         Enum.map(test_entries, & &1.date))
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()
      |> Enum.sort()

    Enum.map(dates, fn date ->
      %{
        date: date,
        label: Calendar.strftime(date, "%d %b"),
        registrations: Map.get(patient_counts, date, 0),
        triaged: Map.get(triage_counts, date, 0),
        doctor_reviews: Map.get(note_counts, date, 0),
        tests: Map.get(test_counts, date, 0),
        completed_tests: Map.get(completed_test_counts, date, 0)
      }
    end)
  end

  defp build_registration_timeline(patients) do
    # Convert inserted_at to Nairobi time (UTC+3) and extract hour
    by_day =
      patients
      |> Enum.map(fn patient ->
        nairobi_dt =
          case patient.inserted_at do
            %DateTime{} = dt ->
              DateTime.shift_zone!(dt, "Africa/Nairobi")

            %NaiveDateTime{} = dt ->
              dt |> DateTime.from_naive!("UTC") |> DateTime.shift_zone!("Africa/Nairobi")
          end

        {DateTime.to_date(nairobi_dt), nairobi_dt.hour}
      end)
      |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))

    all_hours =
      by_day
      |> Map.values()
      |> List.flatten()
      |> Enum.uniq()
      |> Enum.sort()

    min_hour = if all_hours == [], do: 7, else: max(Enum.min(all_hours) - 1, 0)
    max_hour = if all_hours == [], do: 18, else: min(Enum.max(all_hours) + 1, 23)
    hour_range = Enum.to_list(min_hour..max_hour)

    count_by_hour = fn hours ->
      freq = Enum.frequencies(hours)
      Enum.map(hour_range, fn h -> Map.get(freq, h, 0) end)
    end

    %{
      labels:
        Enum.map(hour_range, fn h -> :io_lib.format("~2..0B:00", [h]) |> IO.iodata_to_binary() end),
      day1: count_by_hour.(all_hours),
      day2: []
    }
  end

  defp build_test_breakdown(test_entries, tests_done) do
    test_entries
    |> Enum.group_by(& &1.name)
    |> Enum.map(fn {name, entries} ->
      total = length(entries)
      male = Enum.count(entries, &(&1.gender == "Male"))
      female = Enum.count(entries, &(&1.gender == "Female"))
      other = Enum.count(entries, &(&1.gender not in ["Male", "Female"]))
      completed = Enum.count(entries, & &1.report_complete)
      revenue = Enum.sum(Enum.map(entries, & &1.revenue))

      %{
        name: name,
        total: total,
        male: male,
        female: female,
        other: other,
        completed: completed,
        pending: max(total - completed, 0),
        share: percent(total, tests_done),
        revenue: revenue,
        revenue_label:
          if(revenue > 0, do: "Revenue KSh #{delimited(revenue)}", else: "Volume-only tracking")
      }
    end)
    |> Enum.sort_by(fn test -> {test.total, test.completed, test.revenue} end, :desc)
    |> Enum.take(12)
  end

  defp build_diagnosis_breakdown(doctor_notes) do
    doctor_notes
    |> Enum.map(&diagnosis_label/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
    |> Enum.map(fn {label, count} -> %{label: label, count: count} end)
    |> Enum.sort_by(& &1.count, :desc)
    |> Enum.take(8)
  end

  defp expand_lab_tests(lab_result, patient_lookup) do
    patient = Map.get(patient_lookup, lab_result.patient_id) || lab_result.patient
    gender = patient |> Map.get(:gender) |> normalize_gender()
    event_date = lab_result.date_of_test || date_from_datetime(lab_result.inserted_at)

    tests =
      case lab_result.tests || [] do
        [] ->
          [
            %{
              name: normalize_test_name(lab_result.name),
              revenue: lab_result.total_amount_paid || 0
            }
          ]

        embedded_tests ->
          Enum.map(embedded_tests, fn test ->
            %{
              name: normalize_test_name(Map.get(test, :name) || Map.get(test, "name")),
              revenue: Map.get(test, :price) || Map.get(test, "price") || 0
            }
          end)
      end

    Enum.map(tests, fn test ->
      %{
        name: test.name,
        gender: gender,
        report_complete: lab_result.report_complete,
        date: event_date,
        revenue: test.revenue
      }
    end)
  end

  defp total_test_count(lab_results) do
    lab_results
    |> Enum.flat_map(fn lab_result -> expand_lab_tests(lab_result, %{}) end)
    |> length()
  end

  defp group_counts_by_date(items, date_fun) do
    Enum.reduce(items, %{}, fn item, acc ->
      case date_fun.(item) do
        nil -> acc
        date -> Map.update(acc, date, 1, &(&1 + 1))
      end
    end)
  end

  defp date_from_record(record) do
    Map.get(record, :date) || date_from_datetime(Map.get(record, :inserted_at))
  end

  defp date_from_datetime(nil), do: nil
  defp date_from_datetime(%Date{} = date), do: date
  defp date_from_datetime(%DateTime{} = dt), do: DateTime.to_date(dt)
  defp date_from_datetime(%NaiveDateTime{} = dt), do: NaiveDateTime.to_date(dt)

  defp diagnosis_label(note) do
    [note.diagnosis, note.impression, note.reason_for_consulatation]
    |> Enum.find_value(fn value ->
      value
      |> normalize_text_label()
    end)
  end

  defp normalize_text_label(nil), do: nil

  defp normalize_text_label(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" ->
        nil

      trimmed ->
        trimmed
        |> String.split(~r/[\n;,]/, parts: 2)
        |> List.first()
        |> String.trim()
        |> truncate_label()
    end
  end

  defp normalize_text_label(_), do: nil

  defp truncate_label(nil), do: nil

  defp truncate_label(value) do
    if String.length(value) > 48 do
      String.slice(value, 0, 45) <> "..."
    else
      value
    end
  end

  defp chart_dom_id(title) do
    title
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/u, "-")
    |> String.trim("-")
    |> then(&"medical-camp-chart-#{&1}")
  end

  defp normalize_test_name(nil), do: "Unspecified Test"

  defp normalize_test_name(name) when is_binary(name) do
    name
    |> String.trim()
    |> case do
      "" -> "Unspecified Test"
      value -> value
    end
  end

  defp normalize_test_name(_), do: "Unspecified Test"

  defp normalize_gender("Male"), do: "Male"
  defp normalize_gender("Female"), do: "Female"
  defp normalize_gender(_), do: "Other"

  defp percent(_numerator, 0), do: 0
  defp percent(numerator, denominator), do: round(numerator * 100 / denominator)

  defp delimited(value), do: Number.Delimit.number_to_delimited(value || 0, precision: 0)

  # The UI chrome stays navy/cyan, but *category* charts (diagnoses, test types,
  # patient types, age bands) need distinguishable series colours - one hue per
  # bar/slice - or every bar looks the same and can't be scanned. Fixed order,
  # brand navy + cyan first so 2-3 category charts still read on-brand. See
  # docs/DESIGN.md ("Charts").
  defp camp_palette do
    [
      "#0C2765",
      "#52B2D8",
      "#F59E0B",
      "#22C55E",
      "#8B5CF6",
      "#EC4899",
      "#14B8A6",
      "#F43F5E",
      "#0EA5E9",
      "#94A3B8"
    ]
  end

  defp palette_for(count) do
    Stream.cycle(camp_palette()) |> Enum.take(max(count, 1))
  end

  defp daily_flow_chart(rows) do
    # One distinct colour per day - never the grey "disabled"-looking fallback.
    day_colors = palette_for(length(rows))

    datasets =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {row, i} ->
        %{
          label: row.label,
          data: [row.registrations, row.triaged, row.doctor_reviews, row.tests],
          backgroundColor: Enum.at(day_colors, i),
          borderRadius: 10
        }
      end)

    %{
      type: "bar",
      data: %{
        labels: ["Registrations", "Triaged", "Doctor Notes", "Lab Tests"],
        datasets: datasets
      },
      options:
        base_chart_options(%{
          plugins: %{legend: %{position: "bottom"}},
          scales: %{y: %{beginAtZero: true, ticks: %{precision: 0}}}
        })
    }
  end

  defp registration_timeline_chart(%{labels: labels, day1: day1, day2: day2}) do
    %{
      type: "line",
      data: %{
        labels: labels,
        datasets: [
          %{
            label: "All registrations",
            data: day1,
            borderColor: "rgba(12, 39, 101, 0.9)",
            backgroundColor: "rgba(12, 39, 101, 0.12)",
            borderWidth: 2,
            pointRadius: 4,
            pointHoverRadius: 6,
            tension: 0.4,
            fill: true
          },
          %{
            label: "",
            data: day2,
            borderColor: "rgba(82, 178, 216, 0.9)",
            backgroundColor: "rgba(82, 178, 216, 0.12)",
            borderWidth: 2,
            pointRadius: 4,
            pointHoverRadius: 6,
            tension: 0.4,
            fill: true
          }
        ]
      },
      options:
        base_chart_options(%{
          plugins: %{legend: %{position: "bottom"}},
          scales: %{
            x: %{title: %{display: true, text: "Time of Day (EAT UTC+3)"}},
            y: %{
              beginAtZero: true,
              ticks: %{precision: 0},
              title: %{display: true, text: "Patients Registered"}
            }
          }
        })
    }
  end

  defp camp_gender_chart(rows) do
    %{
      type: "doughnut",
      data: %{
        labels: Enum.map(rows, & &1.label),
        datasets: [
          %{
            data: Enum.map(rows, & &1.count),
            backgroundColor: ["#2563eb", "#ec4899", "#94a3b8"],
            borderWidth: 0
          }
        ]
      },
      options:
        base_chart_options(%{
          cutout: "60%",
          plugins: %{legend: %{position: "bottom"}},
          scales: %{}
        })
    }
  end

  defp patient_type_chart(rows) do
    %{
      type: "bar",
      data: %{
        labels: Enum.map(rows, & &1.label),
        datasets: [
          %{
            label: "Patients",
            data: Enum.map(rows, & &1.count),
            backgroundColor: palette_for(length(rows)),
            borderRadius: 10
          }
        ]
      },
      options:
        base_chart_options(%{
          plugins: %{legend: %{display: false}},
          scales: %{y: %{beginAtZero: true, ticks: %{precision: 0}}}
        })
    }
  end

  defp age_group_chart(rows) do
    %{
      type: "bar",
      data: %{
        labels: Enum.map(rows, & &1.label),
        datasets: [
          %{
            label: "Patients",
            data: Enum.map(rows, & &1.count),
            backgroundColor: palette_for(length(rows)),
            borderRadius: 10
          }
        ]
      },
      options:
        base_chart_options(%{
          plugins: %{legend: %{display: false}},
          scales: %{y: %{beginAtZero: true, ticks: %{precision: 0}}}
        })
    }
  end

  defp test_volume_chart(rows) do
    rows = Enum.take(rows, 8)

    %{
      type: "bar",
      data: %{
        labels: Enum.map(rows, & &1.name),
        datasets: [
          %{
            label: "Tests",
            data: Enum.map(rows, & &1.total),
            backgroundColor: palette_for(length(rows)),
            borderRadius: 10
          }
        ]
      },
      options:
        base_chart_options(%{
          indexAxis: "y",
          plugins: %{legend: %{display: false}},
          scales: %{x: %{beginAtZero: true, ticks: %{precision: 0}}}
        })
    }
  end

  defp test_gender_chart(rows) do
    rows = Enum.take(rows, 8)

    %{
      type: "bar",
      data: %{
        labels: Enum.map(rows, & &1.name),
        datasets: [
          %{
            label: "Male",
            data: Enum.map(rows, & &1.male),
            backgroundColor: "rgba(37, 99, 235, 0.82)",
            borderRadius: 8
          },
          %{
            label: "Female",
            data: Enum.map(rows, & &1.female),
            backgroundColor: "rgba(236, 72, 153, 0.82)",
            borderRadius: 8
          },
          %{
            label: "Other",
            data: Enum.map(rows, & &1.other),
            backgroundColor: "rgba(148, 163, 184, 0.82)",
            borderRadius: 8
          }
        ]
      },
      options:
        base_chart_options(%{
          plugins: %{legend: %{position: "bottom"}},
          scales: %{
            x: %{stacked: true},
            y: %{stacked: true, beginAtZero: true, ticks: %{precision: 0}}
          }
        })
    }
  end

  defp diagnosis_chart(rows) do
    %{
      type: "bar",
      data: %{
        labels: Enum.map(rows, & &1.label),
        datasets: [
          %{
            label: "Doctor Notes",
            data: Enum.map(rows, & &1.count),
            backgroundColor: palette_for(length(rows)),
            borderRadius: 10
          }
        ]
      },
      options:
        base_chart_options(%{
          indexAxis: "y",
          plugins: %{legend: %{display: false}},
          scales: %{x: %{beginAtZero: true, ticks: %{precision: 0}}}
        })
    }
  end

  defp base_chart_options(overrides) do
    Map.merge(
      %{
        responsive: true,
        maintainAspectRatio: false,
        interaction: %{mode: "index", intersect: false},
        plugins: %{
          legend: %{
            labels: %{
              usePointStyle: true,
              boxWidth: 10,
              color: "#334155",
              font: %{family: "ui-sans-serif"}
            }
          },
          tooltip: %{backgroundColor: "#0f172a", titleColor: "#f8fafc", bodyColor: "#e2e8f0"}
        },
        scales: %{
          x: %{grid: %{display: false}, ticks: %{color: "#64748b"}},
          y: %{grid: %{color: "rgba(148, 163, 184, 0.18)"}, ticks: %{color: "#64748b"}}
        }
      },
      overrides
    )
  end

  defp build_preview("summary", %{stats: stats}) do
    rows =
      [
        ["Total Patients Served", stats.total],
        ["Male", stats.male],
        ["Female", stats.female],
        ["Unspecified Gender", max(stats.total - stats.male - stats.female, 0)],
        ["Under 5 yrs", stats.age_groups.under_5],
        ["5 – 17 yrs", stats.age_groups.age_5_17],
        ["18 – 59 yrs", stats.age_groups.age_18_59],
        ["60+ yrs", stats.age_groups.over_60]
      ] ++
        Enum.map(stats.patient_types, fn {type, count} -> ["Patient Type: #{type}", count] end)

    %{title: "Summary Statistics", headers: ["Metric", "Value"], rows: rows}
  end

  defp build_preview("patients", %{
         patients: patients,
         triaged_ids: triaged_ids,
         patient_diagnoses: patient_diagnoses
       }) do
    total = length(patients)

    rows =
      patients
      |> Enum.with_index(1)
      |> Enum.take(50)
      |> Enum.map(fn {p, i} ->
        [
          i,
          full_name(p),
          p.gsrn || "—",
          p.gender || "—",
          p.age || "—",
          age_group_label(p.age),
          p.patient_type || "—",
          if(MapSet.member?(triaged_ids, p.id), do: "Yes", else: "No"),
          Map.get(patient_diagnoses, p.id) || "—"
        ]
      end)

    suffix = if total > 50, do: " (showing 50 of #{total})", else: ""

    %{
      title: "Patient List#{suffix}",
      headers: ["#", "Name", "GSRN", "Gender", "Age", "Age Group", "Type", "Triaged", "Diagnosis"],
      rows: rows
    }
  end

  defp build_preview("geography", %{geographic_breakdown: breakdown}) do
    rows =
      Enum.map(breakdown, fn %{address: address, count: count, pct: pct} ->
        [address, count, "#{pct}%"]
      end)

    %{
      title: "Geographic Spread",
      headers: ["Location / Address", "Patient Count", "% of Total"],
      rows: rows
    }
  end

  defp build_preview("diagnoses", %{camp_doctor_notes: notes, patients: patients}) do
    patient_lookup = Map.new(patients, fn p -> {p.id, p} end)

    rows =
      notes
      |> Enum.map(fn note ->
        label = diagnosis_label(note)
        patient = Map.get(patient_lookup, note.patient_id)
        gender = (patient && patient.gender) || "Unspecified"
        {label, gender}
      end)
      |> Enum.reject(fn {label, _} -> is_nil(label) end)
      |> Enum.group_by(fn {label, _} -> label end)
      |> Enum.map(fn {label, entries} ->
        total = length(entries)
        male = Enum.count(entries, fn {_, g} -> g == "Male" end)
        female = Enum.count(entries, fn {_, g} -> g == "Female" end)
        other = total - male - female
        [label, total, male, female, other]
      end)
      |> Enum.sort_by(fn [_, total | _] -> total end, :desc)

    %{
      title: "Diagnosis Data",
      headers: ["Diagnosis / Impression", "Total Cases", "Male", "Female", "Unspecified"],
      rows: rows
    }
  end

  defp full_name(patient) do
    [patient.first_name, patient.middle_name, patient.last_name]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(" ")
  end

  defp format_datetime(nil), do: "—"
  defp format_datetime(dt), do: Calendar.strftime(dt, "%d %b %Y %H:%M")

  defp format_time(nil), do: "—"

  defp format_time(dt) do
    dt
    |> DateTime.add(3 * 3600, :second)
    |> Calendar.strftime("%H:%M")
  end

  defp gender_badge("Male"), do: "bg-blue-50 text-blue-700"
  defp gender_badge("Female"), do: "bg-pink-50 text-pink-700"
  defp gender_badge(_), do: "bg-slate-100 text-slate-500"

  defp urgency_badge("Urgent"), do: "bg-red-100 text-red-700"
  defp urgency_badge("Routine"), do: "bg-green-100 text-green-700"
  defp urgency_badge(_), do: "bg-slate-100 text-slate-600"

  defp emergency_scale_style("1"), do: "bg-green-100 text-green-700"
  defp emergency_scale_style("2"), do: "bg-yellow-100 text-yellow-700"
  defp emergency_scale_style("3"), do: "bg-orange-100 text-orange-700"
  defp emergency_scale_style("4"), do: "bg-red-100 text-red-700"
  defp emergency_scale_style("5"), do: "bg-red-200 text-red-900"
  defp emergency_scale_style(_), do: "bg-slate-100 text-slate-600"

  # One flat card style for every KPI tile - hairline border, no tint, no shadow
  # (Tibasasa system). The `color` arg is kept for call-site compatibility.
  defp camp_stat_style(_), do: "bg-white border-slate-200"

  defp camp_stat_value_color(_), do: "text-brand-primary"

  defp bar_color("amber"), do: "bg-amber-400"
  defp bar_color("green"), do: "bg-green-500"
  defp bar_color("blue"), do: "bg-blue-500"
  defp bar_color("rose"), do: "bg-rose-400"
  defp bar_color("indigo"), do: "bg-indigo-500"
  defp bar_color(_), do: "bg-slate-400"

  defp vital_style("red"), do: "bg-red-50 border-red-100"
  defp vital_style("rose"), do: "bg-rose-50 border-rose-100"
  defp vital_style("blue"), do: "bg-blue-50 border-blue-100"
  defp vital_style("cyan"), do: "bg-cyan-50 border-cyan-100"
  defp vital_style("green"), do: "bg-green-50 border-green-100"
  defp vital_style("indigo"), do: "bg-indigo-50 border-indigo-100"
  defp vital_style("purple"), do: "bg-slate-50 border-purple-100"
  defp vital_style(_), do: "bg-slate-50 border-slate-200"

  defp age_group_label(nil), do: "Unknown"
  defp age_group_label(age) when age < 5, do: "Under 5"
  defp age_group_label(age) when age < 18, do: "5 – 17"
  defp age_group_label(age) when age < 60, do: "18 – 59"
  defp age_group_label(_age), do: "60+"
end
