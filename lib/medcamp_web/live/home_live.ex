defmodule MedcampWeb.HomeLive do
  use MedcampWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Tibasasa Medical Camp Management System",
       portal_path: portal_path(socket.assigns[:current_user])
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="top" class="min-h-screen bg-white text-[#0C2765]">
      <header class="sticky top-0 z-30 border-b border-slate-200 bg-white">
        <div class="mx-auto max-w-6xl px-5 lg:px-8">
          <div class="grid grid-cols-[1fr_auto] items-center gap-4 py-3 sm:h-16 sm:py-0 md:grid-cols-[1fr_auto_1fr]">
            <a href="#top" class="flex items-center gap-3">
              <img src="/images/tibasasa-ai-logo.png" alt="Tibasasa" class="h-9 w-9 object-contain" />
              <span class="leading-tight">
                <span class="block text-base font-bold tracking-tight">Tibasasa</span>
                <span class="block text-[10px] uppercase tracking-[0.08em] text-slate-500">
                  Medical Camp Management System
                </span>
              </span>
            </a>

            <nav class="hidden justify-self-center md:flex md:items-center md:gap-8">
              <a
                href="#features"
                class="text-sm font-semibold text-slate-600 transition-colors duration-150 hover:text-[#0C2765]"
              >
                Features
              </a>
              <a
                href="#stations"
                class="text-sm font-semibold text-slate-600 transition-colors duration-150 hover:text-[#0C2765]"
              >
                Workflow
              </a>
              <a
                href="#analysis"
                class="text-sm font-semibold text-slate-600 transition-colors duration-150 hover:text-[#0C2765]"
              >
                Reporting
              </a>
            </nav>

            <a
              href={@portal_path}
              class="inline-flex items-center justify-self-end rounded-full bg-[#0C2765] px-4 py-1.5 text-sm font-semibold text-white transition-colors duration-150 hover:bg-[#16418f]"
            >
              Sign in
            </a>
          </div>
        </div>
      </header>

      <main>
        <section class="border-b border-slate-200 bg-slate-50">
          <div class="mx-auto grid max-w-6xl gap-12 px-5 py-16 lg:grid-cols-[minmax(0,1fr)_1.05fr] lg:items-center lg:gap-14 lg:px-8 lg:py-24 lg:pr-0">
            <div>
              <p class="mb-5 inline-flex items-center gap-2 rounded-full border border-slate-200 bg-white px-4 py-2 text-sm font-semibold text-slate-600">
                <span class="h-2 w-2 rounded-full bg-[#52B2D8]"></span> Care that moves with the camp
              </p>
              <h1 class="text-4xl font-bold leading-[1.1] tracking-[-0.02em] sm:text-5xl">
                Run every medical camp from <span class="text-[#52B2D8]">one place</span>.
              </h1>
              <p class="mt-6 max-w-md text-lg leading-relaxed text-slate-600">
                One patient record for the whole camp, from the registration desk to
                the pharmacy.
              </p>
              <div class="mt-10 flex flex-wrap items-center gap-4">
                <a
                  href="/organisations/register"
                  class="inline-flex items-center gap-2 rounded-full bg-[#0C2765] px-6 py-3 text-base font-semibold text-white transition-colors duration-150 hover:bg-[#16418f]"
                >
                  Get started <.feather name="arrow-right" class="h-4 w-4" />
                </a>
                <a
                  href={@portal_path}
                  class="inline-flex items-center rounded-full border border-slate-300 px-6 py-3 text-base font-semibold text-[#0C2765] transition-colors duration-150 hover:border-[#52B2D8]"
                >
                  Staff sign in
                </a>
              </div>
            </div>

            <div class="lg:-mr-8">
              <img
                src="/images/public/african-care-coordination.png"
                alt="Clinicians reviewing a patient's record together"
                class="h-64 w-full rounded-[2rem] border border-slate-200 object-cover sm:h-80 lg:h-[30rem] lg:rounded-r-none lg:border-r-0"
              />
            </div>
          </div>
        </section>
      </main>

      <section id="features" class="scroll-mt-20">
        <div class="mx-auto max-w-6xl px-5 py-12 sm:py-16 lg:px-8 lg:py-20">
          <h2 class="max-w-2xl text-2xl font-bold leading-tight sm:text-3xl lg:text-4xl">
            One record, from registration to dispensing.
          </h2>
          <div class="mt-8 grid gap-4 sm:grid-cols-2 lg:mt-12 lg:grid-cols-3">
            <.feature
              title="Register and triage"
              text="Capture patient details once; the visit opens and the patient joins the queue."
              image="/images/public/african-hospital-reception.png"
            >
              <.feather name="clipboard" class="h-6 w-6" />
            </.feature>
            <.feature
              title="Coordinate care"
              text="Doctors, nurses, lab staff, and pharmacists work from the same patient story."
              image="/images/public/african-care-coordination.png"
            >
              <.feather name="users" class="h-6 w-6" />
            </.feature>
            <.feature
              title="Close the loop"
              text="Prescriptions, lab results, dispensing, and history stay on one patient record."
              image="/images/public/african-diagnostic-care.png"
            >
              <.feather name="refresh-cw" class="h-6 w-6" />
            </.feature>
          </div>
        </div>
      </section>

      <section id="stations" class="scroll-mt-20 border-y border-slate-200 bg-slate-50">
        <div class="mx-auto max-w-6xl px-5 py-20 lg:px-8">
          <h2 class="text-3xl font-bold tracking-[-0.01em] sm:text-4xl">
            Every step of the camp, one connected flow.
          </h2>
          <p class="mt-5 max-w-2xl text-lg leading-relaxed text-slate-600">
            Every station works from the same patient record. A visit moves forward only
            when a step is finished, so the queues never drift out of sync.
          </p>
          <div class="mt-12 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            <.station
              title="Registration"
              text="Enrol patients and issue the GSRN card that opens their visit."
            >
              <.feather name="user-plus" class="h-6 w-6" />
            </.station>
            <.station
              title="Triage and nursing"
              text="Vitals, allergies, and urgency, recorded before the doctor."
            >
              <.feather name="heart" class="h-6 w-6" />
            </.station>
            <.station title="Doctors" text="Consult, diagnose, request lab tests, and prescribe.">
              <.feather name="activity" class="h-6 w-6" />
            </.station>
            <.station
              title="Laboratory"
              text="Fill templated test results against the doctor's request."
            >
              <.feather name="droplet" class="h-6 w-6" />
            </.station>
            <.station
              title="Pharmacy"
              text="Confirm stock by scanning it, then dispense against the prescription."
            >
              <.feather name="package" class="h-6 w-6" />
            </.station>
            <.station
              title="Administration"
              text="Oversee staff, stock, reporting, and exports across the camp."
            >
              <.feather name="grid" class="h-6 w-6" />
            </.station>
          </div>
        </div>
      </section>

      <section id="analysis" class="scroll-mt-20">
        <div class="mx-auto grid max-w-6xl gap-12 px-5 py-20 lg:grid-cols-[0.85fr_1.15fr] lg:items-center lg:px-8">
          <div>
            <h2 class="text-3xl font-bold tracking-[-0.01em] sm:text-4xl">
              See where the camp stands, live.
            </h2>
            <p class="mt-5 text-lg leading-relaxed text-slate-600">
              Watch the day unfold in real time, open any patient's full record, and
              export the report when the camp closes.
            </p>
            <div class="mt-8 space-y-4">
              <.analysis_item
                title="Live camp overview"
                text="Registrations, triage, notes, and lab tests as they happen."
              />
              <.analysis_item
                title="Patient-level detail"
                text="Diagnoses, results, prescriptions, and outcomes, patient by patient."
              />
              <.analysis_item
                title="Operational reporting"
                text="Trends, demographics, workloads, and downloadable reports."
              />
            </div>
          </div>

          <div class="rounded-2xl border border-slate-200 bg-white p-5 sm:p-7">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm font-semibold text-slate-500">Camp overview</p>
                <p class="mt-1 text-2xl font-bold">Today at a glance</p>
              </div>
              <span class="rounded-full bg-[#e9f6fb] px-3 py-1 text-xs font-semibold text-[#0C2765]">
                Live data
              </span>
            </div>
            <div class="mt-6 grid grid-cols-2 gap-3 sm:grid-cols-4">
              <.metric value="124" label="Registered" />
              <.metric value="98" label="Triaged" />
              <.metric value="76" label="Doctor notes" />
              <.metric value="61" label="Lab tests" />
            </div>
            <div class="mt-4 rounded-xl border border-slate-200 p-5">
              <div class="flex h-28 items-end gap-2">
                <div
                  :for={height <- [35, 52, 44, 68, 57, 82, 72, 94, 78, 100, 88, 96]}
                  class="flex-1 rounded-t bg-[#0C2765]"
                  style={"height: #{height}%"}
                >
                </div>
              </div>
              <div class="mt-3 flex justify-between text-xs text-slate-400">
                <span>08:00</span><span>12:00</span><span>16:00</span><span>Now</span>
              </div>
            </div>
            <div class="mt-4 flex items-center gap-3 rounded-xl border border-emerald-200 bg-emerald-50 p-4">
              <span class="grid h-8 w-8 shrink-0 place-items-center rounded-full bg-emerald-500 text-white">
                <.feather name="check" class="h-4 w-4" />
              </span>
              <div>
                <p class="text-sm font-semibold text-emerald-900">All stations reporting</p>
                <p class="text-xs text-emerald-700">Every station is sending live updates.</p>
              </div>
            </div>
          </div>
        </div>
      </section>

      <section class="border-y border-slate-200 bg-slate-50">
        <div class="mx-auto flex max-w-6xl flex-col gap-8 px-5 py-16 lg:flex-row lg:items-end lg:justify-between lg:px-8">
          <div class="max-w-xl">
            <h2 class="text-3xl font-bold tracking-[-0.01em] sm:text-4xl">
              Better coordination means more time for patients.
            </h2>
            <p class="mt-3 text-lg leading-relaxed text-slate-600">
              One shared view of the whole camp, so your team spends its time on patients,
              not paperwork.
            </p>
          </div>
          <div class="flex flex-col gap-3 sm:flex-row">
            <a
              href="/organisations/register"
              class="inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-full bg-[#0C2765] px-6 py-3 text-base font-semibold text-white transition-colors duration-150 hover:bg-[#16418f]"
            >
              Get started <.feather name="arrow-right" class="h-4 w-4" />
            </a>
            <a
              href={@portal_path}
              class="inline-flex items-center justify-center whitespace-nowrap rounded-full border border-slate-300 px-6 py-3 text-base font-semibold text-[#0C2765] transition-colors duration-150 hover:border-[#52B2D8]"
            >
              Open staff workspace
            </a>
          </div>
        </div>
      </section>

      <footer class="border-t border-slate-200 bg-[#0C2765] text-white">
        <div class="mx-auto max-w-6xl px-5 py-14 lg:px-8">
          <div class="grid gap-10 sm:grid-cols-2 lg:grid-cols-[1.6fr_1fr_1fr]">
            <div class="max-w-sm">
              <div class="flex items-center gap-2.5">
                <img src="/images/tibasasa-ai-logo.png" alt="" class="h-8 w-8 object-contain" />
                <span class="text-lg font-bold">Tibasasa</span>
              </div>
              <p class="mt-3 text-base text-white">Care that moves with the camp</p>
              <p class="mt-1.5 text-sm leading-relaxed text-white/55">
                Medical camp management on one patient record, from registration
                through pharmacy.
              </p>
            </div>

            <div>
              <p class="text-xs font-semibold uppercase tracking-[0.14em] text-white/50">
                Explore
              </p>
              <ul class="mt-4 space-y-2.5 text-sm">
                <li>
                  <a
                    href="#features"
                    class="text-white/70 transition-colors duration-150 hover:text-white"
                  >
                    Features
                  </a>
                </li>
                <li>
                  <a
                    href="#stations"
                    class="text-white/70 transition-colors duration-150 hover:text-white"
                  >
                    Workflow
                  </a>
                </li>
                <li>
                  <a
                    href="#analysis"
                    class="text-white/70 transition-colors duration-150 hover:text-white"
                  >
                    Reporting
                  </a>
                </li>
              </ul>
            </div>

            <div>
              <p class="text-xs font-semibold uppercase tracking-[0.14em] text-white/50">
                Get started
              </p>
              <ul class="mt-4 space-y-2.5 text-sm">
                <li>
                  <a
                    href="/organisations/register"
                    class="text-white/70 transition-colors duration-150 hover:text-white"
                  >
                    Create your organisation
                  </a>
                </li>
                <li>
                  <a
                    href={@portal_path}
                    class="text-white/70 transition-colors duration-150 hover:text-white"
                  >
                    Staff sign in
                  </a>
                </li>
              </ul>
            </div>
          </div>

          <p class="mt-12 border-t border-white/15 pt-6 text-sm text-white/50">
            © 2026 Tibasasa Medical Camp Management System
          </p>
        </div>
      </footer>
    </div>
    """
  end

  defp feature(assigns) do
    ~H"""
    <article class="overflow-hidden rounded-2xl border border-slate-200 bg-white">
      <div class="p-5 sm:p-6">
        <span class="grid h-10 w-10 place-items-center rounded-xl bg-[#e9f6fb] text-[#0C2765] sm:h-12 sm:w-12">
          {render_slot(@inner_block)}
        </span>
        <h3 class="mt-4 text-lg font-semibold sm:mt-5 sm:text-xl">{@title}</h3>
        <p class="mt-2 text-sm leading-relaxed text-slate-600 sm:text-base">{@text}</p>
      </div>
      <img
        src={@image}
        alt=""
        loading="lazy"
        class="h-36 w-full border-t border-slate-200 object-cover sm:h-40 lg:h-44"
      />
    </article>
    """
  end

  defp station(assigns) do
    ~H"""
    <article class="rounded-2xl border border-slate-200 bg-white p-6 transition-colors duration-150 hover:border-slate-300">
      <span class="grid h-11 w-11 place-items-center rounded-xl bg-[#e9f6fb] text-[#0C2765]">
        {render_slot(@inner_block)}
      </span>
      <h3 class="mt-5 text-lg font-semibold">{@title}</h3>
      <p class="mt-2 leading-relaxed text-slate-600">{@text}</p>
    </article>
    """
  end

  defp analysis_item(assigns) do
    ~H"""
    <div class="flex gap-3">
      <span class="mt-0.5 grid h-6 w-6 shrink-0 place-items-center rounded-full bg-[#e9f6fb] text-[#0C2765]">
        <.feather name="check" class="h-3.5 w-3.5" />
      </span>
      <div>
        <h3 class="font-semibold">{@title}</h3>
        <p class="mt-1 leading-relaxed text-slate-600">{@text}</p>
      </div>
    </div>
    """
  end

  defp metric(assigns) do
    ~H"""
    <div class="rounded-xl border border-slate-200 p-3">
      <p class="text-2xl font-bold">{@value}</p>
      <p class="mt-1 text-xs text-slate-500">{@label}</p>
    </div>
    """
  end

  attr :name, :string, required: true
  attr :class, :string, default: "h-5 w-5"

  defp feather(assigns) do
    ~H"""
    <svg
      class={@class}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
      stroke-linejoin="round"
      aria-hidden="true"
    >
      {feather_body(@name)}
    </svg>
    """
  end

  defp feather_body("arrow-right") do
    assigns = %{}

    ~H"""
    <line x1="5" y1="12" x2="19" y2="12" /><polyline points="12 5 19 12 12 19" />
    """
  end

  defp feather_body("check") do
    assigns = %{}
    ~H|<polyline points="20 6 9 17 4 12" />|
  end

  defp feather_body("menu") do
    assigns = %{}

    ~H"""
    <line x1="3" y1="6" x2="21" y2="6" /><line x1="3" y1="12" x2="21" y2="12" /><line
      x1="3"
      y1="18"
      x2="21"
      y2="18"
    />
    """
  end

  defp feather_body("clipboard") do
    assigns = %{}

    ~H"""
    <path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2" /><rect
      x="8"
      y="2"
      width="8"
      height="4"
      rx="1"
      ry="1"
    />
    """
  end

  defp feather_body("users") do
    assigns = %{}

    ~H"""
    <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /><path d="M23 21v-2a4 4 0 0 0-3-3.87" /><path d="M16 3.13a4 4 0 0 1 0 7.75" />
    """
  end

  defp feather_body("refresh-cw") do
    assigns = %{}

    ~H"""
    <polyline points="23 4 23 10 17 10" /><polyline points="1 20 1 14 7 14" /><path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15" />
    """
  end

  defp feather_body("user-plus") do
    assigns = %{}

    ~H"""
    <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /><line
      x1="19"
      y1="8"
      x2="19"
      y2="14"
    /><line x1="22" y1="11" x2="16" y2="11" />
    """
  end

  defp feather_body("heart") do
    assigns = %{}

    ~H"""
    <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" />
    """
  end

  defp feather_body("activity") do
    assigns = %{}
    ~H|<polyline points="22 12 18 12 15 21 9 3 6 12 2 12" />|
  end

  defp feather_body("droplet") do
    assigns = %{}
    ~H|<path d="M12 2.69l5.66 5.66a8 8 0 1 1-11.31 0z" />|
  end

  defp feather_body("package") do
    assigns = %{}

    ~H"""
    <line x1="16.5" y1="9.4" x2="7.5" y2="4.21" /><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z" /><polyline points="3.27 6.96 12 12.01 20.73 6.96" /><line
      x1="12"
      y1="22.08"
      x2="12"
      y2="12"
    />
    """
  end

  defp feather_body("grid") do
    assigns = %{}

    ~H"""
    <rect x="3" y="3" width="7" height="7" /><rect x="14" y="3" width="7" height="7" /><rect
      x="14"
      y="14"
      width="7"
      height="7"
    /><rect x="3" y="14" width="7" height="7" />
    """
  end

  defp feather_body("shield") do
    assigns = %{}
    ~H|<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />|
  end

  defp feather_body("eye") do
    assigns = %{}

    ~H"""
    <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" /><circle cx="12" cy="12" r="3" />
    """
  end

  defp feather_body("lock") do
    assigns = %{}

    ~H"""
    <rect x="3" y="11" width="18" height="11" rx="2" ry="2" /><path d="M7 11V7a5 5 0 0 1 10 0v4" />
    """
  end

  defp portal_path(user) when not is_nil(user),
    do: MedcampWeb.UserAuth.landing_path_for_user(user)

  defp portal_path(_), do: "/users/log_in"
end
