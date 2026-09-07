defmodule MedcampWeb.PatientVisitLive.FormComponent do
  use MedcampWeb, :live_component

  alias Medcamp.PatientVisits
  alias Medcamp.Patients
  alias Medcamp.Accounts

  @visit_type_options [
    "Full",
    "Triage Only",
    "GHCE AT 1",
    "ANC",
    "Subsidized Doctor Consultation for Students",
    "Lab Test",
    "Pharmacy",
    "Other"
  ]

  @default_visit_amounts %{
    "GHCE AT 1" => 0,
    "Full" => 500,
    "Triage Only" => 50,
    "ANC" => 500,
    "Subsidized Doctor Consultation for Students" => 300,
    "Lab Test" => 500,
    "Pharmacy" => 500,
    "Other" => 500
  }

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
      </.header>

      <.simple_form
        for={@form}
        id="patient_visit-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:date]} type="date" label="Date" />
        <.input field={@form[:time]} type="time" label="Time" />
        <%= if @selected_patient do %>
          <.input
            field={@form[:patient_id]}
            type="select"
            disabled={true}
            value={@selected_patient.id}
            options={@patients}
            prompt="Select a patient"
            label="Patient"
          />
        <% else %>
          <.input
            field={@form[:patient_id]}
            type="select"
            options={@patients}
            prompt="Select a patient"
            label="Patient"
          />
        <% end %>
        <.input
          field={@form[:doctor_id]}
          type="select"
          options={@doctors}
          prompt="Select a doctor for the visit"
          label="Doctor for the visit"
        />
        <.input
          field={@form[:visit_type]}
          type="select"
          options={@visit_type_options}
          prompt="Select type of visit"
          label="Type of Visit"
        />

        <%= if amount_input_label(@visit_type) do %>
          <.input
            field={@form[:total_amount_paid]}
            type="number"
            label={amount_input_label(@visit_type)}
          />
        <% end %>

        <.input
          field={@form[:payment_type]}
          type="select"
          options={["Mpesa", "Insurance"]}
          prompt="Select payment type"
          label="Payment Type"
        />

        <%= if @payment_type == "Insurance" do %>
          <.input
            field={@form[:insurance_name]}
            type="select"
            prompt="Select insurance provider"
            options={["GHCE", "Altiora School"]}
            label="Insurance Provider"
            required={true}
          />
        <% end %>

        <:actions>
          <.button phx-disable-with="Saving...">Save Patient visit</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{patient_visit: patient_visit} = assigns, socket) do
    patients = Patients.list_patients_for_selection()
    doctors = Accounts.list_all_doctors_for_selection()
    visit_type = assigns[:visit_type] || patient_visit.visit_type || "Full"
    payment_type = assigns[:payment_type] || patient_visit.payment_type || ""
    initial_form_params = initial_form_params(patient_visit, visit_type)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:patients, patients)
     |> assign(:doctors, doctors)
     |> assign(:visit_type, visit_type)
     |> assign(:payment_type, payment_type)
     |> assign(:visit_type_options, @visit_type_options)
     |> assign_new(:form, fn ->
       to_form(PatientVisits.change_patient_visit(patient_visit, initial_form_params))
     end)}
  end

  @impl true
  def handle_event("validate", %{"patient_visit" => patient_visit_params}, socket) do
    visit_type = patient_visit_params["visit_type"] || socket.assigns.visit_type
    payment_type = patient_visit_params["payment_type"] || socket.assigns.payment_type

    params = maybe_put_default_amount(patient_visit_params, socket.assigns.visit_type)

    changeset =
      PatientVisits.change_patient_visit(socket.assigns.patient_visit, params)

    {:noreply,
     socket
     |> assign(:visit_type, visit_type)
     |> assign(:payment_type, payment_type)
     |> assign(:form, to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"patient_visit" => patient_visit_params}, socket) do
    patient_visit_params =
      patient_visit_params
      |> Map.put("creator_id", socket.assigns.current_user.id)

    patient_visit_params =
      if socket.assigns.selected_patient do
        patient_visit_params
        |> Map.put("patient_id", socket.assigns.selected_patient.id)
      else
        patient_visit_params
      end

    patient_visit_params =
      maybe_put_default_amount(patient_visit_params, socket.assigns.visit_type)

    save_patient_visit(socket, socket.assigns.action, patient_visit_params)
  end

  defp save_patient_visit(socket, :edit, patient_visit_params) do
    params = maybe_set_insurance_paid(patient_visit_params)

    case PatientVisits.update_patient_visit(socket.assigns.patient_visit, params) do
      {:ok, _patient_visit} ->
        {:noreply,
         socket
         |> put_flash(:info, "Patient visit updated successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_patient_visit(socket, :new, patient_visit_params) do
    params = maybe_set_insurance_paid(patient_visit_params)

    case PatientVisits.create_patient_visit(params) do
      {:ok, _patient_visit} ->
        {:noreply,
         socket
         |> put_flash(:info, "Patient visit created successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp maybe_set_insurance_paid(%{"payment_type" => "Insurance"} = params) do
    Map.put(params, "has_paid", true)
  end

  defp maybe_set_insurance_paid(params), do: params

  defp amount_input_label("Subsidized"), do: "Subsidized amount (KES)"

  defp amount_input_label("Subsidized Doctor Consultation for Students"),
    do: "Subsidized amount (KES)"

  defp amount_input_label(visit_type)
       when visit_type in [
              "Full",
              "Triage Only",
              "ANC",
              "Lab Test",
              "Pharmacy",
              "Other"
            ] do
    "Total amount to be paid (KES)"
  end

  defp amount_input_label(_visit_type), do: nil

  defp initial_form_params(patient_visit, visit_type) do
    case {patient_visit.total_amount_paid, default_amount_for_visit_type(visit_type)} do
      {nil, default_amount} when is_integer(default_amount) ->
        %{"total_amount_paid" => Integer.to_string(default_amount)}

      _ ->
        %{}
    end
  end

  defp maybe_put_default_amount(params, previous_visit_type) do
    visit_type = Map.get(params, "visit_type", previous_visit_type)
    amount = Map.get(params, "total_amount_paid")
    previous_default = default_amount_for_visit_type(previous_visit_type)
    current_default = default_amount_for_visit_type(visit_type)

    should_apply_default? =
      blank?(amount) or
        (visit_type != previous_visit_type and
           is_integer(previous_default) and amount == Integer.to_string(previous_default))

    if should_apply_default? and is_integer(current_default) do
      Map.put(params, "total_amount_paid", Integer.to_string(current_default))
    else
      params
    end
  end

  defp default_amount_for_visit_type(visit_type), do: Map.get(@default_visit_amounts, visit_type)

  defp blank?(value), do: value in [nil, ""]
end
