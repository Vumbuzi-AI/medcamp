defmodule MedcampWeb.MedicalCampPages.GlobalScan do
  use MedcampWeb, :live_view

  alias MedcampWeb.PublicTenant
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

    case PublicTenant.resolve_patient!(gsrn) do
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
    <div class="flex min-h-screen flex-col items-center bg-slate-50 px-4 py-8">
      <div class="flex w-full justify-center">
        <div class="flex items-center gap-3">
          <img src="/images/tibasasa-ai-logo.png" alt="Tibasasa" class="h-10 w-10 object-contain" />
          <div class="leading-tight">
            <p class="text-base font-bold tracking-tight text-brand-primary">Tibasasa</p>
            <p class="text-xs font-semibold uppercase tracking-[0.14em] text-slate-500">
              Medical Camp
            </p>
          </div>
        </div>
      </div>

      <div class="flex w-full flex-1 items-center justify-center py-10">
        <div class="w-full max-w-sm">
          <%!-- Header --%>
          <div class="text-center mb-6">
            <div class="inline-flex items-center justify-center w-14 h-14 rounded-full bg-brand-primary mb-3">
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
            <h1 class="text-2xl font-bold text-brand-primary">Patient Scanner</h1>
            <p class="text-sm text-slate-500 mt-1">Scan a patient's QR code or Data Matrix</p>
          </div>

          <%!-- Scanner --%>
          <div class="bg-white rounded-xl shadow-sm border border-slate-200 p-4">
            <div id="qr-camera-scanner" phx-hook="QrCameraScanner" class="relative">
              <video class="w-full rounded-lg border border-slate-300" autoplay playsinline muted>
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
              <p class="qr-status text-sm text-center text-slate-500 mt-2">
                Point camera at patient's QR code...
              </p>
            </div>
          </div>

          <%!-- Footer note --%>
          <p class="text-center text-xs text-slate-400 mt-4">
            Powered by Tibasasa Medical Camp
          </p>
        </div>
      </div>
    </div>
    """
  end
end
