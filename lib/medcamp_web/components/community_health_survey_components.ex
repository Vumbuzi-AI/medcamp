defmodule MedcampWeb.CommunityHealthSurveyComponents do
  use Phoenix.Component

  import MedcampWeb.CoreComponents

  attr :metrics, :map, required: true
  attr :filter_date_from, :string, required: true
  attr :filter_date_to, :string, required: true
  attr :filter_search, :string, required: true
  attr :share_path, :string, required: true

  def survey_dashboard(assigns) do
    ~H"""
    <div class="space-y-8">
      <section class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm lg:p-8">
        <div class="flex flex-col gap-6 lg:flex-row lg:items-start lg:justify-between">
          <div class="space-y-3">
            <span class="inline-flex items-center rounded-full bg-emerald-50 px-3 py-1 text-xs font-semibold uppercase tracking-[0.18em] text-emerald-700">
              Community Health Survey
            </span>
            <div>
              <h1 class="text-2xl font-semibold tracking-tight text-slate-950 lg:text-3xl">
                Insurance uptake and service demand at a glance
              </h1>
              <p class="mt-2 max-w-3xl text-sm leading-6 text-slate-600">
                Review completed household surveys, spot conversion opportunities, and keep the reception team aligned on community demand.
              </p>
            </div>
          </div>

          <div class="rounded-3xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm text-slate-600">
            <p class="font-medium text-slate-900">Public survey URL</p>
            <p class="mt-1 break-all font-mono text-xs text-slate-500">{@share_path}</p>
          </div>
        </div>
      </section>

      <div class="flex items-center gap-3">
        <form phx-change="apply_filters" class="flex-1">
          <.search_input
            name="filters[search]"
            value={@filter_search}
            placeholder="Search by surveyor, house number, contact, or facility"
          />
        </form>

        <.filter_drawer
          id="community-health-survey-filters"
          title="Filter survey responses"
          apply_event="apply_filters"
          clear_event="clear_filters"
          active_count={count_active_filters(assigns)}
        >
          <:group label="Survey Date">
            <.date_range_fields
              from_name="filters[date_from]"
              to_name="filters[date_to]"
              from_value={@filter_date_from}
              to_value={@filter_date_to}
              from_label="Survey Date From"
              to_label="Survey Date To"
            />
          </:group>
        </.filter_drawer>
      </div>

      <section class="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        <.metric_card label="Households surveyed" value={@metrics.total_households} tone="slate" />
        <.metric_card label="Total population" value={@metrics.total_population} tone="emerald" />
        <.metric_card
          label="Average household size"
          value={format_decimal(@metrics.average_household_size)}
          tone="amber"
        />
        <.metric_card
          label="Insurance coverage rate"
          value={format_percentage(@metrics.insurance_coverage_rate)}
          tone="sky"
        />
        <.metric_card
          label="SHA coverage rate"
          value={format_percentage(@metrics.sha_coverage_rate)}
          tone="violet"
        />
        <.metric_card
          label="Private insurance penetration"
          value={format_percentage(@metrics.private_insurance_penetration)}
          tone="rose"
        />
        <.metric_card
          label="Awareness of Glocal"
          value={format_percentage(@metrics.awareness_of_glocal_rate)}
          tone="teal"
        />
        <.metric_card
          label="Interested in screenings"
          value={"#{@metrics.screening_interest_count} • #{format_percentage(@metrics.screening_interest_rate)}"}
          tone="lime"
        />
        <.metric_card
          label="Leads generated"
          value={"#{@metrics.contact_leads_count} • #{format_percentage(@metrics.contact_leads_rate)}"}
          tone="orange"
        />
      </section>

      <section class="grid gap-4 xl:grid-cols-2">
        <.ranking_card
          title="Most common insurance providers"
          subtitle="Share of all surveyed households"
          items={@metrics.provider_rankings}
          empty_message="No provider data yet."
        />
        <.ranking_card
          title="Preferred health facilities"
          subtitle="What households rely on today"
          items={@metrics.facility_rankings}
          empty_message="No facility preferences yet."
        />
        <.ranking_card
          title="Demand for services"
          subtitle="Likely services households would use"
          items={@metrics.service_rankings}
          empty_message="No service demand data yet."
        />
        <.ranking_card
          title="Household chronic conditions"
          subtitle="Conditions reported across households"
          items={@metrics.household_condition_rankings}
          empty_message="No chronic condition data yet."
        />
        <.ranking_card
          title="Experience at Glocal"
          subtitle="Only households that have visited"
          items={@metrics.experience_breakdown}
          empty_message="No experience ratings yet."
        />
        <.ranking_card
          title="Why households have not visited Glocal"
          subtitle="Key conversion blockers"
          items={@metrics.non_visit_reason_rankings}
          empty_message="No conversion blockers yet."
        />
      </section>

      <section class="grid gap-4 xl:grid-cols-2">
        <.response_table
          title={"Contact leads (#{@metrics.contact_leads_count})"}
          subtitle="Households open to updates with a valid contact number"
          rows={@metrics.contact_leads}
          empty_message="No leads captured yet."
        />
        <.opportunities_table
          title={"Conversion opportunities (#{@metrics.conversion_opportunities_count})"}
          subtitle="Households that have not yet visited Glocal"
          rows={@metrics.conversion_opportunities}
          empty_message="No conversion opportunities yet."
        />
      </section>

      <section class="rounded-[1.75rem] border border-slate-200 bg-white p-5 shadow-sm">
        <div class="flex items-center justify-between gap-3">
          <div>
            <h2 class="text-lg font-semibold text-slate-950">Recent responses</h2>
            <p class="mt-1 text-sm text-slate-500">
              Latest submissions matching the current filters
            </p>
          </div>
          <span class="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold uppercase tracking-[0.14em] text-slate-500">
            {length(@metrics.recent_responses)} shown
          </span>
        </div>

        <div class="mt-5 overflow-x-auto">
          <table class="min-w-full divide-y divide-slate-200 text-sm">
            <thead>
              <tr class="text-left text-xs font-semibold uppercase tracking-[0.14em] text-slate-500">
                <th class="px-3 py-3">Surveyor</th>
                <th class="px-3 py-3">Date</th>
                <th class="px-3 py-3">House</th>
                <th class="px-3 py-3">Household</th>
                <th class="px-3 py-3">Insurance</th>
                <th class="px-3 py-3">Facility</th>
                <th class="px-3 py-3">Lead</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
              <tr :for={response <- @metrics.recent_responses}>
                <td class="px-3 py-4">
                  <div class="font-medium text-slate-900">{display_surveyor_name(response)}</div>
                  <div class="text-xs text-slate-500">
                    Submitted {format_datetime_kenya(response.inserted_at)}
                  </div>
                </td>
                <td class="px-3 py-4 text-slate-600">{format_date(response.survey_date)}</td>
                <td class="px-3 py-4 text-slate-600">{response.house_number}</td>
                <td class="px-3 py-4 text-slate-600">{response.total_household_members}</td>
                <td class="px-3 py-4">
                  <span class={yes_no_badge(response.has_health_insurance == "Yes")}>
                    {response.has_health_insurance}
                  </span>
                </td>
                <td class="px-3 py-4 text-slate-600">{display_facility(response)}</td>
                <td class="px-3 py-4">
                  <%= if response.wants_updates == "Yes" and response.contact_number do %>
                    <div class="font-medium text-slate-900">{response.contact_number}</div>
                    <div class="text-xs text-slate-500">{response.preferred_contact_method}</div>
                  <% else %>
                    <span class="text-slate-400">No lead</span>
                  <% end %>
                </td>
              </tr>
              <tr :if={Enum.empty?(@metrics.recent_responses)}>
                <td colspan="7" class="px-3 py-10 text-center text-sm text-slate-500">
                  No responses found for the selected filters.
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>
    </div>
    """
  end

  defp count_active_filters(assigns) do
    [assigns.filter_date_from != "", assigns.filter_date_to != ""]
    |> Enum.count(& &1)
  end

  attr :label, :string, required: true
  attr :value, :any, required: true
  attr :tone, :string, default: "slate"

  defp metric_card(assigns) do
    ~H"""
    <article class={["rounded-[1.5rem] border p-5 shadow-sm", metric_card_classes(@tone)]}>
      <p class="text-xs font-semibold uppercase tracking-[0.16em] text-slate-500">{@label}</p>
      <p class="mt-3 text-3xl font-semibold tracking-tight text-slate-950">{@value}</p>
    </article>
    """
  end

  attr :title, :string, required: true
  attr :subtitle, :string, required: true
  attr :items, :list, required: true
  attr :empty_message, :string, required: true

  defp ranking_card(assigns) do
    ~H"""
    <article class="rounded-[1.75rem] border border-slate-200 bg-white p-5 shadow-sm">
      <h2 class="text-lg font-semibold text-slate-950">{@title}</h2>
      <p class="mt-1 text-sm text-slate-500">{@subtitle}</p>

      <div class="mt-5 space-y-4">
        <%= for item <- @items do %>
          <div>
            <div class="flex items-center justify-between gap-3 text-sm">
              <span class="font-medium text-slate-800">{item.label}</span>
              <span class="text-slate-500">
                {item.count} • {format_percentage(item.percentage)}
              </span>
            </div>
            <div class="mt-2 h-2 overflow-hidden rounded-full bg-slate-100">
              <div
                class="h-full rounded-full bg-emerald-500"
                style={"width: #{min(item.percentage, 100.0)}%"}
              >
              </div>
            </div>
          </div>
        <% end %>

        <p :if={Enum.empty?(@items)} class="rounded-2xl bg-slate-50 px-4 py-6 text-sm text-slate-500">
          {@empty_message}
        </p>
      </div>
    </article>
    """
  end

  attr :title, :string, required: true
  attr :subtitle, :string, required: true
  attr :rows, :list, required: true
  attr :empty_message, :string, required: true

  defp response_table(assigns) do
    ~H"""
    <article class="rounded-[1.75rem] border border-slate-200 bg-white p-5 shadow-sm">
      <h2 class="text-lg font-semibold text-slate-950">{@title}</h2>
      <p class="mt-1 text-sm text-slate-500">{@subtitle}</p>

      <div class="mt-5 space-y-3">
        <%= for row <- @rows do %>
          <div class="rounded-2xl border border-slate-200 bg-slate-50 p-4">
            <div class="flex items-start justify-between gap-4">
              <div>
                <p class="font-medium text-slate-900">{display_surveyor_name(row)}</p>
                <p class="mt-1 text-sm text-slate-500">
                  House {row.house_number} • {row.contact_number}
                </p>
              </div>
              <span class="rounded-full bg-emerald-100 px-3 py-1 text-xs font-semibold uppercase tracking-[0.14em] text-emerald-700">
                {row.preferred_contact_method}
              </span>
            </div>
            <div class="mt-3 flex flex-wrap gap-2 text-xs text-slate-500">
              <span class="rounded-full bg-white px-3 py-1">
                Insurance: {Enum.join(row.insurance_providers, ", ")}
              </span>
              <span class="rounded-full bg-white px-3 py-1">
                Facility: {display_facility(row)}
              </span>
            </div>
          </div>
        <% end %>

        <p :if={Enum.empty?(@rows)} class="rounded-2xl bg-slate-50 px-4 py-6 text-sm text-slate-500">
          {@empty_message}
        </p>
      </div>
    </article>
    """
  end

  attr :title, :string, required: true
  attr :subtitle, :string, required: true
  attr :rows, :list, required: true
  attr :empty_message, :string, required: true

  defp opportunities_table(assigns) do
    ~H"""
    <article class="rounded-[1.75rem] border border-slate-200 bg-white p-5 shadow-sm">
      <h2 class="text-lg font-semibold text-slate-950">{@title}</h2>
      <p class="mt-1 text-sm text-slate-500">{@subtitle}</p>

      <div class="mt-5 space-y-3">
        <%= for row <- @rows do %>
          <div class="rounded-2xl border border-slate-200 bg-slate-50 p-4">
            <div class="flex items-start justify-between gap-4">
              <div>
                <p class="font-medium text-slate-900">{display_surveyor_name(row)}</p>
                <p class="mt-1 text-sm text-slate-500">House {row.house_number}</p>
              </div>
              <span class={yes_no_badge(row.interested_in_screenings == "Yes")}>
                Screenings: {row.interested_in_screenings}
              </span>
            </div>
            <p class="mt-3 text-sm text-slate-700">
              Main blocker: <span class="font-medium">{row.glocal_non_visit_reason}</span>
            </p>
            <div class="mt-3 flex flex-wrap gap-2 text-xs text-slate-500">
              <span class="rounded-full bg-white px-3 py-1">
                Preferred facility: {display_facility(row)}
              </span>
              <span class="rounded-full bg-white px-3 py-1">
                Insurance: {row.has_health_insurance}
              </span>
            </div>
          </div>
        <% end %>

        <p :if={Enum.empty?(@rows)} class="rounded-2xl bg-slate-50 px-4 py-6 text-sm text-slate-500">
          {@empty_message}
        </p>
      </div>
    </article>
    """
  end

  defp display_facility(response) do
    case response.preferred_facility_type do
      "Other"
      when is_binary(response.preferred_facility_other) and
             response.preferred_facility_other != "" ->
        response.preferred_facility_other

      other ->
        other || "—"
    end
  end

  defp display_surveyor_name(response) do
    case response.surveyor_name do
      nil -> "Anonymous"
      "" -> "Anonymous"
      value -> value
    end
  end

  defp format_percentage(value), do: "#{format_decimal(value)}%"
  defp format_decimal(value) when is_float(value), do: :erlang.float_to_binary(value, decimals: 1)
  defp format_decimal(value), do: to_string(value)

  defp format_date(nil), do: "—"
  defp format_date(%Date{} = date), do: Calendar.strftime(date, "%d %b %Y")

  defp metric_card_classes("emerald"), do: "border-emerald-200 bg-emerald-50"
  defp metric_card_classes("amber"), do: "border-amber-200 bg-amber-50"
  defp metric_card_classes("sky"), do: "border-sky-200 bg-sky-50"
  defp metric_card_classes("violet"), do: "border-violet-200 bg-violet-50"
  defp metric_card_classes("rose"), do: "border-rose-200 bg-rose-50"
  defp metric_card_classes("teal"), do: "border-teal-200 bg-teal-50"
  defp metric_card_classes("lime"), do: "border-lime-200 bg-lime-50"
  defp metric_card_classes("orange"), do: "border-orange-200 bg-orange-50"
  defp metric_card_classes(_), do: "border-slate-200 bg-slate-50"

  defp yes_no_badge(true),
    do:
      "inline-flex rounded-full bg-emerald-100 px-3 py-1 text-xs font-semibold uppercase tracking-[0.14em] text-emerald-700"

  defp yes_no_badge(false),
    do:
      "inline-flex rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold uppercase tracking-[0.14em] text-slate-600"
end
