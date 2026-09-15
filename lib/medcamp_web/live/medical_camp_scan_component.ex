defmodule MedcampWeb.MedicalCampScanComponent do
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
          <h2 class="text-xl font-semibold text-brand-primary">Medical Camp - Patient QR Scanner</h2>
        </div>

        <.camera_scanner id={@id} target={@myself} nonce={@scan_nonce} error={@scan_error} />

        <div class="flex items-center gap-3 text-xs uppercase tracking-wide text-gray-400">
          <span class="flex-1 h-px bg-gray-200"></span>
          <span>or use a handheld scanner</span>
          <span class="flex-1 h-px bg-gray-200"></span>
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

      <.patient_search target={@myself} term={@search_term} results={@search_results} />
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(:qr_code_value, "")
     |> assign_new(:scan_nonce, fn -> 0 end)
     |> assign_new(:scan_error, fn -> nil end)
     |> assign_new(:search_term, fn -> "" end)
     |> assign_new(:search_results, fn -> [] end)
     |> assign(assigns)}
  end

  @impl true
  def handle_event("qr_scanned", %{"value" => raw_value}, socket) do
    {:noreply, handle_scanned_value(socket, raw_value)}
  end

  def handle_event("check", %{"value" => %{"qr" => qr_code_value}}, socket) do
    {:noreply, handle_scanned_value(socket, qr_code_value)}
  end

  def handle_event("search_patients", %{"search" => term}, socket) do
    {:noreply, assign(socket, search_term: term, search_results: search(term))}
  end

  def handle_event("select_patient", %{"id" => id}, socket) do
    case Patients.get_patient(id) do
      nil ->
        {:noreply, socket}

      patient ->
        {:noreply,
         push_navigate(socket, to: redirect_to_route(socket.assigns.current_user.role, patient))}
    end
  end

  defp search(term) do
    case String.trim(term) do
      "" -> []
      term -> Patients.search_patients(term, 10)
    end
  end

  defp handle_scanned_value(socket, raw_value) do
    gsrn = extract_gsrn(raw_value)

    case Patients.get_patient_by_gsrn(gsrn) do
      nil ->
        socket
        |> assign(:qr_code_value, gsrn)
        |> assign(:scan_error, "No patient found for #{gsrn}. Try scanning again.")
        |> update(:scan_nonce, &(&1 + 1))

      patient ->
        push_navigate(socket, to: redirect_to_route(socket.assigns.current_user.role, patient))
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

  defp redirect_to_route(role, patient),
    do: MedcampWeb.MedicalCampRouting.after_scan_path(role, patient)
end
