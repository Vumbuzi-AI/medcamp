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
    <div class="min-h-screen bg-[radial-gradient(circle_at_top,_rgba(55,56,150,0.18),_transparent_38%),linear-gradient(180deg,_#f8fafc_0%,_#eef2ff_42%,_#ffffff_100%)]">
      <div class="mx-auto flex min-h-screen max-w-6xl items-center px-4 py-10 sm:px-6 lg:px-8">
        <div class="grid w-full gap-8 lg:grid-cols-[1.15fr_0.85fr]">
          <section class="rounded-3xl border border-indigo-100 bg-white/80 p-8 shadow-xl shadow-indigo-100/50 backdrop-blur sm:p-10">
            <div class="inline-flex items-center rounded-full bg-indigo-50 px-3 py-1 text-xs font-semibold uppercase tracking-[0.25em] text-indigo-700">
              Admin PIN Access
            </div>
            <h1 class="mt-6 text-4xl font-bold tracking-tight text-slate-900 sm:text-5xl">
              Medical Camp external reporting entry
            </h1>
            <p class="mt-4 max-w-2xl text-base leading-7 text-slate-600 sm:text-lg">
              Use an admin 4-digit PIN to open a restricted medical camp reporting page for
              external use. This access does not unlock the rest of the admin workspace.
            </p>

            <div class="mt-8 grid gap-4 sm:grid-cols-3">
              <div class="rounded-2xl border border-slate-200 bg-slate-50 p-4">
                <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">
                  Access model
                </p>
                <p class="mt-2 text-sm font-medium text-slate-900">PIN-gated</p>
              </div>
              <div class="rounded-2xl border border-slate-200 bg-slate-50 p-4">
                <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">
                  Allowed role
                </p>
                <p class="mt-2 text-sm font-medium text-slate-900">Admins only</p>
              </div>
              <div class="rounded-2xl border border-slate-200 bg-slate-50 p-4">
                <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">
                  Destination
                </p>
                <p class="mt-2 text-sm font-medium text-slate-900">External camp dashboard</p>
              </div>
            </div>
          </section>

          <section class="rounded-3xl border border-slate-200 bg-white p-8 shadow-2xl shadow-slate-200/70 sm:p-10">
            <h2 class="text-2xl font-semibold text-slate-900">Enter admin PIN</h2>
            <p class="mt-2 text-sm leading-6 text-slate-500">
              Only users with the <span class="font-semibold text-slate-700">admin</span> role can
              unlock this external-only reporting page.
            </p>

            <form action={~p"/admin/medical_camp/access/session"} method="post" class="mt-8 space-y-5">
              <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />

              <label class="block">
                <span class="mb-2 block text-sm font-medium text-slate-700">4-digit PIN</span>
                <input
                  type="text"
                  name="otp"
                  maxlength="4"
                  inputmode="numeric"
                  pattern="[0-9]{4}"
                  placeholder="_ _ _ _"
                  autofocus
                  class="w-full rounded-2xl border border-slate-300 px-5 py-4 text-center text-3xl tracking-[0.55em] text-slate-900 shadow-sm outline-none transition focus:border-indigo-500 focus:ring-4 focus:ring-indigo-100"
                />
              </label>

              <button
                type="submit"
                class="inline-flex w-full items-center justify-center rounded-2xl bg-brand-primary px-4 py-3 text-sm font-semibold text-white transition hover:bg-[#2f307e] focus:outline-none focus:ring-4 focus:ring-indigo-200"
              >
                Open dashboard
              </button>
            </form>

            <div class="mt-6 rounded-2xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-900">
              Use the same OTP stored on the admin user account. Non-admin PINs are rejected, and
              this session only grants access to the external medical camp page.
            </div>
          </section>
        </div>
      </div>
    </div>
    """
  end
end
