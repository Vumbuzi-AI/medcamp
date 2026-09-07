defmodule MedcampWeb.Website.HomeLive do
  use Phoenix.LiveView, layout: false
  import MedcampWeb.CoreComponents, only: [translate_error: 1]
  import MedcampWeb.PublicSiteComponents

  alias Medcamp.Appointments
  alias Medcamp.Appointments.PublicBooking
  alias Medcamp.Blogs

  @page_title "GHCE — Modern Healthcare at Kisaju"
  @body_class "bg-gradient-to-b from-[#cfd0fb] via-[#e9ebff] to-white antialiased"

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, @page_title)
     |> assign(:body_class, @body_class)
     |> assign(:recent_blog_posts, Blogs.list_public_blog_posts(limit: 3))
     |> assign(:booking_feedback, nil)
     |> assign_booking_form(Appointments.change_public_booking())}
  end

  @impl true
  def handle_event("book_appointment", %{"booking" => booking_params}, socket) do
    case Appointments.create_public_appointment(booking_params) do
      {:ok, _appointment} ->
        {:noreply,
         socket
         |> assign_booking_form(Appointments.change_public_booking())
         |> assign(:booking_feedback, %{
           type: :success,
           message: "Your appointment has been booked. Our reception team can now see it."
         })}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> assign_booking_form(changeset)
         |> assign(:booking_feedback, %{
           type: :error,
           message: "Please review the highlighted booking details and try again."
         })}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="top" class={["min-h-screen", public_page_background_class()]}>
      <.public_navbar current_page={:home} />
      <script
        src="https://gs1kenya.org/embed/chatbot.js"
        data-product-id="4"
        data-api-key="public"
        data-api-base="https://gs1kenya.org"
        async
      >
      </script>

      <main>
        <section class="relative overflow-hidden border-b border-[#cfd0fb] bg-white">
          <div class="mx-auto grid max-w-7xl gap-10 px-4 py-12 sm:px-6 sm:py-16 lg:grid-cols-12 lg:items-end lg:gap-8 lg:px-8 lg:py-20 xl:gap-12">
            <div class="flex flex-col justify-center lg:col-span-7">
              <div class="mb-5 inline-flex w-fit items-center gap-2 rounded-md border border-[#cfd0fb] bg-white px-3 py-2 text-sm font-semibold">
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
                  <path d="M22 12h-4l-3 9L9 3l-3 9H2" />
                </svg>
                Level 3 hospital in Kisaju
              </div>
              <h1 class="max-w-4xl text-4xl font-bold leading-[1.02] sm:text-5xl lg:text-6xl">
                Glocal Healthcare<br /> Centre of Excellence
              </h1>
              <p class="mt-2 max-w-2xl text-lg leading-7 sm:text-xl sm:leading-8">
                Global Standards, Local Care.
              </p>
              <p class="mt-6 max-w-2xl text-base leading-7 sm:text-lg sm:leading-8">
                Founded by GS1 Kenya, GHCE is a model healthcare facility and innovation hub where patient care, diagnostics, pharmacy, and supply chains are strengthened by track-and-trace systems.
              </p>
              <div class="mt-8 flex flex-col gap-3 sm:flex-row">
                <a
                  href="/about"
                  class="inline-flex items-center justify-center rounded-md border border-[#cfd0fb] bg-[#cfd0fb] px-6 py-3 font-semibold no-underline shadow-sm hover:bg-white"
                >
                  Our Story
                  <svg
                    viewBox="0 0 24 24"
                    aria-hidden="true"
                    class="ml-2 h-5 w-5"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="2"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                  >
                    <path d="M7 17 17 7" />
                    <path d="M7 7h10v10" />
                  </svg>
                </a>
                <a
                  href="#appointment"
                  class="inline-flex items-center justify-center rounded-md border border-[#cfd0fb] bg-white px-6 py-3 font-semibold no-underline hover:bg-[#cfd0fb]"
                >
                  Book An Appointment
                </a>
              </div>
              <div class="mt-10 grid max-w-3xl gap-3 sm:grid-cols-2 lg:grid-cols-3">
                <div class="rounded-lg border border-[#cfd0fb] bg-white p-4">
                  <p class="text-2xl font-bold">1000+</p>
                  <p class="mt-1 text-sm">Patients Served</p>
                </div>
                <div class="rounded-lg border border-[#cfd0fb] bg-white p-4">
                  <p class="text-2xl font-bold">GS1 Standards</p>
                  <p class="mt-1 text-sm">Powered Traceability</p>
                </div>

                <div class="rounded-lg border border-[#cfd0fb] bg-white p-4">
                  <p class="text-2xl font-bold">20 +</p>
                  <p class="mt-1 text-sm">Services</p>
                </div>
              </div>
            </div>
            <div class="mx-auto flex w-full max-w-xl justify-center lg:col-span-5 lg:max-w-none lg:justify-end">
              <img
                src="/images/hero1.png"
                alt="Doctor consulting with a patient in a bright clinic"
                class="h-72 w-auto max-w-full object-contain object-bottom sm:h-96 lg:h-[36rem] xl:h-[40rem]"
              />
            </div>
          </div>
        </section>

        <section id="about" class="py-16 sm:py-20">
          <div class="mx-auto grid max-w-7xl gap-10 px-4 sm:px-6 lg:grid-cols-[0.9fr_1.1fr] lg:px-8">
            <div class="overflow-hidden rounded-lg">
              <img
                src="/images/public/african-hospital-exterior.png"
                alt="Modern East African hospital exterior with patients and staff"
                class="h-full min-h-[280px] w-full object-cover sm:min-h-[420px]"
                loading="lazy"
              />
            </div>
            <div class="flex flex-col justify-center">
              <p class="text-sm font-bold uppercase">About Us</p>
              <h2 class="mt-3 text-3xl font-bold leading-tight sm:text-4xl lg:text-5xl">
                A model hospital and innovation hub
              </h2>
              <p class="mt-5 text-base leading-7 sm:text-lg sm:leading-8">
                The Glocal Healthcare Centre of Excellence was purposefully designed at Mwalimu Park, Kisaju to show how global standards can transform last-mile healthcare delivery.
              </p>
              <p class="mt-4 text-base leading-7 sm:text-lg sm:leading-8">
                We integrate standards across patient care, diagnostics, pharmacy, and supply chain processes to improve accuracy, efficiency, and patient safety for the communities we serve.
              </p>
              <div class="mt-8 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
                <div class="rounded-lg bg-white p-5 shadow-sm">
                  <p class="text-3xl font-bold">GS1</p>
                  <p class="mt-1 text-sm">Kenya founded</p>
                </div>
                <div class="rounded-lg bg-white p-5 shadow-sm">
                  <p class="text-3xl font-bold">Level 3</p>
                  <p class="mt-1 text-sm">Hospital care</p>
                </div>
                <div class="rounded-lg bg-white p-5 shadow-sm">
                  <p class="text-3xl font-bold">Kisaju</p>
                  <p class="mt-1 text-sm">Nairobi-Namanga Road</p>
                </div>
              </div>
            </div>
          </div>
        </section>

        <section id="services" class="bg-white py-16 sm:py-20">
          <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            <div class="mx-auto max-w-3xl text-center">
              <h2 class="text-3xl font-bold leading-tight sm:text-4xl lg:text-5xl">
                Clinical services designed for the full care journey
              </h2>
              <p class="mt-4 text-base leading-7 sm:text-lg sm:leading-8">
                GHCE offers an integrated service portfolio that meets community health needs while demonstrating global standards in action.
              </p>
            </div>
            <div class="mt-12 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              <.service_card
                title="Outpatient Care"
                body="Daily consultations, procedures, and follow-up supported by digital identification and clear patient-flow systems."
              >
                <path d="M22 12h-4l-3 9L9 3l-3 9H2" />
              </.service_card>
              <.service_card
                title="Inpatient Care"
                body="Short-stay and extended-stay ward services with standardised patient identification and medication safety workflows."
              >
                <path d="M3 7h18" />
                <path d="M5 7v12a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V7" />
                <path d="M9 14h6" />
              </.service_card>
              <.service_card
                title="Emergency Services"
                body="24/7 emergency response, stabilisation, triage, and ambulance referral support when every minute matters."
              >
                <path d="M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.6l-1-1a5.5 5.5 0 0 0-7.8 7.8l1 1L12 21l7.8-7.6 1-1a5.5 5.5 0 0 0 0-7.8Z" />
              </.service_card>
              <.service_card
                title="Maternal & Child Health"
                body="Antenatal, delivery, postnatal, newborn, and immunisation support delivered with dignity and safe processes."
              >
                <circle cx="12" cy="8" r="4" />
                <path d="M4 21a8 8 0 0 1 16 0" />
              </.service_card>
              <.service_card
                title="Diagnostics"
                body="Laboratory, imaging, and point-of-care diagnostics with accurate reporting and sample traceability."
              >
                <path d="M8 3v18" />
                <path d="M16 3v18" />
                <path d="M3 8h18" />
                <path d="M3 16h18" />
              </.service_card>
              <.service_card
                title="Pharmacy"
                body="GS1-enabled medication management, safer dispensing, and counselling that supports adherence and confidence."
              >
                <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10Z" />
              </.service_card>
            </div>
          </div>
        </section>

        <section class="py-16 sm:py-20">
          <div class="mx-auto grid max-w-7xl gap-10 px-4 sm:px-6 lg:grid-cols-2 lg:px-8">
            <div>
              <img
                src="/images/public/african-diagnostic-care.png"
                alt="African nurse supporting a patient during diagnostic screening"
                class="h-full min-h-[280px] w-full rounded-lg object-cover sm:min-h-[420px]"
                loading="lazy"
              />
            </div>
            <div class="flex flex-col justify-center">
              <h2 class="text-3xl font-bold leading-tight sm:text-4xl lg:text-5xl">
                Why GHCE stands apart
              </h2>
              <p class="mt-4 text-base leading-7 sm:text-lg sm:leading-8">
                From identification to treatment, we bring together standards, technology, and clinical practice to deliver safer and more accountable healthcare.
              </p>
              <div class="mt-8 space-y-4">
                <div class="rounded-lg bg-white p-5 shadow-sm">
                  <h3 class="text-xl font-bold">Patient-centred quality care</h3>
                  <p class="mt-2 leading-7">
                    We provide safe, efficient outpatient and inpatient services built around dignity, clarity, and international-quality workflows.
                  </p>
                </div>
                <div class="rounded-lg bg-white p-5 shadow-sm">
                  <h3 class="text-xl font-bold">Traceability and medication safety</h3>
                  <p class="mt-2 leading-7">
                    GS1 identification and data standards improve medication accuracy, product visibility, and patient safety across the care pathway.
                  </p>
                </div>
                <div class="rounded-lg bg-white p-5 shadow-sm">
                  <h3 class="text-xl font-bold">Innovation and capacity building</h3>
                  <p class="mt-2 leading-7">
                    GHCE also serves as a live environment for training, pilot programmes, and interoperable digital health solutions.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </section>

        <section class="bg-gradient-to-b from-[#cfd0fb] via-[#e9ebff] to-white py-16 sm:py-20">
          <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            <div class="grid gap-10 lg:grid-cols-[0.85fr_1.15fr]">
              <div>
                <h2 class="text-3xl font-bold leading-tight sm:text-4xl lg:text-5xl">
                  Strategic objectives in action
                </h2>
                <p class="mt-4 text-base leading-7 sm:text-lg sm:leading-8">
                  Every service line is guided by practical goals that strengthen care quality, safety, and system accountability.
                </p>
              </div>
              <div class="grid gap-4 sm:grid-cols-2">
                <article class="rounded-lg bg-white p-6 shadow-sm">
                  <h3 class="text-xl font-bold">High-quality patient care</h3>
                  <p class="mt-3 leading-7">
                    Safe, efficient, and comprehensive clinical services that align with international standards.
                  </p>
                </article>
                <article class="rounded-lg bg-white p-6 shadow-sm">
                  <h3 class="text-xl font-bold">Traceability and safety</h3>
                  <p class="mt-3 leading-7">
                    Stronger medication accuracy and supply visibility through GS1 identification and data standards.
                  </p>
                </article>
                <article class="rounded-lg bg-white p-6 shadow-sm">
                  <h3 class="text-xl font-bold">Digital transformation</h3>
                  <p class="mt-3 leading-7">
                    Practical pilots and interoperable systems that help healthcare teams adopt future-ready workflows.
                  </p>
                </article>
                <article class="rounded-lg bg-white p-6 shadow-sm">
                  <h3 class="text-xl font-bold">Partnership and governance</h3>
                  <p class="mt-3 leading-7">
                    Collaboration with regulators, providers, academia, and industry to advance standards-driven healthcare.
                  </p>
                </article>
              </div>
            </div>
          </div>
        </section>

        <section class="bg-white py-16 sm:py-20">
          <div class="mx-auto grid max-w-7xl gap-10 px-4 sm:px-6 lg:grid-cols-2 lg:px-8">
            <div class="relative">
              <img
                src="/images/public/african-care-coordination.png"
                alt="African clinicians coordinating care with a patient in a modern consultation room"
                class="h-full min-h-[280px] w-full rounded-lg object-cover sm:min-h-[420px]"
                loading="lazy"
              />
              <div class="absolute bottom-4 left-4 right-4 rounded-lg bg-white p-4 shadow-xl sm:bottom-5 sm:left-5 sm:right-auto sm:w-72 sm:p-5">
                <div class="flex gap-3">
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
                    <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10Z" />
                  </svg>
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
                </div>
                <p class="mt-3 text-sm font-semibold">
                  Standards, diagnostics, and verified follow-up working as one care system.
                </p>
              </div>
            </div>
            <div class="flex flex-col justify-center">
              <h2 class="text-3xl font-bold leading-tight sm:text-4xl lg:text-5xl">
                Healthcare standards and innovation functions
              </h2>
              <p class="mt-4 text-base leading-7 sm:text-lg sm:leading-8">
                Beyond clinical care, GHCE serves as a national hub for healthcare innovation and standards adoption.
              </p>
              <div class="mt-8 grid gap-4 sm:grid-cols-2">
                <div class="rounded-lg border border-[#cfd0fb] p-6">
                  <div class="mb-4 flex h-11 w-11 items-center justify-center rounded-lg bg-[#cfd0fb]">
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
                      <circle cx="12" cy="12" r="10" />
                      <path d="M8 12h8" />
                      <path d="M12 8v8" />
                    </svg>
                  </div>
                  <h3 class="text-xl font-bold">GS1 standards training</h3>
                  <p class="mt-3 leading-7">
                    Practical training for healthcare professionals, administrators, manufacturers, and supply chain teams.
                  </p>
                </div>
                <div class="rounded-lg border border-[#cfd0fb] p-6">
                  <div class="mb-4 flex h-11 w-11 items-center justify-center rounded-lg bg-[#cfd0fb]">
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
                      <rect x="3" y="4" width="18" height="14" rx="2" />
                      <path d="M8 21h8" />
                      <path d="M12 18v3" />
                    </svg>
                  </div>
                  <h3 class="text-xl font-bold">Technology pilot testing</h3>
                  <p class="mt-3 leading-7">
                    A controlled environment for evaluating digital health, clinical, and supply chain solutions before scale-up.
                  </p>
                </div>
                <div class="rounded-lg border border-[#cfd0fb] p-6">
                  <div class="mb-4 flex h-11 w-11 items-center justify-center rounded-lg bg-[#cfd0fb]">
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
                      <path d="M4 7h16" />
                      <path d="M7 4v6" />
                      <path d="M17 4v6" />
                      <rect x="4" y="7" width="16" height="13" rx="2" />
                    </svg>
                  </div>
                  <h3 class="text-xl font-bold">UDI and pharma traceability</h3>
                  <p class="mt-3 leading-7">
                    Support for end-to-end tracking of medical devices and medicines from manufacturer to patient.
                  </p>
                </div>
                <div class="rounded-lg border border-[#cfd0fb] p-6">
                  <div class="mb-4 flex h-11 w-11 items-center justify-center rounded-lg bg-[#cfd0fb]">
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
                      <path d="M8 10h8" />
                      <path d="M8 14h5" />
                      <rect x="4" y="4" width="16" height="16" rx="2" />
                    </svg>
                  </div>
                  <h3 class="text-xl font-bold">Workshops and ecosystem forums</h3>
                  <p class="mt-3 leading-7">
                    Multi-sector sessions that bring together regulators, providers, industry, and partners around best practices.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </section>

        <section id="faq" class="py-16 sm:py-20">
          <div class="mx-auto grid max-w-7xl gap-10 px-4 sm:px-6 lg:grid-cols-[0.8fr_1.2fr] lg:px-8">
            <div>
              <h2 class="text-3xl font-bold leading-tight sm:text-4xl lg:text-5xl">
                Frequently asked questions
              </h2>
              <p class="mt-4 text-base leading-7 sm:text-lg sm:leading-8">
                A few quick answers about services, emergencies, and what makes the Centre different.
              </p>
            </div>
            <div class="space-y-3">
              <.faq_item question="How do I book an appointment?" open>
                You can book through our online appointment form, by phone, or by visiting reception at Mwalimu Park, Kisaju.
              </.faq_item>
              <.faq_item question="Do you offer emergency services?">
                Yes. Our team is available 24/7 to guide urgent cases and route patients to the right clinician quickly.
              </.faq_item>
              <.faq_item question="What makes GHCE different from a typical facility?">
                GHCE combines clinical care with GS1 standards, digital identification, and traceability workflows that improve safety, accuracy, and accountability.
              </.faq_item>
              <.faq_item question="Do you support training and demonstration visits?">
                Yes. The Centre also operates as a live demonstration site for stakeholders who want to experience standards-driven healthcare systems in practice.
              </.faq_item>
              <.faq_item question="Which services can I access at GHCE?">
                We provide outpatient, inpatient, emergency, maternal and child health, diagnostics, pharmacy, and preventive community health services.
              </.faq_item>
            </div>
          </div>
        </section>

        <section :if={@recent_blog_posts != []} class="bg-white py-16 sm:py-20">
          <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            <div class="mx-auto max-w-3xl text-center">
              <h2 class="text-3xl font-bold leading-tight sm:text-4xl lg:text-5xl">
                Our health blogs &amp; insights
              </h2>
              <p class="mt-4 text-base leading-7 sm:text-lg sm:leading-8">
                From consultation to recovery, we're here to support every step of your health journey.
              </p>
            </div>
            <div class="mt-12 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
              <a
                :for={post <- @recent_blog_posts}
                href={"/post/#{post.slug}"}
                class="group overflow-hidden rounded-lg border border-[#cfd0fb] bg-white no-underline"
              >
                <img
                  :if={post.hero_image_url}
                  src={post.hero_image_url}
                  alt={post.hero_image_alt || post.title}
                  class="h-64 w-full object-cover transition group-hover:scale-[1.03]"
                  loading="lazy"
                />
                <div class="p-5">
                  <p class="text-sm font-semibold">{published_label(post)}</p>
                  <h3 class="mt-3 text-xl font-bold leading-snug group-hover:opacity-80">
                    {post.title}
                  </h3>
                </div>
              </a>
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
                Reach us for appointments, referrals, diagnostics, or a guided visit to the Centre of Excellence.
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
            <.appointment_form booking_form={@booking_form} booking_feedback={@booking_feedback} />
          </div>
        </section>
      </main>

      <.public_footer current_page={:home} />

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

  attr :title, :string, required: true
  attr :body, :string, required: true
  slot :inner_block, required: true

  defp service_card(assigns) do
    ~H"""
    <article class="rounded-lg border border-[#cfd0fb] p-6">
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
          {render_slot(@inner_block)}
        </svg>
      </div>
      <h3 class="text-xl font-bold">{@title}</h3>
      <p class="mt-3 leading-7">{@body}</p>
    </article>
    """
  end

  attr :question, :string, required: true
  attr :open, :boolean, default: false
  slot :inner_block, required: true

  defp faq_item(assigns) do
    ~H"""
    <details class="group rounded-lg bg-white p-5 shadow-sm" open={@open}>
      <summary class="flex cursor-pointer list-none items-center justify-between gap-4 text-lg font-bold">
        {@question}
        <span class="transition-transform group-open:rotate-45">
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
            <path d="M12 5v14" />
            <path d="M5 12h14" />
          </svg>
        </span>
      </summary>
      <p class="mt-4 leading-7">{render_slot(@inner_block)}</p>
    </details>
    """
  end

  attr :booking_form, :any, required: true
  attr :booking_feedback, :map, default: nil

  defp appointment_form(assigns) do
    ~H"""
    <.form
      for={@booking_form}
      phx-submit="book_appointment"
      class="rounded-lg bg-white p-5 shadow-sm sm:p-8"
    >
      <div
        :if={@booking_feedback}
        class={[
          "mb-5 rounded-md border px-4 py-3 text-sm",
          @booking_feedback.type == :success &&
            "border-emerald-200 bg-emerald-50 text-emerald-800",
          @booking_feedback.type == :error && "border-red-200 bg-red-50 text-red-700"
        ]}
      >
        {@booking_feedback.message}
      </div>

      <div class="grid gap-5 sm:grid-cols-2">
        <label class="block">
          <span class="text-sm font-semibold">First Name</span>
          <input
            required
            id={@booking_form[:first_name].id}
            name={@booking_form[:first_name].name}
            type="text"
            value={@booking_form[:first_name].value}
            placeholder="First Name"
            class="mt-2 w-full rounded-md border border-[#cfd0fb] px-4 py-3 outline-none focus:border-[#cfd0fb]"
          />
          <p :for={error <- @booking_form[:first_name].errors} class="mt-2 text-sm text-red-600">
            {translate_error(error)}
          </p>
        </label>
        <label class="block">
          <span class="text-sm font-semibold">Last Name</span>
          <input
            required
            id={@booking_form[:last_name].id}
            name={@booking_form[:last_name].name}
            type="text"
            value={@booking_form[:last_name].value}
            placeholder="Last Name"
            class="mt-2 w-full rounded-md border border-[#cfd0fb] px-4 py-3 outline-none focus:border-[#cfd0fb]"
          />
          <p :for={error <- @booking_form[:last_name].errors} class="mt-2 text-sm text-red-600">
            {translate_error(error)}
          </p>
        </label>
        <label class="block">
          <span class="text-sm font-semibold">Email Address</span>
          <input
            required
            id={@booking_form[:email].id}
            name={@booking_form[:email].name}
            type="email"
            value={@booking_form[:email].value}
            placeholder="Enter your email"
            class="mt-2 w-full rounded-md border border-[#cfd0fb] px-4 py-3 outline-none focus:border-[#cfd0fb]"
          />
          <p :for={error <- @booking_form[:email].errors} class="mt-2 text-sm text-red-600">
            {translate_error(error)}
          </p>
        </label>
        <label class="block">
          <span class="text-sm font-semibold">Phone Number</span>
          <input
            required
            id={@booking_form[:phone_number].id}
            name={@booking_form[:phone_number].name}
            type="tel"
            value={@booking_form[:phone_number].value}
            placeholder="+254 7XX XXX XXX"
            class="mt-2 w-full rounded-md border border-[#cfd0fb] px-4 py-3 outline-none focus:border-[#cfd0fb]"
          />
          <p :for={error <- @booking_form[:phone_number].errors} class="mt-2 text-sm text-red-600">
            {translate_error(error)}
          </p>
        </label>
        <label class="block">
          <span class="text-sm font-semibold">Service Type</span>
          <select
            required
            id={@booking_form[:service].id}
            name={@booking_form[:service].name}
            class="mt-2 w-full rounded-md border border-[#cfd0fb] bg-white px-4 py-3 outline-none focus:border-[#cfd0fb]"
          >
            <option value="">Personalized Care</option>
            <option
              :for={{label, value} <- PublicBooking.service_options()}
              value={value}
              selected={@booking_form[:service].value == value}
            >
              {label}
            </option>
          </select>
          <p :for={error <- @booking_form[:service].errors} class="mt-2 text-sm text-red-600">
            {translate_error(error)}
          </p>
        </label>
        <label class="block">
          <span class="text-sm font-semibold">Preferred Date</span>
          <input
            required
            id={@booking_form[:date].id}
            name={@booking_form[:date].name}
            type="date"
            value={@booking_form[:date].value}
            class="mt-2 w-full rounded-md border border-[#cfd0fb] px-4 py-3 outline-none focus:border-[#cfd0fb]"
          />
          <p :for={error <- @booking_form[:date].errors} class="mt-2 text-sm text-red-600">
            {translate_error(error)}
          </p>
        </label>
        <label class="block">
          <span class="text-sm font-semibold">Preferred Time</span>
          <input
            id={@booking_form[:time].id}
            name={@booking_form[:time].name}
            type="time"
            value={@booking_form[:time].value}
            class="mt-2 w-full rounded-md border border-[#cfd0fb] px-4 py-3 outline-none focus:border-[#cfd0fb]"
          />
        </label>
      </div>
      <label class="mt-5 block">
        <span class="text-sm font-semibold">Message</span>
        <textarea
          required
          id={@booking_form[:message].id}
          name={@booking_form[:message].name}
          rows="5"
          placeholder="Write your message..."
          class="mt-2 w-full resize-none rounded-md border border-[#cfd0fb] px-4 py-3 outline-none focus:border-[#cfd0fb]"
        >{Phoenix.HTML.Form.normalize_value("textarea", @booking_form[:message].value)}</textarea>
        <p :for={error <- @booking_form[:message].errors} class="mt-2 text-sm text-red-600">
          {translate_error(error)}
        </p>
      </label>
      <button
        type="submit"
        class="mt-6 inline-flex w-full items-center justify-center rounded-md border border-[#cfd0fb] bg-[#cfd0fb] px-6 py-3 font-semibold shadow-sm hover:bg-white sm:w-auto"
      >
        Book Appointment
      </button>
    </.form>
    """
  end

  defp published_label(post) do
    Blogs.format_published_at(post.published_at) || "Coming Soon"
  end

  defp assign_booking_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :booking_form, to_form(changeset, as: :booking))
  end
end
