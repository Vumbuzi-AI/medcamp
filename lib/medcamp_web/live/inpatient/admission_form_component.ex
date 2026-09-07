defmodule MedcampWeb.Inpatient.AdmissionFormComponent do
  use MedcampWeb, :live_component

  alias Medcamp.Inpatient

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header class="mb-4">
        {@title}
        <:subtitle>Record new patient admission</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="admission-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <.input field={@form[:admission_date]} type="date" label="Admission Date" />
          <.input field={@form[:admission_time]} type="time" label="Admission Time" />
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <.input field={@form[:ward]} type="text" label="Ward" placeholder="e.g., General Ward, ICU" />
          <.input field={@form[:bed_number]} type="text" label="Bed Number" placeholder="e.g., B12" />
        </div>

        <.input
          field={@form[:complaints]}
          type="textarea"
          label="Complaints"
          placeholder="Enter patient's chief complaints..."
          rows={3}
        />

        <.input
          field={@form[:history_of_presenting_illness]}
          type="textarea"
          label="History of Presenting Illness"
          placeholder="Detailed history of the presenting illness..."
          rows={3}
        />

        <.input
          field={@form[:physical_examination]}
          type="textarea"
          label="Physical Examination Findings"
          placeholder="Document physical examination findings..."
          rows={3}
        />

        <div class="space-y-2">
          <label class="block text-sm font-medium text-gray-700">Diagnosis (ICD-11)</label>
          <select
            name="admission_note[diagnosis_icd_code]"
            class="w-full border border-gray-300 rounded-md px-3 py-2 focus:ring-[#6667ab] focus:border-[#6667ab]"
          >
            <option value="">Select diagnosis code...</option>
            <%= for {label, code} <- Medcamp.Icd11.options() do %>
              <option value={code} selected={@form[:diagnosis_icd_code].value == code}>
                {label}
              </option>
            <% end %>
          </select>
          <.input
            field={@form[:diagnosis]}
            type="textarea"
            label="Diagnosis notes (optional)"
            placeholder="Add any additional diagnosis details..."
            rows={2}
          />
        </div>

        <.input
          field={@form[:management_plan]}
          type="textarea"
          label="Management Plan"
          placeholder="Enter the management plan for the patient..."
          rows={3}
        />
        
    <!-- Vital Signs Section -->
        <div class="border-t border-gray-200 pt-4 mt-4">
          <h3 class="text-sm font-semibold text-gray-700 mb-3">Vital Signs at Admission</h3>
          <div class="grid grid-cols-2 md:grid-cols-5 gap-3">
            <.input field={@form[:blood_pressure]} type="text" label="BP (mmHg)" placeholder="120/80" />
            <.input field={@form[:pulse_rate]} type="number" label="Pulse (B/Min)" placeholder="72" />
            <.input
              field={@form[:temperature]}
              type="number"
              label="Temp (°C)"
              placeholder="36.5"
              step="0.1"
            />
            <.input field={@form[:spo2]} type="number" label="SpO2 (%)" placeholder="98" />
            <.input
              field={@form[:respiratory_rate]}
              type="number"
              label="RR (Br/Min)"
              placeholder="16"
            />
          </div>
        </div>

        <:actions>
          <.button phx-disable-with="Saving..." class="bg-[#6667ab] hover:bg-[#5556a0]">
            Save Admission
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{admission_note: admission_note} = assigns, socket) do
    changeset = Inpatient.change_admission_note(admission_note)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"admission_note" => admission_note_params}, socket) do
    params = maybe_fill_diagnosis_from_icd(admission_note_params)

    changeset =
      socket.assigns.admission_note
      |> Inpatient.change_admission_note(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"admission_note" => admission_note_params}, socket) do
    admission_note_params =
      admission_note_params
      |> Map.put("patient_id", socket.assigns.patient.id)
      |> Map.put("doctor_id", socket.assigns.current_user.id)
      |> Map.put("doctor_note_id", socket.assigns.doctor_note.id)

    case Inpatient.create_admission_note(admission_note_params) do
      {:ok, _admission_note} ->
        {:noreply,
         socket
         |> put_flash(:info, "Patient admitted successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
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

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset, as: "admission_note"))
  end
end
