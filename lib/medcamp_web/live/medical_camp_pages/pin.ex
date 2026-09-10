defmodule MedcampWeb.MedicalCampPages.Pin do
  @moduledoc """
  Camp-station PIN sign-in screen. Shown when someone opens a
  `/8018/:gsrn/medical-camp/...` station page without a staff session
  (`MedicalCampAuth.:require_camp_role` redirects here). The operator enters
  their 4-digit PIN once per shift; every scan after that is frictionless.

  Stands alone (`layout: false`) - no patient record is on this page.
  """
  use MedcampWeb, :live_view

  alias MedcampWeb.PublicTenant

  @impl true
  def mount(%{"gsrn" => gsrn}, _session, socket) do
    {org_name, known?} =
      case PublicTenant.resolve_patient(gsrn) do
        {:ok, _patient, org} -> {org && Medcamp.Organisations.display_name(org), true}
        :error -> {nil, false}
      end

    {:ok,
     socket
     |> assign(:page_title, "Camp station sign-in")
     |> assign(:gsrn, gsrn)
     |> assign(:org_name, org_name)
     |> assign(:known?, known?), layout: false}
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
          <.flash_group flash={@flash} />

          <%= if @known? do %>
            <h1 class="text-xl font-semibold text-slate-900">Camp station sign-in</h1>
            <p class="mt-2 text-sm leading-relaxed text-slate-500">
              <span :if={@org_name}>
                {@org_name} &middot;
              </span>
              Enter your 4-digit staff PIN to open this patient. You stay signed in for the
              rest of your shift.
            </p>

            <form
              action={~p"/8018/#{@gsrn}/medical-camp/session"}
              method="post"
              class="mt-6 space-y-4"
            >
              <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />

              <div>
                <label for="camp-pin" class="mb-1.5 block text-sm font-medium text-slate-700">
                  Staff PIN
                </label>
                <input
                  id="camp-pin"
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
                Sign in
              </button>
            </form>

            <p class="mt-5 border-t border-slate-100 pt-4 text-xs leading-relaxed text-slate-400">
              PINs are per staff member and only work for your own organisation's camp.
              Prefer a full login? <.link
                navigate={~p"/users/log_in"}
                class="font-semibold text-[#0C2765] hover:underline"
              >
                Sign in with email
              </.link>.
            </p>
          <% else %>
            <h1 class="text-xl font-semibold text-slate-900">Wristband not recognised</h1>
            <p class="mt-2 text-sm leading-relaxed text-slate-500">
              This code doesn't match a patient. Check the wristband and scan again, or
              <.link navigate={~p"/users/log_in"} class="font-semibold text-[#0C2765] hover:underline">
                sign in
              </.link>
              to look the patient up.
            </p>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
