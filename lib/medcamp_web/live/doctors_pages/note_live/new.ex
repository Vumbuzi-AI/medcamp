defmodule MedcampWeb.DoctorsPagePatientLive.DoctorNoteNew do
  use MedcampWeb, :each_patient_live_view
  alias Medcamp.Patients
  alias Medcamp.DoctorNotes
  alias Medcamp.DoctorNotes.DoctorNote
  alias Medcamp.PatientVisits

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :doctor_notes)
     |> assign(:patient_visit, nil)
     |> stream(:doctor_notes, DoctorNotes.list_doctor_notes())}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    patient = Patients.get_patient!(id)
    params = put_latest_visit_id(params, patient.id)
    {doctor_note, form} = build_initial_note(patient.id, params)

    {:noreply,
     socket
     |> assign(:patient, patient)
     |> assign(:form, to_form(form))
     |> assign(:doctor_note, doctor_note)
     |> assign(:patient_visit, safe_get_patient_visit(params["patient_visit_id"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp put_latest_visit_id(%{"patient_visit_id" => _} = params, _patient_id), do: params

  defp put_latest_visit_id(params, patient_id) do
    case PatientVisits.latest_visit_without_doctor_note(patient_id) do
      nil -> params
      visit -> Map.put(params, "patient_visit_id", to_string(visit.id))
    end
  end

  defp build_initial_note(patient_id, params) do
    base_attrs = base_attrs_for(patient_id)

    attrs =
      case params["patient_visit_id"] do
        nil ->
          base_attrs

        visit_id ->
          visit = PatientVisits.get_patient_visit!(visit_id)

          base_attrs
          |> Map.put("patient_visit_id", visit_id)
          |> Map.put("date", Date.to_iso8601(visit.date))
          |> Map.put(
            "time",
            (visit.time && Time.to_string(visit.time) |> String.slice(0..7)) || base_attrs["time"]
          )
          |> Map.put("reason_for_consulatation", visit.reason)
      end

    note = %DoctorNote{}
    changeset = DoctorNotes.change_doctor_note(note, attrs)
    {note, changeset}
  rescue
    Ecto.NoResultsError ->
      {%DoctorNote{}, DoctorNotes.change_doctor_note(%DoctorNote{}, base_attrs_for(patient_id))}
  end

  defp maybe_put_patient_visit_id(params, %{id: id}),
    do: Map.put(params, "patient_visit_id", to_string(id))

  defp maybe_put_patient_visit_id(params, _), do: params

  defp safe_get_patient_visit(nil), do: nil
  defp safe_get_patient_visit(""), do: nil

  defp safe_get_patient_visit(id) do
    PatientVisits.get_patient_visit!(id)
  rescue
    Ecto.NoResultsError -> nil
  end

  defp base_attrs_for(patient_id) do
    %{
      "patient_id" => to_string(patient_id),
      "date" => Date.utc_today() |> Date.to_iso8601(),
      "time" =>
        Time.utc_now()
        |> Time.add(3 * 60 * 60, :second)
        |> Time.truncate(:second)
        |> Time.to_string()
        |> String.slice(0..7)
    }
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Add Doctor notes")
    |> assign(:live_action, :index)
  end

  defp maybe_fill_diagnosis_from_icd(params) do
    case Map.get(params, "diagnosis_icd_code") do
      nil ->
        params

      "" ->
        params

      code ->
        title = Medcamp.Icd11.list() |> Enum.find_value(fn {c, t} -> if c == code, do: t end)
        if title, do: Map.put(params, "diagnosis", title), else: params
    end
  end

  @impl true
  def handle_event("validate", %{"doctor_note" => doctor_note_params}, socket) do
    params =
      doctor_note_params
      |> maybe_fill_diagnosis_from_icd()
      |> maybe_put_patient_visit_id(socket.assigns.patient_visit)

    changeset = DoctorNotes.change_doctor_note(socket.assigns.doctor_note, params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  @impl true
  def handle_event("save", %{"doctor_note" => doctor_note_params}, socket) do
    doctor_note_params =
      doctor_note_params
      |> Map.put("patient_id", socket.assigns.patient.id)
      |> Map.put("doctor_id", socket.assigns.current_user.id)
      |> maybe_put_patient_visit_id(socket.assigns.patient_visit)

    case DoctorNotes.create_doctor_note(doctor_note_params) do
      {:ok, doctor_note} ->
        {:noreply,
         socket
         |> put_flash(:info, "Doctor note created successfully")
         |> push_event("draft_saved", %{})
         |> push_navigate(
           to:
             "/doctor/patients/#{socket.assigns.patient.id}/notes/#{doctor_note.id}/after_create"
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full">
      <h1 class="text-xl font-semibold text-[#373896] mb-4 flex items-center">
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
        Doctor's Notes
      </h1>
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
