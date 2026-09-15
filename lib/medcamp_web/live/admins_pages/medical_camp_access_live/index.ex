defmodule MedcampWeb.AdminMedicalCampAccessLive.Index do
  use MedcampWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket = assign(socket, :page_title, "Medical Camp Admin Access")

    if match?(%{role: "admin"}, socket.assigns.external_admin_user) do
      {:ok, push_navigate(socket, to: "/admin/medical_camp/external")}
    else
      {:ok, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex min-h-screen items-center justify-center bg-slate-50 px-4 py-12">
      <div class="w-full max-w-md">
        <div class="mb-6 flex items-center gap-2">
          <img src="/images/tibasasa-ai-logo.png" alt="" class="h-8 w-8 rounded-lg object-contain" />
          <span class="text-base font-bold tracking-[-0.01em] text-[#0C2765]">Tibasasa</span>
        </div>

        <div class="rounded-2xl border border-slate-200 bg-white p-6 sm:p-8">
          <h1 class="text-xl font-semibold text-slate-900">Medical camp reporting access</h1>
          <p class="mt-2 text-sm leading-relaxed text-slate-500">
            Enter an admin's 4-digit PIN to open the external medical camp report.
            This does not unlock the rest of the admin workspace.
          </p>

          <form action={~p"/admin/medical_camp/access/session"} method="post" class="mt-6 space-y-4">
            <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />

            <div>
              <label for="camp-access-pin" class="mb-1.5 block text-sm font-medium text-slate-700">
                4-digit PIN
              </label>
              <input
                id="camp-access-pin"
                type="text"
                name="otp"
                maxlength="4"
                inputmode="numeric"
                pattern="[0-9]{4}"
                placeholder="••••"
                autofocus
                autocomplete="off"
                class="h-14 w-full rounded-xl border border-slate-300 text-center text-2xl tracking-[0.5em] text-slate-900 focus:border-brand-accent focus:outline-none focus:ring-0"
              />
            </div>

            <button
              type="submit"
              class="w-full rounded-full bg-[#0C2765] px-6 py-3 text-sm font-semibold text-white transition-colors duration-150 hover:bg-[#16418f]"
            >
              Open report
            </button>
          </form>

          <p class="mt-5 border-t border-slate-100 pt-4 text-xs leading-relaxed text-slate-400">
            Use the OTP on the admin user's account. Non-admin PINs are rejected.
          </p>
        </div>
      </div>
    </div>
    """
  end
end
