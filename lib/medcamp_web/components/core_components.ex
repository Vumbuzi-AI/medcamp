defmodule MedcampWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At first glance, this module may seem daunting, but its goal is to provide
  core building blocks for your application, such as modals, tables, and
  forms. The components consist mostly of markup and are well-documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The default components use Tailwind CSS, a utility-first CSS framework.
  See the [Tailwind CSS documentation](https://tailwindcss.com) to learn
  how to customize them or feel free to swap in another framework altogether.

  Icons are provided by [heroicons](https://heroicons.com). See `icon/1` for usage.
  """
  use Phoenix.Component
  use Gettext, backend: MedcampWeb.Gettext

  alias Phoenix.LiveView.JS
  alias Medcamp.Pagination

  @doc """
  Renders a modal.

  ## Examples

      <.modal id="confirm-modal">
        This is a modal.
      </.modal>

  JS commands may be passed to the `:on_cancel` to configure
  the closing/cancel event, for example:

      <.modal id="confirm" on_cancel={JS.navigate(~p"/posts")}>
        This is another modal.
      </.modal>


  """

  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               range search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  def phone_number_input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> phone_number_input()
  end

  def phone_number_input(assigns) do
    ~H"""
    <div>
      <.label>Phone Number</.label>
      <div class="w-[100%] flex justify-between">
        <div class="w-[15%] h-[45px] rounded-l-lg text-zinc-900 flex justify-center items-center border-[1px] border-zinc-300">
          +254
        </div>
        <input
          type={@type}
          name={@name}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          class={[
            " block w-[85%] rounded-r-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6",
            @errors == [] && "border-zinc-300 focus:border-zinc-400",
            @errors != [] && "border-rose-400 focus:border-rose-400"
          ]}
          {@rest}
        />
      </div>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  slot :inner_block, required: true

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="relative z-50 hidden"
    >
      <div
        id={"#{@id}-bg"}
        class="bg-zinc-950/40 fixed inset-0 transition-opacity print:hidden"
        aria-hidden="true"
      />
      <div
        class="fixed inset-0 overflow-y-auto print:static print:overflow-visible"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center print:block print:min-h-0">
          <div class="w-full max-w-3xl p-4 sm:p-6 lg:py-8 print:max-w-none print:p-0">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              class="shadow-zinc-700/10 ring-zinc-700/10 relative hidden max-h-[calc(100vh-2rem)] overflow-y-auto rounded-2xl bg-white p-6 shadow-lg ring-1 transition sm:p-8 print:rounded-none print:p-0 print:shadow-none print:ring-0"
            >
              <div class="absolute top-6 right-5 print:hidden">
                <button
                  phx-click={JS.exec("data-cancel", to: "##{@id}")}
                  type="button"
                  class="-m-3 flex-none p-3 opacity-20 hover:opacity-40"
                  aria-label={gettext("close")}
                >
                  <.icon name="hero-x-mark-solid" class="h-5 w-5" />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                {render_slot(@inner_block)}
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a page header: an icon in a rounded badge, a title, and an
  optional one-line subtitle, with an optional `:actions` slot on the right
  (e.g. an "Add New" button). Meant to sit at the top of a page's main card,
  above its toolbar (search box / `filter_drawer/1`).

  ## Examples

      <.page_header
        icon_path="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
        title="Listing All Patients"
        subtitle="Search, filter and manage registered patients."
      />
  """
  attr :icon_path, :string, required: true, doc: "SVG path `d` attribute for the header icon"
  attr :title, :string, required: true
  attr :subtitle, :string, default: nil
  slot :actions

  def page_header(assigns) do
    ~H"""
    <div class="flex items-start justify-between gap-4 border-b border-gray-100 pb-4 mb-4">
      <div class="flex items-start gap-3">
        <div class="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-brand-100">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-5 w-5 text-brand-primary"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d={@icon_path} />
          </svg>
        </div>
        <div>
          <h2 class="text-lg font-semibold text-gray-900">{@title}</h2>
          <p :if={@subtitle} class="text-sm text-gray-500">{@subtitle}</p>
        </div>
      </div>
      <div :if={@actions != []} class="flex items-center gap-2">
        {render_slot(@actions)}
      </div>
    </div>
    """
  end

  @doc """
  Renders a "Filters" trigger button that opens an anchored dropdown panel
  below it.

  Groups filter fields under labeled sections and applies them as a single
  batch via an explicit "Apply filters" button, rather than firing an event
  per field change. Opening and closing is pure client-side JS — no
  LiveView round trip — mirroring how `modal/1` opens and closes. The panel
  is sized to its content (not the full viewport height) and anchored to
  the trigger button, like a dropdown menu.

  The caller keeps its existing `phx-submit`/`phx-click` event names
  (typically the same `"filter"`/`"clear_filters"` handlers an inline filter
  form already used); this component only supplies the surrounding chrome.

  ## Examples

      <.filter_drawer
        id="lab-filters"
        title="Filter lab results"
        apply_event="filter"
        active_count={count_active_filters(@filters)}
      >
        <:group label="Date and Time">
          <.date_range_fields
            from_name="filters[date_from]"
            to_name="filters[date_to]"
            from_value={@filters[:date_from]}
            to_value={@filters[:date_to]}
          />
        </:group>
        <:group label="Patient Details">
          ...
        </:group>
      </.filter_drawer>
  """
  attr :id, :string, required: true
  attr :title, :string, default: "Filters"
  attr :trigger_label, :string, default: "Filters"
  attr :active_count, :integer, default: 0

  attr :variant, :string,
    default: "outline",
    values: ~w(outline solid),
    doc:
      "\"outline\" (default) keeps the light/gray trigger used everywhere today; \"solid\" " <>
        "renders it filled with the primary purple even when no filters are active, for " <>
        "pages that want the button to read as a primary action (e.g. the dashboard top card)"

  attr :apply_event, :string,
    required: true,
    doc: "phx-submit (or, when instant: true, phx-change) target for the filter fields"

  attr :clear_event, :string, default: "clear_filters"

  attr :instant, :boolean,
    default: false,
    doc:
      "if true, fields apply on every change instead of requiring an explicit Apply click " <>
        "(for live-report-style pages where results already update instantly outside the " <>
        "drawer); the drawer stays open and hides the Apply button, since there's nothing to apply"

  slot :group, required: true do
    attr :label, :string, required: true
  end

  slot :chip,
    doc:
      "one per currently-active filter value, rendered as a removable pill below the " <>
        "search/filter bar, plus a trailing \"Clear all\" link. Requires the parent element " <>
        "the caller places <.filter_drawer> in to allow wrapping (e.g. `flex flex-wrap`), " <>
        "since the chip row renders as a `w-full` sibling of the trigger button so it drops " <>
        "to its own line." do
    attr :label, :string, required: true

    attr :clear, :any,
      required: true,
      doc: "phx-click value (event name string, or a JS command) fired to remove just this chip"
  end

  def filter_drawer(assigns) do
    ~H"""
    <div class="relative inline-block">
      <button
        type="button"
        phx-click={show_filter_drawer(@id)}
        class={[
          "flex h-[40px] items-center gap-2 rounded-md border px-4 text-sm font-medium whitespace-nowrap transition",
          @active_count > 0 && "border-brand-100 bg-brand-100 text-brand-primary hover:bg-[#dcdcff]",
          @active_count == 0 && @variant == "outline" &&
            "border-gray-300 text-gray-700 hover:bg-gray-50",
          @active_count == 0 && @variant == "solid" &&
            "border-brand-primary bg-brand-primary text-white hover:bg-[#2d2e78]"
        ]}
      >
        <Heroicons.icon name="adjustments-horizontal" type="outline" class="h-4 w-4" />
        {@trigger_label}
        <span
          :if={@active_count > 0}
          class="inline-flex h-5 w-5 items-center justify-center rounded-full bg-brand-primary text-xs font-semibold text-white"
        >
          {@active_count}
        </span>
      </button>

      <div id={@id} class="relative z-50 hidden" phx-remove={hide_filter_drawer(@id)}>
        <div
          id={"#{@id}-panel"}
          class="absolute top-full right-0 z-50 mt-2 hidden max-h-[min(36rem,calc(100vh-9rem))] w-screen max-w-2xl origin-top-right scale-95 transform flex-col overflow-hidden rounded-xl border border-gray-100 bg-white opacity-0 shadow-xl transition"
          role="dialog"
          aria-modal="true"
          aria-labelledby={"#{@id}-title"}
          tabindex="0"
          phx-click-away={hide_filter_drawer(@id)}
          phx-window-keydown={hide_filter_drawer(@id)}
          phx-key="escape"
        >
          <div class="flex items-center justify-between gap-4 border-b border-gray-100 px-5 py-4 sm:px-6">
            <h2 id={"#{@id}-title"} class="min-w-0 flex-1 text-lg font-semibold text-brand-primary">
              {@title}
            </h2>
            <div class="flex shrink-0 items-center gap-2">
              <button
                type="button"
                phx-click={JS.push(@clear_event) |> hide_filter_drawer(@id)}
                class="rounded-md px-2.5 py-1.5 text-sm font-medium text-brand-accent hover:bg-[#f4f4ff] hover:text-brand-primary"
              >
                Reset all
              </button>
              <button
                type="button"
                phx-click={hide_filter_drawer(@id)}
                class="rounded-md p-2 text-gray-400 hover:bg-gray-50 hover:text-gray-600"
                aria-label={gettext("close")}
              >
                <.icon name="hero-x-mark-solid" class="h-5 w-5" />
              </button>
            </div>
          </div>

          <form
            id={"#{@id}-form"}
            phx-change={@instant && @apply_event}
            phx-submit={
              if @instant,
                do: JS.push(@apply_event),
                else: JS.push(@apply_event) |> hide_filter_drawer(@id)
            }
            class="flex min-h-0 flex-1 flex-col"
          >
            <button type="reset" id={"#{@id}-reset-btn"} class="hidden" aria-hidden="true" />

            <div class="flex-1 space-y-6 overflow-y-auto px-5 py-5 sm:px-6">
              <div :for={group <- @group}>
                <h3 class="mb-3 text-xs font-semibold tracking-wide text-gray-500 uppercase">
                  {group.label}
                </h3>
                <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
                  {render_slot(group)}
                </div>
              </div>
            </div>

            <div class="flex items-center justify-end gap-3 border-t border-gray-100 bg-gray-50/60 px-5 py-4 sm:px-6">
              <button
                type="button"
                phx-click={JS.push(@clear_event) |> hide_filter_drawer(@id)}
                class="rounded-md bg-white px-4 py-2 text-sm font-medium text-gray-700 ring-1 ring-gray-200 hover:bg-gray-100"
              >
                Clear filters
              </button>
              <button
                :if={!@instant}
                type="submit"
                class="rounded-md bg-brand-primary px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-brand-accent"
              >
                Apply filters
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>

    <div :if={@chip != []} class="mt-3 flex w-full flex-wrap items-center gap-2">
      <span
        :for={chip <- @chip}
        class="inline-flex items-center gap-1.5 rounded-full bg-brand-100 px-3 py-1 text-sm font-medium text-brand-primary"
      >
        {chip.label}
        <button
          type="button"
          phx-click={chip.clear}
          class="text-brand-primary/70 hover:text-brand-primary"
          aria-label={"Remove #{chip.label} filter"}
        >
          <.icon name="hero-x-mark-solid" class="h-3.5 w-3.5" />
        </button>
      </span>
      <button
        type="button"
        phx-click={@clear_event}
        class="text-sm font-medium text-brand-primary hover:underline"
      >
        Clear all
      </button>
    </div>
    """
  end

  @doc """
  Builds one entry for `filter_drawer/1`'s `:chip` slot from a filter value,
  or `nil` when the value is blank — so callers can map a list of
  `{value, field, label}` through this and `Enum.reject(&is_nil/1)` the
  result, instead of hand-writing a blank-check per field.

  `blank` defaults to `[nil, ""]`; pass a different list for fields whose
  "unset" sentinel isn't nil/empty-string (e.g. `"all"`).

      filter_chip(@filters[:gender], "gender", @filters[:gender])
      filter_chip(@filter_status, "status", "Status: " <> @filter_status, ["all"])
  """
  def filter_chip(value, field, label, blank \\ [nil, ""]) do
    if value in blank do
      nil
    else
      %{field: field, label: label}
    end
  end

  @doc """
  Renders a "from"/"to" pair of date inputs, side by side, for use inside a
  `filter_drawer/1` group. Occupies two grid cells.

  Enforces `from <= to` (each field constrains the other's allowed range) and,
  by default, that neither field can be set beyond today — set
  `disable_future={false}` for fields that filter on a date that is expected
  to be in the future (e.g. an expiry date or a scheduled appointment date).
  """
  attr :from_name, :string, required: true
  attr :to_name, :string, required: true
  attr :from_value, :string, default: ""
  attr :to_value, :string, default: ""
  attr :from_label, :string, default: "Date From"
  attr :to_label, :string, default: "Date To"
  attr :disable_future, :boolean, default: true

  def date_range_fields(assigns) do
    assigns = assign(assigns, :today, Date.to_iso8601(Date.utc_today()))

    ~H"""
    <div>
      <label class="mb-1 block text-sm font-medium text-gray-700">{@from_label}</label>
      <input
        type="date"
        name={@from_name}
        value={@from_value}
        max={date_from_max(@to_value, @today, @disable_future)}
        class="h-[40px] w-full rounded-md border-[1px] border-gray-300 p-2 focus:ring-0 focus:outline-none"
      />
    </div>
    <div>
      <label class="mb-1 block text-sm font-medium text-gray-700">{@to_label}</label>
      <input
        type="date"
        name={@to_name}
        value={@to_value}
        min={@from_value != "" && @from_value}
        max={@disable_future && @today}
        class="h-[40px] w-full rounded-md border-[1px] border-gray-300 p-2 focus:ring-0 focus:outline-none"
      />
    </div>
    """
  end

  defp date_from_max(to_value, _today, false), do: to_value != "" && to_value
  defp date_from_max("", today, true), do: today
  defp date_from_max(to_value, _today, true), do: to_value

  @doc """
  Renders the canonical expiry filter — the base filter every listing that
  shows inventory items carries, so "Expired"/"Expiring in 30 days" mean the
  same thing on every page: a preset status select plus a custom from/to date
  pair for anything the presets don't cover. Occupies three
  `filter_drawer/1` grid cells.

  The submitted status is one of `Medcamp.ExpiryFilter.statuses/0` and the dates
  are ISO strings; fold them into one range in the context with
  `Medcamp.ExpiryFilter.bounds/4` (or, for lists filtered in memory,
  `Medcamp.ExpiryFilter.matches?/4`). A custom date only ever narrows the preset.

  ## Examples

      <.expiry_filter_fields
        status_value={@filters[:expiry_status]}
        from_value={@filters[:expiry_from]}
        to_value={@filters[:expiry_to]}
      />
  """
  attr :status_name, :string, default: "filters[expiry_status]"
  attr :status_value, :string, default: ""
  attr :status_label, :string, default: "Expiry"
  attr :from_name, :string, default: "filters[expiry_from]"
  attr :to_name, :string, default: "filters[expiry_to]"
  attr :from_value, :string, default: ""
  attr :to_value, :string, default: ""

  def expiry_filter_fields(assigns) do
    ~H"""
    <.expiry_status_field name={@status_name} value={@status_value} label={@status_label} />
    <.date_range_fields
      from_name={@from_name}
      to_name={@to_name}
      from_value={@from_value || ""}
      to_value={@to_value || ""}
      from_label="Expiry From"
      to_label="Expiry To"
      disable_future={false}
    />
    """
  end

  @doc """
  Renders just the preset half of `expiry_filter_fields/1`, for pages that
  filter on an expiry they only ever bucket (no custom range). Occupies one
  `filter_drawer/1` grid cell.
  """
  attr :name, :string, default: "filters[expiry_status]"
  attr :value, :string, default: ""
  attr :label, :string, default: "Expiry"

  def expiry_status_field(assigns) do
    assigns = assign(assigns, :value, Medcamp.ExpiryFilter.normalize(assigns.value))

    ~H"""
    <div>
      <label class="mb-1 block text-xs font-medium text-gray-600">{@label}</label>
      <select
        name={@name}
        class="h-9 w-full rounded-md border border-gray-300 px-2 text-sm focus:border-brand-accent focus:ring-brand-accent"
      >
        <option
          :for={{value, label} <- Medcamp.ExpiryFilter.options()}
          value={value}
          selected={@value == value}
        >
          {label}
        </option>
      </select>
    </div>
    """
  end

  @doc """
  Renders a "from"/"to" pair of time inputs, side by side, for use inside a
  `filter_drawer/1` group. Occupies two grid cells.
  """
  attr :from_name, :string, required: true
  attr :to_name, :string, required: true
  attr :from_value, :string, default: ""
  attr :to_value, :string, default: ""
  attr :from_label, :string, default: "Time From"
  attr :to_label, :string, default: "Time To"

  def time_range_fields(assigns) do
    ~H"""
    <div>
      <label class="mb-1 block text-sm font-medium text-gray-700">{@from_label}</label>
      <input
        type="time"
        name={@from_name}
        value={@from_value}
        max={@to_value != "" && @to_value}
        class="h-[40px] w-full rounded-md border-[1px] border-gray-300 p-2 focus:ring-0 focus:outline-none"
      />
    </div>
    <div>
      <label class="mb-1 block text-sm font-medium text-gray-700">{@to_label}</label>
      <input
        type="time"
        name={@to_name}
        value={@to_value}
        min={@from_value != "" && @from_value}
        class="h-[40px] w-full rounded-md border-[1px] border-gray-300 p-2 focus:ring-0 focus:outline-none"
      />
    </div>
    """
  end

  @doc """
  Renders the canonical toolbar search box: a plain text input styled and
  sized the same way everywhere it appears (so pages don't each hand-roll
  slightly different height/font-size combinations). Pair with
  `phx-change`/`phx-submit` on the wrapping `<form>`, same as before.

  ## Examples

      <.search_input name="filters[search]" value={@filters.search} placeholder="Search by name or email" />
  """
  attr :name, :string, required: true
  attr :value, :string, default: ""
  attr :placeholder, :string, required: true
  attr :debounce, :string, default: "300"
  attr :rest, :global

  def search_input(assigns) do
    ~H"""
    <input
      type="text"
      name={@name}
      value={@value}
      placeholder={@placeholder}
      phx-debounce={@debounce}
      class="h-[40px] w-full rounded-md border border-gray-300 px-3 text-sm focus:border-brand-accent focus:outline-none focus:ring-0"
      {@rest}
    />
    """
  end

  @doc """
  Renders the canonical "nothing here yet" placeholder for an empty table,
  so every listing page shows the same shape (icon, short title, one-line
  description) instead of each hand-rolling its own.

  ## Examples

      <.blank_state
        icon_path="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
        title="No patients"
        description="No patients have been registered yet."
      />
  """
  attr :icon_path, :string, required: true
  attr :title, :string, required: true

  attr :description, :string,
    default: nil,
    doc: "ignored if the :description_slot slot is used"

  slot :description_slot, doc: "use instead of the description attr for dynamic/rich content"
  slot :actions, doc: "optional buttons/links rendered below the description, e.g. Clear filters"

  def blank_state(assigns) do
    ~H"""
    <div class="text-center py-8 bg-gray-50 rounded-lg border border-dashed border-gray-300">
      <svg
        xmlns="http://www.w3.org/2000/svg"
        class="mx-auto h-12 w-12 text-gray-400"
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
      >
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d={@icon_path} />
      </svg>
      <h3 class="mt-2 text-sm font-medium text-gray-900">{@title}</h3>
      <p class="mt-1 text-sm text-gray-500">
        {render_slot(@description_slot) || @description}
      </p>
      <div :if={@actions != []} class="mt-2">
        {render_slot(@actions)}
      </div>
    </div>
    """
  end

  @doc """
  Renders the age group + gender select pair shared by the patient/visit
  listing pages, for use inside a `filter_drawer/1` group. Occupies two grid
  cells.
  """
  attr :age_group_name, :string, default: "filters[age_group]"
  attr :age_group_value, :string, default: ""
  attr :gender_name, :string, default: "filters[gender]"
  attr :gender_value, :string, default: ""

  def age_gender_fields(assigns) do
    ~H"""
    <div>
      <label class="mb-1 block text-xs font-medium text-gray-600">Age Group</label>
      <select
        name={@age_group_name}
        class="h-9 w-full rounded-md border border-gray-300 px-2 text-sm focus:border-brand-accent focus:ring-brand-accent"
      >
        <option value="">All</option>
        <option value="<5" selected={@age_group_value == "<5"}>&lt; 5 years</option>
        <option value="5-17" selected={@age_group_value == "5-17"}>5 - 17 years</option>
        <option value="18-59" selected={@age_group_value == "18-59"}>18 - 59 years</option>
        <option value="60+" selected={@age_group_value == "60+"}>60+ years</option>
      </select>
    </div>
    <div>
      <label class="mb-1 block text-xs font-medium text-gray-600">Gender</label>
      <select
        name={@gender_name}
        class="h-9 w-full rounded-md border border-gray-300 px-2 text-sm focus:border-brand-accent focus:ring-brand-accent"
      >
        <option value="">All</option>
        <option value="Male" selected={@gender_value == "Male"}>Male</option>
        <option value="Female" selected={@gender_value == "Female"}>Female</option>
      </select>
    </div>
    """
  end

  @doc """
  Renders the diagnosis search + visit type select pair shared by the
  patient/visit listing pages, for use inside a `filter_drawer/1` group.
  Occupies two grid cells. `visit_type_options` defaults to the standard
  5-option set; pass a longer list for pages with extra visit types (e.g.
  receptions_pages/patient_visit_live's Triage Only/ANC/Lab Test/Pharmacy/Other).
  """
  attr :diagnosis_name, :string, default: "filters[diagnosis]"
  attr :diagnosis_value, :string, default: ""
  attr :visit_type_name, :string, default: "filters[visit_type]"
  attr :visit_type_value, :string, default: ""

  attr :visit_type_options, :list,
    default: [
      {"inpatient", "Inpatient"},
      {"outpatient", "Outpatient"},
      {"MCH", "MCH"},
      {"referral in", "Referral In"},
      {"referral out", "Referral Out"}
    ]

  def diagnosis_visit_type_fields(assigns) do
    ~H"""
    <div>
      <label class="mb-1 block text-xs font-medium text-gray-600">Diagnosis</label>
      <input
        type="text"
        name={@diagnosis_name}
        value={@diagnosis_value}
        placeholder="Search..."
        class="h-9 w-full rounded-md border border-gray-300 px-2 text-sm focus:border-brand-accent focus:ring-brand-accent"
      />
    </div>
    <div>
      <label class="mb-1 block text-xs font-medium text-gray-600">Visit Type</label>
      <select
        name={@visit_type_name}
        class="h-9 w-full rounded-md border border-gray-300 px-2 text-sm focus:border-brand-accent focus:ring-brand-accent"
      >
        <option value="">All</option>
        <option
          :for={{value, label} <- @visit_type_options}
          value={value}
          selected={@visit_type_value == value}
        >
          {label}
        </option>
      </select>
    </div>
    """
  end

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :warning, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class={[
        "fixed top-2 right-2 mr-2 w-80 sm:w-96 z-50 rounded-lg p-3 ring-1 print:hidden",
        @kind == :info && "bg-emerald-50 text-emerald-800 ring-emerald-500 fill-cyan-900",
        @kind == :warning && "bg-amber-50 text-amber-800 ring-amber-500 fill-amber-900",
        @kind == :error && "bg-rose-50 text-rose-900 shadow-md ring-rose-500 fill-rose-900"
      ]}
      {@rest}
    >
      <p :if={@title} class="flex items-center gap-1.5 text-sm font-semibold leading-6">
        <.icon :if={@kind == :info} name="hero-information-circle-mini" class="h-4 w-4" />
        <.icon :if={@kind == :warning} name="hero-exclamation-triangle-mini" class="h-4 w-4" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle-mini" class="h-4 w-4" />
        {@title}
      </p>
      <p class="mt-2 text-sm leading-5">{msg}</p>
      <button type="button" class="group absolute top-1 right-1 p-2" aria-label={gettext("close")}>
        <.icon name="hero-x-mark-solid" class="h-5 w-5 opacity-40 group-hover:opacity-70" />
      </button>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} class="print:hidden">
      <.flash kind={:info} title={gettext("Success!")} flash={@flash} />
      <.flash kind={:warning} title={gettext("Notice")} flash={@flash} />
      <.flash kind={:error} title={gettext("Error!")} flash={@flash} />
      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error")}
        phx-connected={hide("#client-error")}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error")}
        phx-connected={hide("#server-error")}
        hidden
      >
        {gettext("Hang in there while we get back on track")}
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:email]} label="Email"/>
        <.input field={@form[:username]} label="Username" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
  """
  attr :for, :any, required: true, doc: "the data structure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="mt-4 space-y-8 bg-white">
        {render_slot(@inner_block, f)}
        <div :for={action <- @actions} class="mt-2 flex items-center justify-between gap-6">
          {render_slot(action, f)}
        </div>
      </div>
    </.form>
    """
  end

  @doc """
  Renders a button.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
  """
  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "phx-submit-loading:opacity-75 rounded-lg bg-[#1D3557] hover:bg-[#1D3557]/80 py-2 px-3",
        "text-sm font-semibold leading-6 text-white active:text-white/80",
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information. Unsupported types, such as hidden and radio,
  are best written directly in your templates.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               range search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div>
      <label class="flex items-center gap-4 text-sm leading-6 text-zinc-600">
        <input type="hidden" name={@name} value="false" disabled={@rest[:disabled]} />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class="rounded border-zinc-300 text-zinc-900 focus:ring-0"
          {@rest}
        />
        {@label}
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div>
      <.label for={@id}>{@label}</.label>
      <select
        id={@id}
        name={@name}
        class="mt-2 block w-full rounded-md border border-gray-300 bg-white shadow-sm focus:border-zinc-400 focus:ring-0 sm:text-sm"
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt} value="">{@prompt}</option>
        {Phoenix.HTML.Form.options_for_select(@options, @value)}
      </select>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div>
      <.label for={@id}>{@label}</.label>
      <textarea
        id={@id}
        name={@name}
        class={[
          "mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6 min-h-[6rem]",
          @errors == [] && "border-zinc-300 focus:border-zinc-400",
          @errors != [] && "border-rose-400 focus:border-rose-400"
        ]}
        {@rest}
      >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div>
      <.label for={@id}>{@label}</.label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[
          "mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6",
          @errors == [] && "border-zinc-300 focus:border-zinc-400",
          @errors != [] && "border-rose-400 focus:border-rose-400"
        ]}
        {@rest}
      />
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for} class="block text-sm font-semibold leading-6 text-zinc-800">
      {render_slot(@inner_block)}
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="mt-3 flex gap-3 text-sm leading-6 text-rose-600">
      <.icon name="hero-exclamation-circle-mini" class="mt-0.5 h-5 w-5 flex-none" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  attr :class, :string, default: nil

  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", @class]}>
      <div>
        <h1 class="text-lg font-semibold leading-8 text-zinc-800">
          {render_slot(@inner_block)}
        </h1>
        <p :if={@subtitle != []} class="mt-2 text-sm leading-6 text-zinc-600">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div class="flex-none">{render_slot(@actions)}</div>
    </header>
    """
  end

  @doc ~S"""
  Renders a table with generic styling.

  Only a bounded number of columns are shown in the main row so the table
  never needs horizontal scrolling; the rest (plus row actions) live behind
  a chevron toggle that expands the row in place, mirroring how narrow
  dashboards surface "Details" on demand.

  Mark the columns that matter most with `always_show`; those render in the
  fixed row and everything else moves into the expand panel. If no column
  sets `always_show`, the first `visible_cols` columns (default 4) are used
  automatically, so existing callers work unchanged.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id" always_show>{user.id}</:col>
        <:col :let={user} label="username" always_show>{user.username}</:col>
        <:col :let={user} label="email">{user.email}</:col>
      </.table>
  """
  attr :id, :string, required: true

  attr :rows, :any,
    required: true,
    doc: "the table rows as either a list or a Phoenix.LiveView.LiveStream"

  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"
  attr :wrap_cells, :boolean, default: false

  attr :visible_cols, :integer,
    default: 4,
    doc:
      "how many leading :col slots stay always-visible when none of them set " <>
        "`always_show` explicitly"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string

    attr :always_show, :boolean,
      doc: "keep this column in the fixed row instead of the expand panel"
  end

  slot :action, doc: "the slot for showing user actions in the expand panel"

  slot :empty_state,
    doc:
      "rendered as a placeholder <tr> (or <tr>s) when rows is empty, so headers stay visible " <>
        "instead of swapping the whole table out for a blank_state card. Lives in its own " <>
        "<tbody>, separate from the row-stream one, so it never interferes with " <>
        "phx-update=\"stream\" diffing."

  def table(assigns) do
    assigns =
      case assigns.rows do
        %Phoenix.LiveView.LiveStream{} = rows ->
          assign(assigns,
            render_rows: rows,
            row_id: assigns.row_id || fn {id, _item} -> id end
          )

        rows ->
          render_rows =
            rows
            |> Enum.with_index()
            |> Enum.map(fn {row, index} -> {:indexed_table_row, index, row} end)

          assign(assigns, :render_rows, render_rows)
      end

    {visible_cols, hidden_cols} = split_cols(assigns.col, assigns.visible_cols)
    has_expand = hidden_cols != [] or assigns.action != []

    assigns =
      assigns
      |> assign(:visible_cols, visible_cols)
      |> assign(:hidden_cols, hidden_cols)
      |> assign(:has_expand, has_expand)

    ~H"""
    <div class="table-container overflow-hidden rounded-xl border border-slate-200">
      <table class="w-full table-fixed">
        <thead class="border-b border-slate-200 bg-slate-50/80">
          <tr>
            <th
              :for={col <- @visible_cols}
              class={[
                "px-6 py-4 text-left text-sm font-semibold text-slate-700",
                @wrap_cells && "[white-space:normal!important]"
              ]}
            >
              {col[:label]}
            </th>
            <th
              :if={@has_expand}
              class="w-24 px-6 py-4 text-right text-sm font-semibold text-slate-700"
            >
              Details
            </th>
          </tr>
        </thead>
        <tbody
          :if={rows_empty?(@rows) and @empty_state != []}
          class="divide-y divide-slate-100 bg-white"
        >
          {render_slot(@empty_state)}
        </tbody>
        <tbody
          id={@id}
          phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && !@has_expand && "stream"}
          class="divide-y divide-slate-100 bg-white"
        >
          <%= for render_row <- @render_rows do %>
            <% {row, row_id} = table_row_and_id(render_row, @row_id, @id) %>
            <tr id={row_id} class="group transition-colors hover:bg-slate-50/50">
              <td
                :for={col <- @visible_cols}
                phx-click={@row_click && @row_click.(row)}
                class={[
                  "px-6 py-3 text-sm",
                  @row_click && "cursor-pointer",
                  @wrap_cells && "[white-space:normal!important] break-words align-top",
                  !@wrap_cells && "truncate"
                ]}
              >
                {render_slot(col, @row_item.(row))}
              </td>
              <td :if={@has_expand} class="px-6 py-3 text-right text-sm">
                <button
                  type="button"
                  phx-click={row_id && toggle_row_details(row_id)}
                  class="inline-flex h-8 w-8 items-center justify-center rounded-md border border-slate-200 text-slate-500 hover:bg-slate-100"
                  aria-label={gettext("Show details")}
                >
                  <.icon
                    name="hero-chevron-down-mini"
                    class={"h-4 w-4 transition-transform #{row_id && "row-details-chevron-#{row_id}"}"}
                  />
                </button>
              </td>
            </tr>
            <tr :if={@has_expand} id={row_id && "#{row_id}-details"} class="hidden bg-slate-50/60">
              <td colspan={length(@visible_cols) + 1} class="px-6 py-4">
                <dl
                  :if={@hidden_cols != []}
                  class="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3"
                >
                  <div :for={col <- @hidden_cols}>
                    <dt class="text-xs font-semibold tracking-wide text-slate-500 uppercase">
                      {col[:label]}
                    </dt>
                    <dd class="mt-1 text-sm text-slate-700">
                      {render_slot(col, @row_item.(row))}
                    </dd>
                  </div>
                </dl>
                <div
                  :if={@action != []}
                  class="mt-3 flex items-center gap-2 border-t border-slate-200 pt-3"
                >
                  <span :for={action <- @action} class="inline-block">
                    {render_slot(action, @row_item.(row))}
                  </span>
                </div>
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end

  defp split_cols(cols, visible_cols) do
    if Enum.any?(cols, & &1[:always_show]) do
      Enum.split_with(cols, & &1[:always_show])
    else
      Enum.split(cols, visible_cols)
    end
  end

  defp table_row_and_id({:indexed_table_row, index, row}, nil, table_id),
    do: {row, "#{table_id}-row-#{index}"}

  defp table_row_and_id({:indexed_table_row, _index, row}, row_id, _table_id),
    do: {row, row_id.(row)}

  defp table_row_and_id(row, row_id, _table_id), do: {row, row_id.(row)}

  def toggle_row_details(js \\ %JS{}, row_id) when is_binary(row_id) do
    js
    |> JS.toggle(to: "##{row_id}-details", display: "table-row")
    |> JS.toggle_class("rotate-180", to: ".row-details-chevron-#{row_id}")
  end

  # LiveStream's Enumerable impl raises on `slice/1`, which `Enum.empty?/1` relies
  # on, so it can't be used directly on `@streams.x` assigns passed as `rows`.
  defp rows_empty?(%Phoenix.LiveView.LiveStream{inserts: inserts}), do: inserts == []
  defp rows_empty?(rows), do: Enum.empty?(rows)

  @doc """
  Renders a lightweight pagination footer for table views.
  """
  attr :page, :integer, required: true
  attr :total_pages, :integer, required: true
  attr :total_count, :integer, required: true
  attr :per_page, :integer, default: 10
  attr :event, :string, default: "paginate"
  attr :class, :string, default: nil

  attr :show_when_empty, :boolean,
    default: false,
    doc:
      "if true, still render the bar (as \"Page 1 of 0\", Previous/Next disabled, no " <>
        "\"Showing x-y of z\" line) when total_count is 0, instead of rendering nothing"

  def pagination(assigns) do
    {from, to} = Pagination.page_window(assigns.page, assigns.total_count, assigns.per_page)

    assigns =
      assigns
      |> assign(:from, from)
      |> assign(:to, to)
      |> assign(
        :display_total_pages,
        if(assigns.total_count == 0, do: 0, else: assigns.total_pages)
      )

    ~H"""
    <div
      :if={@total_pages > 1 or (@show_when_empty and @total_count == 0)}
      class={["mt-5 border-t border-slate-200 px-4 py-4 sm:px-5", @class]}
    >
      <div class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <p :if={@total_count > 0} class="text-center text-sm text-slate-600 sm:text-left">
          Showing {@from}–{@to} of {@total_count}
        </p>

        <div class="flex flex-col items-center gap-3 sm:flex-row sm:justify-end sm:gap-4">
          <button
            type="button"
            phx-click={@page > 1 && @event}
            phx-value-page={@page - 1}
            disabled={@page <= 1}
            class={[
              "inline-flex min-w-[7.5rem] items-center justify-center gap-1.5 rounded-md px-4 py-2.5 text-sm font-medium transition",
              @page <= 1 &&
                "cursor-not-allowed bg-gray-100 text-gray-400",
              @page > 1 &&
                "bg-gray-100 text-gray-700 hover:bg-gray-200"
            ]}
          >
            <Heroicons.icon name="chevron-left" type="outline" class="h-4 w-4" /> Previous
          </button>

          <span class="text-center text-sm text-slate-500">
            Page <span class="font-semibold text-slate-900">{@page}</span>
            of <span class="font-semibold text-slate-900">{@display_total_pages}</span>
          </span>

          <button
            type="button"
            phx-click={@page < @total_pages && @event}
            phx-value-page={@page + 1}
            disabled={@page >= @total_pages}
            class={[
              "inline-flex min-w-[7.5rem] items-center justify-center gap-1.5 rounded-md px-4 py-2.5 text-sm font-medium transition",
              @page >= @total_pages &&
                "cursor-not-allowed bg-gray-100 text-gray-400",
              @page < @total_pages &&
                "bg-gray-100 text-gray-700 hover:bg-gray-200"
            ]}
          >
            Next <Heroicons.icon name="chevron-right" type="outline" class="h-4 w-4" />
          </button>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title">{@post.title}</:item>
        <:item title="Views">{@post.views}</:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <div class="mt-14">
      <dl class="-my-4 divide-y divide-zinc-100">
        <div :for={item <- @item} class="flex gap-4 py-4 text-sm leading-6 sm:gap-8">
          <dt class="w-1/4 flex-none text-zinc-500">{item.title}</dt>
          <dd class="text-zinc-700">{render_slot(item)}</dd>
        </div>
      </dl>
    </div>
    """
  end

  @doc """
  Renders a back navigation link.

  ## Examples

      <.back navigate={~p"/posts"}>Back to posts</.back>
  """
  attr :navigate, :any, required: true
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def back(assigns) do
    ~H"""
    <div class="">
      <.link
        navigate={@navigate}
        class={[
          "text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700 inline-flex items-center gap-1",
          @class
        ]}
      >
        <.icon name="hero-arrow-left-solid" class="h-3 w-3" />
        {render_slot(@inner_block)}
      </.link>
    </div>
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from the `deps/heroicons` directory and bundled within
  your compiled app.css by the plugin in your `assets/tailwind.config.js`.

  ## Examples

      <.icon name="hero-x-mark-solid" />
      <.icon name="hero-arrow-path" class="ml-1 w-3 h-3 animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :string, default: nil

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      time: 300,
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  def show_filter_drawer(js \\ %JS{}, id) when is_binary(id) do
    js
    # Discard any edits left over from a previous open-without-applying by
    # resetting the form to its last server-rendered values before it's shown
    # again — closing the drawer is pure client-side, so nothing else does this.
    |> JS.dispatch("click", to: "##{id}-reset-btn")
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-panel",
      display: "flex",
      time: 150,
      transition:
        {"transition transform ease-out duration-150", "opacity-0 scale-95",
         "opacity-100 scale-100"}
    )
    |> JS.focus_first(to: "##{id}-panel")
  end

  def hide_filter_drawer(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.hide(
      to: "##{id}-panel",
      time: 100,
      transition:
        {"transition transform ease-in duration-100", "opacity-100 scale-100",
         "opacity-0 scale-95"}
    )
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"}, time: 150)
    |> JS.pop_focus()
  end

  @doc """
  Formats a DateTime/NaiveDateTime for display in Kenya timezone (UTC+3).
  Adds 3 hours to UTC values. Use for all user-facing timestamps.
  """
  def format_datetime_kenya(nil), do: "—"

  def format_datetime_kenya(%DateTime{} = dt) do
    dt
    |> DateTime.add(3 * 60 * 60, :second)
    |> Calendar.strftime("%b %d, %Y %H:%M")
  end

  def format_datetime_kenya(%NaiveDateTime{} = ndt) do
    ndt
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.add(3 * 60 * 60, :second)
    |> Calendar.strftime("%b %d, %Y %H:%M")
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(MedcampWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(MedcampWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end

  @doc """
  Interactive e-signature pad backed by the SignaturePad JS hook.
  Each pad on a page must have a unique `id`.
  """
  attr :id, :string, required: true
  attr :label, :string, default: "Signature"
  attr :name, :string, default: nil
  attr :value, :string, default: ""

  def signature_pad(assigns) do
    assigns =
      assigns
      |> assign_new(:name, fn -> assigns.id end)
      |> assign_new(:value, fn -> "" end)

    ~H"""
    <div class="space-y-1.5">
      <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide">
        {@label}
      </label>
      <div
        id={@id}
        phx-hook="SignaturePad"
        class="relative border border-gray-300 rounded-lg overflow-hidden bg-white group"
      >
        <canvas class="w-full h-24 touch-none cursor-crosshair block"></canvas>
        <input type="hidden" name={@name} value={@value} />
        <div class="absolute top-1.5 right-1.5 flex gap-1 print:hidden opacity-0 group-hover:opacity-100 transition-opacity">
          <button
            type="button"
            data-undo
            class="px-2 py-0.5 text-xs bg-white border border-gray-200 rounded text-gray-500 hover:bg-gray-50 shadow-sm"
          >
            Undo
          </button>
          <button
            type="button"
            data-clear
            class="px-2 py-0.5 text-xs bg-white border border-gray-200 rounded text-red-400 hover:bg-red-50 shadow-sm"
          >
            Clear
          </button>
        </div>
        <p class="absolute bottom-1.5 left-2 text-[10px] text-gray-300 pointer-events-none print:hidden">
          Draw signature above
        </p>
      </div>
    </div>
    """
  end
end
