defmodule MedcampWeb.MedicalCampPages.DoctorNoteNew do
  use MedcampWeb, :live_view

  alias MedcampWeb.PublicTenant
  alias Medcamp.DoctorNotes
  alias Medcamp.DoctorNotes.DoctorNote
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
     |> assign(:doctor_notes, DoctorNotes.doctor_notes_for_patient(patient.id))
     |> assign(:back_url, "/8018/#{patient.gsrn}/medical-camp/doctor_notes")
     |> assign(:page_title, "New Doctor Note")}
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
        :if={@doctor_notes != []}
        class="bg-white mt-4 rounded-lg border border-gray-200 shadow-sm p-4 mt-6"
      >
        <h3 class="text-lg font-semibold text-brand-primary mb-3">Previous Notes</h3>
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
                <p :if={note.doctor} class="text-xs text-brand-accent mt-0.5">
                  Dr. {note.doctor.name}
                </p>
              </div>
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-4 w-4 text-gray-400 group-hover:text-brand-primary flex-shrink-0"
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
      <h1 class="text-xl font-semibold text-brand-primary mb-4">Doctor's Note</h1>
      <.doctor_notes_form
        patient={@patient}
        show_lab_imaging_request={false}
        form={@form}
        draft_key={"doctor_note:#{@patient.id}:new"}
      />
    </div>
    """
  end
end
