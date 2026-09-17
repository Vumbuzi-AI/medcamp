defmodule MedcampWeb.MedicalCampPages.DoctorNoteNew do
  use MedcampWeb, :live_view

  alias MedcampWeb.PublicTenant
  alias Medcamp.DoctorNotes
  alias Medcamp.DoctorNotes.DoctorNote
  alias Medcamp.Patients.Patient
  alias Medcamp.Triages
  alias Medcamp.Accounts

  @impl true
  def mount(%{"gsrn" => gsrn}, session, socket) do
    patient = PublicTenant.resolve_patient!(gsrn)

    current_user =
      case session["user_token"] do
        nil -> nil
        token -> Accounts.get_user_by_session_token(token)
      end

    base_attrs = %{
      "patient_id" => to_string(patient.id),
      "date" => Date.utc_today() |> Date.to_iso8601(),
      "time" =>
        Time.utc_now()
        |> Time.add(3 * 60 * 60, :second)
        |> Time.truncate(:second)
        |> Time.to_string()
        |> String.slice(0..7)
    }

    note = %DoctorNote{}
    changeset = DoctorNotes.change_doctor_note(note, base_attrs)

    {:ok,
     socket
     |> assign(:patient, patient)
     |> assign(:current_user, current_user)
     |> assign(:doctor_note, note)
     |> assign(:form, to_form(changeset))
     |> assign(:active_tab, :doctor_notes)
     |> assign(:panel, :note)
     |> assign(:latest_triage, Triages.most_recent_triage(patient.id))
     |> assign(:doctor_notes, DoctorNotes.doctor_notes_for_patient(patient.id))
     |> assign(:back_url, "/8018/#{patient.gsrn}/medical-camp/doctor_notes")
     |> assign(:page_title, "New Doctor Note")}
  end

  @impl true
  def handle_event("switch_panel", %{"panel" => panel}, socket) do
    {:noreply, assign(socket, :panel, String.to_existing_atom(panel))}
  end

  def handle_event("validate", %{"doctor_note" => params}, socket) do
    changeset = DoctorNotes.change_doctor_note(socket.assigns.doctor_note, params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"doctor_note" => params}, socket) do
    params =
      params
      |> Map.put("patient_id", socket.assigns.patient.id)
      |> Map.put("doctor_id", socket.assigns.current_user.id)

    case DoctorNotes.create_doctor_note(params) do
      {:ok, note} ->
        {:noreply,
         socket
         |> put_flash(:info, "Doctor note created successfully")
         |> push_event("draft_saved", %{})
         |> push_navigate(
           to: "/8018/#{socket.assigns.patient.gsrn}/medical-camp/doctor_notes/#{note.id}"
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full">
      <div class="bg-white rounded-lg border border-slate-200 shadow-sm p-4 mb-4">
        <h2 class="text-lg font-bold text-slate-800">
          {full_name(@patient)}
        </h2>
        <p class="text-sm text-slate-500">
          GSRN: {@patient.gsrn} · {@patient.gender || "-"} · {age_label(@patient)}
        </p>
      </div>

      <div class="flex gap-1 border-b border-slate-200 mb-4 overflow-x-auto">
        <.panel_tab panel={:note} active={@panel} label="New Note" />
        <.panel_tab panel={:triage} active={@panel} label="Triage & Bio Data" />
        <.panel_tab
          panel={:previous}
          active={@panel}
          label={"Previous Notes (#{length(@doctor_notes)})"}
        />
      </div>

      <%!-- Kept mounted rather than `:if`d away so the draft hook does not lose
           anything the doctor typed before flipping to the triage tab. --%>
      <div class={@panel != :note && "hidden"}>
        <h1 class="text-xl font-semibold text-brand-primary mb-4">Doctor's Note</h1>
        <.doctor_notes_form
          patient={@patient}
          show_lab_imaging_request={false}
          form={@form}
          draft_key={"doctor_note:#{@patient.id}:new"}
        />
      </div>

      <div :if={@panel == :triage} class="space-y-4">
        <div class="bg-white rounded-lg border border-slate-200 shadow-sm p-4">
          <h3 class="text-lg font-semibold text-brand-primary mb-3">Latest Triage</h3>
          <.triage_vitals_grid :if={@latest_triage} triage={@latest_triage} />
          <p :if={is_nil(@latest_triage)} class="text-sm text-slate-500">
            No triage has been recorded for this patient yet.
          </p>
        </div>

        <div class="bg-white rounded-lg border border-slate-200 shadow-sm p-4">
          <h3 class="text-lg font-semibold text-brand-primary mb-3">Bio Data</h3>
          <div class="grid grid-cols-2 sm:grid-cols-3 gap-3 text-sm">
            <.bio_field label="Full Name" value={full_name(@patient)} />
            <.bio_field label="GSRN" value={@patient.gsrn} />
            <.bio_field label="Gender" value={@patient.gender} />
            <.bio_field label="Date of Birth" value={@patient.date_of_birth} />
            <.bio_field label="Age" value={age_label(@patient)} />
            <.bio_field label="Phone Number" value={@patient.phone_number} />
            <.bio_field label="Email" value={@patient.email} />
            <.bio_field label="National ID" value={@patient.national_id} />
            <.bio_field label="Home Address" value={@patient.home_address} />
            <.bio_field label="Insurance" value={@patient.insurance_company} />
            <.bio_field label="Insurance Number" value={@patient.insurance_number} />
            <.bio_field label="Emergency Contact" value={emergency_contact(@patient)} />
          </div>
        </div>
      </div>

      <div :if={@panel == :previous} class="bg-white rounded-lg border border-slate-200 shadow-sm p-4">
        <h3 class="text-lg font-semibold text-brand-primary mb-3">Previous Notes</h3>
        <p :if={@doctor_notes == []} class="text-sm text-slate-500">
          No notes have been written for this patient yet.
        </p>
        <div class="divide-y divide-slate-100">
          <%= for note <- @doctor_notes do %>
            <a
              href={"/8018/#{@patient.gsrn}/medical-camp/doctor_notes/#{note.id}"}
              class="flex items-center justify-between py-3 hover:bg-slate-50 rounded px-2 transition-colors group"
            >
              <div>
                <p class="text-sm font-medium text-slate-800">
                  {note.date && Calendar.strftime(note.date, "%d %b %Y")}
                  <span :if={note.time} class="text-slate-500 font-normal ml-1">
                    · {note.time |> Time.to_string() |> String.slice(0..4)}
                  </span>
                </p>
                <p :if={note.symptoms} class="text-xs text-slate-500 mt-0.5 truncate max-w-xs">
                  {note.symptoms}
                </p>
                <p :if={note.doctor} class="text-xs text-brand-accent mt-0.5">
                  Dr. {note.doctor.name}
                </p>
              </div>
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-4 w-4 text-slate-400 group-hover:text-brand-primary shrink-0"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M9 5l7 7-7 7"
                />
              </svg>
            </a>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  attr :panel, :atom, required: true
  attr :active, :atom, required: true
  attr :label, :string, required: true

  defp panel_tab(assigns) do
    ~H"""
    <button
      type="button"
      phx-click="switch_panel"
      phx-value-panel={@panel}
      class={[
        "px-4 py-2 text-sm font-medium whitespace-nowrap border-b-2 -mb-px transition-colors",
        if(@active == @panel,
          do: "border-brand-accent text-brand-primary",
          else: "border-transparent text-slate-500 hover:text-slate-700"
        )
      ]}
    >
      {@label}
    </button>
    """
  end

  attr :label, :string, required: true
  attr :value, :any, required: true

  defp bio_field(assigns) do
    ~H"""
    <div class="bg-slate-50 rounded p-2">
      <span class="text-slate-500 block">{@label}</span>
      <span class="font-medium">{blank_to_dash(@value)}</span>
    </div>
    """
  end

  defp blank_to_dash(nil), do: "-"
  defp blank_to_dash(""), do: "-"
  defp blank_to_dash(value), do: value

  defp full_name(patient) do
    [patient.first_name, patient.middle_name, patient.last_name]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" ")
  end

  defp age_label(patient) do
    case Patient.calculate_age(patient.date_of_birth) do
      nil -> nil
      age -> "#{age} yrs"
    end
  end

  defp emergency_contact(patient) do
    [patient.emergency_contact_name, patient.emergency_contact_phone_number]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(" · ")
  end
end
