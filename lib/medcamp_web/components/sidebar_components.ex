defmodule MedcampWeb.SidebarComponents do
  use Phoenix.Component
  use Gettext, backend: MedcampWeb.Gettext

  alias Phoenix.LiveView.JS

  alias MedcampWeb.SidebarCatalog

  @doc """
  Sticky mobile top bar: just the hamburger that opens the off-canvas sidebar,
  plus the click-catching backdrop behind it. Every authenticated layout
  renders this once, directly after `flash_group`; it is `lg:hidden` because
  at `lg`+ the sidebar is always on screen. The behaviour lives in the
  `SidebarCollapse` JS hook, which wires `#sidebar-mobile-open-btn` and
  `#sidebar-backdrop` and toggles `body.sidebar-mobile-open`.
  """
  attr :variant, :string, default: "tenant", values: ~w(tenant platform)

  def mobile_nav_bar(assigns) do
    ~H"""
    <div
      id="sidebar-backdrop"
      class="pointer-events-none fixed inset-0 z-40 bg-[#1f2433]/40 opacity-0 transition-opacity duration-200 lg:hidden"
      aria-hidden="true"
    >
    </div>

    <div class="sticky top-0 z-30 flex items-center border-b border-slate-200 bg-white/95 px-3 py-2.5 shadow-sm backdrop-blur lg:hidden">
      <button
        id="sidebar-mobile-open-btn"
        type="button"
        class={[
          "flex h-10 w-10 items-center justify-center rounded-xl border border-slate-200 bg-white transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2",
          @variant == "platform" && "text-[#0C2765] hover:bg-slate-50 focus-visible:ring-[#52B2D8]",
          @variant == "tenant" &&
            "text-brand-primary hover:bg-brand-50 focus-visible:ring-brand-accent"
        ]}
        aria-label="Open navigation"
      >
        <Heroicons.icon name="bars-3" type="outline" class="h-5 w-5" />
      </button>
    </div>
    """
  end

  def navbar_user(assigns) do
    ~H"""
    <nav class="shadow-sm sticky top-0 z-40 bg-white">
      <div class="container mx-auto px-4 py-3 flex justify-between items-center">
        <div class="flex items-center">
          <div class="text-2xl font-bold flex flex-col justify-center items-center text-brand-accent">
            <img src="/images/logo.png" alt="GHC Excellence Logo" class="h-[80px] object-contain" />
          </div>
        </div>

        <div class="hidden md:flex items-center space-x-8">
          <a href="/" class="font-medium hover:text-brand-accent transition-colors">Home</a>
          <a href="/" class="font-medium hover:text-brand-accent transition-colors">About Us</a>
          <a href="/" class="font-medium hover:text-brand-accent transition-colors">Services</a>
          <a href="/" class="font-medium hover:text-brand-accent transition-colors">Traceability</a>
          <a href="/" class="font-medium hover:text-brand-accent transition-colors">Contact</a>

          <.link
            href="/users/log_in"
            class="bg-brand-accent text-white px-4 py-2 rounded-md hover:bg-brand-accent-dark transition-colors"
          >
            Login
          </.link>
        </div>

        <div class="md:hidden">
          <button class="text-gray-600 hover:text-brand-accent">
            <i class="fa fa-bars text-2xl"></i>
          </button>
        </div>
      </div>
    </nav>
    """
  end

  def footer_user(assigns) do
    ~H"""
    <footer class="bg-brand-primary text-white py-12">
      <div class="container mx-auto px-4">
        <div class="grid grid-cols-1 md:grid-cols-4 gap-8">
          <div>
            <h3 class="text-xl font-bold mb-4">GHC Excellence</h3>
            <p class="mb-4">
              Leading healthcare provider in Kenya with advanced traceability standards for patient safety and care quality.
            </p>
            <div class="flex space-x-4">
              <a href="/" class="text-white hover:text-brand-200">
                <i class="fa fa-facebook-f"></i>
              </a>
              <a href="/" class="text-white hover:text-brand-200"><i class="fa fa-twitter"></i></a>
              <a href="/" class="text-white hover:text-brand-200">
                <i class="fa fa-linkedin"></i>
              </a>
              <a href="/" class="text-white hover:text-brand-200">
                <i class="fa fa-instagram"></i>
              </a>
            </div>
          </div>

          <div>
            <h3 class="text-xl font-bold mb-4">Our Services</h3>
            <ul class="space-y-2">
              <li><a href="/" class="hover:text-brand-200">General Medicine</a></li>
              <li><a href="/" class="hover:text-brand-200">Pediatrics</a></li>
              <li><a href="/" class="hover:text-brand-200">Obstetrics & Gynecology</a></li>
              <li><a href="/" class="hover:text-brand-200">Surgery</a></li>
              <li><a href="/" class="hover:text-brand-200">Laboratory Services</a></li>
              <li><a href="/" class="hover:text-brand-200">Radiology</a></li>
            </ul>
          </div>

          <div>
            <h3 class="text-xl font-bold mb-4">Quick Links</h3>
            <ul class="space-y-2">
              <li><a href="/" class="hover:text-brand-200">About Us</a></li>
              <li><a href="/" class="hover:text-brand-200">Traceability Standards</a></li>
              <li><a href="/" class="hover:text-brand-200">Patient Portal</a></li>
              <li><a href="/" class="hover:text-brand-200">Careers</a></li>
              <li><a href="/" class="hover:text-brand-200">News & Events</a></li>
              <li><a href="/" class="hover:text-brand-200">Contact Us</a></li>
            </ul>
          </div>

          <div>
            <h3 class="text-xl font-bold mb-4">Working Hours</h3>
            <ul class="space-y-2">
              <li class="pt-2 font-semibold">Open 24/7</li>
            </ul>
          </div>
        </div>

        <div class="border-t border-[#4e50a7] mt-10 pt-6 text-center">
          <p>
            2025 GHC Excellence, a subsidiary of <a
              href="https://gs1kenya.org/"
              class="underline hover:text-brand-200"
            >GS1 Kenya</a>. All rights reserved.
          </p>
        </div>
      </div>
    </footer>
    """
  end

  def doctor_sidebar(assigns) do
    assigns =
      assign(
        assigns,
        :groups,
        SidebarCatalog.visible_tab_groups(assigns.current_user, "doctor")
      )

    ~H"""
    <aside
      id="main-sidebar"
      phx-hook="SidebarCollapse"
      class="fixed top-0 left-0 z-40 w-72 h-screen transition-transform -translate-x-full lg:translate-x-0"
      aria-label="Sidebar"
    >
      <div class="h-full flex flex-col overflow-y-auto border-r border-[#edf0f8] bg-white px-5 py-6">
        <.top_base_sidebar current_user={@current_user} name="Doctor's Panel" />

        <ul class="space-y-1 font-medium flex-1">
          <.sidebar_card
            tab={
              %{
                name: "Dashboard",
                icon: "squares-2x2",
                url: "/doctor/dashboard",
                tab_name: :dashboard
              }
            }
            active_tab={@active_tab}
            current_user={@current_user}
          />

          <%= for group <- @groups do %>
            <.sidebar_section group={group} active_tab={@active_tab} current_user={@current_user} />
          <% end %>
        </ul>

        <.bottom_base_sidebar current_user={@current_user} />
      </div>
    </aside>
    """
  end

  def nurse_sidebar(assigns) do
    assigns =
      assign(
        assigns,
        :groups,
        SidebarCatalog.visible_tab_groups(assigns.current_user, "nurse")
      )

    ~H"""
    <aside
      id="main-sidebar"
      phx-hook="SidebarCollapse"
      class="fixed top-0 left-0 z-40 w-72 h-screen transition-transform -translate-x-full lg:translate-x-0"
      aria-label="Sidebar"
    >
      <div class="h-full flex flex-col overflow-y-auto border-r border-[#edf0f8] bg-white px-5 py-6">
        <.top_base_sidebar current_user={@current_user} name="Nurse's Panel" />

        <ul class="space-y-1 font-medium flex-1">
          <.sidebar_card
            tab={
              %{
                name: "Dashboard",
                icon: "squares-2x2",
                url: "/nurse/dashboard",
                tab_name: :dashboard
              }
            }
            active_tab={@active_tab}
            current_user={@current_user}
          />

          <%= for group <- @groups do %>
            <.sidebar_section group={group} active_tab={@active_tab} current_user={@current_user} />
          <% end %>
        </ul>

        <.bottom_base_sidebar current_user={@current_user} />
      </div>
    </aside>
    """
  end

  def admin_sidebar(assigns) do
    assigns =
      assign(
        assigns,
        :groups,
        SidebarCatalog.visible_tab_groups(assigns.current_user, "admin")
      )

    ~H"""
    <aside
      id="main-sidebar"
      phx-hook="SidebarCollapse"
      class="fixed top-0 left-0 z-40 w-72 h-screen transition-transform -translate-x-full lg:translate-x-0"
      aria-label="Sidebar"
    >
      <div class="h-full flex flex-col overflow-y-auto border-r border-[#edf0f8] bg-white px-5 py-6">
        <.top_base_sidebar current_user={@current_user} name="Admin Panel" />

        <ul class="space-y-1 font-medium flex-1">
          <%!-- Standalone Dashboard link --%>
          <.sidebar_card
            tab={
              %{name: "Dashboard", icon: "home-modern", url: "/admin/dashboard", tab_name: :dashboard}
            }
            active_tab={@active_tab}
            current_user={@current_user}
          />

          <%!-- Grouped sections --%>
          <%= for group <- @groups do %>
            <.sidebar_section group={group} active_tab={@active_tab} current_user={@current_user} />
          <% end %>
        </ul>

        <.bottom_base_sidebar current_user={@current_user} />
      </div>
    </aside>
    """
  end

  # The platform console sits outside every tenant, so it wears the fixed
  # Tibasasa palette (docs/DESIGN.md) rather than the tenant `brand-*` tokens
  # the role sidebars use. Self-contained on purpose — it keeps the
  # `sidebar-*` class hooks the collapse CSS needs but none of the brand
  # colours.
  def superadmin_sidebar(assigns) do
    ~H"""
    <aside
      id="main-sidebar"
      phx-hook="SidebarCollapse"
      class="sidebar-platform fixed left-0 top-0 z-40 h-screen w-72 -translate-x-full transition-transform lg:translate-x-0"
      aria-label="Sidebar"
    >
      <div class="flex h-full flex-col overflow-y-auto border-r border-slate-200 bg-white px-5 py-6">
        <div class="mb-6">
          <div class="sidebar-top-section sidebar-brand-row mb-4 flex items-center justify-between gap-3">
            <a href="/" class="flex min-w-0 items-center gap-2.5">
              <img
                src="/images/tibasasa-ai-logo.png"
                alt="Tibasasa"
                class="h-10 w-10 shrink-0 object-contain"
              />
              <span class="sidebar-brand-copy min-w-0 leading-tight">
                <span class="block truncate text-base font-bold text-[#0C2765]">Tibasasa</span>
                <span class="block truncate text-xs font-medium text-slate-500">
                  Platform Console
                </span>
              </span>
            </a>

            <button
              id="sidebar-toggle-btn"
              type="button"
              title="Toggle sidebar"
              aria-label="Toggle sidebar"
              class="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl border border-slate-200 bg-white text-[#0C2765] transition-colors hover:bg-slate-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#52B2D8] focus-visible:ring-offset-2"
            >
              <Heroicons.icon name="chevron-left" type="outline" class="sidebar-chevron h-4 w-4" />
            </button>
          </div>

          <div class="sidebar-account-card rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3.5">
            <div class="flex items-center gap-3">
              <div class="flex h-11 w-11 shrink-0 items-center justify-center overflow-hidden rounded-full bg-[#0C2765] text-[15px] font-bold text-white">
                <%= if @current_user.image do %>
                  <img src={@current_user.image} alt="" class="h-full w-full object-cover" />
                <% else %>
                  {user_initials(@current_user)}
                <% end %>
              </div>
              <div class="min-w-0">
                <p class="truncate text-[15px] font-bold leading-tight text-slate-900">
                  {@current_user.name}
                </p>
                <p class="truncate text-[13px] font-medium leading-snug text-slate-500">
                  Signed-in account
                </p>
              </div>
            </div>
          </div>
        </div>

        <ul class="flex-1 space-y-1 font-medium">
          <.superadmin_nav_item
            label="Dashboard"
            icon="home-modern"
            url="/superadmin/dashboard"
            active={@active_tab == :dashboard}
          />
          <.superadmin_nav_item
            label="Organisations"
            icon="building-office-2"
            url="/superadmin/organisations"
            active={@active_tab == :organisations}
          />
          <.superadmin_nav_item
            label="Camps"
            icon="calendar-days"
            url="/superadmin/camps"
            active={@active_tab == :camps}
          />
        </ul>

        <div class="mt-auto border-t border-slate-200 pt-6">
          <.link
            href="/users/log_out"
            method="delete"
            class="sidebar-nav-item group relative flex min-h-[48px] items-center gap-3 rounded-xl px-4 py-3 text-[15px] font-semibold text-slate-600 transition-colors hover:bg-slate-50 hover:text-[#0C2765] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#52B2D8] focus-visible:ring-offset-2"
          >
            <Heroicons.icon
              name="arrow-right-on-rectangle"
              type="outline"
              class="h-5 w-5 shrink-0 stroke-2"
            />
            <span class="sidebar-label truncate">Sign out</span>
            <span class="sidebar-tooltip" role="tooltip">Sign out</span>
          </.link>
        </div>
      </div>
    </aside>
    """
  end

  attr :label, :string, required: true
  attr :icon, :string, required: true
  attr :url, :string, required: true
  attr :active, :boolean, default: false

  defp superadmin_nav_item(assigns) do
    ~H"""
    <li class="relative">
      <.link
        navigate={@url}
        aria-current={if @active, do: "page", else: nil}
        class={[
          "sidebar-nav-item group relative flex min-h-[48px] items-center gap-3 rounded-xl px-4 py-3 text-[15px] font-semibold transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#52B2D8] focus-visible:ring-offset-2",
          if(@active,
            do: "bg-[#e9f6fb] text-[#0C2765]",
            else: "text-slate-600 hover:bg-slate-50 hover:text-[#0C2765]"
          )
        ]}
      >
        <Heroicons.icon
          name={@icon}
          type="outline"
          class={[
            "h-5 w-5 shrink-0 stroke-[2]",
            if(@active, do: "text-[#0C2765]", else: "text-slate-500 group-hover:text-[#0C2765]")
          ]}
        />
        <span class="sidebar-label truncate">{@label}</span>
        <span class="sidebar-tooltip" role="tooltip">{@label}</span>
      </.link>
    </li>
    """
  end

  @spec lab_sidebar(any()) :: Phoenix.LiveView.Rendered.t()
  def lab_sidebar(assigns) do
    assigns =
      assign(
        assigns,
        :groups,
        SidebarCatalog.visible_tab_groups(assigns.current_user, "labtechnician")
      )

    ~H"""
    <aside
      id="main-sidebar"
      phx-hook="SidebarCollapse"
      class="fixed top-0 left-0 z-40 w-72 h-screen transition-transform -translate-x-full lg:translate-x-0"
      aria-label="Sidebar"
    >
      <div class="flex h-full flex-col overflow-y-auto border-r border-[#edf0f8] bg-white px-5 py-6">
        <.top_base_sidebar current_user={@current_user} name="Lab Technologist's Panel" />

        <ul class="flex-1 space-y-1 font-medium">
          <.sidebar_card
            tab={
              %{name: "Dashboard", icon: "squares-2x2", url: "/lab/dashboard", tab_name: :dashboard}
            }
            active_tab={@active_tab}
            current_user={@current_user}
          />

          <%= for group <- @groups do %>
            <.sidebar_section group={group} active_tab={@active_tab} current_user={@current_user} />
          <% end %>
        </ul>

        <.bottom_base_sidebar current_user={@current_user} />
      </div>
    </aside>
    """
  end

  def pharmacist_sidebar(assigns) do
    assigns =
      assign(
        assigns,
        :groups,
        SidebarCatalog.visible_tab_groups(assigns.current_user, "pharmacist")
      )

    ~H"""
    <aside
      id="main-sidebar"
      phx-hook="SidebarCollapse"
      class="fixed top-0 left-0 z-40 w-72 h-screen transition-transform -translate-x-full lg:translate-x-0"
      aria-label="Sidebar"
    >
      <div class="h-full flex flex-col overflow-y-auto border-r border-[#edf0f8] bg-white px-5 py-6">
        <.top_base_sidebar current_user={@current_user} name="Pharmacist's Panel" />

        <ul class="space-y-1 font-medium flex-1">
          <.sidebar_card
            tab={
              %{
                name: "Dashboard",
                icon: "squares-2x2",
                url: "/pharmacist/dashboard",
                tab_name: :dashboard
              }
            }
            active_tab={@active_tab}
            current_user={@current_user}
          />

          <%= for group <- @groups do %>
            <.sidebar_section group={group} active_tab={@active_tab} current_user={@current_user} />
          <% end %>
        </ul>

        <.bottom_base_sidebar current_user={@current_user} />
      </div>
    </aside>
    """
  end

  def each_patient_sidebar(assigns) do
    assigns =
      assign(
        assigns,
        :patient_tabs,
        SidebarCatalog.visible_patient_tabs(assigns.current_user, "doctor", assigns.patient)
      )

    ~H"""
    <aside
      id="main-sidebar"
      phx-hook="SidebarCollapse"
      class="fixed top-0 left-0 z-40 w-72 h-screen transition-transform -translate-x-full lg:translate-x-0"
      aria-label="Sidebar"
    >
      <div class="h-full flex flex-col overflow-y-auto border-r border-[#edf0f8] bg-white px-5 py-6">
        <.top_base_sidebar current_user={@current_user} name="Doctor's Panel" />

        <ul class="space-y-1.5 font-medium flex-1">
          <%= for tab <- @patient_tabs do %>
            <.sidebar_card tab={tab} active_tab={@active_tab} current_user={@current_user} />
          <% end %>
        </ul>

        <.bottom_base_sidebar current_user={@current_user} />
      </div>
    </aside>
    """
  end

  def shared_sidebar(assigns) do
    ~H"""
    <aside
      id="main-sidebar"
      phx-hook="SidebarCollapse"
      class="fixed top-0 left-0 z-40 w-72 h-screen transition-transform -translate-x-full lg:translate-x-0"
      aria-label="Sidebar"
    >
      <div class="h-full flex flex-col overflow-y-auto border-r border-[#edf0f8] bg-white px-5 py-6">
        <.top_base_sidebar current_user={@current_user} name="Staff Resources" />

        <ul class="space-y-1.5 font-medium flex-1">
          <%= for tab <- shared_tabs(@current_user) do %>
            <.sidebar_card tab={tab} active_tab={@active_tab} current_user={@current_user} />
          <% end %>
        </ul>

        <.bottom_base_sidebar current_user={@current_user} />
      </div>
    </aside>
    """
  end

  def pharmacist_each_patient_sidebar(assigns) do
    assigns =
      assign(
        assigns,
        :patient_tabs,
        SidebarCatalog.visible_patient_tabs(assigns.current_user, "pharmacist", assigns.patient)
      )

    ~H"""
    <aside
      id="main-sidebar"
      phx-hook="SidebarCollapse"
      class="fixed top-0 left-0 z-40 w-72 h-screen transition-transform -translate-x-full lg:translate-x-0"
      aria-label="Sidebar"
    >
      <div class="h-full flex flex-col overflow-y-auto border-r border-[#edf0f8] bg-white px-5 py-6">
        <.top_base_sidebar current_user={@current_user} name="Pharmacist's Panel" />

        <ul class="space-y-1.5 font-medium flex-1">
          <%= for tab <- @patient_tabs do %>
            <.sidebar_card tab={tab} active_tab={@active_tab} current_user={@current_user} />
          <% end %>
        </ul>

        <.bottom_base_sidebar current_user={@current_user} />
      </div>
    </aside>
    """
  end

  def lab_each_patient_sidebar(assigns) do
    assigns =
      assign(
        assigns,
        :patient_tabs,
        SidebarCatalog.visible_patient_tabs(
          assigns.current_user,
          "labtechnician",
          assigns.patient
        )
      )

    ~H"""
    <aside
      id="main-sidebar"
      phx-hook="SidebarCollapse"
      class="fixed top-0 left-0 z-40 w-72 h-screen transition-transform -translate-x-full lg:translate-x-0"
      aria-label="Sidebar"
    >
      <div class="flex h-full flex-col overflow-y-auto border-r border-[#edf0f8] bg-white px-5 py-6">
        <.top_base_sidebar current_user={@current_user} name="Lab Technologist's Panel" />

        <ul class="flex-1 space-y-1.5 font-medium">
          <%= for tab <- @patient_tabs do %>
            <.sidebar_card tab={tab} active_tab={@active_tab} current_user={@current_user} />
          <% end %>
        </ul>

        <.bottom_base_sidebar current_user={@current_user} />
      </div>
    </aside>
    """
  end

  def nurse_each_patient_sidebar(assigns) do
    assigns =
      assign(
        assigns,
        :patient_tabs,
        SidebarCatalog.visible_patient_tabs(assigns.current_user, "nurse", assigns.patient)
      )

    ~H"""
    <aside
      id="main-sidebar"
      phx-hook="SidebarCollapse"
      class="fixed top-0 left-0 z-40 w-72 h-screen transition-transform -translate-x-full lg:translate-x-0"
      aria-label="Sidebar"
    >
      <div class="h-full flex flex-col overflow-y-auto border-r border-[#edf0f8] bg-white px-5 py-6">
        <.top_base_sidebar current_user={@current_user} name="Nurse's Panel" />

        <ul class="space-y-1.5 font-medium flex-1">
          <%= for tab <- @patient_tabs do %>
            <.sidebar_card tab={tab} active_tab={@active_tab} current_user={@current_user} />
          <% end %>
        </ul>

        <.bottom_base_sidebar current_user={@current_user} />
      </div>
    </aside>
    """
  end

  def sidebar_card(assigns) do
    assigns = assign(assigns, :count, sidebar_badge_count(assigns.tab))

    ~H"""
    <li class="relative">
      <.link
        navigate={resolve_sidebar_tab_url(@tab, @current_user)}
        aria-current={if @active_tab == @tab.tab_name, do: "page", else: nil}
        class={[
          "sidebar-nav-item group relative flex min-h-[48px] items-center gap-3 rounded-xl px-4 py-3 text-[15px] font-semibold transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-accent focus-visible:ring-offset-2",
          if(@active_tab == @tab.tab_name,
            do: "bg-brand-100 text-brand-primary ring-1 ring-brand-200",
            else: "text-[#687083] hover:bg-brand-50 hover:text-brand-primary"
          )
        ]}
      >
        <Heroicons.icon
          name={@tab.icon}
          type="outline"
          class={
            "h-5 w-5 shrink-0 stroke-[2] " <>
            if @active_tab == @tab.tab_name do
              "text-brand-primary"
            else
              "text-[#687083] group-hover:text-brand-primary"
            end
          }
        />
        <div class="sidebar-label flex min-w-0 flex-1 items-center justify-between gap-3">
          <span class="truncate">{@tab.name}</span>
          <span
            :if={@count}
            class="shrink-0 rounded-full bg-brand-primary px-2 py-0.5 text-[11px] font-bold text-white"
          >
            {@count}
          </span>
        </div>
        <span class="sidebar-tooltip" role="tooltip">{@tab.name}</span>
      </.link>
    </li>
    """
  end

  attr :group, :map, required: true
  attr :active_tab, :any, required: true
  attr :current_user, :map, required: true

  defp sidebar_section(%{group: %{tabs: [tab]}} = assigns) do
    assigns = assign(assigns, :tab, tab)

    ~H"""
    <.sidebar_card tab={@tab} active_tab={@active_tab} current_user={@current_user} />
    """
  end

  defp sidebar_section(assigns) do
    ~H"""
    <.sidebar_group group={@group} active_tab={@active_tab} current_user={@current_user} />
    """
  end

  defp sidebar_group(assigns) do
    group_active? =
      Enum.any?(assigns.group.tabs, fn tab -> tab.tab_name == assigns.active_tab end)

    assigns =
      assigns
      |> assign(:group_active?, group_active?)
      |> assign(:group_id, "sidebar-group-#{assigns.group.key}")

    ~H"""
    <li>
      <button
        type="button"
        phx-click={
          JS.toggle(
            to: "##{@group_id}-items",
            in: {"transition-all duration-150", "opacity-0 max-h-0", "opacity-100 max-h-screen"},
            out: {"transition-all duration-150", "opacity-100 max-h-screen", "opacity-0 max-h-0"}
          )
          |> JS.toggle_class("rotate-90", to: "##{@group_id}-chevron")
        }
        class={[
          "sidebar-nav-item group relative flex min-h-[48px] w-full items-center gap-3 rounded-xl px-4 py-3 text-[15px] font-semibold transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-accent focus-visible:ring-offset-2",
          if(@group_active?,
            do: "text-brand-primary hover:bg-brand-50",
            else: "text-[#687083] hover:bg-brand-50 hover:text-brand-primary"
          )
        ]}
      >
        <Heroicons.icon
          name={@group.icon}
          type="outline"
          class={
            "h-5 w-5 shrink-0 stroke-2 #{if(@group_active?, do: "text-brand-primary", else: "text-[#687083] group-hover:text-brand-primary")}"
          }
        />
        <span class="sidebar-label flex min-w-0 flex-1 items-center justify-between gap-2">
          <span class="truncate">{@group.name}</span>
          <span class="flex shrink-0 items-center gap-1.5">
            <span class="rounded-full bg-slate-100 px-2 py-0.5 text-[11px] font-bold text-slate-500">
              {length(@group.tabs)}
            </span>
            <Heroicons.icon
              id={"#{@group_id}-chevron"}
              name="chevron-right"
              type="outline"
              class={"h-4 w-4 transition-transform duration-150 #{if(@group_active?, do: "rotate-90", else: "")}"}
            />
          </span>
        </span>
      </button>

      <ul
        id={"#{@group_id}-items"}
        class={[
          "mt-0.5 ml-4 space-y-0.5 border-l border-[#edf0f8] pl-3 overflow-hidden",
          if(@group_active?, do: "", else: "hidden")
        ]}
      >
        <%= for tab <- @group.tabs do %>
          <.sidebar_card tab={tab} active_tab={@active_tab} current_user={@current_user} />
        <% end %>
      </ul>
    </li>
    """
  end

  defp resolve_sidebar_tab_url(%{url: url}, _current_user), do: url

  defp shared_tabs(user) do
    [
      %{
        name: "Back To Panel",
        icon: "arrow-left-on-rectangle",
        url: get_back_to_panel_url(user.role),
        tab_name: :back_to_panel
      }
    ]
  end

  defp get_back_to_panel_url(role) do
    case role do
      "doctor" -> "/doctor/patients"
      "nurse" -> "/nurse/scan"
      "pharmacist" -> "/pharmacist/scan"
      "labtechnician" -> "/lab/scan"
      "admin" -> "/admin/dashboard"
      _ -> "/"
    end
  end

  defp top_base_sidebar(assigns) do
    # Every sidebar renders through here, so resolving the organisation once
    # in this component brands all eleven of them without threading an extra
    # attr through each sidebar function and each layout template.
    assigns =
      assign_new(assigns, :organisation, fn ->
        Medcamp.Organisations.get_user_organisation(assigns[:current_user])
      end)

    ~H"""
    <div class="mb-6">
      <div class="sidebar-top-section sidebar-brand-row mb-4 flex items-center justify-between gap-3">
        <div class="flex min-w-0 items-center gap-3">
          <div class="flex h-11 w-11 shrink-0 items-center justify-center overflow-hidden rounded-xl border border-brand-300 bg-brand-50 text-[13px] font-bold text-brand-primary">
            <%= if @organisation && @organisation.logo do %>
              <img
                src={@organisation.logo}
                alt={@organisation.name}
                class="h-full w-full object-contain"
              />
            <% else %>
              {MedcampWeb.Layouts.organisation_initials(@organisation)}
            <% end %>
          </div>

          <div class="sidebar-brand-copy min-w-0">
            <p class="truncate text-[17px] font-bold leading-tight text-brand-primary">
              {MedcampWeb.Layouts.organisation_name(%{current_organisation: @organisation})}
            </p>
            <p class="truncate text-[13px] font-medium leading-snug text-[#687083]">{@name}</p>
          </div>
        </div>

        <button
          id="sidebar-toggle-btn"
          type="button"
          title="Toggle sidebar"
          aria-label="Toggle sidebar"
          class="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl border border-[#e2e6f0] bg-white text-brand-primary transition-colors hover:bg-brand-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-accent focus-visible:ring-offset-2"
        >
          <Heroicons.icon name="chevron-left" type="outline" class="sidebar-chevron h-4 w-4" />
        </button>
      </div>

      <div class="sidebar-account-card rounded-2xl border border-[#e8ebf3] bg-[#fbfbff] px-4 py-3.5">
        <div class="flex items-center gap-3">
          <div class="flex h-11 w-11 shrink-0 items-center justify-center overflow-hidden rounded-full bg-brand-primary text-[15px] font-bold text-white">
            <%= if @current_user.image do %>
              <img src={@current_user.image} alt="User Avatar" class="h-full w-full object-cover" />
            <% else %>
              {user_initials(@current_user)}
            <% end %>
          </div>

          <div class="min-w-0">
            <p class="truncate text-[15px] font-bold leading-tight text-[#1f2433]">
              {@current_user.name}
            </p>
            <p class="truncate text-[13px] font-medium leading-snug text-[#687083]">
              Signed-in account
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp bottom_base_sidebar(assigns) do
    ~H"""
    <div class="mt-auto border-t border-[#e8ebf3] pt-6">
      <div class="flex flex-col space-y-1.5">
        <.sidebar_utility_link
          navigate={get_settings_url(@current_user.role)}
          icon="cog-6-tooth"
          label="Settings"
        />

        <.sidebar_utility_link
          href="/users/log_out"
          method="delete"
          icon="arrow-right-on-rectangle"
          label="Sign Out"
          tone="danger"
        />
      </div>
    </div>
    """
  end

  attr :navigate, :string, default: nil
  attr :href, :string, default: nil
  attr :method, :string, default: nil
  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :tone, :string, default: "default"

  defp sidebar_utility_link(assigns) do
    ~H"""
    <.link
      navigate={@navigate}
      href={@href}
      method={@method}
      class={[
        "sidebar-nav-item group relative flex min-h-[48px] items-center gap-3 rounded-xl px-4 py-3 text-[15px] font-semibold transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-accent focus-visible:ring-offset-2",
        if(@tone == "danger",
          do: "text-[#c21f17] hover:bg-red-50",
          else: "text-[#687083] hover:bg-brand-50 hover:text-brand-primary"
        )
      ]}
    >
      <Heroicons.icon
        name={@icon}
        type="outline"
        class={
          "h-5 w-5 shrink-0 stroke-[2] #{if(@tone == "danger", do: "text-current", else: "group-hover:text-brand-primary")}"
        }
      />
      <span class="sidebar-label flex-1 whitespace-nowrap">{@label}</span>
      <span class="sidebar-tooltip" role="tooltip">{@label}</span>
    </.link>
    """
  end

  defp get_settings_url(role) do
    case role do
      "doctor" -> "/doctor/settings"
      "nurse" -> "/nurse/settings"
      "admin" -> "/admin/settings"
      "pharmacist" -> "/pharmacist/settings"
      "labtechnician" -> "/lab/settings"
      _ -> "/users/settings"
    end
  end

  defp user_initials(nil), do: "GH"

  defp user_initials(user) do
    user
    |> Map.get(:name)
    |> case do
      name when is_binary(name) and name != "" -> name
      _ -> Map.get(user, :email, "GHC")
    end
    |> String.split(~r/\s+/, trim: true)
    |> Enum.take(2)
    |> Enum.map_join(&String.first/1)
    |> String.upcase()
    |> case do
      "" -> "GH"
      initials -> initials
    end
  end

  defp sidebar_badge_count(%{count: count}) when is_integer(count) and count > 0, do: count
  defp sidebar_badge_count(_tab), do: nil
end
