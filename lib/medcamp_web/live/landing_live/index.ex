defmodule MedcampWeb.LandingLive.Index do
  use MedcampWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, active_tab: "consulting")}
  end

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <body class="public-site font-sans relative text-gray-800 bg-white">
      <.public_navbar current_page={:home} />

      <%!-- Hero Section --%>
      <section
        class="relative overflow-hidden min-h-[640px] md:min-h-[700px]"
        style="background: linear-gradient(160deg, rgba(247,247,255,0.92) 0%, rgba(236,237,255,0.84) 42%, rgba(210,211,255,0.78) 100%);"
      >
        <%!-- Decorative sparkles --%>
        <div class="absolute top-24 left-[15%] w-2 h-2 bg-[#d2d3ff] rounded-full opacity-60"></div>
        <div class="absolute top-32 left-[25%] w-1.5 h-1.5 bg-[#e6e7ff] rounded-full opacity-40">
        </div>
        <div class="absolute top-20 right-[30%] w-2.5 h-2.5 bg-[#d2d3ff] rounded-full opacity-50">
        </div>
        <div class="absolute top-40 right-[15%] w-1.5 h-1.5 bg-[#ececff] rounded-full opacity-60">
        </div>
        <div class="absolute top-16 right-[25%]">
          <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
            <path
              d="M8 0L9.5 6.5L16 8L9.5 9.5L8 16L6.5 9.5L0 8L6.5 6.5L8 0Z"
              fill="#d2d3ff"
              opacity="0.5"
            />
          </svg>
        </div>
        <div class="absolute top-48 left-[10%]">
          <svg width="12" height="12" viewBox="0 0 16 16" fill="none">
            <path
              d="M8 0L9.5 6.5L16 8L9.5 9.5L8 16L6.5 9.5L0 8L6.5 6.5L8 0Z"
              fill="#e6e7ff"
              opacity="0.4"
            />
          </svg>
        </div>
        <div class="absolute bottom-48 right-[40%]">
          <svg width="14" height="14" viewBox="0 0 16 16" fill="none">
            <path
              d="M8 0L9.5 6.5L16 8L9.5 9.5L8 16L6.5 9.5L0 8L6.5 6.5L8 0Z"
              fill="#d2d3ff"
              opacity="0.35"
            />
          </svg>
        </div>

        <div class="w-[90%] mx-auto pt-32 md:pt-40 pb-12 px-4 lg:px-8 flex flex-col md:flex-row items-start gap-12 md:gap-0 relative z-10">
          <%!-- Left Content --%>
          <div class="md:w-1/2 md:pr-8 pt-4 text-center md:text-left flex flex-col items-center md:items-start">
            <h1 class="text-[32px] sm:text-[40px] md:text-[48px] lg:text-[54px] font-bold text-gray-900 leading-[1.1] mb-5 tracking-tight">
              Glocal Health Center of Excellence<br />Global Standards, Local Care
            </h1>
            <p class="text-gray-400 text-[15px] mb-8 max-w-md leading-relaxed">
              At GHCE, every patient, medicine, diagnostic sample, and clinical process is connected through globally trusted GS1 standards. This ensures safer care, reduces errors, strengthens accountability, and enables smarter healthcare supply chains.
            </p>

            <%!-- CTA Buttons --%>
            <div class="flex flex-col sm:flex-row items-center gap-4 mb-12 w-full sm:w-auto">
              <a
                href="#standards"
                class="inline-flex w-full sm:w-auto justify-center items-center bg-white text-gray-900 pl-3 pr-6 py-3 rounded-full text-sm font-semibold shadow-md hover:shadow-lg transition-all space-x-2.5 border border-gray-100"
              >
                <div class="w-8 h-8 bg-[#d2d3ff] rounded-full flex items-center justify-center">
                  <svg
                    class="w-4 h-4 text-gray-900"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M9 5l7 7-7 7"
                    />
                  </svg>
                </div>
                <span>Explore GS1 Standards</span>
              </a>
              <a
                href="#about"
                class="text-sm font-semibold text-gray-700 hover:text-gray-900 transition-colors"
              >
                About Us
              </a>
            </div>

            <%!-- Stats Row --%>
            <div class="hidden md:flex flex-col pb-4 divide-y divide-gray-100 border bg-white border-gray-100 rounded-2xl overflow-hidden max-w-md">
              <div class="bg-white px-6 py-5 flex flex-col sm:flex-row items-start sm:items-center gap-3 sm:gap-5 text-left">
                <div class="text-[28px] sm:text-[32px] font-bold text-gray-900 leading-none sm:whitespace-nowrap">
                  Level 3
                </div>
                <p class="text-xs text-gray-400 leading-relaxed max-w-[200px]">
                  Hospital care with standards-led clinical delivery and patient safety at the center
                </p>
              </div>

              <div class=" px-6 py-4 flex flex-col sm:flex-row items-start rounded-b-3xl sm:items-center gap-4 text-left">
                <div class="flex -space-x-3">
                  <img
                    src="/images/people/1.jpg"
                    alt="Clinical care team"
                    class="h-10 w-10 object-cover rounded-full border-[2px] border-white bg-white"
                  />
                  <img
                    src="/images/people/2.jpg"
                    alt="Clinical care team"
                    class="h-10 w-10 object-cover rounded-full border-[2px] border-white bg-white"
                  />
                  <img
                    src="/images/people/3.jpg"
                    alt="Clinical care team"
                    class="h-10 w-10 object-cover rounded-full border-[2px] border-white bg-white"
                  />
                </div>
                <span class="text-xs text-gray-400">
                  Trusted clinical services. Intelligent supply chains.
                </span>
              </div>
            </div>
          </div>

          <%!-- Right Content: Doctor Image --%>
          <div class="md:w-1/2 relative flex flex-col items-center justify-end mt-2 md:mt-0 w-full pb-[190px] md:pb-0">
            <%!-- Decorative 3D spheres --%>
            <div
              class="absolute -left-4 bottom-32 w-16 h-16 rounded-full opacity-60 z-0"
              style="background: radial-gradient(circle at 35% 35%, #fff, #ececff, #d2d3ff);"
            >
            </div>
            <div
              class="absolute -left-8 bottom-20 w-8 h-8 rounded-full opacity-50 z-0"
              style="background: radial-gradient(circle at 35% 35%, #fff, #f4f5ff, #e6e7ff);"
            >
            </div>
            <div
              class="absolute left-4 bottom-12 w-5 h-5 rounded-full opacity-40 z-0"
              style="background: radial-gradient(circle at 35% 35%, #fff, #f1f2ff, #d2d3ff);"
            >
            </div>

            <img
              src="/images/hero1.png"
              alt="Doctor"
              class="relative z-10 w-full h-[340px] sm:h-[460px] md:h-[600px] max-w-lg object-contain"
            />

            <%!-- Floating Card: Care Signals --%>
            <div
              class="absolute bottom-0 left-1/2 z-20 w-[88%] max-w-[320px] -translate-x-1/2 rounded-[24px] border border-white/80 bg-white/95 p-4 shadow-[0_18px_45px_rgba(31,41,55,0.14)] backdrop-blur-sm md:bottom-14 md:left-0 md:w-[220px] md:max-w-[220px] md:translate-x-0"
              style="background: linear-gradient(180deg, rgba(255,255,255,0.98) 0%, rgba(243,247,255,0.96) 100%);"
            >
              <div class="flex items-start justify-between gap-3 mb-3">
                <div>
                  <p class="text-[10px] font-semibold uppercase tracking-[0.18em] text-[#8d90d6]">
                    Care Signals
                  </p>
                  <h3 class="text-[15px] font-bold text-gray-900 leading-tight mt-1">
                    Built for safer hospital flow
                  </h3>
                </div>
                <span class="rounded-full bg-emerald-50 px-2 py-1 text-[10px] font-semibold text-emerald-700">
                  Live
                </span>
              </div>

              <div class="space-y-2.5">
                <div class="flex items-start gap-2.5 rounded-2xl bg-[#f6f7ff] px-3 py-2.5">
                  <div class="mt-0.5 h-2.5 w-2.5 rounded-full bg-[#d2d3ff]"></div>
                  <div>
                    <p class="text-[11px] font-semibold text-gray-900 leading-none">
                      Patient identification
                    </p>
                    <p class="mt-1 text-[10px] leading-relaxed text-gray-500">
                      Standards-led registration and continuity of care.
                    </p>
                  </div>
                </div>

                <div class="flex items-start gap-2.5 rounded-2xl bg-[#f8fafc] px-3 py-2.5">
                  <div class="mt-0.5 h-2.5 w-2.5 rounded-full bg-emerald-500"></div>
                  <div>
                    <p class="text-[11px] font-semibold text-gray-900 leading-none">24/7 readiness</p>
                    <p class="mt-1 text-[10px] leading-relaxed text-gray-500">
                      Emergency, inpatient, and outpatient services aligned.
                    </p>
                  </div>
                </div>

                <div class="flex items-start gap-2.5 rounded-2xl bg-[#fff8f2] px-3 py-2.5">
                  <div class="mt-0.5 h-2.5 w-2.5 rounded-full bg-amber-500"></div>
                  <div>
                    <p class="text-[11px] font-semibold text-gray-900 leading-none">
                      Traceability first
                    </p>
                    <p class="mt-1 text-[10px] leading-relaxed text-gray-500">
                      Medicines, samples, and assets tracked with GS1 standards.
                    </p>
                  </div>
                </div>
              </div>
            </div>

            <%!-- Floating Card: Trust Rate --%>
            <div class="hidden md:block absolute top-8 -right-2 md:right-0 bg-white rounded-2xl p-4 shadow-xl z-20 w-[180px]">
              <div class="flex items-center space-x-1.5 mb-2">
                <div class="w-5 h-5 bg-[#d2d3ff] rounded-md flex items-center justify-center">
                  <svg
                    class="w-3 h-3 text-gray-900"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M5 13l4 4L19 7"
                    />
                  </svg>
                </div>
                <span class="text-[11px] font-medium text-gray-500">Standards Focus</span>
              </div>
              <div class="text-[28px] font-bold text-gray-900 leading-none mb-1">GS1</div>
              <p class="text-[10px] text-gray-400 leading-relaxed">
                Standardized patient safety across care, products, samples, and data
              </p>
            </div>
          </div>
        </div>
      </section>

      <%!-- About Us Section --%>
      <section id="about" class="py-20 bg-white">
        <div class="w-[90%] mx-auto  px-4 lg:px-8">
          <%!-- Top Row: Title + Description + Images --%>
          <div class="flex flex-col md:flex-row md:items-start gap-8 lg:gap-16 mb-16">
            <%!-- Left: Title --%>
            <div class="md:w-2/12 flex-shrink-0">
              <h2 class="text-[22px] font-bold text-gray-900 leading-tight">About Us</h2>
            </div>

            <%!-- Middle: Description --%>
            <div class="md:w-5/12">
              <p class="text-[17px] md:text-[19px] font-semibold text-gray-900 leading-[1.5]">
                Glocal Healthcare Centre of Excellence (GHCE) is a model healthcare facility and innovation hub established by GS1 Kenya to demonstrate how global standards transform healthcare delivery through patient safety, traceability, digital efficiency, and interoperable data systems.
              </p>
            </div>

            <%!-- Right: Two Images --%>
            <div class="md:w-5/12 flex items-start gap-3">
              <div class="w-1/2 rounded-2xl overflow-hidden">
                <img src="/images/hero.png" alt="Doctor" class="w-full h-[160px] object-cover" />
              </div>
              <div class="w-1/2 rounded-2xl overflow-hidden relative">
                <img
                  src="/images/why.png"
                  alt="Doctor with glasses"
                  class="w-full h-[160px] object-cover"
                />
                <%!-- Play button overlay --%>
                <div class="absolute inset-0 flex items-center justify-center">
                  <div class="w-10 h-10 bg-white rounded-full flex items-center justify-center shadow-lg">
                    <svg class="w-4 h-4 text-gray-800 ml-0.5" fill="currentColor" viewBox="0 0 20 20">
                      <path d="M6.3 2.841A1.5 1.5 0 004 4.11V15.89a1.5 1.5 0 002.3 1.269l9.344-5.89a1.5 1.5 0 000-2.538L6.3 2.84z" />
                    </svg>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <%!-- Bottom Row: Overview Card --%>
          <div
            class="overflow-hidden rounded-[32px] border border-white/80 shadow-[0_22px_70px_rgba(148,163,184,0.18)]"
            style="background: linear-gradient(135deg, rgba(231,238,255,0.92) 0%, rgba(241,236,247,0.95) 54%, rgba(251,235,232,0.9) 100%);"
          >
            <div class="w-full flex flex-col md:flex-row md:items-end md:justify-between gap-4 p-5 md:p-4">
              <div class="text-[34px] sm:text-[44px] md:text-[76px] font-bold text-gray-900 leading-[0.9] tracking-[-0.05em]">
                GS1 Standards
              </div>
              <p class="max-w-xl text-left md:text-end text-[18px] sm:text-[20px] md:text-[26px] font-medium leading-[1.2] text-gray-600">
                Empowering safer hospital care with standards-led workflows, traceability, and coordinated patient flow.
              </p>
            </div>

            <div class="h-px bg-white/80"></div>

            <div class="w-full flex flex-col md:flex-row items-start md:items-center justify-between gap-8 p-5 md:p-4">
              <div class="inline-flex w-fit items-center rounded-full bg-white/90 p-2.5 shadow-[0_12px_35px_rgba(255,255,255,0.55)]">
                <div class="flex -space-x-3">
                  <div class="h-16 w-16 sm:h-20 sm:w-20 overflow-hidden rounded-full border-[3px] border-white bg-white">
                    <img
                      src="/images/hero1.png"
                      alt="Clinical care team"
                      class="h-full w-full object-top object-cover"
                    />
                  </div>
                  <div class="h-16 w-16 sm:h-20 sm:w-20 overflow-hidden rounded-full border-[3px] border-white bg-white">
                    <img
                      src="/images/hero.png"
                      alt="Hospital services team"
                      class="h-full w-full object-cover"
                    />
                  </div>
                  <div class="h-16 w-16 sm:h-20 sm:w-20 overflow-hidden rounded-full border-[3px] border-white bg-white">
                    <img
                      src="/images/why.png"
                      alt="GS1-enabled care team"
                      class="h-full w-full object-cover"
                    />
                  </div>
                </div>
              </div>

              <div class="flex flex-col items-start md:items-end">
                <p class="max-w-lg text-[20px] sm:text-[24px] text-left md:text-end md:text-[26px] font-medium leading-[1.2] text-gray-600">
                  24/7 emergency, diagnostics, pharmacy, and inpatient teams connected through GS1-ready clinical operations.
                </p>
                <p class="mt-3 text-sm leading-relaxed text-gray-500 text-left md:text-end">
                  Built for continuity of care, accurate identification, and dependable decision-making across the patient journey.
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      <%!-- Services Section --%>
      <section id="services" class="pt-4 pb-16 bg-white">
        <div class="w-[90%] mx-auto  px-4 lg:px-8">
          <%!-- Section Header --%>
          <div class="text-center max-w-xl mx-auto mb-14">
            <h2 class="text-[32px] md:text-[40px] font-bold text-gray-900 leading-tight mb-4">
              Our Services
            </h2>
            <p class="text-gray-400 text-[15px] leading-relaxed">
              As a fully operational Level 3 hospital, GHCE delivers outpatient consultations, inpatient care, emergency response, maternal and child health, diagnostics, pharmacy support, minor procedures, and preventive health services.
            </p>
          </div>

          <%!-- Swiper Carousel --%>
          <div id="services-swiper" phx-hook="ServicesSwiper" class="swiper mb-10">
            <div class="swiper-wrapper">
              <%!-- Slide 1: Outpatient Consultations --%>
              <div class="swiper-slide">
                <div
                  class="bg-white border border-gray-100 rounded-2xl p-8 shadow-sm hover:shadow-md transition-shadow h-full"
                  style="background: linear-gradient(to bottom, #f5f3ff 0%, #ffffff 100%);"
                >
                  <div class="w-14 h-14 bg-[#3B3BC2] rounded-2xl flex items-center justify-center mb-6">
                    <svg
                      class="w-7 h-7 text-white"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="1.5"
                        d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"
                      />
                    </svg>
                  </div>
                  <h3 class="text-lg font-bold text-gray-900 mb-3">Outpatient Consultations</h3>
                  <p class="text-gray-400 text-sm leading-relaxed">
                    Accessible clinical consultations supported by accurate identification, digital records, and standardized workflows.
                  </p>
                </div>
              </div>

              <%!-- Slide 2: Inpatient Care --%>
              <div class="swiper-slide">
                <div
                  class="bg-white border border-gray-100 rounded-2xl p-8 shadow-sm hover:shadow-md transition-shadow h-full"
                  style="background: linear-gradient(to bottom, #ede9fe 0%, #ffffff 100%);"
                >
                  <div class="w-14 h-14 bg-[#3B3BC2] rounded-2xl flex items-center justify-center mb-6">
                    <svg
                      class="w-7 h-7 text-white"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="1.5"
                        d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                      />
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="1.5"
                        d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"
                      />
                    </svg>
                  </div>
                  <h3 class="text-lg font-bold text-gray-900 mb-3">Inpatient Care</h3>
                  <p class="text-gray-400 text-sm leading-relaxed">
                    Coordinated ward-based care with traceable patient journeys, medication verification, and safer handoffs.
                  </p>
                </div>
              </div>

              <%!-- Slide 3: 24/7 Emergency --%>
              <div class="swiper-slide">
                <div
                  class="bg-white border border-gray-100 rounded-2xl p-8 shadow-sm hover:shadow-md transition-shadow h-full"
                  style="background: linear-gradient(to bottom, #fef2f2 0%, #ffffff 100%);"
                >
                  <div class="w-14 h-14 bg-[#3B3BC2] rounded-2xl flex items-center justify-center mb-6">
                    <svg
                      class="w-7 h-7 text-white"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="1.5"
                        d="M7 21a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v12a4 4 0 01-4 4zm0 0h12a2 2 0 002-2v-4a2 2 0 00-2-2h-2.343M11 7.343l1.657-1.657a2 2 0 012.828 0l2.829 2.829a2 2 0 010 2.828l-8.486 8.485M7 17h.01"
                      />
                    </svg>
                  </div>
                  <h3 class="text-lg font-bold text-gray-900 mb-3">24/7 Emergency</h3>
                  <p class="text-gray-400 text-sm leading-relaxed">
                    Rapid emergency response backed by standardized identification, accountability, and data-driven decision-making.
                  </p>
                </div>
              </div>

              <%!-- Slide 4: Maternal and Child Health --%>
              <div class="swiper-slide">
                <div
                  class="bg-white border border-gray-100 rounded-2xl p-8 shadow-sm hover:shadow-md transition-shadow h-full"
                  style="background: linear-gradient(to bottom, #f0fdf4 0%, #ffffff 100%);"
                >
                  <div class="w-14 h-14 bg-[#3B3BC2] rounded-2xl flex items-center justify-center mb-6">
                    <svg
                      class="w-7 h-7 text-white"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="1.5"
                        d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"
                      />
                    </svg>
                  </div>
                  <h3 class="text-lg font-bold text-gray-900 mb-3">Maternal and Child Health</h3>
                  <p class="text-gray-400 text-sm leading-relaxed">
                    Patient-centered maternal and child health services delivered within a robust clinical governance framework.
                  </p>
                </div>
              </div>

              <%!-- Slide 5: Diagnostics --%>
              <div class="swiper-slide">
                <div
                  class="bg-white border border-gray-100 rounded-2xl p-8 shadow-sm hover:shadow-md transition-shadow h-full"
                  style="background: linear-gradient(to bottom, #fefce8 0%, #ffffff 100%);"
                >
                  <div class="w-14 h-14 bg-[#3B3BC2] rounded-2xl flex items-center justify-center mb-6">
                    <svg
                      class="w-7 h-7 text-white"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="1.5"
                        d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z"
                      />
                    </svg>
                  </div>
                  <h3 class="text-lg font-bold text-gray-900 mb-3">Diagnostics</h3>
                  <p class="text-gray-400 text-sm leading-relaxed">
                    Laboratory and diagnostic workflows strengthened by barcode-enabled traceability and accurate sample handling.
                  </p>
                </div>
              </div>

              <%!-- Slide 6: Pharmacy --%>
              <div class="swiper-slide">
                <div
                  class="bg-white border border-gray-100 rounded-2xl p-8 shadow-sm hover:shadow-md transition-shadow h-full"
                  style="background: linear-gradient(to bottom, #fdf2f8 0%, #ffffff 100%);"
                >
                  <div class="w-14 h-14 bg-[#3B3BC2] rounded-2xl flex items-center justify-center mb-6">
                    <svg
                      class="w-7 h-7 text-white"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="1.5"
                        d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"
                      />
                    </svg>
                  </div>
                  <h3 class="text-lg font-bold text-gray-900 mb-3">Pharmacy</h3>
                  <p class="text-gray-400 text-sm leading-relaxed">
                    Safer dispensing through GTIN-based medicine identification, verification systems, and supply chain visibility.
                  </p>
                </div>
              </div>
            </div>
          </div>

          <%!-- Navigation Arrows --%>
          <div class="flex items-center justify-center space-x-3">
            <button class="services-swiper-prev w-10 h-10 rounded-full border border-gray-200 flex items-center justify-center hover:bg-gray-50 transition-colors">
              <svg class="w-4 h-4 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M15 19l-7-7 7-7"
                />
              </svg>
            </button>
            <button class="services-swiper-next w-10 h-10 rounded-full border border-gray-200 flex items-center justify-center hover:bg-gray-50 transition-colors">
              <svg class="w-4 h-4 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M9 5l7 7-7 7"
                />
              </svg>
            </button>
          </div>
        </div>
      </section>

      <%!-- Reason for Choosing Us Section --%>
      <section
        id="standards"
        class="py-20 overflow-hidden"
        style="background: linear-gradient(160deg, #eef0ff 0%, #f0ecff 40%, #f5f3ff 100%);"
      >
        <div class="w-[90%] mx-auto  px-4 lg:px-8">
          <div class="flex flex-col lg:flex-row items-stretch gap-8 lg:gap-12">
            <%!-- Left Column --%>
            <div class="lg:w-[35%] flex flex-col justify-center">
              <h2 class="text-[32px] sm:text-[40px] md:text-[50px] font-bold text-gray-900 leading-[1.05] mb-5">
                Point-of-care Traceability Powered <br />By Gs1 Standards
              </h2>
              <p class="text-gray-400 text-[15px] leading-relaxed mb-10 max-w-sm">
                GS1 standards form the backbone of GHCE's digital healthcare ecosystem, enabling patient-centered care, real-time traceability, and seamless interoperability across clinical and operational workflows.
              </p>

              <%!-- Feature Pills --%>
              <div class="flex flex-col space-y-5">
                <div class="bg-white/70 backdrop-blur-sm rounded-2xl px-5 py-4 flex items-center space-x-4 shadow-sm max-w-sm">
                  <div class="w-12 h-12 bg-[#3B3BC2] rounded-full flex items-center justify-center flex-shrink-0">
                    <svg
                      class="w-6 h-6 text-white"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="1.5"
                        d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"
                      />
                    </svg>
                  </div>
                  <span class="text-[16px] font-bold text-gray-900">
                    GSRN for patient identification
                  </span>
                </div>

                <div class="bg-white/70 backdrop-blur-sm rounded-2xl px-5 py-4 flex items-center space-x-4 shadow-sm max-w-sm">
                  <div class="w-12 h-12 bg-[#3B3BC2] rounded-full flex items-center justify-center flex-shrink-0">
                    <svg
                      class="w-6 h-6 text-white"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="1.5"
                        d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                      />
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="1.5"
                        d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"
                      />
                    </svg>
                  </div>
                  <span class="text-[16px] font-bold text-gray-900">
                    GLN for locations and logistics
                  </span>
                </div>

                <div class="bg-white/70 backdrop-blur-sm rounded-2xl px-5 py-4 flex items-center space-x-4 shadow-sm max-w-sm">
                  <div class="w-12 h-12 bg-[#3B3BC2] rounded-full flex items-center justify-center flex-shrink-0">
                    <svg
                      class="w-6 h-6 text-white"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="1.5"
                        d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"
                      />
                    </svg>
                  </div>
                  <span class="text-[16px] font-bold text-gray-900">
                    GTIN for medicines and devices
                  </span>
                </div>
              </div>
            </div>

            <%!-- Center: Doctor Image --%>
            <div class="lg:w-[30%] flex items-center justify-center">
              <div class="rounded-3xl overflow-hidden w-full max-w-[280px] sm:max-w-[340px]">
                <img
                  src="/images/why.png"
                  alt="Doctor"
                  class="w-full h-[360px] sm:h-[500px] object-cover"
                />
              </div>
            </div>

            <%!-- Right Column: Info Cards --%>
            <div class="lg:w-[35%] flex flex-col justify-center space-y-6">
              <%!-- Top Card --%>
              <div
                class="bg-white/50 backdrop-blur-sm rounded-3xl p-5 sm:p-7"
                style="background: linear-gradient(135deg, rgba(255,255,255,0.6) 0%, rgba(238,230,255,0.4) 100%);"
              >
                <p class="text-gray-600 text-[15px] leading-relaxed mb-5">
                  GIAI helps track medical equipment and assets across the hospital, supporting maintenance, utilization monitoring, and lifecycle management.
                </p>
                <div class="bg-white/80 rounded-2xl px-5 py-3.5 inline-flex items-center space-x-3 shadow-sm">
                  <div class="w-10 h-10 bg-[#3B3BC2] rounded-full flex items-center justify-center flex-shrink-0">
                    <svg
                      class="w-5 h-5 text-white"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M7 17l9.2-9.2M17 17V7H7"
                      />
                    </svg>
                  </div>
                  <span class="text-sm font-bold text-gray-900">View GS1 Identifiers</span>
                </div>
              </div>

              <%!-- Bottom Card --%>
              <div
                class="bg-white/50 backdrop-blur-sm rounded-3xl p-5 sm:p-7"
                style="background: linear-gradient(135deg, rgba(255,240,235,0.5) 0%, rgba(255,230,225,0.3) 100%);"
              >
                <p class="text-gray-600 text-[15px] leading-relaxed mb-5">
                  Why GS1 matters at GHCE: patient safety, traceability, interoperability, and more efficient clinical and operational workflows.
                </p>
                <div class="bg-white/80 rounded-2xl px-5 py-3.5 inline-flex items-center space-x-3 shadow-sm">
                  <div class="w-10 h-10 bg-[#3B3BC2] rounded-full flex items-center justify-center flex-shrink-0">
                    <svg
                      class="w-5 h-5 text-white"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M7 17l9.2-9.2M17 17V7H7"
                      />
                    </svg>
                  </div>
                  <span class="text-sm font-bold text-gray-900">Strengthen Patient Safety</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      <%!-- Reliable Source for Quality Care Section --%>
      <section id="partner" class="py-20 bg-white">
        <div class="w-[90%] mx-auto  px-4 lg:px-8">
          <div class="flex flex-col lg:flex-row items-stretch gap-8 lg:gap-10">
            <%!-- Left: Doctor Video Call Image --%>
            <div class="lg:w-1/2 relative">
              <div class="rounded-3xl overflow-hidden h-full">
                <img
                  src="/images/hero.png"
                  alt="Doctor on video call"
                  class="w-full h-full min-h-[320px] sm:min-h-[420px] lg:min-h-[480px] object-cover"
                />
              </div>
              <%!-- Video Call Controls --%>
              <div class="absolute bottom-4 left-4 right-4 sm:left-1/2 sm:right-auto sm:-translate-x-1/2 bg-white/90 backdrop-blur-sm rounded-full px-4 py-2.5 flex items-center justify-center gap-3 shadow-lg">
                <button class="w-10 h-10 bg-white rounded-full flex items-center justify-center shadow-sm">
                  <svg
                    class="w-5 h-5 text-gray-700"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="1.5"
                      d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"
                    />
                  </svg>
                </button>
                <button class="w-10 h-10 bg-red-400 rounded-full flex items-center justify-center shadow-sm">
                  <svg
                    class="w-5 h-5 text-white"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="1.5"
                      d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"
                    />
                  </svg>
                </button>
                <button class="w-10 h-10 bg-white rounded-full flex items-center justify-center shadow-sm">
                  <svg
                    class="w-5 h-5 text-gray-700"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="1.5"
                      d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z"
                    />
                  </svg>
                </button>
              </div>
            </div>

            <%!-- Right: Content --%>
            <div
              class="lg:w-1/2 rounded-3xl p-6 sm:p-8 lg:p-12 flex flex-col justify-center"
              style="background: linear-gradient(160deg, #f7f7ff 0%, #ececff 52%, #d2d3ff 100%);"
            >
              <h2 class="text-[30px] sm:text-[36px] md:text-[46px] font-bold text-gray-900 leading-[1.08] mb-5">
                Partner With Us
              </h2>
              <p class="text-gray-400 text-[15px] leading-relaxed mb-10 max-w-lg">
                GHCE brings together healthcare providers, regulators, manufacturers, academia, and innovators to build safer, more efficient, and digitally connected healthcare systems.
              </p>

              <div class="mb-8 rounded-[28px] border border-white/70 bg-white/80 p-6 shadow-[0_18px_45px_rgba(148,163,184,0.16)] backdrop-blur-sm">
                <p class="text-[11px] font-semibold uppercase tracking-[0.18em] text-[#8d90d6] mb-4">
                  Contact GHCE
                </p>
                <div class="grid gap-3">
                  <a
                    href="tel:+254726776293"
                    class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-1 sm:gap-4 rounded-2xl bg-[#f4f5ff] px-4 py-3 text-[15px] font-semibold text-gray-900 transition-colors hover:bg-[#e6e7ff]"
                  >
                    <span>+254 726 776 293</span>
                    <span class="text-[12px] font-medium text-gray-500">Primary line</span>
                  </a>
                  <a
                    href="tel:+254739371657"
                    class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-1 sm:gap-4 rounded-2xl bg-[#f4f5ff] px-4 py-3 text-[15px] font-semibold text-gray-900 transition-colors hover:bg-[#e6e7ff]"
                  >
                    <span>+254 739 371 657</span>
                    <span class="text-[12px] font-medium text-gray-500">Support line</span>
                  </a>
                  <a
                    href="mailto:info@glocalhealthcentre.org"
                    class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-1 sm:gap-4 rounded-2xl bg-[#ececff] px-4 py-3 text-[15px] font-semibold text-gray-900 transition-colors hover:bg-[#e0e1ff]"
                  >
                    <span class="break-all">info@glocalhealthcentre.org</span>
                    <span class="shrink-0 text-[12px] font-medium text-gray-500">Email us</span>
                  </a>
                </div>
              </div>

              <%!-- Feature Cards Grid --%>
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <%!-- Advanced Diagnostics --%>
                <div class="bg-white rounded-2xl p-6">
                  <div class="flex items-center space-x-3 mb-4">
                    <div class="w-11 h-11 bg-[#3B3BC2] rounded-full flex items-center justify-center flex-shrink-0">
                      <svg
                        class="w-5 h-5 text-white"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="1.5"
                          d="M9 3v2m6-2v2M9 19v2m6-2v2M5 9H3m2 6H3m18-6h-2m2 6h-2M7 19h10a2 2 0 002-2V7a2 2 0 00-2-2H7a2 2 0 00-2 2v10a2 2 0 002 2zM9 9h6v6H9V9z"
                        />
                      </svg>
                    </div>
                    <span class="text-[15px] font-bold text-gray-900">
                      Innovative<br />Healthcare Solutions
                    </span>
                  </div>
                  <div class="border-t border-gray-100 pt-3">
                    <p class="text-gray-400 text-sm leading-relaxed">
                      Collaborate on digital traceability, GS1 implementation, and smart hospital workflows.
                    </p>
                  </div>
                </div>

                <%!-- Research and Development --%>
                <div class="bg-white rounded-2xl p-6">
                  <div class="flex items-center space-x-3 mb-4">
                    <div class="w-11 h-11 bg-[#3B3BC2] rounded-full flex items-center justify-center flex-shrink-0">
                      <svg
                        class="w-5 h-5 text-white"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="1.5"
                          d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z"
                        />
                      </svg>
                    </div>
                    <span class="text-[15px] font-bold text-gray-900">
                      Research &amp;<br />Development
                    </span>
                  </div>
                  <div class="border-t border-gray-100 pt-3">
                    <p class="text-gray-400 text-sm leading-relaxed">
                      Join pilots, evidence-based innovation, and multidisciplinary healthcare learning at scale.
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      <%!-- FAQ Section --%>
      <section id="faq" class="py-20 bg-white">
        <div class="w-[90%] mx-auto  px-4 lg:px-8">
          <div class="flex flex-col lg:flex-row gap-12 lg:gap-20">
            <%!-- Left: Title --%>
            <div class="lg:w-5/12">
              <h2 class="text-[30px] sm:text-[36px] md:text-[44px] font-bold text-gray-900 leading-[1.1] mb-4">
                Frequently asked<br />questions
              </h2>
              <p class="text-gray-400 text-sm leading-relaxed max-w-xs">
                Key questions about GHCE, GS1-enabled healthcare, and how the Centre of Excellence supports safer care.
              </p>
            </div>

            <%!-- Right: Accordion --%>
            <div class="lg:w-7/12 flex flex-col space-y-3">
              <details class="group bg-[#f4f4ff] rounded-xl">
                <summary class="flex items-center justify-between cursor-pointer px-6 py-5 list-none [&::-webkit-details-marker]:hidden">
                  <span class="text-[15px] font-medium text-gray-900">
                    1. What makes GHCE different from a typical hospital?
                  </span>
                  <span class="text-gray-400 text-xl font-light group-open:hidden">+</span>
                  <span class="text-gray-400 text-xl font-light hidden group-open:inline">−</span>
                </summary>
                <div class="px-6 pb-5 text-gray-500 text-sm leading-relaxed">
                  GHCE is both a fully operational Level 3 hospital and a Centre of Excellence where GS1 standards are applied to patient safety, traceability, data exchange, and healthcare systems innovation.
                </div>
              </details>

              <details class="group bg-[#f4f4ff] rounded-xl">
                <summary class="flex items-center justify-between cursor-pointer px-6 py-5 list-none [&::-webkit-details-marker]:hidden">
                  <span class="text-[15px] font-medium text-gray-900">
                    2. Which GS1 identifiers are used at GHCE?
                  </span>
                  <span class="text-gray-400 text-xl font-light group-open:hidden">+</span>
                  <span class="text-gray-400 text-xl font-light hidden group-open:inline">−</span>
                </summary>
                <div class="px-6 pb-5 text-gray-500 text-sm leading-relaxed">
                  GHCE applies GSRN for patients, GLN for physical locations, GTIN for medicines and devices, and GIAI for medical equipment and assets.
                </div>
              </details>

              <details class="group bg-[#f4f4ff] rounded-xl">
                <summary class="flex items-center justify-between cursor-pointer px-6 py-5 list-none [&::-webkit-details-marker]:hidden">
                  <span class="text-[15px] font-medium text-gray-900">
                    3. Why do GS1 standards matter in healthcare?
                  </span>
                  <span class="text-gray-400 text-xl font-light group-open:hidden">+</span>
                  <span class="text-gray-400 text-xl font-light hidden group-open:inline">−</span>
                </summary>
                <div class="px-6 pb-5 text-gray-500 text-sm leading-relaxed">
                  They improve patient safety, enable real-time traceability, support interoperability, and streamline both clinical and operational workflows.
                </div>
              </details>

              <details class="group bg-[#f4f4ff] rounded-xl">
                <summary class="flex items-center justify-between cursor-pointer px-6 py-5 list-none [&::-webkit-details-marker]:hidden">
                  <span class="text-[15px] font-medium text-gray-900">
                    4. What services does GHCE provide?
                  </span>
                  <span class="text-gray-400 text-xl font-light group-open:hidden">+</span>
                  <span class="text-gray-400 text-xl font-light hidden group-open:inline">−</span>
                </summary>
                <div class="px-6 pb-5 text-gray-500 text-sm leading-relaxed">
                  GHCE provides outpatient consultations, inpatient care, 24/7 emergency services, maternal and child health, diagnostics, pharmacy support, minor procedures, and preventive health services.
                </div>
              </details>

              <details class="group bg-[#f4f4ff] rounded-xl">
                <summary class="flex items-center justify-between cursor-pointer px-6 py-5 list-none [&::-webkit-details-marker]:hidden">
                  <span class="text-[15px] font-medium text-gray-900">
                    5. Who can partner with GHCE?
                  </span>
                  <span class="text-gray-400 text-xl font-light group-open:hidden">+</span>
                  <span class="text-gray-400 text-xl font-light hidden group-open:inline">−</span>
                </summary>
                <div class="px-6 pb-5 text-gray-500 text-sm leading-relaxed">
                  Technology partners, pharmaceutical and medical device companies, academic institutions, regulators, and healthcare development initiatives can collaborate with GHCE.
                </div>
              </details>
            </div>
          </div>
        </div>
      </section>
      <%!-- Footer --%>
      <.public_footer current_page={:home} />
    </body>
    """
  end
end
