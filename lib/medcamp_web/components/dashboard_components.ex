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
    <div class="bg-white rounded-[28px] shadow-[0_14px_32px_rgba(15,23,42,0.05)] border border-[#E8EEF8] p-6 hover:shadow-[0_18px_38px_rgba(15,23,42,0.08)] transition-shadow">
      <div class="flex items-start justify-between">
        <div class="flex-1">
          <p class="text-xs font-medium uppercase tracking-wide text-gray-500 mb-2">
            {@label}
          </p>
          <p class={"text-3xl font-bold leading-none #{@color_classes[:text]}"}>
            {@value}
          </p>
          <%= if @trend do %>
            <p class="text-sm text-[#5F7190] mt-3">{@trend}</p>
          <% end %>
        </div>
        <div class={@color_classes[:bg]}>
          <.icon name={@icon} class="w-8 h-8 text-white" />
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
    <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-6">
      <h3 class="text-lg font-semibold text-gray-900 mb-4">{@title}</h3>
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
      <div class={@bg_class <> " rounded-[22px] p-4 text-center hover:shadow-[0_16px_32px_rgba(15,23,42,0.12)] transition-shadow cursor-pointer"}>
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
    <div class="bg-white rounded-[28px] shadow-[0_14px_32px_rgba(15,23,42,0.05)] border border-[#E8EEF8] p-6">
      <h3 class="text-xl font-semibold text-gray-900 mb-5">{@title}</h3>
      <%= if Enum.empty?(@items) do %>
        <p class="text-center py-8 text-sm text-[#6C7E99]">{@empty_message}</p>
      <% else %>
        <div class="space-y-3.5">
          <%= for item <- @items do %>
            <div class="flex items-center justify-between p-4 border border-[#E8EEF8] rounded-[22px] hover:bg-[#F8FBFF] transition">
              <div class="flex-1">
                <p class="text-sm font-semibold text-gray-900">
                  {item.title}
                </p>
                <p class="text-sm text-[#60718E] mt-1">{item.subtitle}</p>
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

  defp color_classes(color) do
    case color do
      "blue" -> %{text: "text-[#295FDE]", bg: "bg-[#295FDE] rounded-full p-3"}
      "green" -> %{text: "text-[#0FAF8A]", bg: "bg-[#0FAF8A] rounded-full p-3"}
      "red" -> %{text: "text-[#E0566F]", bg: "bg-[#E0566F] rounded-full p-3"}
      "purple" -> %{text: "text-[#7C58E8]", bg: "bg-[#7C58E8] rounded-full p-3"}
      "orange" -> %{text: "text-[#E5963A]", bg: "bg-[#E5963A] rounded-full p-3"}
      "indigo" -> %{text: "text-[#373896]", bg: "bg-[#373896] rounded-full p-3"}
      _ -> %{text: "text-[#5E6D86]", bg: "bg-[#5E6D86] rounded-full p-3"}
    end
  end

  defp quick_action_bg(color) do
    case color do
      "blue" -> "bg-[#2F66E2] shadow-[0_10px_20px_rgba(47,102,226,0.22)]"
      "green" -> "bg-[#10B989] shadow-[0_10px_20px_rgba(16,185,137,0.22)]"
      "red" -> "bg-[#E85D75] shadow-[0_10px_20px_rgba(232,93,117,0.2)]"
      "purple" -> "bg-[#7C58E8] shadow-[0_10px_20px_rgba(124,88,232,0.24)]"
      "orange" -> "bg-[#E39B41] shadow-[0_10px_20px_rgba(227,155,65,0.22)]"
      "indigo" -> "bg-[#373896] shadow-[0_10px_20px_rgba(55,56,150,0.24)]"
      "amber" -> "bg-[#D79B2B] shadow-[0_10px_20px_rgba(215,155,43,0.22)]"
      "cyan" -> "bg-[#2AA8BD] shadow-[0_10px_20px_rgba(42,168,189,0.22)]"
      "pink" -> "bg-[#D75AA5] shadow-[0_10px_20px_rgba(215,90,165,0.22)]"
      "gray" -> "bg-[#64748B] shadow-[0_10px_20px_rgba(100,116,139,0.22)]"
      _ -> "bg-[#64748B] shadow-[0_10px_20px_rgba(100,116,139,0.22)]"
    end
  end

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

  def dashboard_top_card(assigns) do
    ~H"""
    <div class="bg-white rounded-[32px] shadow-[0_20px_42px_rgba(15,23,42,0.06)] border border-[#E6EDF8] p-5 sm:p-7">
      <div class="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-4 mb-5">
        <div>
          <h1 class="text-2xl sm:text-3xl font-bold text-gray-900">
            {@title}
          </h1>
          <p :if={@subtitle} class="text-sm text-gray-500 mt-2">
            {@subtitle}
          </p>
        </div>
        <div :if={@actions != []} class="flex items-center gap-2 shrink-0">
          {render_slot(@actions)}
        </div>
      </div>

      <div :if={@search_name || @filter_id} class="flex flex-wrap items-center gap-3">
        <form :if={@search_name} phx-change={@search_event} class="flex-1 min-w-[220px]">
          <.search_input name={@search_name} value={@search_value} placeholder={@search_placeholder} />
        </form>

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
    <div class="w-full min-w-0 overflow-hidden bg-white rounded-[26px] border border-[#E7EDF8] shadow-[0_12px_28px_rgba(15,23,42,0.045)] px-5 sm:px-6 py-5 min-h-[128px] flex items-center">
      <div class="flex w-full min-w-0 items-center gap-5">
        <div class={[
          "flex p-2 shrink-0 items-center justify-center rounded-full border border-[#DCE5F2] shadow-[inset_0_1px_0_rgba(255,255,255,0.75)]",
          summary_icon_bg(@color)
        ]}>
          <Heroicons.icon name={@icon} type="outline" class={"h-7 w-7 #{summary_icon_color(@color)}"} />
        </div>
        <div class="min-w-0 flex-1">
          <p class="text-xs font-medium uppercase tracking-wide text-gray-500 truncate">
            {@label}
          </p>
          <p class="text-2xl font-bold text-[#373896] leading-none mt-2 truncate">
            {@value}
          </p>
          <p
            :if={@helper}
            class="max-w-full whitespace-normal break-words text-sm text-gray-500 mt-2 leading-snug"
          >
            {@helper}
          </p>
        </div>
      </div>
    </div>
    """
  end

  defp summary_icon_bg("indigo"), do: "bg-[#F8F9FF]"
  defp summary_icon_bg("blue"), do: "bg-[#F7FAFF]"
  defp summary_icon_bg("emerald"), do: "bg-[#F6FFFB]"
  defp summary_icon_bg("amber"), do: "bg-[#FFFBF3]"
  defp summary_icon_bg("violet"), do: "bg-[#FBF8FF]"
  defp summary_icon_bg("teal"), do: "bg-[#F4FFFD]"
  defp summary_icon_bg("cyan"), do: "bg-[#F5FDFF]"
  defp summary_icon_bg("rose"), do: "bg-[#FFF8FA]"
  defp summary_icon_bg(_), do: "bg-[#FAFBFD]"

  defp summary_icon_color("indigo"), do: "text-[#373896]"
  defp summary_icon_color("blue"), do: "text-[#2C66E4]"
  defp summary_icon_color("emerald"), do: "text-[#12B586]"
  defp summary_icon_color("amber"), do: "text-[#D79B2B]"
  defp summary_icon_color("violet"), do: "text-[#7C58E8]"
  defp summary_icon_color("teal"), do: "text-[#14B8A6]"
  defp summary_icon_color("cyan"), do: "text-[#2AA8BD]"
  defp summary_icon_color("rose"), do: "text-[#E85D75]"
  defp summary_icon_color(_), do: "text-[#64748B]"

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
    <div class="inline-flex flex-wrap items-center gap-1 rounded-full border border-[#D8E2F1] bg-[#F8FAFD] p-1.5 shadow-[inset_0_1px_0_rgba(255,255,255,0.9)]">
      <button
        :for={tab <- @visible_tabs}
        type="button"
        phx-click="set_dashboard_analytics_tab"
        phx-value-tab={tab}
        class={[
          "px-5 py-2 rounded-full text-sm font-medium transition-all duration-150",
          if(@active_tab == tab,
            do: "bg-[#373896] text-white shadow-[0_10px_22px_rgba(55,56,150,0.28)]",
            else: "text-[#556781] hover:text-[#173052]"
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
    <div class="bg-white rounded-[30px] shadow-[0_18px_38px_rgba(15,23,42,0.055)] border border-[#E6EDF8] p-5 sm:p-6">
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-5">
        <div>
          <h2 class="text-xl font-semibold text-gray-900">
            {@title}
          </h2>
          <p class="text-sm text-gray-500 mt-2">{@subtitle}</p>
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
    <div class="bg-white rounded-[26px] shadow-[0_14px_32px_rgba(15,23,42,0.05)] border border-[#E8EEF8] p-5 sm:p-6 h-full">
      <div class="mb-5">
        <h3 class="text-lg font-semibold text-gray-900">{@title}</h3>
        <p :if={@subtitle} class="text-sm text-gray-500 mt-1.5 leading-relaxed">
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
    <div class="bg-white rounded-[26px] shadow-[0_14px_32px_rgba(15,23,42,0.05)] border border-[#E8EEF8] p-6">
      <h3 class="text-lg font-semibold text-gray-900 mb-5">
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
      <span class="text-sm text-[#5F7190] w-32 shrink-0 truncate">{@label}</span>
      <div class="flex-1 h-2.5 bg-[#EDF2F8] rounded-full overflow-hidden">
        <div
          class={["h-full rounded-full transition-all duration-500", age_bar_color(@color)]}
          style={"width: #{@pct}%"}
        >
        </div>
      </div>
      <span class="text-sm font-semibold text-[#173052] w-8 text-right">{@count}</span>
    </div>
    """
  end

  defp age_bar_color("amber"), do: "bg-amber-400"
  defp age_bar_color("green"), do: "bg-green-500"
  defp age_bar_color("blue"), do: "bg-blue-500"
  defp age_bar_color("rose"), do: "bg-rose-400"
  defp age_bar_color(_), do: "bg-gray-400"

  @doc """
  Geographic Spread table: location, patient count, % share.
  """
  attr :rows, :list, required: true, doc: "list of %{address:, count:, pct:}"

  def geographic_spread_table(assigns) do
    ~H"""
    <div class="bg-white rounded-[26px] shadow-[0_14px_32px_rgba(15,23,42,0.05)] border border-[#E8EEF8] overflow-hidden">
      <div class="px-5 py-4 border-b border-[#E8EEF8] bg-[#F8FAFD] flex items-center justify-between">
        <div>
          <h3 class="text-lg font-semibold text-gray-900">
            Geographic Spread
          </h3>
          <p class="text-sm text-[#60718E] mt-1">Patient distribution by home address.</p>
        </div>
        <span class="text-xs font-semibold text-[#60718E] bg-[#EEF3FA] px-3 py-1 rounded-full">
          {length(@rows)} locations
        </span>
      </div>
      <%= if Enum.empty?(@rows) do %>
        <div class="flex flex-col items-center justify-center py-12 text-[#8795AB]">
          <p class="text-sm font-medium">No location data available</p>
        </div>
      <% else %>
        <div class="overflow-x-auto max-h-72 overflow-y-auto">
          <table class="min-w-full divide-y divide-[#E8EEF8] text-sm">
            <thead class="bg-[#F8FAFD] sticky top-0">
              <tr>
                <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-gray-500">
                  Location
                </th>
                <th class="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-gray-500">
                  Patients
                </th>
                <th class="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-gray-500">
                  % Share
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-[#F1F5FB] bg-white">
              <%= for loc <- Enum.take(@rows, 15) do %>
                <tr class="hover:bg-[#FAFCFF]">
                  <td class="px-4 py-3 text-[#173052]">{loc.address}</td>
                  <td class="px-4 py-3 text-right font-semibold text-[#173052]">{loc.count}</td>
                  <td class="px-4 py-3 text-right">
                    <div class="flex items-center justify-end gap-2">
                      <div class="w-16 h-1.5 bg-[#EDF2F8] rounded-full overflow-hidden">
                        <div class="h-full bg-[#373896] rounded-full" style={"width: #{loc.pct}%"}>
                        </div>
                      </div>
                      <span class="text-xs text-[#60718E] w-8 text-right">{loc.pct}%</span>
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
    <div class="bg-white rounded-[26px] shadow-[0_14px_32px_rgba(15,23,42,0.05)] border border-[#E8EEF8] p-6">
      <div class="mb-4 flex items-center justify-between gap-4 flex-wrap">
        <div>
          <h3 class="text-lg font-semibold text-gray-900">
            {if @active_view == :visit_type, do: "Visits by Type", else: "Visits by Status"}
          </h3>
          <p class="text-sm text-gray-500 mt-1.5 leading-relaxed">
            {if @active_view == :visit_type,
              do: "See how patient visits are distributed by visit type.",
              else: "How patients paid for visits."}
          </p>
        </div>
        <div class="inline-flex rounded-full border border-[#D8E2F1] bg-[#F8FAFD] p-1.5 overflow-hidden shrink-0">
          <button
            type="button"
            phx-click={@event}
            phx-value-tab="visit_type"
            class={[
              "px-4 py-2 rounded-full text-sm font-medium transition-all",
              if(@active_view == :visit_type,
                do: "bg-[#373896] text-white shadow-[0_10px_22px_rgba(55,56,150,0.28)]",
                else: "text-[#556781]"
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
                do: "bg-[#373896] text-white shadow-[0_10px_22px_rgba(55,56,150,0.28)]",
                else: "text-[#556781]"
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
            backgroundColor: "rgba(55, 56, 150, 0.75)",
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
      "#373896",
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
