defmodule MedcampWeb.MedicalCampPages.DoctorNotes do
  use MedcampWeb, :live_view
  alias Medcamp.Patients
  alias Medcamp.DoctorNotes
  alias Medcamp.DoctorNotes.DoctorNote
  alias Medcamp.Triages
  alias Medcamp.Accounts

  @impl true
  def mount(%{"gsrn" => gsrn} = _params, session, socket) do
    patient = Patients.get_patient_by_gsrn(gsrn)
    most_recent_triage = Triages.most_recent_triage(patient.id)

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
     |> assign(:active_tab, :overview)
     |> assign(:back_url, "/8018/#{patient.gsrn}/medical-camp")
     |> assign(:patient, patient)
     |> assign(:current_user, current_user)
     |> assign(:most_recent_triage, most_recent_triage)
     |> assign(:doctor_note, note)
     |> assign(:form, to_form(changeset))
     |> assign(:page_title, "Doctor Notes")
     |> assign(:doctor_notes, DoctorNotes.doctor_notes_for_patient(patient.id))}
  end

  @impl true
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
      <div
        :if={@most_recent_triage}
        class="bg-white rounded-lg border border-gray-200 shadow-sm p-4 mb-6"
      >
        <h3 class="text-lg font-semibold text-[#373896] mb-1">Most Recent Triage</h3>
        <p class="text-sm text-gray-600 mb-3">
          <span class="font-medium">
            {[@patient.first_name, @patient.middle_name, @patient.last_name]
            |> Enum.filter(&(&1 != nil))
            |> Enum.join(" ")}
          </span>
          <span class="mx-1 text-gray-400">·</span>
          DOB: <span class="font-medium">{@patient.date_of_birth}</span>
        </p>
        <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3 text-sm">
          <div class="bg-gray-50 rounded p-2">
            <span class="text-gray-500 block">Date</span>
            <span class="font-medium">{@most_recent_triage.date}</span>
          </div>
          <div class="bg-gray-50 rounded p-2">
            <span class="text-gray-500 block">Temperature</span>
            <span class="font-medium">{@most_recent_triage.temperature || "-"} °C</span>
          </div>
          <div class="bg-gray-50 rounded p-2">
            <span class="text-gray-500 block">Blood Pressure</span>
            <span class="font-medium">{@most_recent_triage.blood_pressure || "-"}</span>
          </div>
          <div class="bg-gray-50 rounded p-2">
            <span class="text-gray-500 block">Pulse Rate</span>
            <span class="font-medium">{@most_recent_triage.pulse_rate || "-"} bpm</span>
          </div>
          <div class="bg-gray-50 rounded p-2">
            <span class="text-gray-500 block">O2 Saturation</span>
            <span class="font-medium">{@most_recent_triage.oxygen_saturation || "-"} %</span>
          </div>
          <div class="bg-gray-50 rounded p-2">
            <span class="text-gray-500 block">Weight</span>
            <span class="font-medium">{@most_recent_triage.weight || "-"} kg</span>
          </div>
          <div class="bg-gray-50 rounded p-2">
            <span class="text-gray-500 block">Height</span>
            <span class="font-medium">{@most_recent_triage.height || "-"} cm</span>
          </div>
          <div class="bg-gray-50 rounded p-2">
            <span class="text-gray-500 block">Emergency</span>
            <span class={[
              "font-medium",
              @most_recent_triage.emergency_scale == "High" && "text-red-600",
              @most_recent_triage.emergency_scale == "Medium" && "text-amber-600",
              @most_recent_triage.emergency_scale == "Low" && "text-green-600"
            ]}>
              {@most_recent_triage.emergency_scale || "-"}
            </span>
          </div>
        </div>
        <div :if={@most_recent_triage.allergies} class="mt-3 bg-red-50 rounded p-2 text-sm">
          <span class="text-red-600 font-medium">Allergies:</span>
          <span class="text-red-800">{@most_recent_triage.allergies}</span>
        </div>
        <div :if={@most_recent_triage.triage_notes} class="mt-2 bg-gray-50 rounded p-2 text-sm">
          <span class="text-gray-500 font-medium">Notes:</span>
          <span>{@most_recent_triage.triage_notes}</span>
        </div>
      </div>

      <h1 class="text-xl font-semibold text-[#373896] mb-4">New Doctor's Note</h1>
      <.doctor_notes_form
        patient={@patient}
        show_lab_imaging_request={false}
        form={@form}
        draft_key={"doctor_note:#{@patient.id}:new"}
      />

      <%!-- Previous notes --%>
      <div
        :if={@doctor_notes != []}
        class="bg-white rounded-lg border border-gray-200 shadow-sm p-4 mt-6"
      >
        <h3 class="text-lg font-semibold text-[#373896] mb-3">Previous Notes</h3>
        <div class="divide-y divide-gray-100">
          <%= for note <- @doctor_notes do %>
            <a
              href={"/8018/#{@patient.gsrn}/medical-camp/doctor_notes/#{note.id}"}
              class="flex items-center justify-between py-3 hover:bg-gray-50 rounded px-2 transition-colors group"
            >
              <div>
                <p class="text-sm font-medium text-gray-800">
                  {note.date && Calendar.strftime(note.date, "%d %b %Y")}
                  <span :if={note.time} class="text-gray-500 font-normal ml-1">
                    · {note.time |> Time.to_string() |> String.slice(0..4)}
                  </span>
                </p>
                <p :if={note.symptoms} class="text-xs text-gray-500 mt-0.5 truncate max-w-xs">
                  {note.symptoms}
                </p>
                <p :if={note.doctor} class="text-xs text-[#6667ab] mt-0.5">
                  Dr. {note.doctor.name}
                </p>
              </div>
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-4 w-4 text-gray-400 group-hover:text-[#373896] flex-shrink-0"
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
end
