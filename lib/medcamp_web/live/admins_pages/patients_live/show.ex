defmodule MedcampWeb.AdminPatientsLive.Show do
  use MedcampWeb, :admin_live_view

  alias Medcamp.Patients
  alias Medcamp.Triages
  alias Medcamp.PatientVisits
  alias Medcamp.DoctorNotes
  alias Medcamp.LabResults

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :active_tab, :patients)}
  end

  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    patient = Patients.get_patient!(id)
    most_recent_triage = Triages.most_recent_triage(id)

    visits = PatientVisits.list_patient_visits_by_patient_id(id)
    lab_results = LabResults.list_lab_results_for_patient(id)
    doctor_notes = DoctorNotes.doctor_notes_for_patient(id)

    metrics = %{
      visits_count: length(visits),
      last_visit_date: visits |> List.first() |> then(fn v -> v && v.date end),
      lab_results_count: length(lab_results),
      doctor_notes_count: length(doctor_notes)
    }

    {:noreply,
     socket
     |> assign(:page_title, "Patient Overview")
     |> assign(:patient, patient)
     |> assign(:most_recent_triage, most_recent_triage)
     |> assign(:metrics, metrics)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-slate-50 via-white to-slate-100 -m-4 sm:-m-6 p-4 sm:p-6">
      <div class="w-[90%] mx-auto  space-y-6">
        <.patient_overview_to_show_all
          most_recent_triage={@most_recent_triage}
          patient={@patient}
          back_url="/admin/patients"
        />

        <div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-5 gap-4 sm:gap-5">
          <.metric_card
            title="Total Visits"
            value={@metrics.visits_count}
            tone="indigo"
            icon="calendar"
          />
          <.metric_card
            title="Last Visit Date"
            value={format_date(@metrics.last_visit_date)}
            tone="blue"
            icon="clock"
          />
          <.metric_card
            title="Lab Results"
            value={@metrics.lab_results_count}
            tone="emerald"
            icon="beaker"
          />
          <.metric_card
            title="Doctor Notes"
            value={@metrics.doctor_notes_count}
            tone="amber"
            icon="document"
          />
        </div>

        <.patient_detailed_overview patient={@patient} most_recent_triage={@most_recent_triage} />

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-4 sm:gap-6">
          <div class="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
            <div class="px-5 py-4 border-b border-slate-200 bg-slate-50/80">
              <h3 class="text-base font-semibold text-slate-800 flex items-center">
                <div class="w-8 h-8 rounded-lg bg-brand-accent flex items-center justify-center mr-3">
                  <svg
                    class="h-4 w-4 text-white"
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
                Clinical Activity Summary
              </h3>
            </div>

            <div class="p-5 space-y-3">
              <.activity_row
                label="Patient visits"
                value={to_string(@metrics.visits_count)}
                tone="indigo"
              />
              <.activity_row
                label="Lab results recorded"
                value={to_string(@metrics.lab_results_count)}
                tone="emerald"
              />
              <.activity_row
                label="Doctor notes filed"
                value={to_string(@metrics.doctor_notes_count)}
                tone="amber"
              />
              <.activity_row
                label="Last facility interaction"
                value={format_date(@metrics.last_visit_date)}
                tone="blue"
              />
            </div>
          </div>

          <div class="bg-gradient-to-br from-slate-50 to-slate-100 rounded-2xl border border-slate-200 p-6">
            <h3 class="text-base font-semibold text-slate-800 mb-4 flex items-center">
              <div class="w-8 h-8 rounded-lg bg-slate-700 flex items-center justify-center mr-3">
                <svg class="h-4 w-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                  />
                </svg>
              </div>
              Admin Snapshot
            </h3>

            <div class="space-y-3">
              <.info_row label="Patient ID" value={@patient.id} />
              <.info_row label="GSRN" value={@patient.gsrn || "—"} />
              <.info_row label="Phone" value={@patient.phone_number || "—"} />
              <.info_row label="Gender" value={@patient.gender || "—"} />
              <.info_row label="Date of Birth" value={@patient.date_of_birth || "—"} />
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp patient_detailed_overview(assigns) do
    ~H"""
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-4 sm:gap-6">
      <div class="bg-gradient-to-br from-slate-50 to-slate-100 rounded-2xl p-4 sm:p-5 border border-slate-200 shadow-sm">
        <h3 class="text-base font-semibold text-slate-800 mb-4 flex items-center">
          <div class="w-8 h-8 rounded-lg bg-brand-accent flex items-center justify-center mr-3">
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
              |> Enum.filter(&(&1 not in [nil, ""]))
              |> Enum.join(" ")
            }
          />
          <.info_row label="GSRN" value={@patient.gsrn || "—"} />
          <.info_row label="Date of Birth" value={@patient.date_of_birth || "—"} />
          <.info_row label="Phone" value={@patient.phone_number || "—"} />
          <.info_row label="Gender" value={@patient.gender || "—"} />
        </div>
      </div>

      <%= if @most_recent_triage do %>
        <div class="bg-gradient-to-br from-blue-50 to-indigo-50 rounded-2xl p-4 sm:p-5 border border-blue-200 shadow-sm">
          <h3 class="text-base font-semibold text-slate-800 mb-4 flex items-center">
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
              <.triage_metric label="Blood Pressure" value={@most_recent_triage.blood_pressure} />
            <% end %>
            <%= if @most_recent_triage.temperature do %>
              <.triage_metric label="Temperature" value={"#{@most_recent_triage.temperature}°C"} />
            <% end %>
            <%= if @most_recent_triage.weight do %>
              <.triage_metric label="Weight" value={"#{@most_recent_triage.weight} kg"} />
            <% end %>
            <%= if @most_recent_triage.height do %>
              <.triage_metric label="Height" value={"#{@most_recent_triage.height} cm"} />
            <% end %>
          </div>

          <p class="text-xs text-slate-500 mt-4 text-center">
            Recorded: {format_datetime(@most_recent_triage.inserted_at)}
          </p>
        </div>
      <% else %>
        <div class="bg-slate-50 rounded-2xl p-6 border border-slate-200 flex items-center justify-center shadow-sm">
          <p class="text-slate-500">No triage information available</p>
        </div>
      <% end %>
    </div>
    """
  end

  attr :title, :string, required: true
  attr :value, :any, required: true
  attr :tone, :string, required: true
  attr :icon, :string, required: true

  defp metric_card(assigns) do
    ~H"""
    <div class={[
      "rounded-2xl border p-4 shadow-sm",
      metric_card_tone(@tone)
    ]}>
      <div class="flex items-start justify-between gap-4">
        <div>
          <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">{@title}</p>
          <p class="mt-2 text-xl font-bold text-slate-900 break-words leading-tight">{@value}</p>
        </div>
        <div class={[
          "w-10 h-10 rounded-xl flex items-center justify-center",
          metric_icon_tone(@tone)
        ]}>
          <.metric_icon icon={@icon} />
        </div>
      </div>
    </div>
    """
  end

  attr :icon, :string, required: true

  defp metric_icon(assigns) do
    ~H"""
    <svg
      :if={@icon == "calendar"}
      class="h-5 w-5 text-white"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
    >
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M8 7V3m8 4V3m-9 8h10m-11 9h12a2 2 0 002-2V7a2 2 0 00-2-2H6a2 2 0 00-2 2v11a2 2 0 002 2z"
      />
    </svg>
    <svg
      :if={@icon == "clock"}
      class="h-5 w-5 text-white"
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
    <svg
      :if={@icon == "beaker"}
      class="h-5 w-5 text-white"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
    >
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M19.428 15.428a4 4 0 00-5.656 0M6.343 6.343a8 8 0 0111.314 0M9.172 9.172a4 4 0 015.656 0M12 20h.01M4.929 19.071a10 10 0 0114.142 0"
      />
    </svg>
    <svg
      :if={@icon == "document"}
      class="h-5 w-5 text-white"
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
    <svg
      :if={@icon == "currency"}
      class="h-5 w-5 text-white"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
    >
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M12 8c-2.21 0-4 1.119-4 2.5S9.79 13 12 13s4 1.119 4 2.5S14.21 18 12 18m0-10V6m0 12v-2m0 0c-1.657 0-3-.672-3-1.5m3 1.5c1.657 0 3-.672 3-1.5M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
      />
    </svg>
    """
  end

  attr :label, :string, required: true
  attr :value, :any, required: true

  defp info_row(assigns) do
    ~H"""
    <div class="flex items-start justify-between gap-4 py-3 border-b border-slate-200 last:border-b-0">
      <span class="text-sm font-medium text-slate-500">{@label}</span>
      <span class="text-sm font-semibold text-slate-900 text-right break-words">{@value}</span>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :value, :string, required: true

  defp triage_metric(assigns) do
    ~H"""
    <div class="bg-white/60 rounded-lg p-3 text-center">
      <p class="text-xs text-slate-500 uppercase font-medium">{@label}</p>
      <p class="text-base font-semibold text-slate-800">{@value}</p>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :value, :string, required: true
  attr :tone, :string, required: true

  defp activity_row(assigns) do
    ~H"""
    <div class="flex items-center justify-between rounded-xl border border-slate-200 px-4 py-3 bg-white">
      <span class="text-sm font-medium text-slate-600">{@label}</span>
      <span class={[
        "inline-flex items-center rounded-full px-3 py-1 text-sm font-semibold",
        activity_badge_tone(@tone)
      ]}>
        {@value}
      </span>
    </div>
    """
  end

  defp metric_card_tone("indigo"),
    do: "bg-gradient-to-br from-indigo-50 to-white border-indigo-200"

  defp metric_card_tone("blue"), do: "bg-gradient-to-br from-blue-50 to-white border-blue-200"

  defp metric_card_tone("emerald"),
    do: "bg-gradient-to-br from-emerald-50 to-white border-emerald-200"

  defp metric_card_tone("amber"), do: "bg-gradient-to-br from-amber-50 to-white border-amber-200"
  defp metric_card_tone("rose"), do: "bg-gradient-to-br from-rose-50 to-white border-rose-200"
  defp metric_card_tone(_), do: "bg-white border-slate-200"

  defp metric_icon_tone("indigo"), do: "bg-brand-accent"
  defp metric_icon_tone("blue"), do: "bg-blue-500"
  defp metric_icon_tone("emerald"), do: "bg-emerald-500"
  defp metric_icon_tone("amber"), do: "bg-amber-500"
  defp metric_icon_tone("rose"), do: "bg-rose-500"
  defp metric_icon_tone(_), do: "bg-slate-600"

  defp activity_badge_tone("indigo"), do: "bg-indigo-100 text-indigo-700"
  defp activity_badge_tone("blue"), do: "bg-blue-100 text-blue-700"
  defp activity_badge_tone("emerald"), do: "bg-emerald-100 text-emerald-700"
  defp activity_badge_tone("amber"), do: "bg-amber-100 text-amber-700"
  defp activity_badge_tone("rose"), do: "bg-rose-100 text-rose-700"
  defp activity_badge_tone(_), do: "bg-slate-100 text-slate-700"

  defp format_date(nil), do: "—"
  defp format_date(%Date{} = date), do: Calendar.strftime(date, "%B %d, %Y")
  defp format_date(value), do: to_string(value)

  defp format_datetime(nil), do: "—"

  defp format_datetime(datetime) do
    Calendar.strftime(datetime, "%B %d, %Y at %I:%M %p")
  end
end
