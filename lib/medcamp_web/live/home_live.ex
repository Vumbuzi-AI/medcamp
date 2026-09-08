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
    <div id="top" class="min-h-screen bg-white font-sans text-[#0C2765] antialiased">
      <header class="sticky top-0 z-20 border-b border-slate-200/80 bg-white/90 backdrop-blur">
        <div class="mx-auto flex h-[72px] max-w-7xl items-center justify-between gap-6 px-5 lg:px-8">
          <a href="#top" class="flex items-center gap-3">
            <img src="/images/tibasasa-ai-logo.png" alt="Tibasasa" class="h-11 w-11 object-contain" />
            <div>
              <p class="text-lg font-bold tracking-tight">Tibasasa</p>
              <p class="text-xs font-medium text-slate-500">Medical Camp Management System</p>
            </div>
          </a>
          <nav class="hidden items-center gap-8 text-sm font-medium text-slate-600 md:flex">
            <a href="#features" class="transition hover:text-[#52B2D8]">Features</a>
            <a href="#departments" class="transition hover:text-[#52B2D8]">Departments</a>
            <a href="#workflow" class="transition hover:text-[#52B2D8]">How it works</a>
            <a href="#analysis" class="transition hover:text-[#52B2D8]">Analysis</a>
            <a href="#about" class="transition hover:text-[#52B2D8]">About</a>
          </nav>
          <a
            href={@portal_path}
            class="rounded-full bg-[#0C2765] px-5 py-2.5 text-sm font-semibold text-white transition hover:bg-[#16418f]"
          >
            Staff sign in
          </a>
        </div>
      </header>

      <main>
        <section class="overflow-hidden bg-gradient-to-b from-[#e9f6fb]/80 via-white to-white py-16 lg:py-24">
          <div class="mx-auto max-w-7xl px-5 lg:px-8">
            <div class="mx-auto max-w-3xl text-center">
              <span class="inline-flex items-center gap-2 rounded-full border border-slate-200 bg-white px-4 py-2 text-sm font-semibold text-slate-600 shadow-sm">
                <span class="h-2 w-2 rounded-full bg-[#52B2D8]"></span>Care that moves with the camp
              </span>
              <h1 class="mt-7 text-4xl font-semibold leading-tight tracking-[-.04em] sm:text-6xl">
                Run every medical camp from
                <span class="font-serif font-normal italic text-[#52B2D8]">one place.</span>
              </h1>
              <p class="mx-auto mt-6 max-w-2xl text-lg leading-relaxed text-slate-500">
                Tibasasa connects registration, triage, consultations, laboratory work, pharmacy, and patient records into one simple medical-camp workflow.
              </p>
              <div class="mt-9 flex flex-wrap items-center justify-center gap-3">
                <a
                  href={@portal_path}
                  class="rounded-full bg-[#0C2765] px-7 py-3.5 text-base font-semibold text-white shadow-lg shadow-[#0C2765]/15 transition hover:bg-[#16418f]"
                >
                  Open staff workspace
                </a>
                <a
                  href="/medical-camp/scan"
                  class="rounded-full border border-slate-300 bg-white px-7 py-3.5 text-base font-semibold text-[#0C2765] transition hover:border-[#52B2D8] hover:text-[#16418f]"
                >
                  Scan a patient QR code
                </a>
              </div>
            </div>
            <div class="mt-16 grid gap-5 md:grid-cols-[.9fr_1.1fr] md:items-end">
              <img
                src="/images/public/african-hospital-reception.png"
                alt="Healthcare worker reviewing patient information"
                class="h-72 w-full rounded-2xl object-cover shadow-[0_12px_32px_-12px_rgba(0,0,0,.2)] lg:h-96"
              />
              <img
                src="/images/public/african-care-coordination.png"
                alt="Healthcare team coordinating patient care"
                class="h-72 w-full rounded-2xl object-cover shadow-[0_12px_32px_-12px_rgba(0,0,0,.2)] lg:h-[440px]"
              />
            </div>
          </div>
        </section>

        <section id="features" class="scroll-mt-20 border-y border-slate-200 bg-white py-20 lg:py-28">
          <div class="mx-auto max-w-7xl px-5 lg:px-8">
            <div class="max-w-2xl">
              <span class="text-sm font-bold uppercase tracking-[.18em] text-[#52B2D8]">
                Built for the field
              </span>
              <h2 class="mt-4 text-3xl font-semibold tracking-tight sm:text-5xl">
                Everything your camp team needs to deliver better care.
              </h2>
              <p class="mt-5 text-lg leading-relaxed text-slate-500">
                Keep teams aligned, reduce queues, and give every patient a clear, connected record.
              </p>
            </div>
            <div class="mt-12 grid gap-5 md:grid-cols-3">
              <.feature
                icon="01"
                title="Register & triage"
                text="Capture patient details once, create the visit, and move patients into the right queue."
                image="/images/public/african-hospital-reception.png"
              />
              <.feature
                icon="02"
                title="Coordinate care"
                text="Doctors, nurses, laboratory staff, and pharmacists work from the same patient story."
                image="/images/public/african-care-coordination.png"
              />
              <.feature
                icon="03"
                title="Close the loop"
                text="Track prescriptions, lab results, dispensing, and patient history from one record."
                image="/images/public/african-diagnostic-care.png"
              />
            </div>
          </div>
        </section>

        <section id="departments" class="scroll-mt-20 py-20 lg:py-28">
          <div class="mx-auto max-w-7xl px-5 lg:px-8">
            <div class="mx-auto max-w-2xl text-center">
              <span class="text-sm font-bold uppercase tracking-[.18em] text-[#52B2D8]">
                One connected camp
              </span>
              <h2 class="mt-4 text-3xl font-semibold tracking-tight sm:text-5xl">
                Every department, working from the same patient story.
              </h2>
              <p class="mt-5 text-lg leading-relaxed text-slate-500">
                Make handoffs visible and keep care moving, even when the camp is busy.
              </p>
            </div>
            <div class="mt-12 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              <.department
                number="01"
                title="Registration"
                text="Create patient profiles, capture consent, issue GSRNs, and open visits."
                icon="＋"
              />
              <.department
                number="02"
                title="Triage & nursing"
                text="Record vitals, allergies, urgency, notes, and the next point of care."
                icon="♡"
              />
              <.department
                number="03"
                title="Doctors"
                text="Review the patient journey, document findings, diagnose, and prescribe."
                icon="✚"
              />
              <.department
                number="04"
                title="Laboratory"
                text="Receive lab requests, manage test templates, enter findings, and complete reports."
                icon="⌁"
              />
              <.department
                number="05"
                title="Pharmacy"
                text="Track stock, allocate batches, dispense medicines, and print prescriptions."
                icon="◇"
              />
              <.department
                number="06"
                title="Administration"
                text="Monitor camp activity, teams, financials, exports, and operational performance."
                icon="▦"
              />
            </div>
          </div>
        </section>

        <section id="workflow" class="scroll-mt-20 bg-[#f6f6f6] py-20 lg:py-28">
          <div class="mx-auto grid max-w-7xl gap-12 px-5 lg:grid-cols-2 lg:items-center lg:px-8">
            <div>
              <span class="text-sm font-bold uppercase tracking-[.18em] text-[#52B2D8]">
                A clearer workflow
              </span>
              <h2 class="mt-4 text-3xl font-semibold tracking-tight sm:text-5xl">
                From first scan to completed care.
              </h2>
              <p class="mt-5 text-lg leading-relaxed text-slate-500">
                Give every role the context they need while keeping the patient journey visible from registration to follow-up.
              </p>
              <div class="mt-8 space-y-5">
                <.step
                  number="01"
                  title="Register"
                  text="Capture demographics and consent once. Tibasasa creates a unique patient GSRN and visit."
                /><.step
                  number="02"
                  title="Move through care"
                  text="The patient moves from triage to doctor review, laboratory, and pharmacy with clear queues."
                /><.step
                  number="03"
                  title="Close the loop"
                  text="Scan the QR code later to see what was done, including notes, results, prescriptions, and medicines."
                />
              </div>
            </div>
            <img
              src="/images/public/african-clinician-research.png"
              alt="Clinician reviewing medical information"
              class="h-[420px] w-full rounded-2xl object-cover shadow-xl"
            />
          </div>
        </section>

        <section id="analysis" class="scroll-mt-20 bg-white py-20 lg:py-28">
          <div class="mx-auto max-w-7xl px-5 lg:px-8">
            <div class="grid gap-12 lg:grid-cols-[.85fr_1.15fr] lg:items-center">
              <div>
                <span class="text-sm font-bold uppercase tracking-[.18em] text-[#52B2D8]">
                  Make better decisions
                </span>
                <h2 class="mt-4 text-3xl font-semibold tracking-tight sm:text-5xl">
                  See what your camp is accomplishing in real time.
                </h2>
                <p class="mt-5 text-lg leading-relaxed text-slate-500">
                  The reporting workspace turns day-to-day activity into a clear operational picture for coordinators and administrators.
                </p>
                <div class="mt-8 space-y-4">
                  <.analysis_item
                    title="Live camp overview"
                    text="Registrations, triage completion, doctor notes, lab tests, and care progress."
                  /><.analysis_item
                    title="Patient-level analysis"
                    text="Follow diagnoses, test findings, prescriptions, and outcomes for each patient."
                  /><.analysis_item
                    title="Operational reporting"
                    text="Review trends, demographics, workloads, stock activity, and downloadable reports."
                  />
                </div>
              </div>
              <div class="rounded-2xl border border-slate-200 bg-[#f9f9f9] p-5 shadow-sm sm:p-7">
                <div class="flex items-center justify-between">
                  <div>
                    <p class="text-sm font-semibold text-slate-500">Camp overview</p>
                    <p class="mt-1 text-2xl font-semibold">Today at a glance</p>
                  </div>
                  <span class="rounded-full bg-[#e9f6fb] px-3 py-1 text-xs font-bold text-[#0C2765]">
                    Live data
                  </span>
                </div>
                <div class="mt-6 grid grid-cols-2 gap-3 sm:grid-cols-4">
                  <.metric value="124" label="Registered" color="blue" /><.metric
                    value="98"
                    label="Triaged"
                    color="cyan"
                  /><.metric value="76" label="Doctor notes" color="violet" /><.metric
                    value="61"
                    label="Lab tests"
                    color="green"
                  />
                </div>
                <div class="mt-5 rounded-xl bg-white p-5">
                  <div class="flex h-28 items-end gap-2">
                    <%= for height <- [35, 52, 44, 68, 57, 82, 72, 94, 78, 100, 88, 96] do %>
                      <div
                        class="flex-1 rounded-t-md bg-gradient-to-t from-[#0C2765] to-[#52B2D8]"
                        style={"height: #{height}%"}
                      >
                      </div>
                    <% end %>
                  </div>
                  <div class="mt-3 flex justify-between text-xs text-slate-400">
                    <span>08:00</span><span>12:00</span><span>16:00</span><span>Now</span>
                  </div>
                </div>
                <div class="mt-4 flex items-center gap-3 rounded-xl border border-emerald-100 bg-emerald-50 p-4">
                  <span class="grid h-8 w-8 place-items-center rounded-full bg-emerald-500 text-white">
                    ✓
                  </span>
                  <div>
                    <p class="text-sm font-semibold text-emerald-900">Care teams are aligned</p>
                    <p class="text-xs text-emerald-700">
                      All departments are receiving live updates.
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        <section id="about" class="scroll-mt-20 py-20 text-center lg:py-28">
          <div class="mx-auto max-w-3xl px-5">
            <h2 class="text-3xl font-semibold tracking-tight sm:text-5xl">
              Better coordination means more time for patients.
            </h2>
            <p class="mt-5 text-lg leading-relaxed text-slate-500">
              Tibasasa Medical Camp Management System gives your team a shared operational view without adding complexity to the care journey.
            </p>
            <a
              href={@portal_path}
              class="mt-8 inline-flex rounded-full bg-[#0C2765] px-7 py-3.5 font-semibold text-white transition hover:bg-[#16418f]"
            >
              Get started
            </a>
          </div>
        </section>
      </main>
      <footer class="border-t border-slate-200 bg-white py-8">
        <div class="mx-auto flex max-w-7xl flex-col gap-3 px-5 text-sm text-slate-500 sm:flex-row sm:items-center sm:justify-between lg:px-8">
          <span>© 2026 Tibasasa Medical Camp Management System</span><span>Connected care for every camp.</span>
        </div>
      </footer>
    </div>
    """
  end

  defp feature(assigns) do
    ~H"""
    <article class="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm transition hover:-translate-y-1 hover:shadow-lg">
      <div class="p-7">
        <span class="text-sm font-bold text-[#52B2D8]">{@icon}</span>
        <h3 class="mt-5 text-2xl font-semibold tracking-tight">{@title}</h3>
        <p class="mt-3 leading-relaxed text-slate-500">{@text}</p>
      </div>
      <img src={@image} alt="" loading="lazy" class="h-48 w-full object-cover" />
    </article>
    """
  end

  defp step(assigns) do
    ~H"""
    <div class="flex gap-4">
      <span class="grid h-9 w-9 shrink-0 place-items-center rounded-full bg-[#0C2765] text-xs font-bold text-white">
        {@number}
      </span>
      <div>
        <h3 class="font-semibold">{@title}</h3>
        <p class="mt-1 text-slate-500">{@text}</p>
      </div>
    </div>
    """
  end

  defp department(assigns) do
    ~H"""
    <article class="rounded-2xl border border-slate-200 bg-[#f9f9f9] p-6 transition hover:-translate-y-1 hover:bg-white hover:shadow-lg">
      <div class="flex items-start justify-between">
        <span class="grid h-10 w-10 place-items-center rounded-xl bg-[#e9f6fb] text-xl text-[#0C2765]">
          {@icon}
        </span>
        <span class="text-sm font-bold text-[#52B2D8]">{@number}</span>
      </div>
      <h3 class="mt-6 text-xl font-semibold">{@title}</h3>
      <p class="mt-2 leading-relaxed text-slate-500">{@text}</p>
    </article>
    """
  end

  defp analysis_item(assigns) do
    ~H"""
    <div class="flex gap-3">
      <span class="mt-1 grid h-5 w-5 shrink-0 place-items-center rounded-full bg-[#e9f6fb] text-xs font-bold text-[#0C2765]">
        ✓
      </span>
      <div>
        <h3 class="font-semibold">{@title}</h3>
        <p class="mt-1 text-slate-500">{@text}</p>
      </div>
    </div>
    """
  end

  defp metric(assigns) do
    ~H"""
    <div class="rounded-xl border border-slate-200 bg-white p-3">
      <p class="text-2xl font-bold text-[#0C2765]">{@value}</p>
      <p class="mt-1 text-xs text-slate-500">{@label}</p>
    </div>
    """
  end

  defp portal_path(%{role: role}), do: MedcampWeb.UserAuth.default_path_for_role(role)
  defp portal_path(_), do: "/users/log_in"
end
