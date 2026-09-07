defmodule MedcampWeb.NursingConsumableLive.FormComponent do
  use MedcampWeb, :live_component

  alias Medcamp.DoctorNotes
  alias Medcamp.Nursing
  alias Medcamp.Patients

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="mb-6">
        <div class="flex items-center space-x-3 mb-2">
          <div class="w-10 h-10 rounded-xl bg-gradient-to-br from-teal-600 to-teal-500 flex items-center justify-center">
            <svg class="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4"
              />
            </svg>
          </div>
          <div>
            <h2 class="text-xl font-bold text-slate-800">{@title}</h2>
            <p class="text-sm text-slate-500">Record the usage of this item for patient care</p>
          </div>
        </div>
      </div>
      
    <!-- Current Stock Info -->
      <div class="mb-6 p-4 bg-gradient-to-r from-teal-50 to-emerald-50 rounded-xl border border-teal-200">
        <% details = Nursing.allocation_item_details(@nursing_allocation) %>
        <div class="flex items-center justify-between">
          <div class="flex items-center space-x-3">
            <div class="w-12 h-12 rounded-xl bg-white shadow-sm flex items-center justify-center">
              <span class="text-lg font-bold text-teal-700">
                {String.first(details.display_name)}
              </span>
            </div>
            <div>
              <p class="font-semibold text-slate-800">{details.display_name}</p>
              <div class="text-sm text-slate-600 space-y-0.5">
                <p>
                  <span class="text-slate-500">Brand:</span> {(details.brand_name &&
                                                                 String.trim(details.brand_name || "") !=
                                                                   "" && details.brand_name) || "—"}
                </p>
                <p>
                  <span class="text-slate-500">Generic:</span> {(details.generic_name &&
                                                                   String.trim(
                                                                     details.generic_name || ""
                                                                   ) != "" && details.generic_name) ||
                    "—"}
                </p>
                <p>
                  <span class="text-slate-500">Batch:</span> {(details.batch_number &&
                                                                 String.trim(
                                                                   to_string(
                                                                     details.batch_number || ""
                                                                   )
                                                                 ) != "" && details.batch_number) ||
                    "—"}
                </p>
                <%= if details.size_gauge do %>
                  <p>Size/Gauge: {details.size_gauge}</p>
                <% end %>
                <p>GTIN: {details.gtin || "—"}</p>
              </div>
            </div>
          </div>
          <div class="text-right">
            <p class="text-xs text-slate-500 uppercase font-medium">Current Stock</p>
            <p class={"text-2xl font-bold #{if @nursing_allocation.remaining_quantity < @nursing_allocation.allocated_quantity * 0.2, do: "text-amber-600", else: "text-emerald-600"}"}>
              {@nursing_allocation.remaining_quantity}
            </p>
            <p class="text-xs text-slate-500">{@nursing_allocation.uom}</p>
            <p class="mt-2 text-xs text-slate-500 uppercase font-medium">Expiry</p>
            <p class={["text-sm font-semibold", expiry_text_class(@nursing_allocation.expiry_date)]}>
              <%= if @nursing_allocation.expiry_date do %>
                {Calendar.strftime(@nursing_allocation.expiry_date, "%b %d, %Y")}
              <% else %>
                No expiry date
              <% end %>
            </p>
            <p
              :if={expiry_note(@nursing_allocation.expiry_date)}
              class={["text-xs font-medium", expiry_text_class(@nursing_allocation.expiry_date)]}
            >
              {expiry_note(@nursing_allocation.expiry_date)}
            </p>
          </div>
        </div>
      </div>

      <.simple_form
        for={@form}
        id="nursing_consumable-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="space-y-5"
      >
        <!-- Patient Selection -->
        <div>
          <.input
            type="text"
            name="patient_search"
            value={@patient_search}
            label="Search Patient"
            placeholder="Search by name, email or GSRN"
            phx-debounce="300"
          />
          <p class="mt-1 text-xs text-slate-500">Start typing to filter the patient list</p>

          <.input
            type="select"
            field={@form[:patient_id]}
            label="Patient"
            options={@patients}
            prompt="Select a patient (optional)"
          />
          <p class="mt-1 text-xs text-slate-500">Leave empty if not patient-specific usage</p>
        </div>

        <div>
          <.input
            type="select"
            field={@form[:doctor_note_id]}
            label="Doctor Note for Billing Review"
            options={@doctor_note_options}
            prompt="Select doctor note"
          />
          <p class="mt-1 text-xs text-slate-500">
            If you select a patient and doctor note, this usage will create a pending charge for later approval on the doctor side.
          </p>
          <%= if @unit_price > 0 do %>
            <p class="mt-1 text-xs text-teal-700 font-medium">
              Billing rate: KES {@unit_price} per {@nursing_allocation.uom}
            </p>
          <% end %>
        </div>
        
    <!-- Quantity and Date Row -->
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <.input
              field={@form[:consumed_quantity]}
              type="number"
              label={"Quantity Used (#{@nursing_allocation.uom})"}
              placeholder="Enter quantity"
              min="1"
              max={@nursing_allocation.remaining_quantity}
            />
            <p class="mt-1 text-xs text-slate-500">
              Max available: {@nursing_allocation.remaining_quantity} {@nursing_allocation.uom}
            </p>
          </div>

          <.input field={@form[:date]} type="date" label="Date of Usage" />
        </div>
        
    <!-- Purpose -->
        <.input
          field={@form[:purpose]}
          type="textarea"
          label="Purpose / Ward Remarks"
          placeholder="Enter the purpose of usage or any relevant notes..."
          rows={3}
        />
        
    <!-- Actions -->
        <div class="flex items-center justify-end gap-3 pt-4 border-t border-slate-200">
          <.link
            patch={@patch}
            class="px-4 py-2 text-slate-600 hover:text-slate-800 font-medium transition-colors"
          >
            Cancel
          </.link>
          <.button
            phx-disable-with="Saving..."
            class="inline-flex items-center px-5 py-2.5 bg-gradient-to-r from-teal-600 to-teal-500 text-white rounded-xl font-medium hover:from-teal-700 hover:to-teal-600 transition-all shadow-lg shadow-teal-500/25"
          >
            <svg class="w-4 h-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M5 13l4 4L19 7"
              />
            </svg>
            Save Usage Record
          </.button>
        </div>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{nursing_consumable: nursing_consumable} = assigns, socket) do
    patient_id = nursing_consumable.patient_id || assigns[:patient_id]

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:patient_search, "")
     |> assign(:patients, patient_options("", patient_id))
     |> assign(:unit_price, Nursing.unit_price_for_allocation(assigns.nursing_allocation))
     |> assign(:doctor_note_options, doctor_note_options_for(patient_id))
     |> assign(:nursing_allocation, assigns.nursing_allocation)
     |> assign_new(:form, fn ->
       to_form(Nursing.change_nursing_consumable(nursing_consumable))
     end)}
  end

  @impl true
  def handle_event("validate", params, socket) do
    nursing_consumable_params = Map.get(params, "nursing_consumable", %{})
    patient_search = Map.get(params, "patient_search", "")

    changeset =
      Nursing.change_nursing_consumable(
        socket.assigns.nursing_consumable,
        nursing_consumable_params
      )

    patient_id = nursing_consumable_params["patient_id"] || socket.assigns.form[:patient_id].value

    {:noreply,
     socket
     |> assign(:patient_search, patient_search)
     |> assign(:patients, patient_options(patient_search, patient_id))
     |> assign(:doctor_note_options, doctor_note_options_for(patient_id))
     |> assign(form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"nursing_consumable" => params}, socket) do
    params = Map.put(params, "nursing_allocation_id", socket.assigns.nursing_allocation.id)

    # Validate quantity doesn't exceed remaining
    consumed_qty = parse_integer(params["consumed_quantity"])
    remaining = socket.assigns.nursing_allocation.remaining_quantity

    if consumed_qty > remaining do
      {:noreply,
       socket
       |> put_flash(
         :error,
         "Cannot consume more than available stock (#{remaining} #{socket.assigns.nursing_allocation.uom})"
       )}
    else
      save_nursing_consumable(socket, socket.assigns.action, params)
    end
  end

  defp save_nursing_consumable(socket, :new, params) do
    case Nursing.record_nursing_usage(params, socket.assigns.current_user.id) do
      {:ok, usage_result} ->
        notify_parent({:saved, usage_result})

        {:noreply,
         socket
         |> put_flash(:info, "Usage recorded successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_nursing_consumable(socket, :edit, params) do
    case Nursing.update_nursing_consumable(socket.assigns.nursing_consumable, params) do
      {:ok, consumable} ->
        consumable =
          if consumable.patient_id do
            Medcamp.Repo.preload(consumable, :patient)
          else
            consumable
          end

        notify_parent({:saved, consumable})

        {:noreply,
         socket
         |> put_flash(:info, "Usage updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp doctor_note_options_for(nil), do: []
  defp doctor_note_options_for(""), do: []

  defp doctor_note_options_for(patient_id) when is_binary(patient_id) do
    case Integer.parse(patient_id) do
      {parsed_patient_id, _rest} -> doctor_note_options_for(parsed_patient_id)
      :error -> []
    end
  end

  defp doctor_note_options_for(patient_id) when is_integer(patient_id) do
    DoctorNotes.list_doctor_note_options_for_patient(patient_id)
  end

  defp doctor_note_options_for(_), do: []

  defp patient_options(search_term, selected_id) do
    patients =
      case normalize_search(search_term) do
        nil -> Patients.list_patients()
        term -> Patients.search_patients(term)
      end

    patients
    |> ensure_selected_patient(selected_id)
    |> Enum.uniq_by(& &1.id)
    |> Enum.map(&{patient_option_label(&1), &1.id})
  end

  defp ensure_selected_patient(patients, nil), do: patients
  defp ensure_selected_patient(patients, ""), do: patients

  defp ensure_selected_patient(patients, selected_id) when is_binary(selected_id) do
    case Integer.parse(selected_id) do
      {parsed_id, _rest} -> ensure_selected_patient(patients, parsed_id)
      :error -> patients
    end
  end

  defp ensure_selected_patient(patients, selected_id) when is_integer(selected_id) do
    if Enum.any?(patients, &(&1.id == selected_id)) do
      patients
    else
      case Patients.get_patient(selected_id) do
        nil -> patients
        patient -> [patient | patients]
      end
    end
  end

  defp patient_option_label(patient) do
    patient_name =
      [patient.first_name, patient.middle_name, patient.last_name]
      |> Enum.reject(&(is_nil(&1) or String.trim(&1) == ""))
      |> Enum.join(" ")

    display_name =
      if patient_name == "",
        do: patient.email || patient.gsrn || "Unnamed Patient",
        else: patient_name

    email = patient.email || "No email"
    gsrn = patient.gsrn || "No GSRN"

    "#{display_name} - #{email} - #{gsrn}"
  end

  defp normalize_search(nil), do: nil

  defp normalize_search(search_term) when is_binary(search_term) do
    trimmed = String.trim(search_term)
    if trimmed == "", do: nil, else: trimmed
  end

  defp normalize_search(_), do: nil

  defp parse_integer(nil), do: 0
  defp parse_integer(""), do: 0
  defp parse_integer(value) when is_integer(value), do: value

  defp parse_integer(value) when is_binary(value) do
    case Integer.parse(String.trim(value)) do
      {parsed_value, ""} -> parsed_value
      _ -> 0
    end
  end

  # Expiry is colour-coded so a nurse can't miss an expired or soon-to-expire
  # item at the moment they are giving stock out.
  defp expiry_text_class(nil), do: "text-slate-600"

  defp expiry_text_class(expiry_date) do
    case Date.diff(expiry_date, Date.utc_today()) do
      days when days < 0 -> "text-red-600"
      days when days <= 30 -> "text-amber-600"
      _ -> "text-slate-700"
    end
  end

  defp expiry_note(nil), do: nil

  defp expiry_note(expiry_date) do
    case Date.diff(expiry_date, Date.utc_today()) do
      days when days < 0 -> "Expired #{abs(days)} day(s) ago — do not dispense"
      0 -> "Expires today"
      days when days <= 30 -> "Expires in #{days} day(s)"
      _ -> nil
    end
  end
end
