defmodule MedcampWeb.ScanComponents do
  use Phoenix.Component
  use Gettext, backend: MedcampWeb.Gettext
  import MedcampWeb.CoreComponents

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
