defmodule MedcampWeb.LabConsumableLive.FormComponent do
  use MedcampWeb, :live_component

  alias Medcamp.LabConsumables
  alias Medcamp.Patients

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage lab consumable records in your database.</:subtitle>
      </.header>

      <div class="mt-4 grid grid-cols-2 gap-3">
        <div class={[
          "rounded-lg border p-3",
          if(@lab_allocation.remaining_quantity <= 0,
            do: "border-red-200 bg-red-50",
            else: "border-green-200 bg-green-50"
          )
        ]}>
          <p class={[
            "text-xs font-medium",
            if(@lab_allocation.remaining_quantity <= 0, do: "text-red-600", else: "text-green-600")
          ]}>
            Remaining in this allocation
          </p>
          <p class={[
            "text-xl font-semibold",
            if(@lab_allocation.remaining_quantity <= 0, do: "text-red-900", else: "text-green-900")
          ]}>
            {@lab_allocation.remaining_quantity} {@lab_allocation.uom}
          </p>
        </div>

        <div class={[
          "rounded-lg border p-3",
          expiry_classes(@lab_allocation.expiry_date, :container)
        ]}>
          <p class={["text-xs font-medium", expiry_classes(@lab_allocation.expiry_date, :label)]}>
            Expiry date
          </p>
          <p class={[
            "text-xl font-semibold",
            expiry_classes(@lab_allocation.expiry_date, :value)
          ]}>
            <%= if @lab_allocation.expiry_date do %>
              {Calendar.strftime(@lab_allocation.expiry_date, "%b %d, %Y")}
            <% else %>
              No expiry date
            <% end %>
          </p>
          <p
            :if={expiry_note(@lab_allocation.expiry_date)}
            class={["mt-0.5 text-xs font-medium", expiry_classes(@lab_allocation.expiry_date, :label)]}
          >
            {expiry_note(@lab_allocation.expiry_date)}
          </p>
        </div>
      </div>

      <.simple_form
        for={@form}
        id="lab_consumable-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          type="text"
          name="patient_search"
          value={@patient_search}
          label="Search Patient"
          placeholder="Search patient by name"
          phx-debounce="300"
        />
        <p class="mt-1 text-xs text-slate-500">Start typing a patient name to narrow the list.</p>

        <.input
          type="select"
          field={@form[:patient_id]}
          label="Patient"
          options={@patients}
          prompt="Select a patient"
        />
        <.input field={@form[:consumed_quantity]} type="text" label="Consumed quantity" />
        <.input field={@form[:date]} type="date" label="Date" />
        <.input field={@form[:purpose]} type="textarea" label="Purpose" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Lab consumable</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{lab_consumable: lab_consumable} = assigns, socket) do
    patient_id = lab_consumable.patient_id

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:patient_search, "")
     |> assign(:patients, patient_options("", patient_id))
     |> assign_new(:form, fn ->
       to_form(LabConsumables.change_lab_consumable(lab_consumable))
     end)}
  end

  @impl true
  def handle_event("validate", params, socket) do
    lab_consumable_params = Map.get(params, "lab_consumable", %{})
    patient_search = Map.get(params, "patient_search", "")

    changeset =
      LabConsumables.change_lab_consumable(socket.assigns.lab_consumable, lab_consumable_params)

    patient_id = lab_consumable_params["patient_id"] || socket.assigns.form[:patient_id].value

    {:noreply,
     socket
     |> assign(:patient_search, patient_search)
     |> assign(:patients, patient_options(patient_search, patient_id))
     |> assign(form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"lab_consumable" => lab_consumable_params}, socket) do
    lab_consumable_params =
      lab_consumable_params
      |> Map.put("lab_allocation_id", socket.assigns.lab_allocation.id)

    save_lab_consumable(socket, socket.assigns.action, lab_consumable_params)
  end

  defp save_lab_consumable(socket, :edit, lab_consumable_params) do
    case LabConsumables.update_lab_consumable(
           socket.assigns.lab_consumable,
           lab_consumable_params
         ) do
      {:ok, lab_consumable} ->
        lab_consumable = maybe_preload_patient(lab_consumable)
        notify_parent({:saved, lab_consumable})

        {:noreply,
         socket
         |> put_flash(:info, "Lab consumable updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_lab_consumable(socket, :new, lab_consumable_params) do
    case LabConsumables.create_lab_consumable(lab_consumable_params) do
      {:ok, lab_consumable} ->
        lab_consumable = maybe_preload_patient(lab_consumable)
        notify_parent({:saved, lab_consumable})

        {:noreply,
         socket
         |> put_flash(:info, "Lab consumable created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  # Expiry is colour-coded so a lab tech can't miss an expired or
  # soon-to-expire item at the moment they are giving stock out.
  defp expiry_status(nil), do: :unknown

  defp expiry_status(expiry_date) do
    case Date.diff(expiry_date, Date.utc_today()) do
      days when days < 0 -> :expired
      days when days <= 30 -> :expiring_soon
      _ -> :ok
    end
  end

  defp expiry_classes(expiry_date, part) do
    case {expiry_status(expiry_date), part} do
      {:expired, :container} -> "border-red-200 bg-red-50"
      {:expired, :label} -> "text-red-600"
      {:expired, :value} -> "text-red-900"
      {:expiring_soon, :container} -> "border-amber-200 bg-amber-50"
      {:expiring_soon, :label} -> "text-amber-600"
      {:expiring_soon, :value} -> "text-amber-900"
      {_, :container} -> "border-purple-200 bg-slate-50"
      {_, :label} -> "text-purple-600"
      {_, :value} -> "text-purple-900"
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

  defp maybe_preload_patient(lab_consumable) do
    if lab_consumable.patient_id do
      Medcamp.Repo.preload(lab_consumable, :patient)
    else
      lab_consumable
    end
  end

  defp patient_options(search_term, selected_id) do
    search_term
    |> patients_for_search()
    |> ensure_selected_patient(selected_id)
    |> Enum.uniq_by(& &1.id)
    |> Enum.map(&{patient_option_label(&1), &1.id})
  end

  defp patients_for_search(search_term) do
    search_term
    |> normalize_search()
    |> case do
      nil ->
        Patients.list_patients()

      term ->
        Patients.list_patients()
        |> Enum.filter(fn patient ->
          patient_name =
            [patient.first_name, patient.middle_name, patient.last_name]
            |> Enum.reject(&(is_nil(&1) or String.trim(&1) == ""))
            |> Enum.join(" ")
            |> String.downcase()

          String.contains?(patient_name, String.downcase(term))
        end)
    end
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
    [patient.first_name, patient.middle_name, patient.last_name]
    |> Enum.reject(&(is_nil(&1) or String.trim(&1) == ""))
    |> Enum.join(" ")
    |> case do
      "" -> patient.gsrn || "Unnamed Patient"
      full_name -> full_name
    end
  end

  defp normalize_search(nil), do: nil

  defp normalize_search(search_term) when is_binary(search_term) do
    trimmed = String.trim(search_term)
    if trimmed == "", do: nil, else: trimmed
  end

  defp normalize_search(_), do: nil
end
