defmodule MedcampWeb.TibasasaLive.Index do
  use MedcampWeb, :live_view

  alias MedcampWeb.TibasasaLive.Components

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :tibasasa, nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <!doctype html>
    <html lang="en" class="scroll-smooth">
      <head>
        <meta charset="utf-8" />
        <meta content="width=device-width, initial-scale=1" name="viewport" />
        <title>Tibasasa AI — AI-Powered Hospital Operations Platform</title>
        <meta
          name="description"
          content="Tibasasa AI is an AI-augmented hospital operations platform covering reception, doctors, pharmacy, labs, radiology, and finance — with multilingual voice dictation and AI clinical decision support built in."
        />

        <meta property="og:type" content="website" />
        <meta property="og:title" content="Tibasasa AI — AI-Powered Hospital Operations Platform" />
        <meta
          property="og:description"
          content="From reception to pharmacy stock to radiology — run your hospital on one AI-augmented platform."
        />
        <meta property="og:image" content="/images/public/african-hospital-exterior.png" />
        <meta name="twitter:card" content="summary_large_image" />
        <meta name="twitter:title" content="Tibasasa AI — AI-Powered Hospital Operations Platform" />
        <meta
          name="twitter:description"
          content="From reception to pharmacy stock to radiology — run your hospital on one AI-augmented platform."
        />
        <meta name="twitter:image" content="/images/public/african-hospital-exterior.png" />

        <link rel="icon" href="/images/tibasasa-ai-logo.png" />

        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
        <link
          rel="stylesheet"
          href="https://fonts.googleapis.com/css2?family=Inter+Tight:wght@300;400;500;600;700&family=Lora:ital,wght@0,400;0,500;0,600;1,400;1,500&display=swap"
        />

        <script src="https://cdn.tailwindcss.com">
        </script>
        <script>
          tailwind.config = {
            theme: {
              extend: {
                colors: {
                  brand: { DEFAULT: "#0C2765", light: "#52B2D8", mint: "#e9f6fb" },
                  ink: "#0C2765",
                  muted: "#667085",
                  stroke: "#eeeeee",
                  shape: "#f9f9f9",
                  smoke: "#f6f6f6",
                },
                fontFamily: {
                  sans: [
                    '"Inter Tight"',
                    "ui-sans-serif",
                    "system-ui",
                    "sans-serif",
                  ],
                  display: ["Lora", "ui-serif", "Georgia", "serif"],
                },
                fontSize: {
                  h1: [
                    "clamp(2.5rem, 5.2vw, 4rem)",
                    { lineHeight: "1.08", letterSpacing: "-0.03em" },
                  ],
                  h2: [
                    "clamp(2rem, 3.8vw, 2.875rem)",
                    { lineHeight: "1.14", letterSpacing: "-0.025em" },
                  ],
                  h3: [
                    "clamp(1.75rem, 3vw, 2.25rem)",
                    { lineHeight: "1.2", letterSpacing: "-0.02em" },
                  ],
                  h4: [
                    "1.625rem",
                    { lineHeight: "1.28", letterSpacing: "-0.015em" },
                  ],
                  h5: [
                    "1.375rem",
                    { lineHeight: "1.35", letterSpacing: "-0.01em" },
                  ],
                  h6: ["1.125rem", { lineHeight: "1.45" }],
                },
                borderRadius: { xl2: "16px", pill: "76px" },
                boxShadow: {
                  card: "0 1px 2px rgba(0,0,0,.04), 0 12px 32px -12px rgba(0,0,0,.10)",
                  menu: "0 24px 48px -16px rgba(0,0,0,.16)",
                },
                keyframes: {
                  "marquee-x": {
                    from: { transform: "translateX(0)" },
                    to: { transform: "translateX(-100%)" },
                  },
                  "marquee-y": {
                    from: { transform: "translateY(0)" },
                    to: { transform: "translateY(-50%)" },
                  },
                  blink: { "0%,100%": { opacity: "1" }, "50%": { opacity: ".25" } },
                },
                animation: {
                  "marquee-x": "marquee-x 32s linear infinite",
                  "marquee-y": "marquee-y 40s linear infinite",
                  blink: "blink 1.6s ease-in-out infinite",
                },
              },
            },
          };
        </script>
        <style type="text/tailwindcss">
          /* Fade the top/bottom of the testimonial columns — not expressible as a utility. */
          .mask-y {
            -webkit-mask-image: linear-gradient(
              180deg,
              transparent,
              #000 12%,
              #000 88%,
              transparent
            );
            mask-image: linear-gradient(
              180deg,
              transparent,
              #000 12%,
              #000 88%,
              transparent
            );
          }
          .mask-x {
            -webkit-mask-image: linear-gradient(
              90deg,
              transparent,
              #000 10%,
              #000 90%,
              transparent
            );
            mask-image: linear-gradient(
              90deg,
              transparent,
              #000 10%,
              #000 90%,
              transparent
            );
          }
          /* Rotate the FAQ chevron when its <details> is open. */
          details[open] .faq-chevron {
            transform: rotate(180deg);
          }

          /* Scroll-reveal: JS toggles .is-visible via IntersectionObserver. */
          .reveal {
            opacity: 0;
            transform: translateY(24px);
            transition: opacity 0.7s cubic-bezier(0.16, 1, 0.3, 1),
              transform 0.7s cubic-bezier(0.16, 1, 0.3, 1);
          }
          .reveal.is-visible {
            opacity: 1;
            transform: translateY(0);
          }

          @media (prefers-reduced-motion: reduce) {
            .animate-marquee-x,
            .animate-marquee-y,
            .animate-blink {
              animation: none !important;
            }
            .reveal {
              opacity: 1 !important;
              transform: none !important;
              transition: none !important;
            }
          }
        </style>
      </head>

      <body class="bg-white font-sans text-ink antialiased">
        <!-- ══════════════════════════════ HEADER ══════════════════════════════ -->
        <header class="sticky top-0 z-50 border-b border-stroke/80 bg-white/85 backdrop-blur">
          <div class="mx-auto max-w-7xl px-5 lg:px-8">
            <!-- Mobile nav state. Must precede the <nav> it toggles so `peer-checked:` can reach it. -->
            <input type="checkbox" id="nav-toggle" class="peer hidden" />

            <div class="flex h-[72px] items-center justify-between gap-6">
              <a href="#top" class="flex items-center gap-2.5">
                <img
                  src="/images/tibasasa-ai-logo.png"
                  alt="Tibasasa AI"
                  class="h-11 w-11 object-contain"
                />
                <span class="text-[20px] font-bold tracking-tight text-brand">Tibasasa AI</span>
              </a>
              
    <!-- Desktop nav -->
              <nav class="hidden items-center gap-8 lg:flex" aria-label="Main">
                <div class="group relative">
                  <button
                    type="button"
                    class="flex items-center gap-1.5 text-[15px] font-medium text-ink/80 transition hover:text-brand"
                  >
                    Pages
                    <svg
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      stroke-width="2"
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      class="h-4 w-4 transition group-hover:rotate-180"
                      aria-hidden="true"
                    >
                      <path d="m6 9 6 6 6-6" />
                    </svg>
                  </button>
                  <!-- Hover/focus-within replaces the Webflow click-driven .w--open state. -->
                  <div class="invisible absolute left-1/2 top-full z-50 w-[640px] -translate-x-1/2 pt-4 opacity-0 transition group-hover:visible group-hover:opacity-100 group-focus-within:visible group-focus-within:opacity-100">
                    <div class="grid grid-cols-3 gap-8 rounded-xl2 border border-stroke bg-white p-7 shadow-menu">
                      <div>
                        <p class="mb-3 text-[13px] font-semibold uppercase tracking-wider text-muted">
                          Main Pages
                        </p>
                        <ul class="space-y-2.5 text-[15px]">
                          <li><a href="#top" class="text-brand">Home</a></li>
                          <li>
                            <a href="#who" class="text-ink/75 transition hover:text-brand">About</a>
                          </li>
                          <li>
                            <a href="#features" class="text-ink/75 transition hover:text-brand">
                              Features
                            </a>
                          </li>
                          <li>
                            <a href="#pricing" class="text-ink/75 transition hover:text-brand">
                              Pricing
                            </a>
                          </li>
                          <li>
                            <a href="#blog" class="text-ink/75 transition hover:text-brand">Blog</a>
                          </li>
                        </ul>
                      </div>
                      <div>
                        <p class="mb-3 text-[13px] font-semibold uppercase tracking-wider text-muted">
                          Inner pages
                        </p>
                        <ul class="space-y-2.5 text-[15px]">
                          <li>
                            <a href="#blog" class="text-ink/75 transition hover:text-brand">
                              Blog single
                            </a>
                          </li>
                          <li>
                            <a href="#pricing" class="text-ink/75 transition hover:text-brand">
                              Pricing single
                            </a>
                          </li>
                          <li>
                            <a href="#cta" class="text-ink/75 transition hover:text-brand">
                              Download
                            </a>
                          </li>
                          <li>
                            <a href="#footer" class="text-ink/75 transition hover:text-brand">
                              Career
                            </a>
                          </li>
                          <li>
                            <a href="#contact" class="text-ink/75 transition hover:text-brand">
                              Contact
                            </a>
                          </li>
                        </ul>
                      </div>
                      <div>
                        <p class="mb-3 text-[13px] font-semibold uppercase tracking-wider text-muted">
                          Utility pages
                        </p>
                        <ul class="space-y-2.5 text-[15px]">
                          <li>
                            <a href="#footer" class="text-ink/75 transition hover:text-brand">404</a>
                          </li>
                          <li>
                            <a href="#footer" class="text-ink/75 transition hover:text-brand">
                              License
                            </a>
                          </li>
                          <li>
                            <a href="#footer" class="text-ink/75 transition hover:text-brand">
                              Changelog
                            </a>
                          </li>
                          <li>
                            <a href="#footer" class="text-ink/75 transition hover:text-brand">
                              Style guide
                            </a>
                          </li>
                          <li>
                            <a href="#footer" class="text-ink/75 transition hover:text-brand">
                              Password
                            </a>
                          </li>
                        </ul>
                      </div>
                    </div>
                  </div>
                </div>
                <a
                  href="#features"
                  class="text-[15px] font-medium text-ink/80 transition hover:text-brand"
                >
                  Features
                </a>
                <a href="#who" class="text-[15px] font-medium text-ink/80 transition hover:text-brand">
                  About
                </a>
                <a
                  href="#pricing"
                  class="text-[15px] font-medium text-ink/80 transition hover:text-brand"
                >
                  Pricing
                </a>
                <a
                  href="#blog"
                  class="text-[15px] font-medium text-ink/80 transition hover:text-brand"
                >
                  Blog
                </a>
              </nav>

              <div class="flex items-center gap-3">
                <a
                  href="#contact"
                  class="hidden rounded-pill bg-brand px-6 py-3 text-[15px] font-medium text-white transition hover:bg-brand-light sm:inline-block"
                >
                  Get a demo
                </a>
                <label
                  for="nav-toggle"
                  class="grid h-10 w-10 cursor-pointer place-items-center rounded-lg border border-stroke text-ink lg:hidden"
                  aria-label="Toggle navigation"
                >
                  <svg
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="2"
                    stroke-linecap="round"
                    class="h-5 w-5"
                    aria-hidden="true"
                  >
                    <path d="M4 7h16M4 12h16M4 17h16" />
                  </svg>
                </label>
              </div>
            </div>
            
    <!-- Mobile nav panel -->
            <nav
              class="hidden border-t border-stroke py-5 peer-checked:block lg:!hidden"
              aria-label="Mobile"
            >
              <ul class="space-y-1 text-[16px] font-medium">
                <li>
                  <a href="#features" class="block rounded-lg px-2 py-2.5 hover:bg-shape">Features</a>
                </li>
                <li>
                  <a href="#who" class="block rounded-lg px-2 py-2.5 hover:bg-shape">About</a>
                </li>
                <li>
                  <a href="#steps" class="block rounded-lg px-2 py-2.5 hover:bg-shape">
                    How it works
                  </a>
                </li>
                <li>
                  <a href="#pricing" class="block rounded-lg px-2 py-2.5 hover:bg-shape">Pricing</a>
                </li>
                <li>
                  <a href="#faq" class="block rounded-lg px-2 py-2.5 hover:bg-shape">FAQ</a>
                </li>
                <li>
                  <a href="#blog" class="block rounded-lg px-2 py-2.5 hover:bg-shape">Blog</a>
                </li>
              </ul>
              <a
                href="#contact"
                class="mt-4 block rounded-pill bg-brand px-6 py-3 text-center text-[15px] font-medium text-white"
              >
                Get a demo
              </a>
            </nav>
          </div>
        </header>

        <main id="top">
          <!-- ══════════════════════════════ HERO ══════════════════════════════ -->
          <section class="relative overflow-hidden bg-gradient-to-b from-brand-mint/45 via-white to-white pt-16 lg:pt-24">
            <div class="mx-auto max-w-7xl px-5 lg:px-8">
              <div class="mx-auto max-w-3xl text-center">
                <div class="mx-auto mb-7 inline-flex items-center gap-3 rounded-pill border border-stroke bg-white py-1.5 pl-1.5 pr-5 shadow-sm">
                  <div class="flex -space-x-2.5">
                    <img
                      src="data:image/svg+xml,%3Csvg%20xmlns%3D%27http%3A//www.w3.org/2000/svg%27%20viewBox%3D%270%200%2096%2096%27%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27%230C2765%27/%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2740%27%20r%3D%2715%27%20fill%3D%27%2352B2D8%27/%3E%3Cpath%20d%3D%27M18%2088c3-22%2019-34%2030-34s27%2012%2030%2034%27%20fill%3D%27%2352B2D8%27/%3E%3C/svg%3E"
                      alt=""
                      class="h-8 w-8 rounded-full object-cover ring-2 ring-white"
                    />
                    <img
                      src="data:image/svg+xml,%3Csvg%20xmlns%3D%27http%3A//www.w3.org/2000/svg%27%20viewBox%3D%270%200%2096%2096%27%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27%230C2765%27/%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2740%27%20r%3D%2715%27%20fill%3D%27%2352B2D8%27/%3E%3Cpath%20d%3D%27M18%2088c3-22%2019-34%2030-34s27%2012%2030%2034%27%20fill%3D%27%2352B2D8%27/%3E%3C/svg%3E"
                      alt=""
                      class="h-8 w-8 rounded-full object-cover ring-2 ring-white"
                    />
                    <img
                      src="data:image/svg+xml,%3Csvg%20xmlns%3D%27http%3A//www.w3.org/2000/svg%27%20viewBox%3D%270%200%2096%2096%27%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27%230C2765%27/%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2740%27%20r%3D%2715%27%20fill%3D%27%2352B2D8%27/%3E%3Cpath%20d%3D%27M18%2088c3-22%2019-34%2030-34s27%2012%2030%2034%27%20fill%3D%27%2352B2D8%27/%3E%3C/svg%3E"
                      alt=""
                      class="h-8 w-8 rounded-full object-cover ring-2 ring-white"
                    />
                  </div>
                  <span class="text-[14px] font-medium text-muted">Joined 5k+ Members</span>
                </div>

                <h1 class="text-h1 font-semibold">
                  Run Your Hospital,<br />
                  <span class="font-display italic font-normal text-brand">One</span> AI Platform
                </h1>
                <p class="mx-auto mt-6 max-w-xl text-[18px] leading-relaxed text-muted">
                  Reception, doctors, pharmacy, labs, and radiology — all in one
                  system, backed by multilingual voice dictation and AI clinical
                  decision support.
                </p>

                <div class="mt-9 flex flex-wrap items-center justify-center gap-3">
                  <a
                    href="#pricing"
                    class="rounded-pill bg-brand px-7 py-3.5 text-[16px] font-medium text-white transition hover:bg-brand-light"
                  >
                    Start free trial
                  </a>
                  <a
                    href="#showcase"
                    class="inline-flex items-center gap-2 rounded-pill border border-stroke bg-white px-7 py-3.5 text-[16px] font-medium text-ink transition hover:border-brand hover:text-brand"
                  >
                    <svg
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      stroke-width="2"
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      class="h-4 w-4"
                      aria-hidden="true"
                    >
                      <polygon points="6 3 20 12 6 21 6 3" fill="currentColor" stroke="none" />
                    </svg>
                    Watch demo
                  </a>
                </div>
              </div>

              <div class="relative mt-16 grid gap-6 lg:mt-20 lg:grid-cols-[0.9fr_1.1fr] lg:items-end">
                <img
                  src="/images/public/african-hospital-reception.png"
                  alt="Clinician reviewing patient records on a tablet"
                  class="h-[300px] w-full rounded-xl2 object-cover shadow-card lg:h-[380px]"
                />
                <img
                  src="/images/public/african-surgical-team.png"
                  alt="Tibasasa AI analytics dashboard"
                  class="h-[300px] w-full rounded-xl2 object-cover shadow-card lg:h-[440px]"
                />
              </div>
            </div>
          </section>
          
    <!-- ══════════════════════════════ LOGO MARQUEE ══════════════════════════════ -->
          <section class="border-y border-stroke bg-white py-14">
            <p class="mb-9 text-center text-[15px] text-muted">
              Trusted by healthcare professionals worldwide.
            </p>
            <div class="mask-x overflow-hidden">
              <div class="flex w-max animate-marquee-x items-center gap-16 pr-16">
                <!-- Two identical runs so the -100% translate loops seamlessly. -->
                <div class="flex shrink-0 items-center gap-16 pr-16 text-muted/70">
                  <span class="flex items-center gap-2 text-[19px] font-semibold tracking-tight">
                    <svg
                      viewBox="0 0 24 24"
                      class="h-6 w-6"
                      fill="none"
                      stroke="currentColor"
                      stroke-width="2"
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      aria-hidden="true"
                    >
                      <path d="M12 21s-7-4.35-9.33-8.5A5.5 5.5 0 0 1 12 6.5a5.5 5.5 0 0 1 9.33 6C19 16.65 12 21 12 21z" /></svg>CareLoop
                  </span>
                  <span class="flex items-center gap-2 text-[19px] font-semibold tracking-tight">
                    <svg
                      viewBox="0 0 24 24"
                      class="h-6 w-6"
                      fill="none"
                      stroke="currentColor"
                      stroke-width="2"
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      aria-hidden="true"
                    >
                      <path d="M3 12h4l2-6 4 12 2-6h6" /></svg>Vitalis
                  </span>
                  <span class="flex items-center gap-2 text-[19px] font-semibold tracking-tight">
                    <svg
                      viewBox="0 0 24 24"
                      class="h-6 w-6"
                      fill="none"
                      stroke="currentColor"
                      stroke-width="2"
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      aria-hidden="true"
                    >
                      <circle cx="12" cy="12" r="9" />
                      <path d="M12 7v10M7 12h10" /></svg>Medera
                  </span>
                  <span class="flex items-center gap-2 text-[19px] font-semibold tracking-tight">
                    <svg
                      viewBox="0 0 24 24"
                      class="h-6 w-6"
                      fill="none"
                      stroke="currentColor"
                      stroke-width="2"
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      aria-hidden="true"
                    >
                      <rect x="3" y="4" width="18" height="16" rx="3" />
                      <path d="M8 2v4M16 2v4M3 10h18" /></svg>Clinexa
                  </span>
                  <span class="flex items-center gap-2 text-[19px] font-semibold tracking-tight">
                    <svg
                      viewBox="0 0 24 24"
                      class="h-6 w-6"
                      fill="none"
                      stroke="currentColor"
                      stroke-width="2"
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      aria-hidden="true"
                    >
                      <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l8.84 8.84 8.84-8.84a5.5 5.5 0 0 0 0-7.78z" /></svg>Pulseway
                  </span>
                  <span class="flex items-center gap-2 text-[19px] font-semibold tracking-tight">
                    <svg
                      viewBox="0 0 24 24"
                      class="h-6 w-6"
                      fill="none"
                      stroke="currentColor"
                      stroke-width="2"
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      aria-hidden="true"
                    >
                      <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" /></svg>Sanora
                  </span>
                </div>
                <div class="flex shrink-0 items-center gap-16 pr-16 text-muted/70" aria-hidden="true">
                  <span class="flex items-center gap-2 text-[19px] font-semibold tracking-tight">
                    <svg
                      viewBox="0 0 24 24"
                      class="h-6 w-6"
                      fill="none"
                      stroke="currentColor"
                      stroke-width="2"
                      stroke-linecap="round"
                      stroke-linejoin="round"
                    >
                      <path d="M12 21s-7-4.35-9.33-8.5A5.5 5.5 0 0 1 12 6.5a5.5 5.5 0 0 1 9.33 6C19 16.65 12 21 12 21z" /></svg>CareLoop
                  </span>
                  <span class="flex items-center gap-2 text-[19px] font-semibold tracking-tight">
                    <svg
                      viewBox="0 0 24 24"
                      class="h-6 w-6"
                      fill="none"
                      stroke="currentColor"
                      stroke-width="2"
                      stroke-linecap="round"
                      stroke-linejoin="round"
                    >
                      <path d="M3 12h4l2-6 4 12 2-6h6" /></svg>Vitalis
                  </span>
                  <span class="flex items-center gap-2 text-[19px] font-semibold tracking-tight">
                    <svg
                      viewBox="0 0 24 24"
                      class="h-6 w-6"
                      fill="none"
                      stroke="currentColor"
                      stroke-width="2"
                      stroke-linecap="round"
                      stroke-linejoin="round"
                    >
                      <circle cx="12" cy="12" r="9" />
                      <path d="M12 7v10M7 12h10" /></svg>Medera
                  </span>
                  <span class="flex items-center gap-2 text-[19px] font-semibold tracking-tight">
                    <svg
                      viewBox="0 0 24 24"
                      class="h-6 w-6"
                      fill="none"
                      stroke="currentColor"
                      stroke-width="2"
                      stroke-linecap="round"
                      stroke-linejoin="round"
                    >
                      <rect x="3" y="4" width="18" height="16" rx="3" />
                      <path d="M8 2v4M16 2v4M3 10h18" /></svg>Clinexa
                  </span>
                  <span class="flex items-center gap-2 text-[19px] font-semibold tracking-tight">
                    <svg
                      viewBox="0 0 24 24"
                      class="h-6 w-6"
                      fill="none"
                      stroke="currentColor"
                      stroke-width="2"
                      stroke-linecap="round"
                      stroke-linejoin="round"
                    >
                      <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l8.84 8.84 8.84-8.84a5.5 5.5 0 0 0 0-7.78z" /></svg>Pulseway
                  </span>
                  <span class="flex items-center gap-2 text-[19px] font-semibold tracking-tight">
                    <svg
                      viewBox="0 0 24 24"
                      class="h-6 w-6"
                      fill="none"
                      stroke="currentColor"
                      stroke-width="2"
                      stroke-linecap="round"
                      stroke-linejoin="round"
                    >
                      <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" /></svg>Sanora
                  </span>
                </div>
              </div>
            </div>
          </section>
          
    <!-- ══════════════════════════════ FEATURES ══════════════════════════════ -->
          <section id="features" class="scroll-mt-24 py-20 lg:py-28">
            <div class="mx-auto max-w-7xl px-5 lg:px-8">
              <div class="mx-auto max-w-2xl text-center reveal">
                <span class="inline-flex items-center gap-2 rounded-pill border border-stroke bg-shape px-4 py-1.5 text-[14px] font-medium text-muted">
                  <span class="h-1.5 w-1.5 animate-blink rounded-full bg-brand"></span>Features
                </span>
                <h2 class="mt-5 text-h2 font-semibold">
                  Everything Your Hospital<br />Needs to
                  <span class="font-display italic font-normal text-brand">Run Smarter</span>
                </h2>
                <p class="mt-4 text-[18px] text-muted">
                  From reception to pharmacy to radiology, manage every
                  department — with AI support built in at the point of care.
                </p>
              </div>

              <div class="mt-14 grid gap-6 md:grid-cols-2">
                <article class="overflow-hidden rounded-xl2 border border-stroke bg-shape reveal">
                  <div class="p-8">
                    <div class="mb-4 grid h-11 w-11 place-items-center rounded-xl bg-brand-mint text-brand">
                      <svg
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="currentColor"
                        stroke-width="2"
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        class="h-5 w-5"
                        aria-hidden="true"
                      >
                        <path d="M23 7l-7 5 7 5V7z" />
                        <rect x="1" y="5" width="15" height="14" rx="2" />
                      </svg>
                    </div>
                    <h3 class="text-h5 font-semibold">
                      Multilingual Voice Dictation
                    </h3>
                    <p class="mt-2 text-[16px] text-muted">
                      Dictate clinical notes in English, Kiswahili, or local
                      languages — transcribed straight into the patient record.
                    </p>
                  </div>
                  <img
                    src="/images/public/african-clinician-research.png"
                    alt="Doctor dictating clinical notes"
                    loading="lazy"
                    class="h-56 w-full object-cover"
                  />
                </article>

                <article class="overflow-hidden rounded-xl2 border border-stroke bg-shape reveal">
                  <div class="p-8">
                    <div class="mb-4 grid h-11 w-11 place-items-center rounded-xl bg-brand-mint text-brand">
                      <svg
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="currentColor"
                        stroke-width="2"
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        class="h-5 w-5"
                        aria-hidden="true"
                      >
                        <rect x="3" y="3" width="7" height="7" rx="1.5" />
                        <rect x="14" y="3" width="7" height="7" rx="1.5" />
                        <rect x="3" y="14" width="7" height="7" rx="1.5" />
                        <rect x="14" y="14" width="7" height="7" rx="1.5" />
                      </svg>
                    </div>
                    <h3 class="text-h5 font-semibold">AI Second-Opinion Reviewer</h3>
                    <p class="mt-2 text-[16px] text-muted">
                      An independent AI impression from triage, labs, and notes —
                      scored against the doctor's diagnosis as a decision-support
                      check.
                    </p>
                  </div>
                  <img
                    src="/images/public/african-care-coordination.png"
                    alt="Specialist reviewing medical imaging"
                    loading="lazy"
                    class="h-56 w-full object-cover"
                  />
                </article>

                <article class="overflow-hidden rounded-xl2 border border-stroke bg-shape reveal">
                  <div class="p-8">
                    <div class="mb-4 grid h-11 w-11 place-items-center rounded-xl bg-brand-mint text-brand">
                      <svg
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="currentColor"
                        stroke-width="2"
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        class="h-5 w-5"
                        aria-hidden="true"
                      >
                        <rect x="2" y="5" width="20" height="14" rx="2" />
                        <path d="M2 10h20M6 15h4" />
                      </svg>
                    </div>
                    <h3 class="text-h5 font-semibold">
                      Pharmacy &amp; Stock Management
                    </h3>
                    <p class="mt-2 text-[16px] text-muted">
                      Track drug allocation, dispensing, and stock-take flows in
                      real time, with M-Pesa and PayPal billing built in.
                    </p>
                  </div>
                  <img
                    src="/images/register.png"
                    alt="Pharmacist dispensing medication"
                    loading="lazy"
                    class="h-56 w-full object-cover"
                  />
                </article>

                <article class="overflow-hidden rounded-xl2 border border-stroke bg-shape reveal">
                  <div class="p-8">
                    <div class="mb-4 grid h-11 w-11 place-items-center rounded-xl bg-brand-mint text-brand">
                      <svg
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="currentColor"
                        stroke-width="2"
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        class="h-5 w-5"
                        aria-hidden="true"
                      >
                        <path d="M3 3v18h18" />
                        <path d="M7 15l4-5 3 3 5-7" />
                      </svg>
                    </div>
                    <h3 class="text-h5 font-semibold">
                      Labs, Radiology &amp; MOH Reporting
                    </h3>
                    <p class="mt-2 text-[16px] text-muted">
                      Manage lab and imaging orders, then let the AI mapping
                      advisor prepare your Ministry of Health reports.
                    </p>
                  </div>
                  <img
                    src="/images/public/african-diagnostic-care.png"
                    alt="Analytics charts on a screen"
                    loading="lazy"
                    class="h-56 w-full object-cover"
                  />
                </article>
              </div>
            </div>
          </section>
          
    <!-- ══════════════════════════════ WHO WE ARE ══════════════════════════════ -->
          <section id="who" class="scroll-mt-24 bg-shape py-20 lg:py-28">
            <div class="mx-auto max-w-7xl px-5 lg:px-8">
              <div class="mx-auto max-w-2xl text-center reveal">
                <span class="inline-flex items-center gap-2 rounded-pill border border-stroke bg-white px-4 py-1.5 text-[14px] font-medium text-muted">
                  <span class="h-1.5 w-1.5 animate-blink rounded-full bg-brand"></span>Who we are
                </span>
                <h2 class="mt-5 text-h2 font-semibold">
                  Built for <span class="font-display italic font-normal text-brand">Kenyan</span>
                  Hospitals
                </h2>
                <p class="mt-4 text-[18px] text-muted">
                  Built from real hospital workflows — reception to pharmacy to
                  finance — with AI support at every step.
                </p>
              </div>

              <div class="mt-14 grid items-center gap-10 lg:grid-cols-2 lg:gap-16">
                <div>
                  <h3 class="text-h3 font-semibold">
                    One system for every department, one record per patient
                  </h3>
                  <p class="mt-4 max-w-lg text-[17px] text-muted">
                    Reception, nurses, doctors, pharmacy, labs, radiology,
                    procurement, and finance all work off the same patient record
                    — no re-entry, no lost paperwork.
                  </p>
                  <a
                    href="#cta"
                    class="mt-7 inline-block rounded-pill bg-brand px-7 py-3.5 text-[16px] font-medium text-white transition hover:bg-brand-light"
                  >
                    About us
                  </a>

                  <div class="mt-12 border-t border-stroke pt-8">
                    <p class="font-display text-[clamp(2.75rem,6vw,4.25rem)] font-semibold leading-none text-brand">
                      <span id="stat-counter" data-target="12200">0</span><span class="text-brand-light">+</span>
                    </p>
                    <p class="mt-3 text-[16px] text-muted">
                      Patient visits processed on the platform
                    </p>
                  </div>
                </div>

                <img
                  src="/images/public/african-hospital-exterior.png"
                  alt="Care team reviewing patient data together"
                  loading="lazy"
                  class="h-[420px] w-full rounded-xl2 object-cover shadow-card lg:h-[520px]"
                />
              </div>
            </div>
          </section>
          
    <!-- ══════════════════════════════ STEPS (CSS-only tabs) ══════════════════════════════ -->
          <section id="steps" class="scroll-mt-24 py-20 lg:py-28">
            <div class="mx-auto max-w-7xl px-5 lg:px-8">
              <div class="mx-auto max-w-2xl text-center reveal">
                <span class="inline-flex items-center gap-2 rounded-pill border border-stroke bg-shape px-4 py-1.5 text-[14px] font-medium text-muted">
                  <span class="h-1.5 w-1.5 animate-blink rounded-full bg-brand"></span>Simple steps
                </span>
                <h2 class="mt-5 text-h2 font-semibold">
                  Get <span class="font-display italic font-normal text-brand">Set Up</span>
                  in Minutes
                </h2>
                <p class="mt-4 text-[18px] text-muted">
                  From reception to reporting — get your hospital onto Tibasasa
                  AI in three easy steps.
                </p>
              </div>
              
    <!-- Radio group replaces the Webflow tabs widget. Inputs first so `peer-checked/x:` can reach the labels and panes. -->
              <div class="mt-12">
                <input type="radio" name="step" id="step-1" class="peer/s1 sr-only" checked />
                <input type="radio" name="step" id="step-2" class="peer/s2 sr-only" />
                <input type="radio" name="step" id="step-3" class="peer/s3 sr-only" />
                
    <!-- The labels are nested, so `peer-checked` is applied to this sibling row and drilled down
               to the matching label with an arbitrary child selector. -->
                <div class="grid gap-4 border-b border-stroke sm:grid-cols-3 peer-checked/s1:[&>[for=step-1]]:border-brand peer-checked/s1:[&>[for=step-1]]:text-ink peer-checked/s2:[&>[for=step-2]]:border-brand peer-checked/s2:[&>[for=step-2]]:text-ink peer-checked/s3:[&>[for=step-3]]:border-brand peer-checked/s3:[&>[for=step-3]]:text-ink">
                  <label
                    for="step-1"
                    class="cursor-pointer border-b-2 border-transparent pb-4 text-[17px] font-medium text-muted transition"
                  >
                    1. Register Your Facility
                  </label>
                  <label
                    for="step-2"
                    class="cursor-pointer border-b-2 border-transparent pb-4 text-[17px] font-medium text-muted transition"
                  >
                    2. Load Patients &amp; Stock
                  </label>
                  <label
                    for="step-3"
                    class="cursor-pointer border-b-2 border-transparent pb-4 text-[17px] font-medium text-muted transition"
                  >
                    3. Go Live Across Departments
                  </label>
                </div>

                <div class="mt-10 hidden peer-checked/s1:block">
                  <div class="grid items-center gap-8 overflow-hidden rounded-xl2 bg-brand p-8 text-white lg:grid-cols-2 lg:p-14">
                    <div>
                      <p class="text-[14px] font-medium uppercase tracking-widest text-white/70">
                        Step 1
                      </p>
                      <h3 class="mt-3 text-h3 font-semibold">
                        Set up your hospital, departments, and staff accounts in
                        minutes.
                      </h3>
                    </div>
                    <img
                      src="/images/hero1.png"
                      alt="Account setup screen"
                      loading="lazy"
                      class="h-72 w-full rounded-xl2 object-cover"
                    />
                  </div>
                </div>

                <div class="mt-10 hidden peer-checked/s2:block">
                  <div class="grid items-center gap-8 overflow-hidden rounded-xl2 bg-brand p-8 text-white lg:grid-cols-2 lg:p-14">
                    <div>
                      <p class="text-[14px] font-medium uppercase tracking-widest text-white/70">
                        Step 2
                      </p>
                      <h3 class="mt-3 text-h3 font-semibold">
                        Import Patient Records and Pharmacy Stock
                      </h3>
                    </div>
                    <img
                      src="/images/why.png"
                      alt="Structured patient data table"
                      loading="lazy"
                      class="h-72 w-full rounded-xl2 object-cover"
                    />
                  </div>
                </div>

                <div class="mt-10 hidden peer-checked/s3:block">
                  <div class="grid items-center gap-8 overflow-hidden rounded-xl2 bg-brand p-8 text-white lg:grid-cols-2 lg:p-14">
                    <div>
                      <p class="text-[14px] font-medium uppercase tracking-widest text-white/70">
                        Step 3
                      </p>
                      <h3 class="mt-3 text-h3 font-semibold">
                        Reception, Doctors, and Pharmacy All Working from Day One
                      </h3>
                    </div>
                    <img
                      src="/images/public/african-surgical-team.png"
                      alt="Patient booking an appointment"
                      loading="lazy"
                      class="h-72 w-full rounded-xl2 object-cover"
                    />
                  </div>
                </div>
              </div>
            </div>
          </section>
          
    <!-- ══════════════════════════════ BENEFITS ══════════════════════════════ -->
          <section id="benefits" class="scroll-mt-24 bg-shape py-20 lg:py-28">
            <div class="mx-auto max-w-7xl px-5 lg:px-8">
              <div class="mx-auto max-w-2xl text-center reveal">
                <span class="inline-flex items-center gap-2 rounded-pill border border-stroke bg-white px-4 py-1.5 text-[14px] font-medium text-muted">
                  <span class="h-1.5 w-1.5 animate-blink rounded-full bg-brand"></span>Benefits
                </span>
                <h2 class="mt-5 text-h2 font-semibold">
                  Empowering
                  <span class="font-display italic font-normal text-brand">Every Department</span>
                </h2>
                <p class="mt-4 text-[18px] text-muted">
                  Purpose-built tools for doctors, pharmacy teams, and hospital
                  administrators.
                </p>
              </div>

              <div class="mt-14 space-y-6">
                <article class="grid items-center gap-8 rounded-xl2 border border-stroke bg-white p-6 lg:grid-cols-2 lg:p-10 reveal">
                  <div>
                    <span class="inline-flex items-center gap-2 rounded-pill bg-brand-mint px-4 py-1.5 text-[14px] font-medium text-brand">
                      For doctors
                    </span>
                    <h3 class="mt-5 text-h4 font-semibold">
                      Notes and diagnoses, backed by AI
                    </h3>
                    <p class="mt-3 text-[16px] text-muted">
                      Dictate notes in your own language and get an independent AI
                      clinical impression before you finalize a diagnosis.
                    </p>
                    <ul class="mt-6 space-y-3 text-[16px] text-muted">
                      <li class="flex gap-3">
                        <svg
                          viewBox="0 0 24 24"
                          fill="none"
                          stroke="#0C2765"
                          stroke-width="2"
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          class="mt-1 h-4 w-4 shrink-0"
                          aria-hidden="true"
                        >
                          <path d="M20 6 9 17l-5-5" />
                        </svg>
                        <span>
                          <strong class="font-medium text-ink">Dictate notes hands-free.</strong>
                          Speak your clinical notes in English, Kiswahili, or a
                          local language and have them transcribed instantly.
                        </span>
                      </li>
                      <li class="flex gap-3">
                        <svg
                          viewBox="0 0 24 24"
                          fill="none"
                          stroke="#0C2765"
                          stroke-width="2"
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          class="mt-1 h-4 w-4 shrink-0"
                          aria-hidden="true"
                        >
                          <path d="M20 6 9 17l-5-5" />
                        </svg>
                        <span>
                          <strong class="font-medium text-ink">
                            Get a second opinion, instantly.
                          </strong>
                          The AI reviewer forms its own impression from triage and
                          labs, then flags where it disagrees with your
                          diagnosis.
                        </span>
                      </li>
                    </ul>
                  </div>
                  <img
                    src="/images/public/african-clinician-research.png"
                    alt="Doctor reviewing a patient chart"
                    loading="lazy"
                    class="h-80 w-full rounded-xl2 object-cover"
                  />
                </article>

                <article class="grid items-center gap-8 rounded-xl2 border border-stroke bg-white p-6 lg:grid-cols-2 lg:p-10 reveal">
                  <img
                    src="/images/public/african-hospital-reception.png"
                    alt="Hospital department corridor"
                    loading="lazy"
                    class="h-80 w-full rounded-xl2 object-cover lg:order-last"
                  />
                  <div>
                    <span class="inline-flex items-center gap-2 rounded-pill bg-brand-mint px-4 py-1.5 text-[14px] font-medium text-brand">
                      For Pharmacy &amp; Stock Teams
                    </span>
                    <h3 class="mt-5 text-h4 font-semibold">
                      Dispensing and stock, always accounted for
                    </h3>
                    <p class="mt-3 text-[16px] text-muted">
                      Track drug allocation and stock-take flows in real time, and
                      reconcile billing across M-Pesa and PayPal without manual
                      spreadsheets.
                    </p>
                    <ul class="mt-6 space-y-3 text-[16px] text-muted">
                      <li class="flex gap-3">
                        <svg
                          viewBox="0 0 24 24"
                          fill="none"
                          stroke="#0C2765"
                          stroke-width="2"
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          class="mt-1 h-4 w-4 shrink-0"
                          aria-hidden="true"
                        >
                          <path d="M20 6 9 17l-5-5" />
                        </svg>
                        <span>
                          <strong class="font-medium text-ink">
                            Dispense with a full audit trail.
                          </strong>
                          Every allocation and dispense event is logged against
                          the patient and the stock record.
                        </span>
                      </li>
                      <li class="flex gap-3">
                        <svg
                          viewBox="0 0 24 24"
                          fill="none"
                          stroke="#0C2765"
                          stroke-width="2"
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          class="mt-1 h-4 w-4 shrink-0"
                          aria-hidden="true"
                        >
                          <path d="M20 6 9 17l-5-5" />
                        </svg>
                        <span>
                          <strong class="font-medium text-ink">
                            Catch stock issues before they bite.
                          </strong>
                          Run stock-takes and see discrepancies as they happen,
                          not at month-end.
                        </span>
                      </li>
                    </ul>
                  </div>
                </article>

                <article class="grid items-center gap-8 rounded-xl2 border border-stroke bg-white p-6 lg:grid-cols-2 lg:p-10 reveal">
                  <div>
                    <span class="inline-flex items-center gap-2 rounded-pill bg-brand-mint px-4 py-1.5 text-[14px] font-medium text-brand">
                      For Administrators
                    </span>
                    <h3 class="mt-5 text-h4 font-semibold">
                      Compliance and reporting, handled
                    </h3>
                    <p class="mt-3 text-[16px] text-muted">
                      Audit logs, MOH reporting, and finance run alongside
                      clinical operations — with an AI mapping advisor to prep
                      Ministry of Health submissions.
                    </p>
                    <ul class="mt-6 space-y-3 text-[16px] text-muted">
                      <li class="flex gap-3">
                        <svg
                          viewBox="0 0 24 24"
                          fill="none"
                          stroke="#0C2765"
                          stroke-width="2"
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          class="mt-1 h-4 w-4 shrink-0"
                          aria-hidden="true"
                        >
                          <path d="M20 6 9 17l-5-5" />
                        </svg>
                        <span>
                          <strong class="font-medium text-ink">
                            Generate MOH reports in minutes.
                          </strong>
                          The AI mapping advisor maps your clinic data into the
                          right reporting format automatically.
                        </span>
                      </li>
                      <li class="flex gap-3">
                        <svg
                          viewBox="0 0 24 24"
                          fill="none"
                          stroke="#0C2765"
                          stroke-width="2"
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          class="mt-1 h-4 w-4 shrink-0"
                          aria-hidden="true"
                        >
                          <path d="M20 6 9 17l-5-5" />
                        </svg>
                        <span>
                          <strong class="font-medium text-ink">See everything, end to end.</strong>
                          Audit logs cover every department, from reception to
                          procurement to finance.
                        </span>
                      </li>
                    </ul>
                  </div>
                  <img
                    src="/images/public/african-surgical-team.png"
                    alt="Patient checking results on a phone"
                    loading="lazy"
                    class="h-80 w-full rounded-xl2 object-cover"
                  />
                </article>
              </div>
            </div>
          </section>
          
    <!-- ══════════════════════════════ SHOWCASE / TESTIMONIALS ══════════════════════════════ -->
          <section id="showcase" class="scroll-mt-24 py-20 lg:py-28">
            <div class="mx-auto max-w-7xl px-5 lg:px-8">
              <div class="mx-auto max-w-2xl text-center reveal">
                <span class="inline-flex items-center gap-2 rounded-pill border border-stroke bg-shape px-4 py-1.5 text-[14px] font-medium text-muted">
                  <span class="h-1.5 w-1.5 animate-blink rounded-full bg-brand"></span>Showcase
                </span>
                <h2 class="mt-5 text-h2 font-semibold">
                  <span class="font-display italic font-normal text-brand">Trusted</span>
                  by Doctors, <span class="font-display italic font-normal text-brand">Loved</span>
                  by Patients
                </h2>
                <p class="mt-4 text-[18px] text-muted">
                  Real stories from medical professionals and patients who've
                  experienced the difference.
                </p>
              </div>
              
    <!-- Each column duplicates its cards so the -50% translate loops seamlessly. -->
              <div class="mask-y mt-14 grid max-h-[680px] grid-cols-1 gap-6 overflow-hidden md:grid-cols-2 lg:grid-cols-3">
                <div class="flex animate-marquee-y flex-col [animation-duration:46s] [&_figure]:mb-6">
                  <figure class="rounded-xl2 border border-stroke bg-shape p-7">
                    <blockquote class="text-[16px] leading-relaxed text-ink/85">
                      "This platform has completely transformed how we manage patient flow.
                      The reporting and stock insights are a game-changer for our
                      clinic."
                    </blockquote>
                    <figcaption class="mt-5 flex items-center gap-3">
                      <img
                        src="data:image/svg+xml,%3Csvg%20xmlns%3D%27http%3A//www.w3.org/2000/svg%27%20viewBox%3D%270%200%2096%2096%27%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27%230C2765%27/%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27none%27%20stroke%3D%27%2352B2D8%27%20stroke-width%3D%273%27/%3E%3Ctext%20x%3D%2748%27%20y%3D%2761%27%20font-family%3D%27Arial%2C%20sans-serif%27%20font-size%3D%2730%27%20font-weight%3D%27700%27%20fill%3D%27%23ffffff%27%20text-anchor%3D%27middle%27%3EIC%3C/text%3E%3C/svg%3E"
                        alt=""
                        loading="lazy"
                        class="h-10 w-10 rounded-full object-cover"
                      />
                      <span class="text-[15px] font-medium">
                        Isabella Chen, Hospital Administrator
                      </span>
                    </figcaption>
                  </figure>
                  <figure class="rounded-xl2 border border-stroke bg-shape p-7">
                    <blockquote class="text-[16px] leading-relaxed text-ink/85">
                      "Handover between shifts has never been smoother. The shared patient
                      record keeps doctors, nurses, and pharmacy aligned."
                    </blockquote>
                    <figcaption class="mt-5 flex items-center gap-3">
                      <img
                        src="data:image/svg+xml,%3Csvg%20xmlns%3D%27http%3A//www.w3.org/2000/svg%27%20viewBox%3D%270%200%2096%2096%27%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27%230C2765%27/%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27none%27%20stroke%3D%27%2352B2D8%27%20stroke-width%3D%273%27/%3E%3Ctext%20x%3D%2748%27%20y%3D%2761%27%20font-family%3D%27Arial%2C%20sans-serif%27%20font-size%3D%2730%27%20font-weight%3D%27700%27%20fill%3D%27%23ffffff%27%20text-anchor%3D%27middle%27%3ELG%3C/text%3E%3C/svg%3E"
                        alt=""
                        loading="lazy"
                        class="h-10 w-10 rounded-full object-cover"
                      /><span class="text-[15px] font-medium">Liam Goldberg, Head of Nursing</span>
                    </figcaption>
                  </figure>
                  <figure class="rounded-xl2 border border-stroke bg-shape p-7">
                    <blockquote class="text-[16px] leading-relaxed text-ink/85">
                      "We've cut charting time by nearly half since adopting voice
                      dictation. The AI doc reviewer catches things we'd otherwise
                      miss."
                    </blockquote>
                    <figcaption class="mt-5 flex items-center gap-3">
                      <img
                        src="data:image/svg+xml,%3Csvg%20xmlns%3D%27http%3A//www.w3.org/2000/svg%27%20viewBox%3D%270%200%2096%2096%27%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27%230C2765%27/%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27none%27%20stroke%3D%27%2352B2D8%27%20stroke-width%3D%273%27/%3E%3Ctext%20x%3D%2748%27%20y%3D%2761%27%20font-family%3D%27Arial%2C%20sans-serif%27%20font-size%3D%2730%27%20font-weight%3D%27700%27%20fill%3D%27%23ffffff%27%20text-anchor%3D%27middle%27%3ESR%3C/text%3E%3C/svg%3E"
                        alt=""
                        loading="lazy"
                        class="h-10 w-10 rounded-full object-cover"
                      />
                      <span class="text-[15px] font-medium">
                        Dr. Sophia Rodriguez, Consultant Physician
                      </span>
                    </figcaption>
                  </figure>
                  <figure class="rounded-xl2 border border-stroke bg-shape p-7">
                    <blockquote class="text-[16px] leading-relaxed text-ink/85">
                      "The MOH reporting used to take our team days. Now the AI mapping
                      advisor prepares it in minutes, and it's accurate."
                    </blockquote>
                    <figcaption class="mt-5 flex items-center gap-3">
                      <img
                        src="data:image/svg+xml,%3Csvg%20xmlns%3D%27http%3A//www.w3.org/2000/svg%27%20viewBox%3D%270%200%2096%2096%27%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27%230C2765%27/%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27none%27%20stroke%3D%27%2352B2D8%27%20stroke-width%3D%273%27/%3E%3Ctext%20x%3D%2748%27%20y%3D%2761%27%20font-family%3D%27Arial%2C%20sans-serif%27%20font-size%3D%2730%27%20font-weight%3D%27700%27%20fill%3D%27%23ffffff%27%20text-anchor%3D%27middle%27%3ENP%3C/text%3E%3C/svg%3E"
                        alt=""
                        loading="lazy"
                        class="h-10 w-10 rounded-full object-cover"
                      /><span class="text-[15px] font-medium">Noah Patel, Reporting Officer</span>
                    </figcaption>
                  </figure>
                  <div aria-hidden="true" class="contents">
                    <figure class="rounded-xl2 border border-stroke bg-shape p-7">
                      <blockquote class="text-[16px] leading-relaxed text-ink/85">
                        "This platform has completely transformed how we manage patient flow.
                        The reporting and stock insights are a game-changer for
                        our clinic."
                      </blockquote>
                      <figcaption class="mt-5 flex items-center gap-3">
                        <img
                          src="data:image/svg+xml,%3Csvg%20xmlns%3D%27http%3A//www.w3.org/2000/svg%27%20viewBox%3D%270%200%2096%2096%27%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27%230C2765%27/%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27none%27%20stroke%3D%27%2352B2D8%27%20stroke-width%3D%273%27/%3E%3Ctext%20x%3D%2748%27%20y%3D%2761%27%20font-family%3D%27Arial%2C%20sans-serif%27%20font-size%3D%2730%27%20font-weight%3D%27700%27%20fill%3D%27%23ffffff%27%20text-anchor%3D%27middle%27%3EIC%3C/text%3E%3C/svg%3E"
                          alt=""
                          loading="lazy"
                          class="h-10 w-10 rounded-full object-cover"
                        />
                        <span class="text-[15px] font-medium">
                          Isabella Chen, Hospital Administrator
                        </span>
                      </figcaption>
                    </figure>
                    <figure class="rounded-xl2 border border-stroke bg-shape p-7">
                      <blockquote class="text-[16px] leading-relaxed text-ink/85">
                        "Handover between shifts has never been smoother. The shared
                        patient record keeps doctors, nurses, and pharmacy
                        aligned."
                      </blockquote>
                      <figcaption class="mt-5 flex items-center gap-3">
                        <img
                          src="data:image/svg+xml,%3Csvg%20xmlns%3D%27http%3A//www.w3.org/2000/svg%27%20viewBox%3D%270%200%2096%2096%27%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27%230C2765%27/%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27none%27%20stroke%3D%27%2352B2D8%27%20stroke-width%3D%273%27/%3E%3Ctext%20x%3D%2748%27%20y%3D%2761%27%20font-family%3D%27Arial%2C%20sans-serif%27%20font-size%3D%2730%27%20font-weight%3D%27700%27%20fill%3D%27%23ffffff%27%20text-anchor%3D%27middle%27%3ELG%3C/text%3E%3C/svg%3E"
                          alt=""
                          loading="lazy"
                          class="h-10 w-10 rounded-full object-cover"
                        /><span class="text-[15px] font-medium">Liam Goldberg, Head of Nursing</span>
                      </figcaption>
                    </figure>
                    <figure class="rounded-xl2 border border-stroke bg-shape p-7">
                      <blockquote class="text-[16px] leading-relaxed text-ink/85">
                        "We've cut charting time by nearly half since adopting voice
                        dictation. The AI doc reviewer catches things we'd
                        otherwise miss."
                      </blockquote>
                      <figcaption class="mt-5 flex items-center gap-3">
                        <img
                          src="data:image/svg+xml,%3Csvg%20xmlns%3D%27http%3A//www.w3.org/2000/svg%27%20viewBox%3D%270%200%2096%2096%27%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27%230C2765%27/%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27none%27%20stroke%3D%27%2352B2D8%27%20stroke-width%3D%273%27/%3E%3Ctext%20x%3D%2748%27%20y%3D%2761%27%20font-family%3D%27Arial%2C%20sans-serif%27%20font-size%3D%2730%27%20font-weight%3D%27700%27%20fill%3D%27%23ffffff%27%20text-anchor%3D%27middle%27%3ESR%3C/text%3E%3C/svg%3E"
                          alt=""
                          loading="lazy"
                          class="h-10 w-10 rounded-full object-cover"
                        />
                        <span class="text-[15px] font-medium">
                          Dr. Sophia Rodriguez, Consultant Physician
                        </span>
                      </figcaption>
                    </figure>
                    <figure class="rounded-xl2 border border-stroke bg-shape p-7">
                      <blockquote class="text-[16px] leading-relaxed text-ink/85">
                        "The MOH reporting used to take our team days. Now the AI mapping
                        advisor prepares it in minutes, and it's accurate."
                      </blockquote>
                      <figcaption class="mt-5 flex items-center gap-3">
                        <img
                          src="data:image/svg+xml,%3Csvg%20xmlns%3D%27http%3A//www.w3.org/2000/svg%27%20viewBox%3D%270%200%2096%2096%27%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27%230C2765%27/%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27none%27%20stroke%3D%27%2352B2D8%27%20stroke-width%3D%273%27/%3E%3Ctext%20x%3D%2748%27%20y%3D%2761%27%20font-family%3D%27Arial%2C%20sans-serif%27%20font-size%3D%2730%27%20font-weight%3D%27700%27%20fill%3D%27%23ffffff%27%20text-anchor%3D%27middle%27%3ENP%3C/text%3E%3C/svg%3E"
                          alt=""
                          loading="lazy"
                          class="h-10 w-10 rounded-full object-cover"
                        /><span class="text-[15px] font-medium">Noah Patel, Reporting Officer</span>
                      </figcaption>
                    </figure>
                  </div>
                </div>

                <div class="hidden animate-marquee-y flex-col [animation-duration:38s] md:flex [&_figure]:mb-6">
                  <figure class="rounded-xl2 border border-stroke bg-shape p-7">
                    <blockquote class="text-[16px] leading-relaxed text-ink/85">
                      "The dispensing workflow has saved us countless hours. Our
                      pharmacists can focus on patients instead of paperwork."
                    </blockquote>
                    <figcaption class="mt-5 flex items-center gap-3">
                      <img
                        src="data:image/svg+xml,%3Csvg%20xmlns%3D%27http%3A//www.w3.org/2000/svg%27%20viewBox%3D%270%200%2096%2096%27%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27%230C2765%27/%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27none%27%20stroke%3D%27%2352B2D8%27%20stroke-width%3D%273%27/%3E%3Ctext%20x%3D%2748%27%20y%3D%2761%27%20font-family%3D%27Arial%2C%20sans-serif%27%20font-size%3D%2730%27%20font-weight%3D%27700%27%20fill%3D%27%23ffffff%27%20text-anchor%3D%27middle%27%3EBC%3C/text%3E%3C/svg%3E"
                        alt=""
                        loading="lazy"
                        class="h-10 w-10 rounded-full object-cover"
                      /><span class="text-[15px] font-medium">Ben Carter, Chief Pharmacist</span>
                    </figcaption>
                  </figure>
                  <figure class="rounded-xl2 border border-stroke bg-shape p-7">
                    <blockquote class="text-[16px] leading-relaxed text-ink/85">
                      "The onboarding process was seamless, and the support team is
                      always responsive. A fantastic platform backed by a
                      fantastic team."
                    </blockquote>
                    <figcaption class="mt-5 flex items-center gap-3">
                      <img
                        src="data:image/svg+xml,%3Csvg%20xmlns%3D%27http%3A//www.w3.org/2000/svg%27%20viewBox%3D%270%200%2096%2096%27%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27%230C2765%27/%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27none%27%20stroke%3D%27%2352B2D8%27%20stroke-width%3D%273%27/%3E%3Ctext%20x%3D%2748%27%20y%3D%2761%27%20font-family%3D%27Arial%2C%20sans-serif%27%20font-size%3D%2730%27%20font-weight%3D%27700%27%20fill%3D%27%23ffffff%27%20text-anchor%3D%27middle%27%3EJK%3C/text%3E%3C/svg%3E"
                        alt=""
                        loading="lazy"
                        class="h-10 w-10 rounded-full object-cover"
                      /><span class="text-[15px] font-medium">James Kim, Hospital Director</span>
                    </figcaption>
                  </figure>
                  <figure class="rounded-xl2 border border-stroke bg-shape p-7">
                    <blockquote class="text-[16px] leading-relaxed text-ink/85">
                      "I was skeptical about another 'all-in-one' system, but this one
                      actually delivers. It has replaced three other tools our
                      team was using."
                    </blockquote>
                    <figcaption class="mt-5 flex items-center gap-3">
                      <img
                        src="data:image/svg+xml,%3Csvg%20xmlns%3D%27http%3A//www.w3.org/2000/svg%27%20viewBox%3D%270%200%2096%2096%27%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27%230C2765%27/%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27none%27%20stroke%3D%27%2352B2D8%27%20stroke-width%3D%273%27/%3E%3Ctext%20x%3D%2748%27%20y%3D%2761%27%20font-family%3D%27Arial%2C%20sans-serif%27%20font-size%3D%2730%27%20font-weight%3D%27700%27%20fill%3D%27%23ffffff%27%20text-anchor%3D%27middle%27%3ECD%3C/text%3E%3C/svg%3E"
                        alt=""
                        loading="lazy"
                        class="h-10 w-10 rounded-full object-cover"
                      /><span class="text-[15px] font-medium">Charlotte Dubois, Lab Supervisor</span>
                    </figcaption>
                  </figure>
                  <figure class="rounded-xl2 border border-stroke bg-shape p-7">
                    <blockquote class="text-[16px] leading-relaxed text-ink/85">
                      "The ability to track stock and dispensing in real time has
                      transformed our procurement planning."
                    </blockquote>
                    <figcaption class="mt-5 flex items-center gap-3">
                      <img
                        src="data:image/svg+xml,%3Csvg%20xmlns%3D%27http%3A//www.w3.org/2000/svg%27%20viewBox%3D%270%200%2096%2096%27%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27%230C2765%27/%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27none%27%20stroke%3D%27%2352B2D8%27%20stroke-width%3D%273%27/%3E%3Ctext%20x%3D%2748%27%20y%3D%2761%27%20font-family%3D%27Arial%2C%20sans-serif%27%20font-size%3D%2730%27%20font-weight%3D%27700%27%20fill%3D%27%23ffffff%27%20text-anchor%3D%27middle%27%3ELM%3C/text%3E%3C/svg%3E"
                        alt=""
                        loading="lazy"
                        class="h-10 w-10 rounded-full object-cover"
                      /><span class="text-[15px] font-medium">Lucas Martinez, Procurement Lead</span>
                    </figcaption>
                  </figure>
                  <div aria-hidden="true" class="contents">
                    <figure class="rounded-xl2 border border-stroke bg-shape p-7">
                      <blockquote class="text-[16px] leading-relaxed text-ink/85">
                        "The dispensing workflow has saved us countless hours. Our
                        pharmacists can focus on patients instead of paperwork."
                      </blockquote>
                      <figcaption class="mt-5 flex items-center gap-3">
                        <img
                          src="data:image/svg+xml,%3Csvg%20xmlns%3D%27http%3A//www.w3.org/2000/svg%27%20viewBox%3D%270%200%2096%2096%27%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27%230C2765%27/%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27none%27%20stroke%3D%27%2352B2D8%27%20stroke-width%3D%273%27/%3E%3Ctext%20x%3D%2748%27%20y%3D%2761%27%20font-family%3D%27Arial%2C%20sans-serif%27%20font-size%3D%2730%27%20font-weight%3D%27700%27%20fill%3D%27%23ffffff%27%20text-anchor%3D%27middle%27%3EBC%3C/text%3E%3C/svg%3E"
                          alt=""
                          loading="lazy"
                          class="h-10 w-10 rounded-full object-cover"
                        /><span class="text-[15px] font-medium">Ben Carter, Chief Pharmacist</span>
                      </figcaption>
                    </figure>
                    <figure class="rounded-xl2 border border-stroke bg-shape p-7">
                      <blockquote class="text-[16px] leading-relaxed text-ink/85">
                        "The onboarding process was seamless, and the support team
                        is always responsive. A fantastic platform backed by a
                        fantastic team."
                      </blockquote>
                      <figcaption class="mt-5 flex items-center gap-3">
                        <img
                          src="data:image/svg+xml,%3Csvg%20xmlns%3D%27http%3A//www.w3.org/2000/svg%27%20viewBox%3D%270%200%2096%2096%27%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27%230C2765%27/%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27none%27%20stroke%3D%27%2352B2D8%27%20stroke-width%3D%273%27/%3E%3Ctext%20x%3D%2748%27%20y%3D%2761%27%20font-family%3D%27Arial%2C%20sans-serif%27%20font-size%3D%2730%27%20font-weight%3D%27700%27%20fill%3D%27%23ffffff%27%20text-anchor%3D%27middle%27%3EJK%3C/text%3E%3C/svg%3E"
                          alt=""
                          loading="lazy"
                          class="h-10 w-10 rounded-full object-cover"
                        /><span class="text-[15px] font-medium">James Kim, Hospital Director</span>
                      </figcaption>
                    </figure>
                    <figure class="rounded-xl2 border border-stroke bg-shape p-7">
                      <blockquote class="text-[16px] leading-relaxed text-ink/85">
                        "I was skeptical about another 'all-in-one' system, but this
                        one actually delivers. It has replaced three other tools
                        our team was using."
                      </blockquote>
                      <figcaption class="mt-5 flex items-center gap-3">
                        <img
                          src="data:image/svg+xml,%3Csvg%20xmlns%3D%27http%3A//www.w3.org/2000/svg%27%20viewBox%3D%270%200%2096%2096%27%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27%230C2765%27/%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27none%27%20stroke%3D%27%2352B2D8%27%20stroke-width%3D%273%27/%3E%3Ctext%20x%3D%2748%27%20y%3D%2761%27%20font-family%3D%27Arial%2C%20sans-serif%27%20font-size%3D%2730%27%20font-weight%3D%27700%27%20fill%3D%27%23ffffff%27%20text-anchor%3D%27middle%27%3ECD%3C/text%3E%3C/svg%3E"
                          alt=""
                          loading="lazy"
                          class="h-10 w-10 rounded-full object-cover"
                        />
                        <span class="text-[15px] font-medium">
                          Charlotte Dubois, Lab Supervisor
                        </span>
                      </figcaption>
                    </figure>
                    <figure class="rounded-xl2 border border-stroke bg-shape p-7">
                      <blockquote class="text-[16px] leading-relaxed text-ink/85">
                        "The ability to track stock and dispensing in real time has
                        transformed our procurement planning."
                      </blockquote>
                      <figcaption class="mt-5 flex items-center gap-3">
                        <img
                          src="data:image/svg+xml,%3Csvg%20xmlns%3D%27http%3A//www.w3.org/2000/svg%27%20viewBox%3D%270%200%2096%2096%27%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27%230C2765%27/%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27none%27%20stroke%3D%27%2352B2D8%27%20stroke-width%3D%273%27/%3E%3Ctext%20x%3D%2748%27%20y%3D%2761%27%20font-family%3D%27Arial%2C%20sans-serif%27%20font-size%3D%2730%27%20font-weight%3D%27700%27%20fill%3D%27%23ffffff%27%20text-anchor%3D%27middle%27%3ELM%3C/text%3E%3C/svg%3E"
                          alt=""
                          loading="lazy"
                          class="h-10 w-10 rounded-full object-cover"
                        />
                        <span class="text-[15px] font-medium">
                          Lucas Martinez, Procurement Lead
                        </span>
                      </figcaption>
                    </figure>
                  </div>
                </div>

                <div class="hidden animate-marquee-y flex-col [animation-duration:52s] lg:flex [&_figure]:mb-6">
                  <figure class="rounded-xl2 border border-stroke bg-shape p-7">
                    <blockquote class="text-[16px] leading-relaxed text-ink/85">
                      "A must-have for any modern hospital. It simplifies complexity and
                      empowers our team to deliver exceptional care."
                    </blockquote>
                    <figcaption class="mt-5 flex items-center gap-3">
                      <img
                        src="data:image/svg+xml,%3Csvg%20xmlns%3D%27http%3A//www.w3.org/2000/svg%27%20viewBox%3D%270%200%2096%2096%27%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27%230C2765%27/%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27none%27%20stroke%3D%27%2352B2D8%27%20stroke-width%3D%273%27/%3E%3Ctext%20x%3D%2748%27%20y%3D%2761%27%20font-family%3D%27Arial%2C%20sans-serif%27%20font-size%3D%2730%27%20font-weight%3D%27700%27%20fill%3D%27%23ffffff%27%20text-anchor%3D%27middle%27%3EMT%3C/text%3E%3C/svg%3E"
                        alt=""
                        loading="lazy"
                        class="h-10 w-10 rounded-full object-cover"
                      /><span class="text-[15px] font-medium">Mia Thompson, Radiology Lead</span>
                    </figcaption>
                  </figure>
                  <figure class="rounded-xl2 border border-stroke bg-shape p-7">
                    <blockquote class="text-[16px] leading-relaxed text-ink/85">
                      "This platform helped us streamline our entire billing process,
                      cutting reconciliation time by more than half."
                    </blockquote>
                    <figcaption class="mt-5 flex items-center gap-3">
                      <img
                        src="data:image/svg+xml,%3Csvg%20xmlns%3D%27http%3A//www.w3.org/2000/svg%27%20viewBox%3D%270%200%2096%2096%27%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27%230C2765%27/%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27none%27%20stroke%3D%27%2352B2D8%27%20stroke-width%3D%273%27/%3E%3Ctext%20x%3D%2748%27%20y%3D%2761%27%20font-family%3D%27Arial%2C%20sans-serif%27%20font-size%3D%2730%27%20font-weight%3D%27700%27%20fill%3D%27%23ffffff%27%20text-anchor%3D%27middle%27%3EOF%3C/text%3E%3C/svg%3E"
                        alt=""
                        loading="lazy"
                        class="h-10 w-10 rounded-full object-cover"
                      /><span class="text-[15px] font-medium">Olivia Fischer, Finance Officer</span>
                    </figcaption>
                  </figure>
                  <figure class="rounded-xl2 border border-stroke bg-shape p-7">
                    <blockquote class="text-[16px] leading-relaxed text-ink/85">
                      "The patient database is incredibly comprehensive and up-to-date.
                      It's made finding the right records so much easier."
                    </blockquote>
                    <figcaption class="mt-5 flex items-center gap-3">
                      <img
                        src="data:image/svg+xml,%3Csvg%20xmlns%3D%27http%3A//www.w3.org/2000/svg%27%20viewBox%3D%270%200%2096%2096%27%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27%230C2765%27/%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27none%27%20stroke%3D%27%2352B2D8%27%20stroke-width%3D%273%27/%3E%3Ctext%20x%3D%2748%27%20y%3D%2761%27%20font-family%3D%27Arial%2C%20sans-serif%27%20font-size%3D%2730%27%20font-weight%3D%27700%27%20fill%3D%27%23ffffff%27%20text-anchor%3D%27middle%27%3EGL%3C/text%3E%3C/svg%3E"
                        alt=""
                        loading="lazy"
                        class="h-10 w-10 rounded-full object-cover"
                      /><span class="text-[15px] font-medium">Grace Lee, Reception Lead</span>
                    </figcaption>
                  </figure>
                  <figure class="rounded-xl2 border border-stroke bg-shape p-7">
                    <blockquote class="text-[16px] leading-relaxed text-ink/85">
                      "It's rare to find a system that is both powerful for administrators
                      and easy to use for the whole team. This is it."
                    </blockquote>
                    <figcaption class="mt-5 flex items-center gap-3">
                      <img
                        src="data:image/svg+xml,%3Csvg%20xmlns%3D%27http%3A//www.w3.org/2000/svg%27%20viewBox%3D%270%200%2096%2096%27%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27%230C2765%27/%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27none%27%20stroke%3D%27%2352B2D8%27%20stroke-width%3D%273%27/%3E%3Ctext%20x%3D%2748%27%20y%3D%2761%27%20font-family%3D%27Arial%2C%20sans-serif%27%20font-size%3D%2730%27%20font-weight%3D%27700%27%20fill%3D%27%23ffffff%27%20text-anchor%3D%27middle%27%3EHW%3C/text%3E%3C/svg%3E"
                        alt=""
                        loading="lazy"
                        class="h-10 w-10 rounded-full object-cover"
                      /><span class="text-[15px] font-medium">Hannah Wright, Triage Nurse</span>
                    </figcaption>
                  </figure>
                  <div aria-hidden="true" class="contents">
                    <figure class="rounded-xl2 border border-stroke bg-shape p-7">
                      <blockquote class="text-[16px] leading-relaxed text-ink/85">
                        "A must-have for any modern hospital. It simplifies complexity
                        and empowers our team to deliver exceptional care."
                      </blockquote>
                      <figcaption class="mt-5 flex items-center gap-3">
                        <img
                          src="data:image/svg+xml,%3Csvg%20xmlns%3D%27http%3A//www.w3.org/2000/svg%27%20viewBox%3D%270%200%2096%2096%27%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27%230C2765%27/%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27none%27%20stroke%3D%27%2352B2D8%27%20stroke-width%3D%273%27/%3E%3Ctext%20x%3D%2748%27%20y%3D%2761%27%20font-family%3D%27Arial%2C%20sans-serif%27%20font-size%3D%2730%27%20font-weight%3D%27700%27%20fill%3D%27%23ffffff%27%20text-anchor%3D%27middle%27%3EMT%3C/text%3E%3C/svg%3E"
                          alt=""
                          loading="lazy"
                          class="h-10 w-10 rounded-full object-cover"
                        /><span class="text-[15px] font-medium">Mia Thompson, Radiology Lead</span>
                      </figcaption>
                    </figure>
                    <figure class="rounded-xl2 border border-stroke bg-shape p-7">
                      <blockquote class="text-[16px] leading-relaxed text-ink/85">
                        "This platform helped us streamline our entire billing process,
                        cutting reconciliation time by more than half."
                      </blockquote>
                      <figcaption class="mt-5 flex items-center gap-3">
                        <img
                          src="data:image/svg+xml,%3Csvg%20xmlns%3D%27http%3A//www.w3.org/2000/svg%27%20viewBox%3D%270%200%2096%2096%27%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27%230C2765%27/%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27none%27%20stroke%3D%27%2352B2D8%27%20stroke-width%3D%273%27/%3E%3Ctext%20x%3D%2748%27%20y%3D%2761%27%20font-family%3D%27Arial%2C%20sans-serif%27%20font-size%3D%2730%27%20font-weight%3D%27700%27%20fill%3D%27%23ffffff%27%20text-anchor%3D%27middle%27%3EOF%3C/text%3E%3C/svg%3E"
                          alt=""
                          loading="lazy"
                          class="h-10 w-10 rounded-full object-cover"
                        /><span class="text-[15px] font-medium">Olivia Fischer, Finance Officer</span>
                      </figcaption>
                    </figure>
                    <figure class="rounded-xl2 border border-stroke bg-shape p-7">
                      <blockquote class="text-[16px] leading-relaxed text-ink/85">
                        "The patient database is incredibly comprehensive and
                        up-to-date. It's made finding the right records so much
                        easier."
                      </blockquote>
                      <figcaption class="mt-5 flex items-center gap-3">
                        <img
                          src="data:image/svg+xml,%3Csvg%20xmlns%3D%27http%3A//www.w3.org/2000/svg%27%20viewBox%3D%270%200%2096%2096%27%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27%230C2765%27/%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27none%27%20stroke%3D%27%2352B2D8%27%20stroke-width%3D%273%27/%3E%3Ctext%20x%3D%2748%27%20y%3D%2761%27%20font-family%3D%27Arial%2C%20sans-serif%27%20font-size%3D%2730%27%20font-weight%3D%27700%27%20fill%3D%27%23ffffff%27%20text-anchor%3D%27middle%27%3EGL%3C/text%3E%3C/svg%3E"
                          alt=""
                          loading="lazy"
                          class="h-10 w-10 rounded-full object-cover"
                        /><span class="text-[15px] font-medium">Grace Lee, Reception Lead</span>
                      </figcaption>
                    </figure>
                    <figure class="rounded-xl2 border border-stroke bg-shape p-7">
                      <blockquote class="text-[16px] leading-relaxed text-ink/85">
                        "It's rare to find a system that is both powerful for administrators
                        and easy to use for the whole team. This is it."
                      </blockquote>
                      <figcaption class="mt-5 flex items-center gap-3">
                        <img
                          src="data:image/svg+xml,%3Csvg%20xmlns%3D%27http%3A//www.w3.org/2000/svg%27%20viewBox%3D%270%200%2096%2096%27%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27%230C2765%27/%3E%3Ccircle%20cx%3D%2748%27%20cy%3D%2748%27%20r%3D%2746%27%20fill%3D%27none%27%20stroke%3D%27%2352B2D8%27%20stroke-width%3D%273%27/%3E%3Ctext%20x%3D%2748%27%20y%3D%2761%27%20font-family%3D%27Arial%2C%20sans-serif%27%20font-size%3D%2730%27%20font-weight%3D%27700%27%20fill%3D%27%23ffffff%27%20text-anchor%3D%27middle%27%3EHW%3C/text%3E%3C/svg%3E"
                          alt=""
                          loading="lazy"
                          class="h-10 w-10 rounded-full object-cover"
                        /><span class="text-[15px] font-medium">Hannah Wright, Triage Nurse</span>
                      </figcaption>
                    </figure>
                  </div>
                </div>
              </div>
            </div>
          </section>
          
    <!-- ══════════════════════════════ PRICING (CSS-only tabs) ══════════════════════════════ -->
          <section id="pricing" class="scroll-mt-24 bg-shape py-20 lg:py-28">
            <div class="mx-auto max-w-7xl px-5 lg:px-8">
              <div class="mx-auto max-w-2xl text-center reveal">
                <span class="inline-flex items-center gap-2 rounded-pill border border-stroke bg-white px-4 py-1.5 text-[14px] font-medium text-muted">
                  <span class="h-1.5 w-1.5 animate-blink rounded-full bg-brand"></span>Pricing
                </span>
                <h2 class="mt-5 text-h2 font-semibold">
                  Simple &amp;
                  <span class="font-display italic font-normal text-brand">Transparent</span>
                  Pricing
                </h2>
                <p class="mt-4 text-[18px] text-muted">
                  Choose the plan that fits your needs — no hidden fees, no
                  surprises.
                </p>
              </div>

              <div class="mt-10">
                <input type="radio" name="billing" id="bill-monthly" class="peer/m sr-only" checked />
                <input type="radio" name="billing" id="bill-yearly" class="peer/y sr-only" />

                <div class="mx-auto flex w-max items-center gap-1 rounded-pill border border-stroke bg-white p-1.5 peer-checked/m:[&>[for=bill-monthly]]:bg-brand peer-checked/m:[&>[for=bill-monthly]]:text-white peer-checked/y:[&>[for=bill-yearly]]:bg-brand peer-checked/y:[&>[for=bill-yearly]]:text-white">
                  <label
                    for="bill-monthly"
                    class="cursor-pointer rounded-pill px-6 py-2.5 text-[15px] font-medium text-muted transition"
                  >
                    Monthly
                  </label>
                  <label
                    for="bill-yearly"
                    class="cursor-pointer rounded-pill px-6 py-2.5 text-[15px] font-medium text-muted transition"
                  >
                    Yearly
                  </label>
                </div>
                
    <!-- Monthly -->
                <div class="mt-12 hidden peer-checked/m:block">
                  <div class="grid gap-6 lg:grid-cols-2">
                    <article class="flex flex-col rounded-xl2 bg-brand p-8 text-white lg:p-10 reveal">
                      <div class="mb-6 grid h-12 w-12 place-items-center rounded-xl bg-white/15">
                        <svg
                          viewBox="0 0 24 24"
                          fill="none"
                          stroke="currentColor"
                          stroke-width="2"
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          class="h-6 w-6"
                          aria-hidden="true"
                        >
                          <path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z" />
                          <path d="m3.3 7 8.7 5 8.7-5M12 22V12" />
                        </svg>
                      </div>
                      <h3 class="text-h4 font-semibold">Basic plan</h3>
                      <p class="mt-2 text-[16px] text-white/75">
                        Perfect for small clinics or individual practitioners
                        getting started.
                      </p>
                      <p class="mt-7 flex items-baseline gap-1.5">
                        <span class="font-display text-[52px] font-semibold leading-none">$29</span><span class="text-[16px] text-white/70">/month</span>
                      </p>
                      <a
                        href="#cta"
                        class="mt-7 rounded-pill bg-white px-7 py-3.5 text-center text-[16px] font-medium text-brand transition hover:bg-brand-mint"
                      >
                        Start with Basic
                      </a>
                      <div class="mt-8 border-t border-white/20 pt-7">
                        <p class="text-[15px] font-medium">Includes:</p>
                        <ul class="mt-4 space-y-3 text-[16px] text-white/85">
                          <li class="flex gap-3">
                            <svg
                              viewBox="0 0 24 24"
                              fill="none"
                              stroke="currentColor"
                              stroke-width="2"
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              class="mt-1 h-4 w-4 shrink-0"
                              aria-hidden="true"
                            >
                              <path d="M20 6 9 17l-5-5" /></svg>Up to 3 staff accounts
                          </li>
                          <li class="flex gap-3">
                            <svg
                              viewBox="0 0 24 24"
                              fill="none"
                              stroke="currentColor"
                              stroke-width="2"
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              class="mt-1 h-4 w-4 shrink-0"
                              aria-hidden="true"
                            >
                              <path d="M20 6 9 17l-5-5" /></svg>Reception & patient registration
                          </li>
                          <li class="flex gap-3">
                            <svg
                              viewBox="0 0 24 24"
                              fill="none"
                              stroke="currentColor"
                              stroke-width="2"
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              class="mt-1 h-4 w-4 shrink-0"
                              aria-hidden="true"
                            >
                              <path d="M20 6 9 17l-5-5" /></svg>Basic patient records
                          </li>
                          <li class="flex gap-3">
                            <svg
                              viewBox="0 0 24 24"
                              fill="none"
                              stroke="currentColor"
                              stroke-width="2"
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              class="mt-1 h-4 w-4 shrink-0"
                              aria-hidden="true"
                            >
                              <path d="M20 6 9 17l-5-5" /></svg>Standard reports
                          </li>
                        </ul>
                      </div>
                    </article>

                    <article class="flex flex-col rounded-xl2 border border-stroke bg-white p-8 lg:p-10 reveal">
                      <div class="mb-6 grid h-12 w-12 place-items-center rounded-xl bg-brand-mint text-brand">
                        <svg
                          viewBox="0 0 24 24"
                          fill="none"
                          stroke="currentColor"
                          stroke-width="2"
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          class="h-6 w-6"
                          aria-hidden="true"
                        >
                          <path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z" />
                          <path d="m3.3 7 8.7 5 8.7-5M12 22V12" />
                        </svg>
                      </div>
                      <h3 class="text-h4 font-semibold">Professional Plan</h3>
                      <p class="mt-2 text-[16px] text-muted">
                        Designed for busy clinics and hospitals needing advanced
                        tools.
                      </p>
                      <p class="mt-7 flex items-baseline gap-1.5">
                        <span class="font-display text-[52px] font-semibold leading-none">$59</span><span class="text-[16px] text-muted">/month</span>
                      </p>
                      <a
                        href="#cta"
                        class="mt-7 rounded-pill bg-brand px-7 py-3.5 text-center text-[16px] font-medium text-white transition hover:bg-brand-light"
                      >
                        Go Professional
                      </a>
                      <div class="mt-8 border-t border-stroke pt-7">
                        <p class="text-[15px] font-medium">Includes:</p>
                        <ul class="mt-4 space-y-3 text-[16px] text-muted">
                          <li class="flex gap-3">
                            <svg
                              viewBox="0 0 24 24"
                              fill="none"
                              stroke="#0C2765"
                              stroke-width="2"
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              class="mt-1 h-4 w-4 shrink-0"
                              aria-hidden="true"
                            >
                              <path d="M20 6 9 17l-5-5" /></svg>Unlimited staff accounts
                          </li>
                          <li class="flex gap-3">
                            <svg
                              viewBox="0 0 24 24"
                              fill="none"
                              stroke="#0C2765"
                              stroke-width="2"
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              class="mt-1 h-4 w-4 shrink-0"
                              aria-hidden="true"
                            >
                              <path d="M20 6 9 17l-5-5" /></svg>Full patient history access
                          </li>
                          <li class="flex gap-3">
                            <svg
                              viewBox="0 0 24 24"
                              fill="none"
                              stroke="#0C2765"
                              stroke-width="2"
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              class="mt-1 h-4 w-4 shrink-0"
                              aria-hidden="true"
                            >
                              <path d="M20 6 9 17l-5-5" /></svg>Advanced analytics &amp; reporting
                          </li>
                          <li class="flex gap-3">
                            <svg
                              viewBox="0 0 24 24"
                              fill="none"
                              stroke="#0C2765"
                              stroke-width="2"
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              class="mt-1 h-4 w-4 shrink-0"
                              aria-hidden="true"
                            >
                              <path d="M20 6 9 17l-5-5" /></svg>Priority support
                          </li>
                        </ul>
                      </div>
                    </article>
                  </div>
                </div>
                
    <!-- Yearly -->
                <div class="mt-12 hidden peer-checked/y:block">
                  <div class="grid gap-6 lg:grid-cols-2">
                    <article class="flex flex-col rounded-xl2 bg-brand p-8 text-white lg:p-10 reveal">
                      <div class="mb-6 grid h-12 w-12 place-items-center rounded-xl bg-white/15">
                        <svg
                          viewBox="0 0 24 24"
                          fill="none"
                          stroke="currentColor"
                          stroke-width="2"
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          class="h-6 w-6"
                          aria-hidden="true"
                        >
                          <path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z" />
                          <path d="m3.3 7 8.7 5 8.7-5M12 22V12" />
                        </svg>
                      </div>
                      <h3 class="text-h4 font-semibold">Basic plan</h3>
                      <p class="mt-2 text-[16px] text-white/75">
                        Perfect for small clinics or individual practitioners
                        getting started.
                      </p>
                      <p class="mt-7 flex items-baseline gap-1.5">
                        <span class="font-display text-[52px] font-semibold leading-none">$300</span><span class="text-[16px] text-white/70">/year</span>
                      </p>
                      <a
                        href="#cta"
                        class="mt-7 rounded-pill bg-white px-7 py-3.5 text-center text-[16px] font-medium text-brand transition hover:bg-brand-mint"
                      >
                        Start with Basic
                      </a>
                      <div class="mt-8 border-t border-white/20 pt-7">
                        <p class="text-[15px] font-medium">Includes:</p>
                        <ul class="mt-4 space-y-3 text-[16px] text-white/85">
                          <li class="flex gap-3">
                            <svg
                              viewBox="0 0 24 24"
                              fill="none"
                              stroke="currentColor"
                              stroke-width="2"
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              class="mt-1 h-4 w-4 shrink-0"
                              aria-hidden="true"
                            >
                              <path d="M20 6 9 17l-5-5" /></svg>Up to 3 staff accounts
                          </li>
                          <li class="flex gap-3">
                            <svg
                              viewBox="0 0 24 24"
                              fill="none"
                              stroke="currentColor"
                              stroke-width="2"
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              class="mt-1 h-4 w-4 shrink-0"
                              aria-hidden="true"
                            >
                              <path d="M20 6 9 17l-5-5" /></svg>Reception & patient registration
                          </li>
                          <li class="flex gap-3">
                            <svg
                              viewBox="0 0 24 24"
                              fill="none"
                              stroke="currentColor"
                              stroke-width="2"
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              class="mt-1 h-4 w-4 shrink-0"
                              aria-hidden="true"
                            >
                              <path d="M20 6 9 17l-5-5" /></svg>Basic patient records
                          </li>
                          <li class="flex gap-3">
                            <svg
                              viewBox="0 0 24 24"
                              fill="none"
                              stroke="currentColor"
                              stroke-width="2"
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              class="mt-1 h-4 w-4 shrink-0"
                              aria-hidden="true"
                            >
                              <path d="M20 6 9 17l-5-5" /></svg>Standard reports
                          </li>
                        </ul>
                      </div>
                    </article>

                    <article class="flex flex-col rounded-xl2 border border-stroke bg-white p-8 lg:p-10 reveal">
                      <div class="mb-6 grid h-12 w-12 place-items-center rounded-xl bg-brand-mint text-brand">
                        <svg
                          viewBox="0 0 24 24"
                          fill="none"
                          stroke="currentColor"
                          stroke-width="2"
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          class="h-6 w-6"
                          aria-hidden="true"
                        >
                          <path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z" />
                          <path d="m3.3 7 8.7 5 8.7-5M12 22V12" />
                        </svg>
                      </div>
                      <h3 class="text-h4 font-semibold">Professional Plan</h3>
                      <p class="mt-2 text-[16px] text-muted">
                        Designed for busy clinics and hospitals needing advanced
                        tools.
                      </p>
                      <p class="mt-7 flex items-baseline gap-1.5">
                        <span class="font-display text-[52px] font-semibold leading-none">$600</span><span class="text-[16px] text-muted">/year</span>
                      </p>
                      <a
                        href="#cta"
                        class="mt-7 rounded-pill bg-brand px-7 py-3.5 text-center text-[16px] font-medium text-white transition hover:bg-brand-light"
                      >
                        Go Professional
                      </a>
                      <div class="mt-8 border-t border-stroke pt-7">
                        <p class="text-[15px] font-medium">Includes:</p>
                        <ul class="mt-4 space-y-3 text-[16px] text-muted">
                          <li class="flex gap-3">
                            <svg
                              viewBox="0 0 24 24"
                              fill="none"
                              stroke="#0C2765"
                              stroke-width="2"
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              class="mt-1 h-4 w-4 shrink-0"
                              aria-hidden="true"
                            >
                              <path d="M20 6 9 17l-5-5" /></svg>Unlimited staff accounts
                          </li>
                          <li class="flex gap-3">
                            <svg
                              viewBox="0 0 24 24"
                              fill="none"
                              stroke="#0C2765"
                              stroke-width="2"
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              class="mt-1 h-4 w-4 shrink-0"
                              aria-hidden="true"
                            >
                              <path d="M20 6 9 17l-5-5" /></svg>Full patient history access
                          </li>
                          <li class="flex gap-3">
                            <svg
                              viewBox="0 0 24 24"
                              fill="none"
                              stroke="#0C2765"
                              stroke-width="2"
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              class="mt-1 h-4 w-4 shrink-0"
                              aria-hidden="true"
                            >
                              <path d="M20 6 9 17l-5-5" /></svg>Advanced analytics &amp; reporting
                          </li>
                          <li class="flex gap-3">
                            <svg
                              viewBox="0 0 24 24"
                              fill="none"
                              stroke="#0C2765"
                              stroke-width="2"
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              class="mt-1 h-4 w-4 shrink-0"
                              aria-hidden="true"
                            >
                              <path d="M20 6 9 17l-5-5" /></svg>Priority support
                          </li>
                        </ul>
                      </div>
                    </article>
                  </div>
                </div>
              </div>
            </div>
          </section>
          
    <!-- ══════════════════════════════ FAQ ══════════════════════════════ -->
          <section id="faq" class="scroll-mt-24 py-20 lg:py-28">
            <div class="mx-auto max-w-7xl px-5 lg:px-8">
              <div class="mx-auto max-w-2xl text-center reveal">
                <span class="inline-flex items-center gap-2 rounded-pill border border-stroke bg-shape px-4 py-1.5 text-[14px] font-medium text-muted">
                  <span class="h-1.5 w-1.5 animate-blink rounded-full bg-brand"></span>FAQ
                </span>
                <h2 class="mt-5 text-h2 font-semibold">
                  Your Questions,
                  <span class="font-display italic font-normal text-brand">Answered</span>
                </h2>
                <p class="mt-4 text-[18px] text-muted">
                  Find clear, quick answers to help you get started with confidence.
                </p>
              </div>
              
    <!-- <details> replaces the Webflow click-driven accordion. -->
              <div class="mx-auto mt-12 max-w-3xl space-y-3">
                <details
                  class="group rounded-xl2 border border-stroke bg-shape px-6 open:bg-white"
                  open
                >
                  <summary class="flex cursor-pointer list-none items-center justify-between gap-6 py-5 text-[17px] font-medium marker:hidden">
                    How secure is my medical data?
                    <svg
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      stroke-width="2"
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      class="faq-chevron h-5 w-5 shrink-0 text-brand transition-transform"
                      aria-hidden="true"
                    >
                      <path d="m6 9 6 6 6-6" />
                    </svg>
                  </summary>
                  <p class="pb-6 pr-10 text-[16px] leading-relaxed text-muted">
                    Patient data is encrypted in transit and at rest, access is
                    logged in a full audit trail, and every role — reception,
                    doctor, pharmacy, admin — only sees what it needs to.
                  </p>
                </details>

                <details class="group rounded-xl2 border border-stroke bg-shape px-6 open:bg-white">
                  <summary class="flex cursor-pointer list-none items-center justify-between gap-6 py-5 text-[17px] font-medium marker:hidden">
                    How does the AI doc reviewer work?
                    <svg
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      stroke-width="2"
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      class="faq-chevron h-5 w-5 shrink-0 text-brand transition-transform"
                      aria-hidden="true"
                    >
                      <path d="m6 9 6 6 6-6" />
                    </svg>
                  </summary>
                  <p class="pb-6 pr-10 text-[16px] leading-relaxed text-muted">
                    It forms an independent clinical impression from triage, labs,
                    and notes before seeing the doctor's diagnosis, then flags
                    where the two disagree. It's a second opinion, not a
                    replacement for clinical judgment.
                  </p>
                </details>

                <details class="group rounded-xl2 border border-stroke bg-shape px-6 open:bg-white">
                  <summary class="flex cursor-pointer list-none items-center justify-between gap-6 py-5 text-[17px] font-medium marker:hidden">
                    Which languages does voice dictation support?
                    <svg
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      stroke-width="2"
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      class="faq-chevron h-5 w-5 shrink-0 text-brand transition-transform"
                      aria-hidden="true"
                    >
                      <path d="m6 9 6 6 6-6" />
                    </svg>
                  </summary>
                  <p class="pb-6 pr-10 text-[16px] leading-relaxed text-muted">
                    English and Kiswahili are fully supported, with experimental
                    support for Sheng, Gikuyu, Dholuo, Kikamba, Luhya, Kalenjin,
                    and Somali — dictated notes are transcribed straight into the
                    patient record.
                  </p>
                </details>

                <details class="group rounded-xl2 border border-stroke bg-shape px-6 open:bg-white">
                  <summary class="flex cursor-pointer list-none items-center justify-between gap-6 py-5 text-[17px] font-medium marker:hidden">
                    Is there a limit to the number of doctors or patients I can add?
                    <svg
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      stroke-width="2"
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      class="faq-chevron h-5 w-5 shrink-0 text-brand transition-transform"
                      aria-hidden="true"
                    >
                      <path d="m6 9 6 6 6-6" />
                    </svg>
                  </summary>
                  <p class="pb-6 pr-10 text-[16px] leading-relaxed text-muted">
                    The Basic plan caps staff accounts; the Professional plan
                    supports unlimited staff and patients across every
                    department.
                  </p>
                </details>

                <details class="group rounded-xl2 border border-stroke bg-shape px-6 open:bg-white">
                  <summary class="flex cursor-pointer list-none items-center justify-between gap-6 py-5 text-[17px] font-medium marker:hidden">
                    Do you offer support if I have technical issues?
                    <svg
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      stroke-width="2"
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      class="faq-chevron h-5 w-5 shrink-0 text-brand transition-transform"
                      aria-hidden="true"
                    >
                      <path d="m6 9 6 6 6-6" />
                    </svg>
                  </summary>
                  <p class="pb-6 pr-10 text-[16px] leading-relaxed text-muted">
                    Yes — standard support on the Basic plan, and priority support
                    with faster response times on Professional.
                  </p>
                </details>

                <details class="group rounded-xl2 border border-stroke bg-shape px-6 open:bg-white">
                  <summary class="flex cursor-pointer list-none items-center justify-between gap-6 py-5 text-[17px] font-medium marker:hidden">
                    Can I upgrade or downgrade my plan anytime?
                    <svg
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      stroke-width="2"
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      class="faq-chevron h-5 w-5 shrink-0 text-brand transition-transform"
                      aria-hidden="true"
                    >
                      <path d="m6 9 6 6 6-6" />
                    </svg>
                  </summary>
                  <p class="pb-6 pr-10 text-[16px] leading-relaxed text-muted">
                    Yes, you can switch between Basic and Professional, or between
                    monthly and yearly billing, at any time.
                  </p>
                </details>

                <details class="group rounded-xl2 border border-stroke bg-shape px-6 open:bg-white">
                  <summary class="flex cursor-pointer list-none items-center justify-between gap-6 py-5 text-[17px] font-medium marker:hidden">
                    Can this integrate with M-Pesa and existing finance systems?
                    <svg
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      stroke-width="2"
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      class="faq-chevron h-5 w-5 shrink-0 text-brand transition-transform"
                      aria-hidden="true"
                    >
                      <path d="m6 9 6 6 6-6" />
                    </svg>
                  </summary>
                  <p class="pb-6 pr-10 text-[16px] leading-relaxed text-muted">
                    Yes — M-Pesa and PayPal payments are built in, and billing
                    data flows through to your procurement and finance modules.
                  </p>
                </details>
              </div>
            </div>
          </section>
          
    <!-- ══════════════════════════════ BLOG ══════════════════════════════ -->
          <section id="blog" class="scroll-mt-24 bg-shape py-20 lg:py-28">
            <div class="mx-auto max-w-7xl px-5 lg:px-8">
              <div class="mx-auto max-w-2xl text-center reveal">
                <span class="inline-flex items-center gap-2 rounded-pill border border-stroke bg-white px-4 py-1.5 text-[14px] font-medium text-muted">
                  <span class="h-1.5 w-1.5 animate-blink rounded-full bg-brand"></span>Blogs
                </span>
                <h2 class="mt-5 text-h2 font-semibold">
                  <span class="font-display italic font-normal text-brand">Inspiration</span>
                  &amp; <span class="font-display italic font-normal text-brand">Insights</span>
                  from Blog
                </h2>
                <p class="mt-4 text-[18px] text-muted">
                  Latest tips, stories, and updates to keep you informed and
                  inspired every day.
                </p>
              </div>

              <div class="mt-14 grid gap-6 md:grid-cols-3">
                <a
                  href="#blog"
                  class="group block overflow-hidden rounded-xl2 border border-stroke bg-white transition hover:shadow-card reveal"
                >
                  <div class="overflow-hidden">
                    <img
                      src="/images/why.png"
                      alt="Immune-boosting foods arranged on a table"
                      loading="lazy"
                      class="h-56 w-full object-cover transition duration-500 group-hover:scale-105"
                    />
                  </div>
                  <div class="p-7">
                    <h3 class="text-h6 font-semibold leading-snug">
                      How AI Voice Dictation Cuts Doctors' Charting Time in Half
                    </h3>
                    <p class="mt-3 text-[14px] text-muted">September 4, 2025</p>
                  </div>
                </a>

                <a
                  href="#blog"
                  class="group block overflow-hidden rounded-xl2 border border-stroke bg-white transition hover:shadow-card reveal"
                >
                  <div class="overflow-hidden">
                    <img
                      src="/images/public/african-diagnostic-care.png"
                      alt="Pharmacist checking stock on a tablet"
                      loading="lazy"
                      class="h-56 w-full object-cover transition duration-500 group-hover:scale-105"
                    />
                  </div>
                  <div class="p-7">
                    <h3 class="text-h6 font-semibold leading-snug">
                      5 Signs Your Pharmacy Stock-Take Process Needs an Upgrade
                    </h3>
                    <p class="mt-3 text-[14px] text-muted">September 4, 2025</p>
                  </div>
                </a>

                <a
                  href="#blog"
                  class="group block overflow-hidden rounded-xl2 border border-stroke bg-white transition hover:shadow-card reveal"
                >
                  <div class="overflow-hidden">
                    <img
                      src="/images/public/african-hospital-exterior.png"
                      alt="Hospital administrator reviewing MOH reports"
                      loading="lazy"
                      class="h-56 w-full object-cover transition duration-500 group-hover:scale-105"
                    />
                  </div>
                  <div class="p-7">
                    <h3 class="text-h6 font-semibold leading-snug">
                      A Practical Guide to Faster MOH Reporting with AI Mapping
                    </h3>
                    <p class="mt-3 text-[14px] text-muted">September 4, 2025</p>
                  </div>
                </a>
              </div>

              <div class="mt-12 text-center">
                <a
                  href="#blog"
                  class="inline-block rounded-pill bg-brand px-7 py-3.5 text-[16px] font-medium text-white transition hover:bg-brand-light"
                >
                  Browse to All
                </a>
              </div>
            </div>
          </section>
          
    <!-- ══════════════════════════════ CTA ══════════════════════════════ -->
          <section id="cta" class="scroll-mt-24 py-20 lg:py-28">
            <div class="mx-auto max-w-7xl px-5 lg:px-8">
              <div class="relative overflow-hidden rounded-[32px] bg-brand px-6 py-20 text-center text-white lg:px-16">
                <div class="pointer-events-none absolute -right-24 -top-24 h-72 w-72 rounded-full bg-white/10">
                </div>
                <div class="pointer-events-none absolute -bottom-28 -left-20 h-80 w-80 rounded-full bg-white/[0.07]">
                </div>
                <div class="relative mx-auto max-w-2xl">
                  <div class="mx-auto mb-7 grid h-14 w-14 place-items-center rounded-2xl bg-white/15">
                    <svg viewBox="0 0 32 32" class="h-7 w-7" aria-hidden="true">
                      <path
                        d="M16 7v18M7 16h18"
                        stroke="#fff"
                        stroke-width="3.5"
                        stroke-linecap="round"
                      />
                    </svg>
                  </div>
                  <h2 class="text-h2 font-semibold">
                    Bring Your Hospital Onto One Platform
                  </h2>
                  <p class="mx-auto mt-5 max-w-xl text-[18px] text-white/80">
                    Join hospitals and clinics that trust Tibasasa AI to run
                    reception, pharmacy, labs, and finance — with AI support at
                    every step.
                  </p>
                  <a
                    href="#contact"
                    class="mt-9 inline-block rounded-pill bg-white px-8 py-4 text-[16px] font-medium text-brand transition hover:bg-brand-mint"
                  >
                    Get Started Now
                  </a>
                </div>
              </div>
            </div>
          </section>
          
    <!-- ══════════════════════════════ CONTACT ══════════════════════════════ -->
          <section id="contact" class="scroll-mt-24 bg-shape py-20 lg:py-28">
            <div class="mx-auto max-w-4xl px-5 lg:px-8">
              <div class="rounded-xl2 border border-stroke bg-white p-8 lg:p-12">
                <span class="inline-flex items-center gap-2 rounded-pill bg-brand-mint px-4 py-1.5 text-[14px] font-medium text-brand">
                  Get Started in Minutes
                </span>
                <h2 class="mt-5 text-h3 font-semibold">
                  Ready to modernize your hospital?
                </h2>
                <p class="mt-3 text-[17px] text-muted">
                  See reception, pharmacy, labs, and AI decision support in
                  action. Book a free 30-min consultation.
                </p>

                <form class="mt-9 grid gap-5 sm:grid-cols-2" action="#" method="post">
                  <div>
                    <label for="c-name" class="mb-2 block text-[15px] font-medium">Full Name</label>
                    <input
                      id="c-name"
                      name="name"
                      type="text"
                      autocomplete="name"
                      class="w-full rounded-xl border border-stroke bg-shape px-4 py-3 text-[16px] outline-none transition focus:border-brand focus:bg-white"
                    />
                  </div>
                  <div>
                    <label for="c-email" class="mb-2 block text-[15px] font-medium">Email</label>
                    <input
                      id="c-email"
                      name="email"
                      type="email"
                      autocomplete="email"
                      class="w-full rounded-xl border border-stroke bg-shape px-4 py-3 text-[16px] outline-none transition focus:border-brand focus:bg-white"
                    />
                  </div>
                  <div>
                    <label for="c-phone" class="mb-2 block text-[15px] font-medium">
                      Phone number
                    </label>
                    <input
                      id="c-phone"
                      name="phone"
                      type="tel"
                      autocomplete="tel"
                      class="w-full rounded-xl border border-stroke bg-shape px-4 py-3 text-[16px] outline-none transition focus:border-brand focus:bg-white"
                    />
                  </div>
                  <div class="sm:col-span-2">
                    <label for="c-message" class="mb-2 block text-[15px] font-medium">Message</label>
                    <textarea
                      id="c-message"
                      name="message"
                      rows="4"
                      class="w-full resize-y rounded-xl border border-stroke bg-shape px-4 py-3 text-[16px] outline-none transition focus:border-brand focus:bg-white"
                    ></textarea>
                  </div>
                  <div class="sm:col-span-2">
                    <button
                      type="submit"
                      class="w-full rounded-pill bg-brand px-8 py-4 text-[16px] font-medium text-white transition hover:bg-brand-light sm:w-auto"
                    >
                      Book a consultation
                    </button>
                  </div>
                </form>
              </div>
            </div>
          </section>
        </main>
        
    <!-- ══════════════════════════════ FOOTER ══════════════════════════════ -->
        <footer id="footer" class="scroll-mt-24 border-t border-stroke bg-white pt-16">
          <div class="mx-auto max-w-7xl px-5 lg:px-8">
            <div class="flex flex-col gap-6 border-b border-stroke pb-12 lg:flex-row lg:items-center lg:justify-between">
              <div>
                <h2 class="text-h5 font-semibold">
                  Stay updated with our latest news
                </h2>
                <p class="mt-2 text-[16px] text-muted">
                  Get updates straight to your inbox.
                </p>
              </div>
              <form class="flex w-full max-w-md gap-2" action="#" method="post">
                <label for="newsletter" class="sr-only">Email address</label>
                <input
                  id="newsletter"
                  name="email"
                  type="email"
                  placeholder="Enter your email"
                  autocomplete="email"
                  class="w-full rounded-pill border border-stroke bg-shape px-5 py-3.5 text-[16px] outline-none transition focus:border-brand focus:bg-white"
                />
                <button
                  type="submit"
                  class="shrink-0 rounded-pill bg-brand px-7 py-3.5 text-[16px] font-medium text-white transition hover:bg-brand-light"
                >
                  Subscribe
                </button>
              </form>
            </div>

            <div class="grid gap-10 py-14 sm:grid-cols-2 lg:grid-cols-4">
              <div>
                <p class="mb-4 text-[15px] font-semibold">Main pages</p>
                <ul class="space-y-2.5 text-[15px] text-muted">
                  <li><a href="#top" class="text-brand">Home</a></li>
                  <li>
                    <a href="#who" class="transition hover:text-brand">About</a>
                  </li>
                  <li>
                    <a href="#features" class="transition hover:text-brand">Features</a>
                  </li>
                  <li>
                    <a href="#pricing" class="transition hover:text-brand">Pricing</a>
                  </li>
                  <li>
                    <a href="#blog" class="transition hover:text-brand">Blog</a>
                  </li>
                </ul>
              </div>
              <div>
                <p class="mb-4 text-[15px] font-semibold">Inner pages</p>
                <ul class="space-y-2.5 text-[15px] text-muted">
                  <li>
                    <a href="#blog" class="transition hover:text-brand">Blog single</a>
                  </li>
                  <li>
                    <a href="#pricing" class="transition hover:text-brand">Pricing single</a>
                  </li>
                  <li>
                    <a href="#contact" class="transition hover:text-brand">Contact</a>
                  </li>
                </ul>
              </div>
              <div>
                <p class="mb-4 text-[15px] font-semibold">Utility pages</p>
                <ul class="space-y-2.5 text-[15px] text-muted">
                  <li>
                    <a href="#footer" class="transition hover:text-brand">404</a>
                  </li>
                  <li>
                    <a href="#footer" class="transition hover:text-brand">Styleguide</a>
                  </li>
                  <li>
                    <a href="#footer" class="transition hover:text-brand">Licenses</a>
                  </li>
                  <li>
                    <a href="#footer" class="transition hover:text-brand">Changelog</a>
                  </li>
                  <li>
                    <a href="#footer" class="transition hover:text-brand">Password</a>
                  </li>
                </ul>
              </div>
              <div>
                <p class="mb-4 text-[15px] font-semibold">Contact Us</p>
                <ul class="space-y-3.5 text-[15px] text-muted">
                  <li>
                    <a
                      href="mailto:support@tibasasa.ai"
                      class="flex items-center gap-3 transition hover:text-brand"
                    >
                      <svg
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="currentColor"
                        stroke-width="2"
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        class="h-4 w-4 shrink-0 text-brand"
                        aria-hidden="true"
                      >
                        <rect x="2" y="4" width="20" height="16" rx="2" />
                        <path d="m2 7 10 6 10-6" />
                      </svg>
                      support@tibasasa.ai
                    </a>
                  </li>
                  <li class="flex gap-3">
                    <svg
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      stroke-width="2"
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      class="mt-0.5 h-4 w-4 shrink-0 text-brand"
                      aria-hidden="true"
                    >
                      <path d="M21 10c0 6-9 13-9 13S3 16 3 10a9 9 0 0 1 18 0z" />
                      <circle cx="12" cy="10" r="3" />
                    </svg>
                    <span>Nairobi, Kenya</span>
                  </li>
                </ul>
              </div>
            </div>

            <div class="flex flex-col items-center justify-between gap-4 border-t border-stroke py-8 sm:flex-row">
              <a href="#top" class="flex items-center gap-2.5">
                <img
                  src="/images/tibasasa-ai-logo.png"
                  alt="Tibasasa AI"
                  class="h-10 w-10 object-contain"
                />
                <span class="text-[18px] font-bold tracking-tight text-brand">Tibasasa AI</span>
              </a>
              <p class="text-center text-[14px] text-muted">
                ©2025 Tibasasa AI. Designed &amp; Developed by <a
                  href="https://waidastudio.com"
                  class="text-brand hover:underline"
                >Waida Studio</a>.
              </p>
            </div>
          </div>
        </footer>

        <script>
          // Scroll reveal: fade/rise elements in as they enter the viewport, with a light stagger per group.
          (function () {
            var reveals = document.querySelectorAll(".reveal");
            if (!("IntersectionObserver" in window) || !reveals.length) {
              reveals.forEach(function (el) {
                el.classList.add("is-visible");
              });
              return;
            }

            var observer = new IntersectionObserver(
              function (entries) {
                entries.forEach(function (entry) {
                  if (!entry.isIntersecting) return;
                  var el = entry.target;
                  var siblings = Array.prototype.filter.call(
                    el.parentElement ? el.parentElement.children : [],
                    function (child) {
                      return child.classList && child.classList.contains("reveal");
                    }
                  );
                  var index = siblings.indexOf(el);
                  var delay = Math.max(0, index) * 90;
                  setTimeout(function () {
                    el.classList.add("is-visible");
                  }, delay);
                  observer.unobserve(el);
                });
              },
              { threshold: 0.15, rootMargin: "0px 0px -40px 0px" }
            );

            reveals.forEach(function (el) {
              observer.observe(el);
            });
          })();

          // Animated stat counter: counts up once when it scrolls into view.
          (function () {
            var counter = document.getElementById("stat-counter");
            if (!counter) return;
            var target = parseInt(counter.getAttribute("data-target"), 10) || 0;

            function animate() {
              var start = null;
              var duration = 1400;

              function format(n) {
                return Math.round(n).toLocaleString("en-US");
              }

              function step(timestamp) {
                if (start === null) start = timestamp;
                var progress = Math.min((timestamp - start) / duration, 1);
                var eased = 1 - Math.pow(1 - progress, 3);
                counter.textContent = format(target * eased);
                if (progress < 1) requestAnimationFrame(step);
              }

              requestAnimationFrame(step);
            }

            if (!("IntersectionObserver" in window)) {
              counter.textContent = target.toLocaleString("en-US");
              return;
            }

            var observer = new IntersectionObserver(
              function (entries) {
                entries.forEach(function (entry) {
                  if (entry.isIntersecting) {
                    animate();
                    observer.disconnect();
                  }
                });
              },
              { threshold: 0.4 }
            );
            observer.observe(counter);
          })();

          // Header shadow/opacity on scroll for a subtle sense of depth.
          (function () {
            var header = document.querySelector("header");
            if (!header) return;
            function onScroll() {
              if (window.scrollY > 8) {
                header.classList.add("shadow-sm");
              } else {
                header.classList.remove("shadow-sm");
              }
            }
            onScroll();
            window.addEventListener("scroll", onScroll, { passive: true });
          })();
        </script>
      </body>
    </html>
    """
  end
end
