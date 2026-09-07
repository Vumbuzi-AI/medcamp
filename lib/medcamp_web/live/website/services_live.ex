defmodule MedcampWeb.Website.ServicesLive do
  use Phoenix.LiveView, layout: false
  import MedcampWeb.PublicSiteComponents

  @page_title "Services | GHCE — Quality Care at Kisaju"
  @body_class "bg-gradient-to-b from-[#cfd0fb] via-[#e9ebff] to-white antialiased"

  @services [
    %{
      slug: "outpatient",
      title: "Outpatient Care",
      summary:
        "Daily consultations, diagnostics, and procedures supported by digital identification and patient-flow systems.",
      detail:
        "The outpatient department provides general and specialist consultations, family medicine, paediatrics, obstetrics and gynaecology, internal medicine, geriatric care, nutrition support, and minor procedures with clear coordination from registration to follow-up."
    },
    %{
      slug: "inpatient",
      title: "Inpatient Care",
      summary:
        "Short-stay and extended-stay ward care supported by standardised patient identification and medication safety systems.",
      detail:
        "Our inpatient services cover general medical, surgical, paediatric, maternity, observation, and short-stay wards with daily clinician rounds, chronic disease management, infection management, bedside testing, inpatient imaging, and verified medication workflows."
    },
    %{
      slug: "emergency",
      title: "Emergency Services",
      summary:
        "24/7 emergency response with rapid triage, stabilisation, and coordinated referral support.",
      detail:
        "Emergency and ambulatory care includes rapid diagnostics for acute conditions, basic trauma and fracture management, stabilisation, triage services, and ambulance or referral support so urgent cases are routed quickly and safely."
    },
    %{
      slug: "maternal",
      title: "Maternal & Child Health",
      summary:
        "Antenatal, delivery, postnatal, and newborn care delivered in a safe and supportive environment.",
      detail:
        "Maternity and newborn care spans antenatal and postnatal visits, normal delivery services, newborn assessments, immunisation, maternal follow-up, and demonstration of newborn identification using GS1-enabled traceability best practices."
    },
    %{
      slug: "diagnostics",
      title: "Diagnostics",
      summary:
        "Laboratory, imaging, and point-of-care testing with accurate reporting and traceable workflows.",
      detail:
        "Patients have access to a fully equipped laboratory, radiology and imaging services including X-ray and ultrasound, point-of-care diagnostics, bedside tests, and digital records that help clinicians act on reliable results quickly."
    },
    %{
      slug: "pharmacy",
      title: "Pharmacy",
      summary:
        "Safer dispensing through GS1-enabled medicine identification, traceability, and counselling.",
      detail:
        "Pharmacy services support outpatient and inpatient dispensing, barcode-enabled medication administration demonstrations, treatment adherence support, discharge counselling, and better supply visibility that helps reduce risk."
    }
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, @page_title)
     |> assign(:body_class, @body_class)
     |> assign(:services, @services)
     |> assign(:selected_service, nil)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    service = service_by_slug(params["slug"])

    {:noreply,
     socket
     |> assign(:selected_service, service)
     |> assign(:page_title, page_title_for(service))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="top" class={["min-h-screen", public_page_background_class()]}>
      <.public_navbar current_page={:services} />

      <script
        src="https://gs1kenya.org/embed/chatbot.js"
        data-product-id="4"
        data-api-key="public"
        data-api-base="https://gs1kenya.org"
        async
      >
      </script>

      <main>
        <section class="overflow-hidden border-b border-[#cfd0fb] bg-white">
          <div class="mx-auto grid max-w-7xl gap-10 px-4 py-16 sm:px-6 md:py-20 lg:grid-cols-[0.9fr_1.1fr] lg:px-8">
            <div class="flex flex-col justify-center">
              <p class="text-sm font-bold uppercase tracking-wide">GHCE Services</p>
              <h1 class="mt-4 text-4xl font-bold leading-[1.04] sm:text-5xl lg:text-6xl">
                {if @selected_service,
                  do: @selected_service.title,
                  else: "Clinical Services"}
              </h1>
              <p class="mt-6 max-w-2xl text-base leading-7 sm:text-lg sm:leading-8">
                {if @selected_service,
                  do: @selected_service.summary,
                  else:
                    "Our integrated service portfolio meets community health needs while showing how standards-driven systems improve safety, accuracy, and coordination."}
              </p>
              <div class="mt-8 flex flex-col gap-3 sm:flex-row">
                <a
                  href="#services"
                  class="inline-flex items-center justify-center rounded-md border border-[#cfd0fb] bg-[#cfd0fb] px-6 py-3 font-semibold no-underline shadow-sm hover:bg-white"
                >
                  Explore Services
                </a>
                <a
                  :if={@selected_service}
                  href="/services"
                  class="inline-flex items-center justify-center rounded-md border border-[#cfd0fb] bg-white px-6 py-3 font-semibold no-underline hover:bg-[#cfd0fb]"
                >
                  Back to All Services
                </a>
                <a
                  :if={!@selected_service}
                  href="#appointment"
                  class="inline-flex items-center justify-center rounded-md border border-[#cfd0fb] bg-white px-6 py-3 font-semibold no-underline hover:bg-[#cfd0fb]"
                >
                  Book Appointment
                </a>
              </div>
            </div>
            <div class="relative min-h-[280px] sm:min-h-[360px]">
              <img
                src="/images/public/african-care-coordination.png"
                alt="African clinicians coordinating care with a patient in a modern consultation room"
                class="h-full min-h-[280px] w-full rounded-lg object-cover shadow-2xl sm:min-h-[360px]"
              />
              <div class="absolute bottom-4 left-4 right-4 rounded-lg bg-white p-4 shadow-xl backdrop-blur sm:bottom-5 sm:left-auto sm:right-5 sm:w-80 sm:p-5">
                <p class="text-sm font-semibold uppercase">Integrated services</p>
                <p class="mt-2 text-xl font-bold sm:text-2xl">
                  Clinical care, diagnostics, and pharmacy working as one system
                </p>
              </div>
            </div>
          </div>
        </section>

        <section :if={!@selected_service} class="py-16 sm:py-20">
          <div class="mx-auto grid max-w-7xl gap-10 px-4 sm:px-6 lg:grid-cols-[0.9fr_1.1fr] lg:px-8">
            <div class="relative">
              <img
                src="/images/public/african-diagnostic-care.png"
                alt="African nurse supporting a patient during diagnostic screening"
                class="h-full min-h-[280px] w-full rounded-lg object-cover sm:min-h-[430px]"
                loading="lazy"
              />
              <div class="absolute left-4 top-4 rounded-lg border border-[#cfd0fb] bg-white p-4 shadow-xl sm:left-5 sm:top-5">
                <div class="flex items-center gap-3">
                  <span class="flex h-11 w-11 items-center justify-center rounded-lg bg-[#cfd0fb]">
                    <svg
                      viewBox="0 0 24 24"
                      aria-hidden="true"
                      class="h-6 w-6"
                      fill="none"
                      stroke="currentColor"
                      stroke-width="2"
                      stroke-linecap="round"
                      stroke-linejoin="round"
                    >
                      <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" />
                      <circle cx="9" cy="7" r="4" />
                      <path d="M22 21v-2a4 4 0 0 0-3-3.87" />
                      <path d="M16 3.13a4 4 0 0 1 0 7.75" />
                    </svg>
                  </span>
                  <p class="font-bold">
                    Trusted clinical<br />professionals
                  </p>
                </div>
              </div>
            </div>
            <div class="flex flex-col justify-center">
              <p class="text-sm font-bold uppercase tracking-wide">
                Built for the whole care journey
              </p>
              <h2 class="mt-3 text-3xl font-bold leading-tight sm:text-4xl lg:text-5xl">
                Services that move with the patient
              </h2>
              <p class="mt-5 text-base leading-7 sm:text-lg sm:leading-8">
                GHCE combines frontline clinical care with digital identification, standards-based workflows, and coordinated support services.
              </p>
              <div class="mt-8 grid gap-4">
                <article class="rounded-lg bg-white p-6 shadow-sm">
                  <div class="flex gap-4">
                    <span class="flex h-12 w-12 shrink-0 items-center justify-center rounded-lg bg-[#cfd0fb]">
                      <svg
                        viewBox="0 0 24 24"
                        aria-hidden="true"
                        class="h-6 w-6"
                        fill="none"
                        stroke="currentColor"
                        stroke-width="2"
                        stroke-linecap="round"
                        stroke-linejoin="round"
                      >
                        <path d="M20 6 9 17l-5-5" />
                      </svg>
                    </span>
                    <div>
                      <h3 class="text-xl font-bold">Outpatient to emergency continuity</h3>
                      <p class="mt-2 leading-7">
                        Daily consultations, emergency triage, minor procedures, and referral support are designed to connect smoothly across departments.
                      </p>
                    </div>
                  </div>
                </article>
                <article class="rounded-lg bg-white p-6 shadow-sm">
                  <div class="flex gap-4">
                    <span class="flex h-12 w-12 shrink-0 items-center justify-center rounded-lg bg-[#cfd0fb]">
                      <svg
                        viewBox="0 0 24 24"
                        aria-hidden="true"
                        class="h-6 w-6"
                        fill="none"
                        stroke="currentColor"
                        stroke-width="2"
                        stroke-linecap="round"
                        stroke-linejoin="round"
                      >
                        <path d="M21 15a4 4 0 0 1-4 4H8l-5 3V7a4 4 0 0 1 4-4h10a4 4 0 0 1 4 4z" />
                      </svg>
                    </span>
                    <div>
                      <h3 class="text-xl font-bold">Diagnostics, pharmacy, and records</h3>
                      <p class="mt-2 leading-7">
                        Barcode-based identification, digital records, imaging, laboratory testing, and medication safety help every team work from reliable information.
                      </p>
                    </div>
                  </div>
                </article>
                <article class="rounded-lg bg-white p-6 shadow-sm">
                  <div class="flex gap-4">
                    <span class="flex h-12 w-12 shrink-0 items-center justify-center rounded-lg bg-[#cfd0fb]">
                      <svg
                        viewBox="0 0 24 24"
                        aria-hidden="true"
                        class="h-6 w-6"
                        fill="none"
                        stroke="currentColor"
                        stroke-width="2"
                        stroke-linecap="round"
                        stroke-linejoin="round"
                      >
                        <path d="M12 21c-4.97 0-9-3.58-9-8s4.03-8 9-8 9 3.58 9 8-4.03 8-9 8Z" />
                        <path d="M12 9v6" />
                        <path d="M9 12h6" />
                      </svg>
                    </span>
                    <div>
                      <h3 class="text-xl font-bold">Maternal, newborn, and preventive care</h3>
                      <p class="mt-2 leading-7">
                        Antenatal, postnatal, immunisation, family planning, and community screening services strengthen long-term health beyond the immediate visit.
                      </p>
                    </div>
                  </div>
                </article>
              </div>
            </div>
          </div>
        </section>

        <section :if={!@selected_service} id="services" class="bg-white py-16 sm:py-20">
          <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            <div class="mx-auto max-w-3xl text-center">
              <h2 class="text-3xl font-bold leading-tight sm:text-4xl lg:text-5xl">
                Clinical services at the Centre
              </h2>
              <p class="mt-4 text-base leading-7 sm:text-lg sm:leading-8">
                Explore the service areas that make GHCE both a functioning hospital and a practical demonstration site for safer healthcare systems.
              </p>
            </div>
            <div class="mt-12 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              <a
                :for={service <- @services}
                href={"/services/#{service.slug}"}
                id={service.slug}
                class="block rounded-lg border border-[#cfd0fb] bg-white p-6 no-underline transition hover:-translate-y-1 hover:bg-[#cfd0fb]"
              >
                <div class="mb-5 flex h-12 w-12 items-center justify-center rounded-lg bg-[#cfd0fb]">
                  <svg
                    viewBox="0 0 24 24"
                    aria-hidden="true"
                    class="h-6 w-6"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="2"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                  >
                    <path d="M22 12h-4l-3 9L9 3l-3 9H2" />
                  </svg>
                </div>
                <h3 class="text-xl font-bold">{service.title}</h3>
                <p class="mt-3 leading-7">{service.summary}</p>
                <span class="mt-5 inline-flex items-center gap-2 font-semibold">
                  Learn more
                  <svg
                    viewBox="0 0 24 24"
                    aria-hidden="true"
                    class="h-4 w-4"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="2"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                  >
                    <path d="M5 12h14" />
                    <path d="m12 5 7 7-7 7" />
                  </svg>
                </span>
              </a>
            </div>
          </div>
        </section>

        <section :if={@selected_service} class="py-16 sm:py-20">
          <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            <div class="grid gap-8 lg:grid-cols-[1.1fr_0.9fr]">
              <article class="rounded-lg border border-[#cfd0fb] bg-white p-6 shadow-sm sm:p-8">
                <p class="text-sm font-bold uppercase tracking-wide">
                  Service Overview
                </p>
                <h2 class="mt-3 text-3xl font-bold leading-tight sm:text-4xl lg:text-5xl">
                  {@selected_service.title}
                </h2>
                <p class="mt-5 text-base leading-7 sm:text-lg sm:leading-8">
                  {@selected_service.summary}
                </p>
                <p class="mt-5 text-base leading-7 sm:text-lg sm:leading-8">
                  {@selected_service.detail}
                </p>
              </article>
              <aside class={["rounded-lg p-6 sm:p-8", public_surface_background_class()]}>
                <h3 class="text-2xl font-bold">Need help choosing a service?</h3>
                <p class="mt-4 leading-7">
                  Reach out for appointments, referrals, diagnostics, maternity visits, or guidance on the right entry point into care. We will help route you to the right team.
                </p>
                <a
                  href="/contact"
                  class="mt-6 inline-flex items-center justify-center rounded-md border border-white bg-white px-6 py-3 font-semibold no-underline shadow-sm hover:opacity-80"
                >
                  Book Appointment
                </a>
              </aside>
            </div>
          </div>
        </section>

        <section :if={!@selected_service} class="py-16 sm:py-20">
          <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            <div class="grid gap-10 lg:grid-cols-[0.85fr_1.15fr]">
              <div>
                <h2 class="text-3xl font-bold leading-tight sm:text-4xl lg:text-5xl">
                  Innovation and support functions
                </h2>
                <p class="mt-4 text-base leading-7 sm:text-lg sm:leading-8">
                  Alongside clinical services, GHCE supports the broader healthcare ecosystem through training, demonstrations, and collaboration.
                </p>
              </div>
              <div class="grid gap-4 sm:grid-cols-2">
                <article class="rounded-lg bg-white p-6 shadow-sm">
                  <h3 class="text-xl font-bold">GS1 healthcare standards training</h3>
                  <p class="mt-3 leading-7">
                    Capacity building for healthcare professionals, hospital administrators, manufacturers, and supply chain operators.
                  </p>
                </article>
                <article class="rounded-lg bg-white p-6 shadow-sm">
                  <h3 class="text-xl font-bold">UDI and pharmaceutical traceability</h3>
                  <p class="mt-3 leading-7">
                    Practical support for end-to-end tracking of medical devices and medicines from manufacturer to patient.
                  </p>
                </article>
                <article class="rounded-lg bg-white p-6 shadow-sm">
                  <h3 class="text-xl font-bold">Master data and digital workflows</h3>
                  <p class="mt-3 leading-7">
                    Demonstrations that show why clean, interoperable product and patient data matters for safe operations and regulatory compliance.
                  </p>
                </article>
                <article class="rounded-lg bg-white p-6 shadow-sm">
                  <h3 class="text-xl font-bold">Stakeholder workshops and pilots</h3>
                  <p class="mt-3 leading-7">
                    A practical environment for ecosystem forums, pilot evaluations, and collaborative improvement across the health sector.
                  </p>
                </article>
              </div>
            </div>
          </div>
        </section>

        <section id="appointment" class="bg-white py-16 sm:py-20">
          <div class="mx-auto grid max-w-7xl gap-10 px-4 sm:px-6 lg:grid-cols-[0.85fr_1.15fr] lg:px-8">
            <div>
              <h2 class="text-3xl font-bold leading-tight sm:text-4xl lg:text-5xl">
                Schedule your appointment today
              </h2>
              <p class="mt-4 text-base leading-7 sm:text-lg sm:leading-8">
                Book care, request a referral, or contact the team for guidance on the right service line.
              </p>
              <div class="mt-8 space-y-4">
                <a
                  :for={phone <- public_phone_contacts()}
                  href={phone.href}
                  class="flex items-center gap-3 rounded-lg border border-[#cfd0fb] bg-white p-4 font-semibold no-underline hover:bg-[#cfd0fb]"
                >
                  <svg
                    viewBox="0 0 24 24"
                    aria-hidden="true"
                    class="h-5 w-5"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="2"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                  >
                    <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.8 19.8 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6A19.8 19.8 0 0 1 2.1 4.18 2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72c.13.96.35 1.9.66 2.81a2 2 0 0 1-.45 2.11L8.05 9.91a16 16 0 0 0 6.04 6.04l1.27-1.27a2 2 0 0 1 2.11-.45c.91.31 1.85.53 2.81.66A2 2 0 0 1 22 16.92Z" />
                  </svg>
                  {phone.display}
                </a>
                <a
                  href="mailto:info@glocalhealthcentre.org"
                  class="flex items-center gap-3 rounded-lg border border-[#cfd0fb] bg-white p-4 font-semibold no-underline hover:bg-[#cfd0fb]"
                >
                  <svg
                    viewBox="0 0 24 24"
                    aria-hidden="true"
                    class="h-5 w-5"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="2"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                  >
                    <path d="m4 4 16 0a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2Z" />
                    <path d="m22 6-10 7L2 6" />
                  </svg>
                  info@glocalhealthcentre.org
                </a>
              </div>
            </div>
            <form
              action="#"
              method="get"
              class="rounded-lg border border-[#cfd0fb] bg-white p-5 shadow-sm sm:p-8"
            >
              <div class="grid gap-5 sm:grid-cols-2">
                <label class="block">
                  <span class="text-sm font-semibold">First Name</span>
                  <input
                    required
                    name="first-name"
                    type="text"
                    placeholder="First Name"
                    class="mt-2 w-full rounded-md border border-[#cfd0fb] px-4 py-3 outline-none focus:border-[#cfd0fb]"
                  />
                </label>
                <label class="block">
                  <span class="text-sm font-semibold">Last Name</span>
                  <input
                    required
                    name="last-name"
                    type="text"
                    placeholder="Last Name"
                    class="mt-2 w-full rounded-md border border-[#cfd0fb] px-4 py-3 outline-none focus:border-[#cfd0fb]"
                  />
                </label>
                <label class="block">
                  <span class="text-sm font-semibold">Email Address</span>
                  <input
                    required
                    name="email"
                    type="email"
                    placeholder="Enter your email"
                    class="mt-2 w-full rounded-md border border-[#cfd0fb] px-4 py-3 outline-none focus:border-[#cfd0fb]"
                  />
                </label>
                <label class="block">
                  <span class="text-sm font-semibold">Phone Number</span>
                  <input
                    required
                    name="phone"
                    type="tel"
                    placeholder="+254 7XX XXX XXX"
                    class="mt-2 w-full rounded-md border border-[#cfd0fb] px-4 py-3 outline-none focus:border-[#cfd0fb]"
                  />
                </label>
                <label class="block">
                  <span class="text-sm font-semibold">Service Type</span>
                  <select
                    required
                    name="service"
                    class="mt-2 w-full rounded-md border border-[#cfd0fb] bg-white px-4 py-3 outline-none focus:border-[#cfd0fb]"
                  >
                    <option value="">Personalized Care</option>
                    <option :for={s <- @services} value={s.slug}>{s.title}</option>
                  </select>
                </label>
                <label class="block">
                  <span class="text-sm font-semibold">Date &amp; Time</span>
                  <input
                    name="date"
                    type="date"
                    class="mt-2 w-full rounded-md border border-[#cfd0fb] px-4 py-3 outline-none focus:border-[#cfd0fb]"
                  />
                </label>
              </div>
              <label class="mt-5 block">
                <span class="text-sm font-semibold">Message</span>
                <textarea
                  required
                  name="message"
                  rows="5"
                  placeholder="Write your message..."
                  class="mt-2 w-full resize-none rounded-md border border-[#cfd0fb] px-4 py-3 outline-none focus:border-[#cfd0fb]"
                ></textarea>
              </label>
              <button
                type="submit"
                class="mt-6 inline-flex w-full items-center justify-center rounded-md border border-[#cfd0fb] bg-[#cfd0fb] px-6 py-3 font-semibold shadow-sm hover:bg-white sm:w-auto"
              >
                Book Appointment
              </button>
            </form>
          </div>
        </section>
      </main>

      <.public_footer current_page={:services} />

      <a
        href="#top"
        aria-label="Back to top"
        class="fixed bottom-4 right-4 z-40 flex h-10 w-10 items-center justify-center rounded-md border border-[#cfd0fb] bg-white no-underline shadow-lg hover:bg-[#cfd0fb] sm:bottom-5 sm:right-5 sm:h-11 sm:w-11"
      >
        <svg
          viewBox="0 0 24 24"
          aria-hidden="true"
          class="h-5 w-5"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
        >
          <path d="m18 15-6-6-6 6" />
        </svg>
      </a>
    </div>
    """
  end

  defp service_by_slug(nil), do: nil
  defp service_by_slug(slug), do: Enum.find(@services, &(&1.slug == slug))

  defp page_title_for(nil), do: @page_title
  defp page_title_for(service), do: "#{service.title} | GHCE — Quality Care at Kisaju"
end
