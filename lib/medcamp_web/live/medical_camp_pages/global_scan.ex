defmodule MedcampWeb.MedicalCampPages.GlobalScan do
  use MedcampWeb, :live_view
  alias Medcamp.Patients
  alias Medcamp.Accounts

  @impl true
  def mount(_params, session, socket) do
    current_user =
      case session["user_token"] do
        nil -> nil
        token -> Accounts.get_user_by_session_token(token)
      end

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> assign(:page_title, "Scan Patient")}
  end

  @impl true
  def handle_event("qr_scanned", %{"value" => raw_value}, socket) do
    gsrn = extract_gsrn(raw_value)

    case Patients.get_patient_by_gsrn(gsrn) do
      nil ->
        {:noreply, put_flash(socket, :error, "Patient not found for scanned code")}

      patient ->
        role =
          if socket.assigns.current_user, do: socket.assigns.current_user.role, else: nil

        {:noreply, push_navigate(socket, to: redirect_to_route(role, patient))}
    end
  end

  defp extract_gsrn(value) do
    cond do
      String.starts_with?(value, "https://") ->
        parts = String.split(value, "/")
        idx = Enum.find_index(parts, &(&1 == "8018"))
        if idx, do: Enum.at(parts, idx + 1, ""), else: List.last(parts)

      String.starts_with?(value, "8018") ->
        String.slice(value, 4..-1//-1)

      true ->
        value
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
    <div class="min-h-screen bg-gray-50 py-4 flex flex-col items-center justify-between px-4">
      <div class="flex justify-end mb-4">
        <.link
          href="/users/log_out"
          method="delete"
          class="hidden sm:flex items-center gap-1 text-sm text-red-600 hover:text-red-800 font-medium border border-red-200 rounded-md px-3 py-1.5 hover:bg-red-50 transition-colors"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-4 w-4"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a2 2 0 01-2 2H5a2 2 0 01-2-2V7a2 2 0 012-2h6a2 2 0 012 2v1"
            />
          </svg>
          Logout
        </.link>
      </div>
      <div class="w-full max-w-sm">
        <%!-- Header --%>
        <div class="text-center mb-6">
          <div class="inline-flex items-center justify-center w-14 h-14 rounded-full bg-[#373896] mb-3">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-7 w-7 text-white"
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
          </div>
          <h1 class="text-2xl font-bold text-[#373896]">HDF Medical Camp</h1>
          <p class="text-sm text-gray-500 mt-1">Scan a patient's QR code or Data Matrix</p>
        </div>

        <%!-- Scanner --%>
        <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-4">
          <div id="qr-camera-scanner" phx-hook="QrCameraScanner" class="relative">
            <video class="w-full rounded-lg border border-gray-300" autoplay playsinline muted>
            </video>
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

        <%!-- Footer note --%>
        <p class="text-center text-xs text-gray-400 mt-4">
          Islamic University of Kenya · Glocal Health Centre of Excellence
        </p>
      </div>

      <div>
        Glocal Health Centre of Excellence
      </div>
    </div>
    """
  end
end
