defmodule MedcampWeb.DoctorProcedureLive.FormComponent do
  use MedcampWeb, :live_component

  alias Medcamp.DoctorProcedures
  alias Medcamp.Procedures
  alias Medcamp.SubsidizedProcedures
  alias Medcamp.Patients

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
      </.header>

      <.simple_form
        for={@form}
        id="doctor_procedure-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <%= if @selected_patient do %>
          <.input
            field={@form[:patient_id]}
            type="select"
            options={@patients}
            value={@selected_patient.id}
            disabled={true}
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

        <div class="mb-4">
          <label class="block text-sm font-medium text-gray-700 mb-1">Procedure payment</label>
          <select
            name="procedure_payment_type"
            phx-change="change_procedure_payment_type"
            phx-target={@myself}
            class="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 focus:border-[#6667ab] focus:ring-[#6667ab]"
          >
            <option value="full" selected={@procedure_payment_type == "full"}>Full Payment</option>
            <option value="subsidized" selected={@procedure_payment_type == "subsidized"}>
              Subsidized ( For Students Only )
            </option>
          </select>
        </div>

        <%= if @procedure_payment_type == "full" do %>
          <.input
            field={@form[:procedure_id]}
            type="select"
            options={@procedures}
            prompt="Select a procedure"
            label="Procedure"
          />
          <input type="hidden" name="doctor_procedure[subsidized_procedure_id]" value="" />
        <% else %>
          <.input
            field={@form[:subsidized_procedure_id]}
            type="select"
            options={@subsidized_procedures}
            prompt="Select a procedure"
            label="Procedure"
          />
          <input type="hidden" name="doctor_procedure[procedure_id]" value="" />
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
          <.button phx-disable-with="Saving...">Save Doctor procedure</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{doctor_procedure: doctor_procedure} = assigns, socket) do
    patients = Patients.list_patients_for_selection()
    procedures = Procedures.list_procedures_for_selection()
    subsidized_procedures = SubsidizedProcedures.list_subsidized_procedures_for_selection()

    procedure_payment_type =
      assigns[:procedure_payment_type] ||
        if doctor_procedure.subsidized_procedure_id, do: "subsidized", else: "full"

    payment_type = assigns[:payment_type] || doctor_procedure.payment_type || ""

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:patients, patients)
     |> assign(:procedures, procedures)
     |> assign(:subsidized_procedures, subsidized_procedures)
     |> assign(:procedure_payment_type, procedure_payment_type)
     |> assign(:payment_type, payment_type)
     |> assign_new(:form, fn ->
       to_form(DoctorProcedures.change_doctor_procedure(doctor_procedure))
     end)}
  end

  @impl true
  def handle_event("change_procedure_payment_type", %{"procedure_payment_type" => type}, socket) do
    {:noreply,
     socket
     |> assign(:procedure_payment_type, type)
     |> assign(
       :form,
       to_form(DoctorProcedures.change_doctor_procedure(socket.assigns.doctor_procedure),
         action: :validate
       )
     )}
  end

  @impl true
  def handle_event("validate", %{"doctor_procedure" => doctor_procedure_params} = params, socket) do
    payment_type = params["procedure_payment_type"] || socket.assigns.procedure_payment_type

    insurance_payment_type =
      doctor_procedure_params["payment_type"] || socket.assigns.payment_type

    attrs = normalize_procedure_params(doctor_procedure_params, payment_type)

    changeset =
      DoctorProcedures.change_doctor_procedure(
        socket.assigns.doctor_procedure,
        attrs
      )

    {:noreply,
     socket
     |> assign(:procedure_payment_type, payment_type)
     |> assign(:payment_type, insurance_payment_type)
     |> assign(:form, to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"doctor_procedure" => doctor_procedure_params} = params, socket) do
    patient_id =
      if socket.assigns.selected_patient do
        socket.assigns.selected_patient.id
      else
        doctor_procedure_params["patient_id"]
      end

    payment_type = params["procedure_payment_type"] || socket.assigns.procedure_payment_type
    is_insurance = doctor_procedure_params["payment_type"] == "Insurance"

    doctor_procedure_params =
      doctor_procedure_params
      |> normalize_procedure_params(payment_type)
      |> Map.put("doctor_id", socket.assigns.current_user.id)
      |> Map.put("patient_id", patient_id)
      |> Map.put("has_paid", is_insurance)

    save_doctor_procedure(socket, socket.assigns.action, doctor_procedure_params)
  end

  defp normalize_procedure_params(params, "subsidized") do
    Map.put(params, "procedure_id", nil)
  end

  defp normalize_procedure_params(params, _) do
    Map.put(params, "subsidized_procedure_id", nil)
  end

  defp save_doctor_procedure(socket, :edit, doctor_procedure_params) do
    case DoctorProcedures.update_doctor_procedure(
           socket.assigns.doctor_procedure,
           doctor_procedure_params
         ) do
      {:ok, _doctor_procedure} ->
        {:noreply,
         socket
         |> put_flash(:info, "Doctor procedure updated successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_doctor_procedure(socket, :new, doctor_procedure_params) do
    case DoctorProcedures.create_doctor_procedure(doctor_procedure_params) do
      {:ok, _doctor_procedure} ->
        {:noreply,
         socket
         |> put_flash(:info, "Doctor procedure created successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
