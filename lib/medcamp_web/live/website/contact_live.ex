defmodule MedcampWeb.Website.ContactLive do
  use Phoenix.LiveView, layout: false
  import MedcampWeb.PublicSiteComponents

  @page_title "Contact | GHCE — Quality Care at Kisaju"
  @body_class "bg-gradient-to-b from-[#cfd0fb] via-[#e9ebff] to-white antialiased"

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, @page_title)
     |> assign(:body_class, @body_class)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="top" class={["min-h-screen", public_page_background_class()]}>
      <.public_navbar current_page={:contact} />
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
              <p class="text-sm font-bold uppercase tracking-wide">Contact GHCE</p>
              <h1 class="mt-4 text-4xl font-bold leading-[1.04] sm:text-5xl lg:text-6xl">
                Contact Us
              </h1>
              <p class="mt-6 max-w-2xl text-base leading-7 sm:text-lg sm:leading-8">
                Reach out for appointments, referrals, diagnostics, training inquiries, or partnership visits to the Centre of Excellence.
              </p>
              <div class="mt-8 flex flex-col gap-3 sm:flex-row sm:flex-wrap">
                <a
                  href="#appointment"
                  class="inline-flex items-center justify-center rounded-md border border-[#cfd0fb] bg-[#cfd0fb] px-6 py-3 font-semibold no-underline shadow-sm hover:bg-white"
                >
                  Book Appointment
                </a>
                <a
                  :for={phone <- public_phone_contacts()}
                  href={phone.href}
                  class="inline-flex items-center justify-center rounded-md border border-[#cfd0fb] bg-white px-4 py-3 text-center font-semibold no-underline hover:bg-[#cfd0fb] sm:px-6"
                >
                  {phone.display}
                </a>
              </div>
            </div>
            <div class="relative min-h-[280px] sm:min-h-[360px]">
              <img
                src="/images/public/african-hospital-reception.png"
                alt="African hospital reception team assisting a patient"
                class="h-full min-h-[280px] w-full rounded-lg object-cover shadow-2xl sm:min-h-[360px]"
              />
              <div class="absolute bottom-4 left-4 right-4 rounded-lg bg-white p-4 shadow-xl backdrop-blur sm:bottom-5 sm:left-auto sm:right-5 sm:w-80 sm:p-5">
                <p class="text-sm font-semibold uppercase">Here to help</p>
                <p class="mt-2 text-xl font-bold sm:text-2xl">
                  Support for care bookings, urgent routing, and demonstration visits
                </p>
              </div>
            </div>
          </div>
        </section>

        <section id="appointment" class="py-16 sm:py-20">
          <div class="mx-auto grid max-w-7xl gap-8 px-4 sm:px-6 lg:grid-cols-[1.1fr_0.9fr] lg:px-8">
            <form
              action="#"
              method="get"
              class="rounded-lg border border-[#cfd0fb] bg-white p-5 shadow-sm sm:p-8"
            >
              <div class="mb-8">
                <h2 class="text-3xl font-bold leading-tight sm:text-4xl lg:text-5xl">
                  Book care or request a visit
                </h2>
                <p class="mt-4 text-base leading-7 sm:text-lg sm:leading-8">
                  Use this form for outpatient bookings, maternal visits, diagnostics, referrals, or stakeholder visits to the hospital and innovation hub.
                </p>
              </div>
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
                    <option value="outpatient">Outpatient</option>
                    <option value="emergency">Emergency</option>
                    <option value="maternal">Maternal &amp; Child</option>
                    <option value="diagnostics">Diagnostics</option>
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
                  placeholder="Tell us about your visit, question, or request"
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

            <div class="grid gap-4">
              <article class="rounded-lg border border-[#cfd0fb] bg-white p-6 shadow-sm">
                <div class="mb-4 flex h-12 w-12 items-center justify-center rounded-lg bg-[#cfd0fb]">
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
                    <path d="M20 10c0 6-8 12-8 12S4 16 4 10a8 8 0 1 1 16 0Z" />
                    <circle cx="12" cy="10" r="3" />
                  </svg>
                </div>
                <h3 class="text-xl font-bold">Address</h3>
                <p class="mt-3 leading-7">
                  Mwalimu Park, Kisaju<br />Along Nairobi–Namanga Road
                </p>
              </article>
              <article class="rounded-lg border border-[#cfd0fb] bg-white p-6 shadow-sm">
                <div class="mb-4 flex h-12 w-12 items-center justify-center rounded-lg bg-[#cfd0fb]">
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
                    <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.8 19.8 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6A19.8 19.8 0 0 1 2.1 4.18 2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72c.13.96.35 1.9.66 2.81a2 2 0 0 1-.45 2.11L8.05 9.91a16 16 0 0 0 6.04 6.04l1.27-1.27a2 2 0 0 1 2.11-.45c.91.31 1.85.53 2.81.66A2 2 0 0 1 22 16.92Z" />
                  </svg>
                </div>
                <h3 class="text-xl font-bold">Phone Numbers</h3>
                <a
                  :for={{phone, index} <- Enum.with_index(public_phone_contacts())}
                  href={phone.href}
                  class={[
                    "block break-words font-semibold no-underline hover:opacity-80",
                    index == 0 && "mt-3",
                    index > 0 && "mt-1"
                  ]}
                >
                  {phone.display}
                </a>
              </article>
              <article class="rounded-lg border border-[#cfd0fb] bg-white p-6 shadow-sm">
                <div class="mb-4 flex h-12 w-12 items-center justify-center rounded-lg bg-[#cfd0fb]">
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
                    <path d="M12 6v6l4 2" />
                  </svg>
                </div>
                <h3 class="text-xl font-bold">Opening Hours</h3>
                <p class="mt-3 leading-7">Emergency services: 24/7</p>
                <p class="leading-7">Outpatient and diagnostics: daily consultations</p>
              </article>
              <article class="rounded-lg border border-[#cfd0fb] bg-white p-6 shadow-sm">
                <div class="mb-4 flex h-12 w-12 items-center justify-center rounded-lg bg-[#cfd0fb]">
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
                    <path d="m4 4 16 0a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2Z" />
                    <path d="m22 6-10 7L2 6" />
                  </svg>
                </div>
                <h3 class="text-xl font-bold">Email</h3>
                <a
                  href="mailto:info@glocalhealthcentre.org"
                  class="mt-3 block break-words font-semibold no-underline hover:opacity-80"
                >
                  info@glocalhealthcentre.org
                </a>
              </article>
              <article class="overflow-hidden rounded-lg border border-[#cfd0fb] bg-white shadow-sm">
                <div class="p-6">
                  <div class="mb-4 flex h-12 w-12 items-center justify-center rounded-lg bg-[#cfd0fb]">
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
                      <path d="M20 10c0 6-8 12-8 12S4 16 4 10a8 8 0 1 1 16 0Z" />
                      <circle cx="12" cy="10" r="3" />
                    </svg>
                  </div>
                  <h3 class="text-xl font-bold">Find us on the map</h3>
                  <p class="mt-3 leading-7">
                    Visit us at Mwalimu Park, Kisaju, along Nairobi-Namanga Road.
                  </p>
                </div>
                <iframe
                  title="Map showing Mwalimu Park in Kisaju"
                  src="https://www.google.com/maps?q=Mwalimu+Park,+Kisaju,+along+Nairobi-Namanga+Road&z=15&output=embed"
                  class="h-72 w-full border-0"
                  loading="lazy"
                  referrerpolicy="no-referrer-when-downgrade"
                >
                </iframe>
                <div class="border-t border-[#cfd0fb] p-6">
                  <a
                    href="https://maps.google.com/?q=Mwalimu+Park+Kisaju"
                    target="_blank"
                    rel="noreferrer"
                    class="inline-flex items-center justify-center rounded-md border border-[#cfd0fb] bg-[#f5f0ff] px-5 py-3 font-semibold no-underline transition hover:bg-[#e9ddff]"
                  >
                    Open in Google Maps
                  </a>
                </div>
              </article>
            </div>
          </div>
        </section>

        <section class="bg-white py-16 sm:py-20">
          <div class="mx-auto grid max-w-7xl gap-10 px-4 sm:px-6 lg:grid-cols-[0.8fr_1.2fr] lg:px-8">
            <div>
              <h2 class="text-3xl font-bold leading-tight sm:text-4xl lg:text-5xl">
                Frequently asked questions
              </h2>
              <p class="mt-4 text-base leading-7 sm:text-lg sm:leading-8">
                Quick answers about services, emergencies, and arranging a visit to GHCE.
              </p>
            </div>
            <div class="space-y-3">
              <.faq question="How do I book an appointment?" open>
                Use the form on this page, call us directly, or visit reception at Mwalimu Park, Kisaju — our care team will help schedule the right appointment.
              </.faq>
              <.faq question="Do you offer emergency services?">
                Yes. Emergency support is available 24 hours, and our team can route urgent cases to the appropriate clinician.
              </.faq>
              <.faq question="Which services can I book through GHCE?">
                You can contact us for outpatient, inpatient, maternal and child health, diagnostics, pharmacy, preventive care, and emergency triage support.
              </.faq>
              <.faq question="Can organisations visit the Centre of Excellence?">
                Yes. GHCE also serves as a live demonstration site for stakeholders interested in healthcare traceability, GS1 standards, and digital health workflows.
              </.faq>
              <.faq question="Do you support training on GS1 healthcare standards?">
                Yes. The Centre supports training, workshops, and capacity building for healthcare providers, administrators, manufacturers, and supply chain partners.
              </.faq>
            </div>
          </div>
        </section>
      </main>

      <.public_footer current_page={:contact} />

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

  attr :question, :string, required: true
  attr :open, :boolean, default: false
  slot :inner_block, required: true

  defp faq(assigns) do
    ~H"""
    <details
      class={["group rounded-lg p-5 shadow-sm", public_surface_background_class()]}
      open={@open}
    >
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
end
