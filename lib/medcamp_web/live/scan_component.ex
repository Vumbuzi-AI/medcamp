defmodule MedcampWeb.ScanComponent do
  use MedcampWeb, :live_component
  alias Medcamp.Patients
  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-slate-100 p-6 w-[100%]">
      <.form for={%{}} phx-submit="check" phx-change="check" phx-target={@myself} class="space-y-4">
        <div class="flex items-center mb-4">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-6 w-6 text-brand-accent mr-2"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M12 4v1m6 11h2m-6 0h-2v4m0-11v3m0 0h.01M12 12h4.01M16 20h4M4 12h4m12 0h.01M5 8h2a1 1 0 001-1V5a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1zm12 0h2a1 1 0 001-1V5a1 1 0 00-1-1h-2a1 1 0 00-1 1v2a1 1 0 001 1zM5 20h2a1 1 0 001-1v-2a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1z"
            />
          </svg>
          <h2 class="text-xl font-semibold text-brand-primary">Patient QR Code Scanner</h2>
        </div>

        <.input
          name="value[qr]"
          value={@qr_code_value}
          type="text"
          phx-mounted={JS.focus()}
          label="Scan QR Code for Patient"
          placeholder="Focus here and scan patient QR code..."
        />

        <div class="text-sm text-slate-500 flex items-center mt-2">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-4 w-4 mr-1 text-brand-accent"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
            />
          </svg>
          <span>QR code will be automatically processed when scanned</span>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(:qr_code_value, "")
     |> assign(assigns)}
  end

  @impl true

  def handle_event("check", %{"value" => %{"qr" => qr_code_value}}, socket) do
    qr_code_value = extract_gsrn(qr_code_value)

    IO.inspect(qr_code_value, label: "QR Code Value")

    case Patients.get_patient_by_gsrn(qr_code_value) do
      nil ->
        {:noreply,
         socket
         |> assign(:qr_code_value, qr_code_value)}

      patient ->
        {:noreply,
         socket
         |> push_navigate(to: redirect_to_route(socket.assigns.current_user.role, patient))}
    end
  end

  defp extract_gsrn(qr_code_value) do
    cond do
      String.starts_with?(qr_code_value, "https://") ->
        parts = String.split(qr_code_value, "/")
        idx = Enum.find_index(parts, &(&1 == "8018"))
        if idx, do: Enum.at(parts, idx + 1, ""), else: List.last(parts)

      String.starts_with?(qr_code_value, "8018") ->
        String.slice(qr_code_value, 4..-1//-1)

      true ->
        qr_code_value
    end
  end

  defp redirect_to_route(role, patient) do
    case role do
      "doctor" ->
        "/doctor/patients/#{patient.id}"

      "nurse" ->
        "/nurse/#{patient.id}/patient_overview"

      "reception" ->
        "/reception/#{patient.id}/patient_overview"

      "labtechnician" ->
        "/lab/#{patient.id}/lab_results"

      "pharmacist" ->
        "/pharmacist/#{patient.id}/drug_allocations"

      "radiologist" ->
        "/radiologist/#{patient.id}/radiology_results"

      _ ->
        "/"
    end
  end
end
