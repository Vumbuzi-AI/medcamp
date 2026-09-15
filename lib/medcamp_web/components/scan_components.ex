defmodule MedcampWeb.ScanComponents do
  use Phoenix.Component
  use Gettext, backend: MedcampWeb.Gettext
  import MedcampWeb.CoreComponents

  @doc """
  In-app camera scanner for patient QR codes / Data Matrix labels.

  Driven by the `QrCameraScanner` JS hook, which pushes a `"qr_scanned"` event
  with the raw decoded value. The `nonce` is part of the element id so bumping
  it remounts the hook and restarts the camera after a failed lookup.
  """
  attr :id, :string, required: true
  attr :target, :any, required: true
  attr :nonce, :integer, default: 0
  attr :error, :string, default: nil

  def camera_scanner(assigns) do
    ~H"""
    <div class="space-y-2">
      <div
        id={"#{@id}-camera-#{@nonce}"}
        phx-hook="QrCameraScanner"
        phx-target={@target}
        class="relative"
      >
        <video class="w-full rounded-lg border border-gray-300" autoplay playsinline muted></video>
        <div class="qr-overlay hidden absolute inset-0 bg-green-500/20 rounded-lg items-center justify-center">
          <svg class="h-16 w-16 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
          </svg>
        </div>
        <p class="qr-status text-sm text-center text-gray-500 mt-2">
          Point camera at the patient's QR code...
        </p>
      </div>

      <p :if={@error} class="text-sm text-center text-red-600">{@error}</p>
    </div>
    """
  end

  @doc """
  Live patient lookup for the scan pages, for when a patient has no card to
  scan. Typing filters on name, phone, email, national ID or GSRN as you go and
  the results are selectable — picking one goes to the same place a scan would.

  The owning live component handles `"search_patients"` and `"select_patient"`.
  """
  attr :target, :any, required: true
  attr :term, :string, default: ""
  attr :results, :list, default: []

  def patient_search(assigns) do
    ~H"""
    <div class="space-y-3">
      <div class="flex items-center gap-3 text-xs uppercase tracking-wide text-gray-400">
        <span class="flex-1 h-px bg-gray-200"></span>
        <span>or find the patient</span>
        <span class="flex-1 h-px bg-gray-200"></span>
      </div>

      <form phx-change="search_patients" phx-submit="search_patients" phx-target={@target}>
        <.search_input
          name="search"
          value={@term}
          placeholder="Search by name, phone, email, national ID or GSRN"
          autocomplete="off"
        />
      </form>

      <p :if={@term != "" and @results == []} class="text-sm text-gray-500">
        No patients match "{@term}".
      </p>

      <ul :if={@results != []} class="divide-y divide-gray-100 rounded-md border border-gray-200">
        <li :for={patient <- @results}>
          <button
            type="button"
            phx-click="select_patient"
            phx-value-id={patient.id}
            phx-target={@target}
            class="flex w-full items-center justify-between gap-4 px-3 py-2 text-left hover:bg-gray-50"
          >
            <span class="flex flex-col">
              <span class="text-sm font-medium text-brand-primary">
                {[patient.first_name, patient.middle_name, patient.last_name]
                |> Enum.reject(&(&1 in [nil, ""]))
                |> Enum.join(" ")}
              </span>
              <span class="text-xs text-gray-500">
                {[patient.phone_number, patient.email, patient.national_id]
                |> Enum.reject(&(&1 in [nil, ""]))
                |> Enum.join(" · ")}
              </span>
            </span>
            <span class="shrink-0 text-xs font-medium text-gray-400">{patient.gsrn}</span>
          </button>
        </li>
      </ul>
    </div>
    """
  end

  def scan_card(assigns) do
    ~H"""
    <div class="bg-white rounded-lg border border-slate-100 p-6 max-w-xl">
      <.form for={%{}} phx-change="check" class="space-y-4">
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
          id="qr_scan_input"
          name="qr_code_value"
          value={@qr_code_value}
          type="textarea"
          label="Scan QR Code for Patient"
          placeholder="Position the QR code in front of your camera..."
          rows={4}
          class="focus:border-brand-accent focus:ring-brand-accent"
        />

        <div class="text-sm text-slate-500 flex items-center">
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
          <span>Scan the patient's QR code or enter their GSRN code manually</span>
        </div>
      </.form>
    </div>
    """
  end
end
