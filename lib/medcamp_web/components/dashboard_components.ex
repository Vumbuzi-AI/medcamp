defmodule MedcampWeb.DashboardComponents do
  use Phoenix.Component
  import MedcampWeb.CoreComponents

  @doc """
  Dashboard stat card with metric, label, and optional trend
  """
  attr :label, :string, required: true
  attr :value, :string, required: true
  attr :icon, :string, default: "hero-chart-bar"
  attr :trend, :string, default: nil
  attr :color, :string, default: "blue"
  slot :inner_block

  def stat_card(assigns) do
    assigns = assign(assigns, :color_classes, color_classes(assigns.color))

    ~H"""
    <div class="bg-white rounded-2xl border border-slate-200 p-6 shadow-card transition-shadow hover:shadow-card-hover">
      <div class="flex items-start justify-between">
        <div class="flex-1">
          <p class="text-xs font-medium uppercase tracking-wide text-slate-500 mb-2">
            {@label}
          </p>
          <p class={"text-3xl font-bold leading-none #{@color_classes[:text]}"}>
            {@value}
          </p>
          <%= if @trend do %>
            <p class="text-sm text-slate-500 mt-3">{@trend}</p>
          <% end %>
        </div>
        <div class="flex shrink-0 items-center justify-center rounded-full bg-brand-50 p-3">
          <.icon name={@icon} class={"w-8 h-8 #{@color_classes[:text]}"} />
        </div>
      </div>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Chart container wrapper
  """
  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :type, :string, default: "line"

  def chart_card(assigns) do
    ~H"""
    <div class="bg-white rounded-2xl border border-slate-200 p-6 shadow-card">
      <h3 class="text-lg font-semibold text-slate-900 mb-4">{@title}</h3>
      <canvas id={@id} class="w-full h-80"></canvas>
    </div>
    """
  end

  @doc """
  Quick action button for dashboard
  """
  attr :label, :string, required: true
  attr :icon, :string, default: "hero-plus"
  attr :href, :string, default: "#"
  attr :color, :string, default: "blue"

  def quick_action(assigns) do
    assigns = assign(assigns, :bg_class, quick_action_bg(assigns.color))

    ~H"""
    <.link href={@href} class="block">
      <div class={@bg_class <> " rounded-xl p-4 text-center shadow-card transition-shadow hover:shadow-card-hover cursor-pointer"}>
        <.icon name={@icon} class="w-6 h-6 text-white mx-auto mb-2.5" />
        <p class="text-sm font-semibold text-white">{@label}</p>
      </div>
    </.link>
    """
  end

  @doc """
  Recent items list
  """
  attr :title, :string, required: true
  attr :items, :list, required: true
  attr :empty_message, :string, default: "No items yet"

  def recent_items(assigns) do
    ~H"""
    <div class="bg-white rounded-2xl border border-slate-200 p-6 shadow-card">
      <h3 class="text-xl font-semibold text-slate-900 mb-5">{@title}</h3>
      <%= if Enum.empty?(@items) do %>
        <p class="text-center py-8 text-sm text-slate-500">{@empty_message}</p>
      <% else %>
        <div class="space-y-3.5">
          <%= for item <- @items do %>
            <div class="flex items-center justify-between p-4 border border-slate-200 rounded-xl hover:bg-slate-50 transition-colors">
              <div class="flex-1">
                <p class="text-sm font-semibold text-slate-900">
                  {item.title}
                </p>
                <p class="text-sm text-slate-500 mt-1">{item.subtitle}</p>
              </div>
              <%= if item.badge do %>
                <span class={"px-3 py-1 text-xs font-semibold rounded-full #{item.badge_color}"}>
                  {item.badge}
                </span>
              <% end %>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  # Two-tone glyphs on the tint tile. The medic per-metric rainbow is gone;
  # instead every metric resolves to navy or cyan (both from the org's
  # `brand-*` palette) so a KPI row alternates without leaving the palette.
  # "Cool"/primary counts read navy; activity/flow counts read cyan.
  @cyan_metrics ~w(green emerald teal cyan blue amber orange)
  defp color_classes(color) when color in @cyan_metrics,
    do: %{text: "text-brand-accent", bg: "bg-brand-50 rounded-full p-3"}

  defp color_classes(_color),
    do: %{text: "text-brand-primary", bg: "bg-brand-50 rounded-full p-3"}

  defp quick_action_bg(color) when color in @cyan_metrics, do: "bg-brand-accent"
  defp quick_action_bg(_color), do: "bg-brand-primary"

  # ============================================================
  # Shared role-based dashboard widgets (Admin / Doctor / Reception)
  #
  # These back the dashboard described in dashboard.md: one shared top
  # card, one shared summary-card grid, one shared analytics section,
  # whose *content* differs per role via MedcampWeb.Dashboards.WidgetResolver.
  # ============================================================

  @doc """
  The shared page top card: title, subtitle, optional search box, optional
  Filters button + panel. Used identically on the Admin/Doctor/Reception
  dashboards — only the title/subtitle/placeholder/filter fields differ,
  passed in by the caller.
  """
  attr :title, :string, required: true
  attr :subtitle, :string, default: nil

  attr :search_name, :string,
    default: nil,
    doc: "when set, renders a search box wired to phx-change={@search_event}"

  attr :search_value, :string, default: ""
  attr :search_placeholder, :string, default: "Search..."
  attr :search_event, :string, default: "search"

  attr :filter_id, :string,
    default: nil,
    doc: "when set, renders a Filters button + panel using the :filter_group slot"

  attr :filter_apply_event, :string, default: "filter"
  attr :filter_clear_event, :string, default: "clear_filters"
  attr :active_filter_count, :integer, default: 0

  slot :filter_group do
    attr :label, :string, required: true
  end

  slot :actions

  attr :camps, :list,
    default: [],
    doc: "when non-empty, renders the camp view selector in the toolbar"

  attr :camp_filter, :any, default: nil

  def dashboard_top_card(assigns) do
    ~H"""
    <div class="bg-white rounded-2xl border border-slate-200 p-5 sm:p-7 shadow-card">
      <div class="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-4 mb-5">
        <div>
          <h1 class="text-2xl sm:text-3xl font-bold text-slate-900">
            {@title}
          </h1>
          <p :if={@subtitle} class="text-sm text-slate-500 mt-2">
            {@subtitle}
          </p>
        </div>
        <div :if={@actions != []} class="flex items-center gap-2 shrink-0">
          {render_slot(@actions)}
        </div>
      </div>

      <div :if={@search_name || @filter_id || @camps != []} class="flex flex-wrap items-center gap-3">
        <form :if={@search_name} phx-change={@search_event} class="flex-1 min-w-[220px]">
          <.search_input name={@search_name} value={@search_value} placeholder={@search_placeholder} />
        </form>

        <MedcampWeb.CampComponents.camp_switcher
          :if={@camps != []}
          camps={@camps}
          camp_filter={@camp_filter}
        />

        <.filter_drawer
          :if={@filter_id}
          id={@filter_id}
          variant="solid"
          apply_event={@filter_apply_event}
          clear_event={@filter_clear_event}
          active_count={@active_filter_count}
        >
          <:group :for={group <- @filter_group} label={group.label}>
            {render_slot(group)}
          </:group>
        </.filter_drawer>
      </div>
    </div>
    """
  end

  @summary_card_meta %{
    total_patients: %{label: "Total Patients", icon: "users", color: "indigo"},
    patient_visits: %{label: "Patient Visits", icon: "home-modern", color: "blue"},
    returning_patients: %{label: "Returning Patients", icon: "arrow-path", color: "sky"},
    revenue_collected: %{label: "Revenue Collected", icon: "banknotes", color: "emerald"},
    appointments: %{label: "Appointments", icon: "clock", color: "amber"},
    doctor_notes: %{label: "Doctor Notes", icon: "document-text", color: "violet"},
    lab_tests_done: %{label: "Lab Tests Done", icon: "beaker", color: "teal"},
    active_system_users: %{label: "Active System Users", icon: "user-group", color: "cyan"},
    mpesa_transactions: %{label: "M-Pesa Transactions", icon: "credit-card", color: "rose"},
    triages_completed: %{
      label: "Triages Completed",
      icon: "clipboard-document-check",
      color: "indigo"
    },
    nurse_procedures: %{label: "Nurse Procedures", icon: "heart", color: "emerald"},
    room_allocations: %{label: "Room Allocations", icon: "building-office-2", color: "amber"},
    lab_results: %{label: "Lab Results", icon: "beaker", color: "teal"},
    completed_lab_reports: %{
      label: "Completed Lab Reports",
      icon: "document-check",
      color: "emerald"
    },
    pending_lab_results: %{label: "Pending Lab Reports", icon: "clock", color: "amber"},
    drug_allocations: %{
      label: "Drug Allocations",
      icon: "clipboard-document-list",
      color: "violet"
    },
    pending_drug_allocations: %{
      label: "Pending Drug Allocations",
      icon: "exclamation-circle",
      color: "amber"
    },
    pharmacy_stock_units: %{
      label: "Stock on Hand",
      icon: "archive-box-arrow-down",
      color: "blue"
    },
    pharmacy_stock_value: %{
      label: "Current Stock Value",
      icon: "banknotes",
      color: "emerald"
    },
    dispensed_units: %{
      label: "Units Dispensed",
      icon: "arrow-up-tray",
      color: "violet"
    },
    dispensed_value: %{
      label: "Dispensed Value",
      icon: "currency-dollar",
      color: "teal"
    },
    low_stock_items: %{label: "Low Stock Items", icon: "exclamation-triangle", color: "rose"},
    drug_catalog: %{label: "Drugs in Catalog", icon: "archive-box", color: "cyan"},
    platform_organisations: %{
      label: "Total Organisations",
      icon: "building-office-2",
      color: "indigo"
    },
    platform_active_organisations: %{
      label: "Active Organisations",
      icon: "check-badge",
      color: "blue"
    },
    platform_pending_approvals: %{
      label: "Pending Approvals",
      icon: "clock",
      color: "amber"
    },
    platform_total_camps: %{label: "Total Camps", icon: "calendar-days", color: "indigo"},
    platform_active_camps: %{label: "Active Camps", icon: "check-badge", color: "blue"},
    platform_camp_patients: %{label: "Patients Across Camps", icon: "users", color: "teal"},
    platform_camp_records: %{label: "Camp Records", icon: "document-text", color: "violet"},
    platform_returning_patients: %{
      label: "Returning Patients",
      icon: "arrow-path",
      color: "emerald"
    },
    radiology_exams: %{label: "Radiology Exams", icon: "film", color: "indigo"},
    completed_radiology_reports: %{
      label: "Completed Reports",
      icon: "document-check",
      color: "emerald"
    },
    pending_radiology_reports: %{label: "Pending Reviews", icon: "clock", color: "amber"},
    urgent_radiology_cases: %{label: "Urgent Cases", icon: "bolt", color: "rose"},
    inventory_items: %{label: "Inventory Items", icon: "cube", color: "blue"},
    inventories_received: %{
      label: "Inventories Received",
      icon: "inbox-arrow-down",
      color: "emerald"
    },
    inventories_issued: %{label: "Inventories Issued", icon: "inbox-stack", color: "violet"},
    stock_alerts: %{label: "Stock Alerts", icon: "bell-alert", color: "rose"}
  }

  @doc """
  Builds the list of card assigns for `summary_card_grid/1` from the atoms
  `MedcampWeb.Dashboards.WidgetResolver.summary_cards/1` returns for the
  current role, plus a `%{key => {value, helper}}` map of computed values.

      summary_cards_for([:total_patients, :patient_visits], %{
        total_patients: {5, "Registered patients"},
        patient_visits: {14, "Visits in selected window"}
      })
  """
  def summary_cards_for(visible_keys, values) do
    Enum.map(visible_keys, fn key ->
      meta = Map.fetch!(@summary_card_meta, key)
      {value, helper} = Map.fetch!(values, key)
      Map.merge(meta, %{key: key, value: value, helper: helper})
    end)
  end

  @doc """
  Renders the shared summary-card grid. Works for any subset of the full
  card set (3–8 cards) in a responsive grid — never assumes all 8 are
  present. Build `cards` with `summary_cards_for/2`.
  """
  attr :cards, :list, required: true

  def summary_card_grid(assigns) do
    assigns = assign(assigns, :grid_class, summary_card_grid_class(length(assigns.cards)))

    ~H"""
    <div class={["grid gap-5", @grid_class]}>
      <.summary_card
        :for={card <- @cards}
        label={card.label}
        value={card.value}
        helper={card.helper}
        icon={card.icon}
        color={card.color}
      />
    </div>
    """
  end

  defp summary_card_grid_class(0), do: "grid-cols-1"
  defp summary_card_grid_class(1), do: "grid-cols-1"
  defp summary_card_grid_class(2), do: "grid-cols-1 sm:grid-cols-2"
  defp summary_card_grid_class(3), do: "grid-cols-1 md:grid-cols-3"
  defp summary_card_grid_class(_), do: "grid-cols-1 sm:grid-cols-2 xl:grid-cols-4"

  attr :label, :string, required: true
  attr :value, :any, required: true
  attr :helper, :string, default: nil
  attr :icon, :string, required: true
  attr :color, :string, default: "indigo"

  defp summary_card(assigns) do
    ~H"""
    <div class="w-full min-w-0 overflow-hidden bg-white rounded-2xl border border-slate-200 px-5 sm:px-6 py-5 min-h-[128px] flex items-center shadow-card">
      <div class="flex w-full min-w-0 items-center gap-5">
        <div class={[
          "flex p-2 shrink-0 items-center justify-center rounded-full border border-slate-200",
          summary_icon_bg(@color)
        ]}>
          <Heroicons.icon name={@icon} type="outline" class={"h-7 w-7 #{summary_icon_color(@color)}"} />
        </div>
        <div class="min-w-0 flex-1">
          <p class="text-xs font-medium uppercase tracking-wide text-slate-500 truncate">
            {@label}
          </p>
          <p class="text-2xl font-bold text-brand-primary leading-none mt-2 truncate">
            {@value}
          </p>
          <p
            :if={@helper}
            class="max-w-full whitespace-normal break-words text-sm text-slate-500 mt-2 leading-snug"
          >
            {@helper}
          </p>
        </div>
      </div>
    </div>
    """
  end

  # Every KPI icon tile is the brand tint; the glyph is navy or cyan (see
  # color_classes/1). No per-metric background hue - that was medic-era slop.
  defp summary_icon_bg(_), do: "bg-brand-50"

  # Two-tone glyphs, both from the org palette: activity/flow metrics read cyan,
  # the rest navy - so a KPI row alternates. See docs/DESIGN.md.
  @summary_cyan ~w(blue teal cyan emerald green amber orange)
  defp summary_icon_color(color) when color in @summary_cyan, do: "text-brand-accent"
  defp summary_icon_color(_), do: "text-brand-primary"

  @analytics_tab_labels %{revenue: "Revenue", patients: "Patients", operations: "Operations"}

  @doc """
  Renders the Revenue/Patients/Operations pill toggle, showing only the
  tabs the current role is allowed to see (never assumes Revenue is first
  or present). Fires `set_dashboard_analytics_tab` with the tab atom.
  """
  attr :visible_tabs, :list, required: true
  attr :active_tab, :atom, required: true

  def analytics_tab_toggle(assigns) do
    ~H"""
    <div class="inline-flex flex-wrap items-center gap-1 rounded-full border border-slate-200 bg-slate-50 p-1.5">
      <button
        :for={tab <- @visible_tabs}
        type="button"
        phx-click="set_dashboard_analytics_tab"
        phx-value-tab={tab}
        class={[
          "px-5 py-2 rounded-full text-sm font-medium transition-all duration-150",
          if(@active_tab == tab,
            do: "bg-brand-primary text-white",
            else: "text-slate-500 hover:text-slate-900"
          )
        ]}
      >
        {analytics_tab_label(tab)}
      </button>
    </div>
    """
  end

  def analytics_tab_label(tab), do: Map.fetch!(@analytics_tab_labels, tab)

  attr :title, :string, required: true
  attr :subtitle, :string, required: true
  slot :actions
  slot :inner_block, required: true

  def analytics_section(assigns) do
    ~H"""
    <div class="bg-white rounded-2xl border border-slate-200 p-5 sm:p-6 shadow-card">
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-5">
        <div>
          <h2 class="text-xl font-semibold text-slate-900">
            {@title}
          </h2>
          <p class="text-sm text-slate-500 mt-2">{@subtitle}</p>
        </div>
        <div :if={@actions != []} class="shrink-0">
          {render_slot(@actions)}
        </div>
      </div>

      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  A single chart card: title, optional subtitle, and a Chart.js canvas
  wired via the `ChartJS` hook. `config` is the Chart.js config map (see
  the `*_chart/1` builders below).
  """
  attr :title, :string, required: true
  attr :subtitle, :string, default: nil
  attr :config, :map, required: true
  attr :height, :string, default: "300px"

  def chart_panel(assigns) do
    assigns =
      assigns
      |> assign(:config_json, Jason.encode!(assigns.config))
      |> assign(:dom_id, chart_dom_id(assigns.title))

    ~H"""
    <div class="bg-white rounded-2xl border border-slate-200 p-5 sm:p-6 h-full shadow-card">
      <div class="mb-5">
        <h3 class="text-lg font-semibold text-slate-900">{@title}</h3>
        <p :if={@subtitle} class="text-sm text-slate-500 mt-1.5 leading-relaxed">
          {@subtitle}
        </p>
      </div>

      <div class="w-full" style={"height: #{@height}"}>
        <div id={@dom_id} phx-hook="ChartJS" data-chart={@config_json} class="h-full w-full">
          <canvas class="h-full w-full"></canvas>
        </div>
      </div>
    </div>
    """
  end

  defp chart_dom_id(title) do
    title
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/u, "-")
    |> String.trim("-")
    |> then(&"dashboard-chart-#{&1}")
  end

  @doc """
  Age Group Breakdown card: horizontal bars for the four age buckets.
  """
  attr :age_groups, :map, required: true, doc: "%{under_5:, age_5_17:, age_18_59:, over_60:}"
  attr :total, :integer, required: true

  def age_group_breakdown_card(assigns) do
    ~H"""
    <div class="bg-white rounded-2xl border border-slate-200 p-6 shadow-card">
      <h3 class="text-lg font-semibold text-slate-900 mb-5">
        Age Group Breakdown
      </h3>
      <div class="space-y-3">
        <.age_bar
          label="Under 5 yrs"
          count={@age_groups.under_5}
          total={max(@total, 1)}
          color="amber"
        />
        <.age_bar
          label="5 – 17 yrs"
          count={@age_groups.age_5_17}
          total={max(@total, 1)}
          color="green"
        />
        <.age_bar
          label="18 – 59 yrs"
          count={@age_groups.age_18_59}
          total={max(@total, 1)}
          color="blue"
        />
        <.age_bar label="60+ yrs" count={@age_groups.over_60} total={max(@total, 1)} color="rose" />
      </div>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :count, :integer, required: true
  attr :total, :integer, required: true
  attr :color, :string, required: true

  defp age_bar(assigns) do
    assigns = assign(assigns, :pct, trunc(assigns.count / assigns.total * 100))

    ~H"""
    <div class="flex items-center gap-3">
      <span class="text-sm text-slate-500 w-32 shrink-0 truncate">{@label}</span>
      <div class="flex-1 h-2.5 bg-slate-50 rounded-full overflow-hidden">
        <div
          class={["h-full rounded-full transition-all duration-500", age_bar_color(@color)]}
          style={"width: #{@pct}%"}
        >
        </div>
      </div>
      <span class="text-sm font-semibold text-slate-900 w-8 text-right">{@count}</span>
    </div>
    """
  end

  defp age_bar_color("amber"), do: "bg-amber-400"
  defp age_bar_color("green"), do: "bg-green-500"
  defp age_bar_color("blue"), do: "bg-blue-500"
  defp age_bar_color("rose"), do: "bg-rose-400"
  defp age_bar_color(_), do: "bg-slate-400"

  @doc """
  Geographic Spread table: location, patient count, % share.
  """
  attr :rows, :list, required: true, doc: "list of %{address:, count:, pct:}"

  def geographic_spread_table(assigns) do
    ~H"""
    <div class="bg-white rounded-2xl border border-slate-200 overflow-hidden shadow-card">
      <div class="px-5 py-4 border-b border-slate-200 bg-slate-50 flex items-center justify-between">
        <div>
          <h3 class="text-lg font-semibold text-slate-900">
            Geographic Spread
          </h3>
          <p class="text-sm text-slate-500 mt-1">Patient distribution by home address.</p>
        </div>
        <span class="text-xs font-semibold text-slate-500 bg-slate-50 px-3 py-1 rounded-full">
          {length(@rows)} locations
        </span>
      </div>
      <%= if Enum.empty?(@rows) do %>
        <div class="flex flex-col items-center justify-center py-12 text-slate-500">
          <p class="text-sm font-medium">No location data available</p>
        </div>
      <% else %>
        <div class="overflow-x-auto max-h-72 overflow-y-auto">
          <table class="min-w-full divide-y divide-[#E8EEF8] text-sm">
            <thead class="bg-slate-50 sticky top-0">
              <tr>
                <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                  Location
                </th>
                <th class="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-slate-500">
                  Patients
                </th>
                <th class="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-slate-500">
                  % Share
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-[#F1F5FB] bg-white">
              <%= for loc <- Enum.take(@rows, 15) do %>
                <tr class="hover:bg-slate-50">
                  <td class="px-4 py-3 text-slate-900">{loc.address}</td>
                  <td class="px-4 py-3 text-right font-semibold text-slate-900">{loc.count}</td>
                  <td class="px-4 py-3 text-right">
                    <div class="flex items-center justify-end gap-2">
                      <div class="w-16 h-1.5 bg-slate-50 rounded-full overflow-hidden">
                        <div class="h-full bg-brand-primary rounded-full" style={"width: #{loc.pct}%"}>
                        </div>
                      </div>
                      <span class="text-xs text-slate-500 w-8 text-right">{loc.pct}%</span>
                    </div>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      <% end %>
    </div>
    """
  end

  @doc """
  Visits by Type / Visits by Status card with an internal Type ⇄ Status
  toggle (shared chart card — never shows both charts at once).
  """
  attr :active_view, :atom, required: true, doc: ":visit_type or :visit_status"
  attr :visit_types, :list, required: true
  attr :visit_statuses, :list, required: true
  attr :event, :string, default: "set_visit_chart_tab"

  def visit_breakdown_card(assigns) do
    ~H"""
    <div class="bg-white rounded-2xl border border-slate-200 p-6 shadow-card">
      <div class="mb-4 flex items-center justify-between gap-4 flex-wrap">
        <div>
          <h3 class="text-lg font-semibold text-slate-900">
            {if @active_view == :visit_type, do: "Visits by Type", else: "Visits by Status"}
          </h3>
          <p class="text-sm text-slate-500 mt-1.5 leading-relaxed">
            {if @active_view == :visit_type,
              do: "See how patient visits are distributed by visit type.",
              else: "How patients paid for visits."}
          </p>
        </div>
        <div class="inline-flex rounded-full border border-slate-200 bg-slate-50 p-1.5 overflow-hidden shrink-0">
          <button
            type="button"
            phx-click={@event}
            phx-value-tab="visit_type"
            class={[
              "px-4 py-2 rounded-full text-sm font-medium transition-all",
              if(@active_view == :visit_type,
                do: "bg-brand-primary text-white",
                else: "text-slate-500"
              )
            ]}
          >
            Type
          </button>
          <button
            type="button"
            phx-click={@event}
            phx-value-tab="visit_status"
            class={[
              "px-4 py-2 rounded-full text-sm font-medium transition-all",
              if(@active_view == :visit_status,
                do: "bg-brand-primary text-white",
                else: "text-slate-500"
              )
            ]}
          >
            Status
          </button>
        </div>
      </div>
      <div class="w-full" style="height: 320px">
        <div
          id="dashboard-visit-breakdown-chart"
          phx-hook="ChartJS"
          data-chart={
            Jason.encode!(
              if @active_view == :visit_type,
                do: visit_type_chart(@visit_types),
                else: visit_status_chart(@visit_statuses)
            )
          }
          class="h-full w-full"
        >
          <canvas class="h-full w-full"></canvas>
        </div>
      </div>
    </div>
    """
  end

  # ---- Chart config builders (Chart.js configs, generic over `rows`) ----

  def daily_revenue_chart(rows) do
    %{
      type: "line",
      data: %{
        labels: Enum.map(rows, &Calendar.strftime(&1.date, "%d %b")),
        datasets: [
          %{
            label: "KSh Collected",
            data: Enum.map(rows, & &1.amount),
            borderColor: "rgba(16, 185, 129, 0.95)",
            backgroundColor: "rgba(16, 185, 129, 0.12)",
            borderWidth: 2,
            pointRadius: 3,
            tension: 0.35,
            fill: true
          }
        ]
      },
      options:
        base_chart_options(%{
          plugins: %{legend: %{position: "bottom"}},
          scales: %{y: %{beginAtZero: true, ticks: %{precision: 0}}}
        })
    }
  end

  def daily_registrations_chart(rows) do
    %{
      type: "bar",
      data: %{
        labels: Enum.map(rows, &Calendar.strftime(&1.date, "%d %b")),
        datasets: [
          %{
            label: "New Patients",
            data: Enum.map(rows, & &1.count),
            backgroundColor: "rgba(12, 39, 101, 0.75)",
            borderRadius: 6
          }
        ]
      },
      options:
        base_chart_options(%{
          plugins: %{legend: %{display: false}},
          scales: %{y: %{beginAtZero: true, ticks: %{precision: 0}}}
        })
    }
  end

  def monthly_revenue_chart(rows) do
    %{
      type: "bar",
      data: %{
        labels: Enum.map(rows, & &1.label),
        datasets: [
          %{
            label: "KSh Collected",
            data: Enum.map(rows, & &1.amount),
            backgroundColor: "rgba(20, 184, 166, 0.78)",
            borderRadius: 8
          }
        ]
      },
      options:
        base_chart_options(%{
          plugins: %{legend: %{display: false}},
          scales: %{y: %{beginAtZero: true, ticks: %{precision: 0}}}
        })
    }
  end

  def gender_chart(rows) do
    %{
      type: "doughnut",
      data: %{
        labels: Enum.map(rows, & &1.label),
        datasets: [
          %{
            data: Enum.map(rows, & &1.count),
            backgroundColor: ["#2563eb", "#ec4899", "#94a3b8"],
            borderWidth: 0
          }
        ]
      },
      options:
        base_chart_options(%{
          cutout: "60%",
          plugins: %{legend: %{position: "bottom"}},
          scales: %{}
        })
    }
  end

  def age_chart(rows) do
    %{
      type: "bar",
      data: %{
        labels: Enum.map(rows, & &1.label),
        datasets: [
          %{
            label: "Patients",
            data: Enum.map(rows, & &1.count),
            backgroundColor: ["#f59e0b", "#22c55e", "#3b82f6", "#f43f5e"],
            borderRadius: 10
          }
        ]
      },
      options:
        base_chart_options(%{
          plugins: %{legend: %{display: false}},
          scales: %{y: %{beginAtZero: true, ticks: %{precision: 0}}}
        })
    }
  end

  def visit_type_chart(rows) do
    %{
      type: "doughnut",
      data: %{
        labels: Enum.map(rows, & &1.label),
        datasets: [
          %{
            data: Enum.map(rows, & &1.count),
            backgroundColor: doughnut_palette(),
            borderWidth: 0
          }
        ]
      },
      options:
        base_chart_options(%{
          cutout: "60%",
          plugins: %{legend: %{position: "bottom"}},
          scales: %{}
        })
    }
  end

  def visit_status_chart(rows) do
    %{
      type: "doughnut",
      data: %{
        labels: Enum.map(rows, & &1.label),
        datasets: [
          %{
            data: Enum.map(rows, & &1.count),
            backgroundColor: doughnut_palette(),
            borderWidth: 0
          }
        ]
      },
      options:
        base_chart_options(%{
          cutout: "60%",
          plugins: %{legend: %{position: "bottom"}},
          scales: %{}
        })
    }
  end

  def revenue_by_reason_chart(rows) do
    %{
      type: "bar",
      data: %{
        labels: Enum.map(rows, & &1.label),
        datasets: [
          %{
            label: "KSh",
            data: Enum.map(rows, & &1.total),
            backgroundColor: "rgba(15, 118, 110, 0.8)",
            borderRadius: 8
          }
        ]
      },
      options:
        base_chart_options(%{
          indexAxis: "y",
          plugins: %{legend: %{display: false}},
          scales: %{x: %{beginAtZero: true, ticks: %{precision: 0}}}
        })
    }
  end

  def revenue_by_prompter_chart(rows) do
    %{
      type: "bar",
      data: %{
        labels: Enum.map(rows, & &1.label),
        datasets: [
          %{
            label: "KSh",
            data: Enum.map(rows, & &1.total),
            backgroundColor: "rgba(124, 58, 237, 0.8)",
            borderRadius: 8
          }
        ]
      },
      options:
        base_chart_options(%{
          indexAxis: "y",
          plugins: %{legend: %{display: false}},
          scales: %{x: %{beginAtZero: true, ticks: %{precision: 0}}}
        })
    }
  end

  defp doughnut_palette do
    [
      "#0C2765",
      "#0ea5e9",
      "#8b5cf6",
      "#14b8a6",
      "#f59e0b",
      "#ec4899",
      "#22c55e",
      "#f43f5e",
      "#94a3b8"
    ]
  end

  defp base_chart_options(overrides) do
    Map.merge(
      %{
        responsive: true,
        maintainAspectRatio: false,
        interaction: %{mode: "index", intersect: false},
        plugins: %{
          legend: %{
            labels: %{
              usePointStyle: true,
              boxWidth: 10,
              color: "#334155",
              font: %{family: "ui-sans-serif"}
            }
          },
          tooltip: %{
            backgroundColor: "#0f172a",
            titleColor: "#f8fafc",
            bodyColor: "#e2e8f0"
          }
        },
        scales: %{
          x: %{grid: %{display: false}, ticks: %{color: "#64748b"}},
          y: %{grid: %{color: "rgba(148, 163, 184, 0.18)"}, ticks: %{color: "#64748b"}}
        }
      },
      overrides
    )
  end
end
