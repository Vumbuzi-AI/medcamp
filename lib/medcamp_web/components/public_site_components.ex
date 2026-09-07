defmodule MedcampWeb.PublicSiteComponents do
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  @public_pages [:home, :about, :services, :blog, :contact]
  @nav_items [
    %{id: :home, label: "Home", href: "/"},
    %{id: :about, label: "About", href: "/about"},
    %{id: :services, label: "Services", href: "/services"},
    %{id: :blog, label: "Blog", href: "/blog"},
    %{id: :contact, label: "Contact", href: "/contact"}
  ]
  @primary_phone_display "+254 726 776 293"
  @primary_phone_href "tel:+254726776293"
  @secondary_phone_display "+254 739 371 657"
  @secondary_phone_href "tel:+254739371657"
  @phone_contacts [
    %{display: @primary_phone_display, href: @primary_phone_href},
    %{display: @secondary_phone_display, href: @secondary_phone_href}
  ]
  @primary_email "info@glocalhealthcentre.org"
  @address "Mwalimu Park, Kisaju along Nairobi-Namanga Road, Kajiado"

  attr :current_page, :atom, default: :home, values: @public_pages

  def public_navbar(assigns) do
    assigns =
      assigns
      |> public_site_assigns()
      |> assign(:nav_items, @nav_items)

    ~H"""
    <header class="sticky top-0 z-50 border-b border-[#ddd2f9]/80 bg-[#cfd0fb] backdrop-blur-md">
      <div class="mx-auto max-w-7xl">
        <div class="overflow-hidden">
          <div class="flex items-center gap-3 px-4 py-4 sm:gap-4 sm:px-6">
            <a href="/" aria-label="GHCE home" class="flex min-w-0 items-center gap-3 no-underline">
              <span class="flex h-10 w-10 items-center justify-center rounded-2xl ring-1 ring-[#d9defd] sm:h-12 sm:w-12">
                <img src="/images/logo.png" alt="" class="h-10 w-10 object-contain sm:h-12 sm:w-12" />
              </span>
              <span class="min-w-0">
                <span class="public-wordmark block truncate text-lg font-bold tracking-tight text-slate-950 sm:text-xl">
                  GHCE
                </span>
                <span class="hidden text-xs font-medium text-slate-500 sm:block">
                  Global Standards, Local Care
                </span>
              </span>
            </a>

            <nav aria-label="Primary navigation" class="hidden flex-1 justify-center lg:flex">
              <div class="flex items-center gap-1 rounded-full bg-[#f5f7ff] p-1">
                <%= for item <- @nav_items do %>
                  <a href={item.href} class={nav_link_class(item.id == @current_page)}>
                    {item.label}
                  </a>
                <% end %>
              </div>
            </nav>

            <div class="ml-auto hidden items-center gap-3 lg:flex">
              <div class="inline-flex items-center gap-2 rounded-2xl px-3 py-2 text-sm text-slate-600">
                <svg
                  viewBox="0 0 24 24"
                  aria-hidden="true"
                  class="h-4 w-4 shrink-0"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                >
                  <path d="M22 16.9v3a2 2 0 0 1-2.2 2 19.8 19.8 0 0 1-8.6-3.1 19.4 19.4 0 0 1-6-6 19.8 19.8 0 0 1-3.1-8.7A2 2 0 0 1 4 2h3a2 2 0 0 1 2 1.7l.4 2.8a2 2 0 0 1-.6 1.8l-1.3 1.3a16 16 0 0 0 6 6l1.3-1.3a2 2 0 0 1 1.8-.6l2.8.4A2 2 0 0 1 22 16.9Z" />
                </svg>
                <div class="flex flex-col leading-tight">
                  <a
                    :for={phone <- @phone_contacts}
                    href={phone.href}
                    class="font-medium text-slate-600 no-underline transition hover:text-slate-950"
                  >
                    {phone.display}
                  </a>
                </div>
              </div>
              <a
                href="/users/log_in"
                class="inline-flex items-center rounded-full border border-slate-200 bg-white px-4 py-2 text-sm font-semibold text-slate-700 no-underline transition hover:border-slate-300 hover:bg-slate-50 hover:text-slate-950"
              >
                Log In
              </a>
              <a
                href="/contact"
                class="public-cta inline-flex items-center rounded-full bg-[#d9c8ff] px-5 py-2.5 text-sm font-semibold text-[#2a3184] no-underline shadow-sm transition hover:bg-[#c8b1ff]"
              >
                Book Appointment
              </a>
            </div>

            <button
              type="button"
              phx-click={toggle_public_mobile_menu()}
              aria-controls="public-mobile-menu"
              aria-label="Toggle navigation menu"
              class="ml-auto inline-flex items-center justify-center rounded-2xl border border-slate-200 bg-white p-3 text-slate-700 shadow-sm transition hover:border-slate-300 hover:text-slate-950 lg:hidden"
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
                <path d="M4 7h16" />
                <path d="M4 12h16" />
                <path d="M4 17h16" />
              </svg>
            </button>
          </div>
        </div>

        <div
          id="public-mobile-menu"
          class="hidden border-t border-[#ddd2f9]/70 px-4 pb-4 pt-3 lg:hidden"
        >
          <div class="overflow-hidden rounded-[1.25rem] border border-slate-200 bg-white p-4 shadow-[0_18px_40px_-32px_rgba(15,23,42,0.45)]">
            <div class="rounded-[1rem] bg-[#f5f7ff] p-4">
              <p class="text-xs font-semibold uppercase tracking-[0.18em] text-[#2a3184]">
                GHCE Kisaju
              </p>
              <p class="mt-2 text-sm leading-6 text-slate-600">
                Safe, traceable, patient-centred care powered by GS1 standards.
              </p>
            </div>

            <nav aria-label="Mobile navigation" class="mt-4 space-y-2">
              <%= for item <- @nav_items do %>
                <a
                  href={item.href}
                  phx-click={close_public_mobile_menu()}
                  class={mobile_nav_link_class(item.id == @current_page)}
                >
                  {item.label}
                </a>
              <% end %>
            </nav>

            <div class="mt-4 grid gap-3 sm:grid-cols-2">
              <a
                href="/contact"
                phx-click={close_public_mobile_menu()}
                class="inline-flex items-center justify-center rounded-2xl bg-[#d9c8ff] px-4 py-3 text-sm font-semibold text-[#2a3184] no-underline transition hover:bg-[#c8b1ff]"
              >
                Book Appointment
              </a>
              <a
                href="/users/log_in"
                phx-click={close_public_mobile_menu()}
                class="inline-flex items-center justify-center rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm font-semibold text-slate-700 no-underline transition hover:border-slate-300 hover:text-slate-950"
              >
                Staff Log In
              </a>
            </div>

            <div class="mt-4 grid gap-3 border-t border-slate-200 pt-4 text-sm text-slate-600">
              <a
                :for={phone <- @phone_contacts}
                href={phone.href}
                class="break-words no-underline transition hover:text-slate-950"
              >
                {phone.display}
              </a>
              <a
                href={"mailto:#{@primary_email}"}
                class="break-words no-underline transition hover:text-slate-950"
              >
                {@primary_email}
              </a>
            </div>
          </div>
        </div>
      </div>
    </header>
    """
  end

  attr :current_page, :atom, default: :home, values: @public_pages

  def public_footer(assigns) do
    assigns =
      assigns
      |> public_site_assigns()
      |> assign(:nav_items, @nav_items)

    ~H"""
    <footer class={["border-t border-white", public_surface_background_class()]}>
      <div class="mx-auto max-w-7xl px-4 py-14 sm:px-6 lg:px-8">
        <div class="grid gap-10 lg:grid-cols-[1.1fr_1.4fr]">
          <div>
            <a href="/" aria-label="GHCE home" class="flex items-center gap-3 no-underline">
              <span class="flex h-10 w-10 items-center justify-center rounded-lg bg-white">
                <img src="/images/logo.png" alt="" class="h-7 w-7 object-contain" />
              </span>
              <span class="text-xl font-bold">GHCE</span>
            </a>
            <h3 class="mt-8 text-xl font-bold sm:text-2xl">Sign up to Newsletter</h3>
            <form action="#" method="get" class="mt-4 flex flex-col gap-3 sm:flex-row">
              <input
                required
                type="email"
                name="newsletter-email"
                placeholder="Enter your email address"
                class="min-h-12 flex-1 rounded-md border border-white bg-white px-4 outline-none focus:border-white"
              />
              <button
                type="submit"
                class="rounded-md border border-white bg-white px-5 py-3 font-semibold hover:opacity-80"
              >
                Subscribe Now
              </button>
            </form>
          </div>

          <div class="grid gap-8 md:grid-cols-3">
            <div>
              <h4 class="font-bold">Menus</h4>
              <div class="mt-4 space-y-3">
                <%= for item <- @nav_items do %>
                  <a href={item.href} class={footer_link_class(item.id == @current_page)}>
                    {item.label}
                  </a>
                <% end %>
              </div>
            </div>

            <div>
              <h4 class="font-bold">Foundation</h4>
              <div class="mt-4 space-y-3">
                <a href="/about#vision" class={footer_link_class(false)}>Vision &amp; Mission</a>
                <a href="/about#values" class={footer_link_class(false)}>Our Values</a>
                <a href="/services" class={footer_link_class(false)}>Patient Safety</a>
              </div>
            </div>

            <div>
              <h4 class="font-bold">Contact</h4>
              <div class="mt-4 space-y-3">
                <a :for={phone <- @phone_contacts} href={phone.href} class={footer_link_class(false)}>
                  {phone.display}
                </a>
                <a href={"mailto:#{@primary_email}"} class={footer_link_class(false)}>
                  {@primary_email}
                </a>
                <a
                  href="https://maps.google.com/?q=Mwalimu+Park+Kisaju"
                  target="_blank"
                  rel="noreferrer"
                  class={footer_link_class(false)}
                >
                  {@address}
                </a>
              </div>
            </div>
          </div>
        </div>

        <div class="mt-12 flex flex-col gap-5 border-t border-white pt-6 sm:flex-row sm:items-center sm:justify-between">
          <p class="text-sm">
            © 2026 Glocal Healthcare Centre of Excellence. All rights reserved.
          </p>
          <div class="flex flex-wrap gap-3">
            <a
              href="#"
              target="_blank"
              aria-label="Facebook"
              class="flex h-10 w-10 items-center justify-center rounded-md border border-white bg-white hover:opacity-80"
            >
              <svg viewBox="0 0 24 24" aria-hidden="true" class="h-5 w-5" fill="currentColor">
                <path d="M14 8h3V4h-3c-3.3 0-5 2-5 5v2H6v4h3v5h4v-5h3.2l.8-4h-4V9c0-.7.3-1 1-1Z" />
              </svg>
            </a>
            <a
              href="#"
              target="_blank"
              aria-label="LinkedIn"
              class="flex h-10 w-10 items-center justify-center rounded-md border border-white bg-white hover:opacity-80"
            >
              <svg viewBox="0 0 24 24" aria-hidden="true" class="h-5 w-5" fill="currentColor">
                <path d="M6.5 8.8H3V21h3.5V8.8ZM4.8 3a2 2 0 1 0 0 4.1 2 2 0 0 0 0-4.1ZM21 14.2c0-3.3-1.8-5.7-4.8-5.7-1.7 0-2.8.9-3.3 1.8V8.8H9.4V21h3.5v-6.4c0-1.7.8-2.7 2.2-2.7s2.3 1 2.3 2.7V21H21v-6.8Z" />
              </svg>
            </a>
            <a
              href="#"
              target="_blank"
              aria-label="YouTube"
              class="flex h-10 w-10 items-center justify-center rounded-md border border-white bg-white hover:opacity-80"
            >
              <svg viewBox="0 0 24 24" aria-hidden="true" class="h-5 w-5" fill="currentColor">
                <path d="M21.6 7.2a3 3 0 0 0-2.1-2.1C17.6 4.6 12 4.6 12 4.6s-5.6 0-7.5.5a3 3 0 0 0-2.1 2.1C2 9.1 2 12 2 12s0 2.9.4 4.8a3 3 0 0 0 2.1 2.1c1.9.5 7.5.5 7.5.5s5.6 0 7.5-.5a3 3 0 0 0 2.1-2.1c.4-1.9.4-4.8.4-4.8s0-2.9-.4-4.8ZM10 15.5v-7l6 3.5-6 3.5Z" />
              </svg>
            </a>
            <a
              href="#"
              target="_blank"
              aria-label="X"
              class="flex h-10 w-10 items-center justify-center rounded-md border border-white bg-white text-sm font-bold hover:opacity-80"
            >
              X
            </a>
          </div>
        </div>
      </div>
    </footer>
    """
  end

  defp nav_link_class(true) do
    "inline-flex items-center rounded-full border-t-0 bg-[#cfd0fb] px-4 py-2 text-sm font-semibold text-black no-underline shadow-sm"
  end

  defp nav_link_class(false) do
    "inline-flex items-center rounded-full border-t-0 px-4 py-2 text-sm font-medium text-slate-600 no-underline transition hover:bg-white hover:text-slate-950"
  end

  defp mobile_nav_link_class(true) do
    "block rounded-2xl bg-[#eef2ff] px-4 py-3 text-[15px] font-semibold text-[#2f349f] no-underline ring-1 ring-[#d9defd]"
  end

  defp mobile_nav_link_class(false) do
    "block rounded-2xl px-4 py-3 text-[15px] font-medium text-slate-600 no-underline transition hover:bg-slate-50 hover:text-slate-950"
  end

  def public_phone_contacts do
    @phone_contacts
  end

  defp toggle_public_mobile_menu(js \\ %JS{}) do
    JS.toggle(js,
      to: "#public-mobile-menu",
      in:
        {"transition ease-out duration-200", "opacity-0 -translate-y-2",
         "opacity-100 translate-y-0"},
      out:
        {"transition ease-in duration-150", "opacity-100 translate-y-0",
         "opacity-0 -translate-y-2"}
    )
  end

  defp close_public_mobile_menu(js \\ %JS{}) do
    JS.hide(js,
      to: "#public-mobile-menu",
      transition:
        {"transition ease-in duration-150", "opacity-100 translate-y-0",
         "opacity-0 -translate-y-2"}
    )
  end

  def public_page_background_class do
    "bg-gradient-to-b from-[#cfd0fb] via-[#e9ebff] to-white"
  end

  def public_surface_background_class do
    "bg-gradient-to-b from-[#cfd0fb] via-[#e4e6ff] to-[#f8f8ff]"
  end

  defp footer_link_class(true) do
    "block break-words font-semibold no-underline"
  end

  defp footer_link_class(false) do
    "block break-words no-underline hover:opacity-80"
  end

  defp public_site_assigns(assigns) do
    assign(assigns,
      primary_phone_display: @primary_phone_display,
      primary_phone_href: @primary_phone_href,
      secondary_phone_display: @secondary_phone_display,
      secondary_phone_href: @secondary_phone_href,
      phone_contacts: @phone_contacts,
      primary_email: @primary_email,
      address: @address
    )
  end
end
