defmodule MedcampWeb.MedicalCampPages.Scan do
  use MedcampWeb, :live_view

  alias MedcampWeb.PublicTenant
  alias Medcamp.Accounts

  @impl true
  def mount(%{"gsrn" => gsrn}, session, socket) do
    patient = PublicTenant.resolve_patient!(gsrn)

    current_user =
      case session["user_token"] do
        nil -> nil
        token -> Accounts.get_user_by_session_token(token)
      end

    {:ok,
     socket
     |> assign(:patient, patient)
     |> assign(:current_user, current_user)
     |> assign(:page_title, "Scan Next Patient")}
  end

  @impl true
  def handle_event("qr_scanned", %{"value" => raw_value}, socket) do
    gsrn = extract_gsrn(raw_value)

    case PublicTenant.resolve_patient!(gsrn) do
      nil ->
        {:noreply, put_flash(socket, :error, "Patient not found for scanned QR code")}

      patient ->
        role =
          if socket.assigns.current_user, do: socket.assigns.current_user.role, else: nil

        {:noreply,
         socket
         |> push_navigate(to: redirect_to_route(role, patient))}
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
      "nurse" -> "/8018/#{patient.gsrn}/medical-camp/triages/new"
      "doctor" -> "/8018/#{patient.gsrn}/medical-camp/doctor_notes"
      _ -> "/8018/#{patient.gsrn}/medical-camp"
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto mt-8">
      <div class="bg-green-50 border border-green-200 rounded-lg p-4 mb-6 flex items-center">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="h-6 w-6 text-green-500 mr-3 flex-shrink-0"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
        </svg>
        <p class="text-green-700 font-medium">
          Data saved successfully! Scan the next patient's QR code below.
        </p>
      </div>

      <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-6">
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
          <h2 class="text-xl font-semibold text-brand-primary">Scan Next Patient</h2>
        </div>

        <div id="qr-camera-scanner" phx-hook="QrCameraScanner" class="relative">
          <video class="w-full rounded-lg border border-gray-300" autoplay playsinline muted></video>
          <div class="qr-overlay hidden absolute inset-0 bg-green-500/20 rounded-lg items-center justify-center">
            <svg
              class="h-16 w-16 text-green-600"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M5 13l4 4L19 7"
              />
            </svg>
          </div>
          <p class="qr-status text-sm text-center text-gray-500 mt-2">
            Point camera at patient's QR code...
          </p>
        </div>
      </div>
    </div>
    """
  end
end
