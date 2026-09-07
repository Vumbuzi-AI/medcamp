defmodule MedcampWeb.Website.AboutLive do
  use Phoenix.LiveView, layout: false
  import MedcampWeb.PublicSiteComponents

  @page_title "About | GHCE — Quality Care at Kisaju"
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
      <.public_navbar current_page={:about} />
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
              <p class="text-sm font-bold uppercase tracking-wide">About GHCE</p>
              <h1 class="mt-4 max-w-3xl text-4xl font-bold leading-[1.04] sm:text-5xl lg:text-6xl">
                A centre of excellence for safer healthcare.
              </h1>
              <p class="mt-6 max-w-2xl text-base leading-7 sm:text-lg sm:leading-8">
                Founded by GS1 Kenya, GHCE is a fully operational Level 3 hospital and innovation hub demonstrating how standards-driven systems can transform care delivery.
              </p>
              <div class="mt-8 flex flex-col gap-3 sm:flex-row">
                <a
                  href="#story"
                  class="inline-flex items-center justify-center rounded-md border border-[#cfd0fb] bg-[#cfd0fb] px-6 py-3 font-semibold no-underline shadow-sm hover:bg-white"
                >
                  Our Story
                </a>
                <a
                  href="/contact"
                  class="inline-flex items-center justify-center rounded-md border border-[#cfd0fb] bg-white px-6 py-3 font-semibold no-underline hover:bg-[#cfd0fb]"
                >
                  Book Appointment
                </a>
              </div>
            </div>
            <div class="relative min-h-[280px] sm:min-h-[360px]">
              <img
                src="/images/public/african-hospital-exterior.png"
                alt="Modern East African hospital exterior with patients and staff"
                class="h-full min-h-[280px] w-full rounded-lg object-cover shadow-2xl sm:min-h-[360px]"
              />
              <div class="absolute bottom-4 left-4 right-4 rounded-lg bg-white p-4 shadow-xl backdrop-blur sm:bottom-5 sm:left-auto sm:right-5 sm:w-80 sm:p-5">
                <p class="text-sm font-semibold uppercase">Model hospital</p>
                <p class="mt-2 text-xl font-bold sm:text-2xl">
                  Where global standards meet local care in practice
                </p>
              </div>
            </div>
          </div>
        </section>

        <section id="story" class="py-16 sm:py-20">
          <div class="mx-auto grid max-w-7xl gap-10 px-4 sm:px-6 lg:grid-cols-[0.9fr_1.1fr] lg:px-8">
            <div class="overflow-hidden rounded-lg">
              <img
                src="/images/public/african-surgical-team.png"
                alt="African surgical team working together in a modern operating theatre"
                class="h-full min-h-[280px] w-full object-cover sm:min-h-[420px]"
                loading="lazy"
              />
            </div>
            <div class="flex flex-col justify-center">
              <p class="text-sm font-bold uppercase tracking-wide">Who We Are</p>
              <h2 class="mt-3 text-3xl font-bold leading-tight sm:text-4xl lg:text-5xl">
                Built to show how standards improve care.
              </h2>
              <p class="mt-5 text-base leading-7 sm:text-lg sm:leading-8">
                The Glocal Healthcare Centre of Excellence was purposefully designed at Mwalimu Park, Kisaju along the Nairobi-Namanga Road to demonstrate how track-and-trace systems can strengthen last-mile healthcare delivery.
              </p>
              <p class="mt-4 text-base leading-7 sm:text-lg sm:leading-8">
                We integrate global standards across patient care, diagnostics, pharmacy, and supply chain processes so accuracy, efficiency, and patient safety improve together.
              </p>
              <div class="mt-8 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
                <div class="rounded-lg bg-white p-5 shadow-sm">
                  <p class="text-3xl font-bold">GS1</p>
                  <p class="mt-1 text-sm">Kenya founded</p>
                </div>
                <div class="rounded-lg bg-white p-5 shadow-sm">
                  <p class="text-3xl font-bold">Level 3</p>
                  <p class="mt-1 text-sm">Referral-ready hospital</p>
                </div>
                <div class="rounded-lg bg-white p-5 shadow-sm">
                  <p class="text-3xl font-bold">Live</p>
                  <p class="mt-1 text-sm">Innovation site</p>
                </div>
              </div>
            </div>
          </div>
        </section>

        <section id="vision" class="bg-white py-16 sm:py-20">
          <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            <div class="grid gap-10 lg:grid-cols-[0.75fr_1.25fr]">
              <div>
                <p class="text-sm font-bold uppercase tracking-wide">
                  Vision &amp; Mission
                </p>
                <h2 class="mt-3 text-3xl font-bold leading-tight sm:text-4xl lg:text-5xl">
                  The principles shaping every service line.
                </h2>
                <p class="mt-5 text-base leading-7 sm:text-lg sm:leading-8">
                  GHCE exists to deliver trusted care today while building a stronger standards-driven health ecosystem for tomorrow.
                </p>
              </div>
              <div class="grid gap-4 md:grid-cols-3">
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
                      <path d="M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.6l-1-1a5.5 5.5 0 0 0-7.8 7.8l1 1L12 21l7.8-7.6 1-1a5.5 5.5 0 0 0 0-7.8Z" />
                    </svg>
                  </div>
                  <h3 class="text-xl font-bold">Vision</h3>
                  <p class="mt-3 leading-7">
                    To be a referral centre of excellence in GS1 Healthcare standards for patient safety, traceability, and data management.
                  </p>
                </article>
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
                      <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10Z" />
                      <path d="m9 12 2 2 4-4" />
                    </svg>
                  </div>
                  <h3 class="text-xl font-bold">Mission</h3>
                  <p class="mt-3 leading-7">
                    To discharge affordable, reliable, and trusted quality healthcare services through global healthcare standards with localized care and GS1 training.
                  </p>
                </article>
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
                      <rect x="3" y="4" width="18" height="14" rx="2" />
                      <path d="M8 21h8" />
                      <path d="M12 18v3" />
                    </svg>
                  </div>
                  <h3 class="text-xl font-bold">Core Values</h3>
                  <p class="mt-3 leading-7">
                    Patient safety, integrity, accuracy, innovation, collaboration, excellence, and learning guide how we care, teach, and build partnerships.
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
                Contact us for care, referrals, training inquiries, or a visit to experience standards-driven healthcare in action.
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
            <form action="#" method="get" class="rounded-lg bg-white p-5 shadow-sm sm:p-8">
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

      <.public_footer current_page={:about} />

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
end
