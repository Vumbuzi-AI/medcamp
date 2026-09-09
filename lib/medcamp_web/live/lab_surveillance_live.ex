defmodule MedcampWeb.LabSurveillanceLive do
  @moduledoc false

  use MedcampWeb, :html

  alias Medcamp.LabSurveillance

  def mount(socket) do
    today = Date.utc_today()
    date_from = Date.beginning_of_month(today)

    filters = %{
      date_from: Date.to_iso8601(date_from),
      date_to: Date.to_iso8601(today),
      test_name: "",
      age_group: ""
    }

    socket
    |> Phoenix.Component.assign(:active_tab, :lab_surveillance)
    |> Phoenix.Component.assign(:page_title, "Lab Surveillance")
    |> load_report(filters)
  end

  def apply_filters(socket, params) do
    params = normalize_params(socket, params)

    filters = %{
      date_from: Map.get(params, "date_from"),
      date_to: Map.get(params, "date_to"),
      test_name: Map.get(params, "test_name"),
      age_group: Map.get(params, "age_group")
    }

    with {:ok, date_from} <- parse_date(filters.date_from),
         {:ok, date_to} <- parse_date(filters.date_to),
         :ok <- validate_range(date_from, date_to) do
      load_report(socket, filters)
    else
      {:error, :invalid_range} ->
        Phoenix.LiveView.put_flash(
          socket,
          :error,
          "The start date must be on or before the end date."
        )

      _ ->
        Phoenix.LiveView.put_flash(socket, :error, "Choose a valid start and end date.")
    end
  end

  def clear_filters(socket), do: mount(socket)

  def report(assigns) do
    ~H"""
    <div class="lab-surveillance-page space-y-5">
      <style>
        @media print {
          body * { visibility: hidden; }
          .lab-surveillance-report, .lab-surveillance-report * { visibility: visible; }
          .lab-surveillance-report { position: absolute; inset: 0; width: 100%; }
          .no-print { display: none !important; }
        }
      </style>

      <div class="no-print">
        <.dashboard_top_card
          title="Lab Surveillance"
          subtitle="Completed tests grouped by test name, result and patient age at the time of testing."
          search_name="test_name"
          search_value={@filters.test_name}
          search_placeholder="Search lab test"
          search_event="filter"
          filter_id="lab-surveillance-filters"
          filter_apply_event="filter"
          filter_clear_event="clear_filters"
          active_filter_count={active_filter_count(@filters)}
          camps={assigns[:camp_options] || []}
          camp_filter={assigns[:camp_filter]}
        >
          <:filter_group label="Testing window">
            <.date_range_fields
              from_name="date_from"
              to_name="date_to"
              from_value={@filters.date_from}
              to_value={@filters.date_to}
              from_label="Date from"
              to_label="Date to"
            />
          </:filter_group>

          <:filter_group label="Patient age">
            <div>
              <label
                for="surveillance-age-group"
                class="mb-1 block text-xs font-medium text-slate-600"
              >
                Age group
              </label>
              <select
                id="surveillance-age-group"
                name="age_group"
                class="h-10 w-full rounded-md border border-slate-300 px-3 text-sm focus:border-brand-accent focus:ring-brand-accent"
              >
                <option value="">All ages</option>
                <option value="under_five" selected={@filters.age_group == "under_five"}>
                  Under 5 years
                </option>
                <option value="five_plus" selected={@filters.age_group == "five_plus"}>
                  5 years and above
                </option>
                <option value="unknown" selected={@filters.age_group == "unknown"}>
                  Age not recorded
                </option>
              </select>
            </div>
          </:filter_group>
        </.dashboard_top_card>
      </div>

      <section class="lab-surveillance-report overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
        <div class="flex flex-wrap items-center justify-between gap-3 border-b border-slate-200 px-5 py-4">
          <div>
            <h2 class="text-lg font-bold text-slate-900">Laboratory Surveillance Summary</h2>
            <p class="mt-1 text-sm text-slate-500">
              {@filters.date_from} to {@filters.date_to} · Completed and verified tests only
            </p>
          </div>
          <button
            type="button"
            onclick="window.print()"
            class="no-print inline-flex h-9 items-center rounded-md border border-[#cdd0ff] bg-brand-50 px-3 text-sm font-semibold text-brand-primary hover:bg-brand-100"
          >
            Print summary
          </button>
        </div>

        <div class="grid grid-cols-2 gap-px bg-slate-200 sm:grid-cols-4">
          <.summary_card label="Tests done" value={@report.totals.total_tested} />
          <.summary_card label="Positive" value={@report.totals.total_positive} />
          <.summary_card label="Under 5 tested" value={@report.totals.under_five_tested} />
          <.summary_card label="5+ tested" value={@report.totals.five_plus_tested} />
        </div>

        <div class="overflow-x-auto">
          <table id="lab-surveillance-table" class="min-w-full border-collapse text-sm">
            <thead>
              <tr class="bg-slate-50 text-slate-700">
                <th
                  rowspan="2"
                  class="border-b border-r border-slate-200 px-4 py-3 text-left font-semibold"
                >
                  Lab test
                </th>
                <th
                  colspan="2"
                  class="border-b border-r border-slate-200 px-4 py-2 text-center font-semibold"
                >
                  Under 5 years
                </th>
                <th
                  colspan="2"
                  class="border-b border-r border-slate-200 px-4 py-2 text-center font-semibold"
                >
                  5 years and above
                </th>
                <th colspan="2" class="border-b border-slate-200 px-4 py-2 text-center font-semibold">
                  Total
                </th>
              </tr>
              <tr class="bg-slate-50 text-xs uppercase tracking-wide text-slate-500">
                <th class="border-b border-r border-slate-200 px-3 py-2 text-center">Tested</th>
                <th class="border-b border-r border-slate-200 px-3 py-2 text-center">Positive</th>
                <th class="border-b border-r border-slate-200 px-3 py-2 text-center">Tested</th>
                <th class="border-b border-r border-slate-200 px-3 py-2 text-center">Positive</th>
                <th class="border-b border-r border-slate-200 px-3 py-2 text-center">Tested</th>
                <th class="border-b border-slate-200 px-3 py-2 text-center">Positive</th>
              </tr>
            </thead>
            <tbody>
              <tr :if={@report.rows == []}>
                <td colspan="7" class="p-4">
                  <.blank_state
                    icon_path="M9.75 3.104v5.714a2.25 2.25 0 01-.659 1.591L5 14.5M9.75 3.104c-.251.023-.501.05-.75.082M9.75 3.104a24.301 24.301 0 014.5 0m0 0v5.714c0 .597.237 1.17.659 1.591L19.8 15.3M14.25 3.104c.251.023.501.05.75.082M19.8 15.3l-1.57.393A9.065 9.065 0 0112 15a9.065 9.065 0 00-6.23-.693L5 14.5m14.8.8l1.402 1.402c1.232 1.232.65 3.318-1.067 3.611A48.309 48.309 0 0112 21c-2.773 0-5.491-.235-8.135-.687-1.718-.293-2.3-2.379-1.067-3.61L5 14.5"
                    title="No completed lab tests"
                    description="No completed lab tests match these filters."
                  />
                </td>
              </tr>
              <tr :for={row <- @report.rows} class="even:bg-slate-50/60">
                <td class="border-b border-r border-slate-200 px-4 py-3 font-medium text-slate-900">
                  {row.test_name}
                </td>
                <.number_cell value={row.under_five_tested} />
                <.number_cell value={row.under_five_positive} positive />
                <.number_cell value={row.five_plus_tested} />
                <.number_cell value={row.five_plus_positive} positive />
                <.number_cell value={row.total_tested} />
                <.number_cell value={row.total_positive} positive last />
              </tr>
            </tbody>
            <tfoot :if={@report.rows != []}>
              <tr class="bg-brand-50 font-bold text-brand-primary">
                <td class="border-r border-t border-[#d9dcff] px-4 py-3">All tests</td>
                <.number_cell value={@report.totals.under_five_tested} footer />
                <.number_cell value={@report.totals.under_five_positive} footer />
                <.number_cell value={@report.totals.five_plus_tested} footer />
                <.number_cell value={@report.totals.five_plus_positive} footer />
                <.number_cell value={@report.totals.total_tested} footer />
                <.number_cell value={@report.totals.total_positive} footer last />
              </tr>
            </tfoot>
          </table>
        </div>

        <div
          :if={@report.totals.unknown_age_tested > 0}
          class="border-t border-amber-200 bg-amber-50 px-5 py-3 text-sm text-amber-800"
        >
          {@report.totals.unknown_age_tested} completed test(s) are included in the total but not in an age column because the patient's date of birth is missing.
        </div>
        <p class="border-t border-slate-200 px-5 py-3 text-xs text-slate-500">
          Positive counts include results explicitly recorded as positive, reactive, detected, present, a malaria species, or with a “+” result. Numeric and other descriptive findings remain in tested totals but are not assumed to be positive.
        </p>
      </section>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :value, :integer, required: true

  defp summary_card(assigns) do
    ~H"""
    <div class="bg-white px-5 py-4">
      <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">{@label}</p>
      <p class="mt-1 text-2xl font-bold text-slate-900">{@value}</p>
    </div>
    """
  end

  attr :value, :integer, required: true
  attr :positive, :boolean, default: false
  attr :last, :boolean, default: false
  attr :footer, :boolean, default: false

  defp number_cell(assigns) do
    ~H"""
    <td class={[
      "px-3 py-3 text-center tabular-nums",
      !@last && "border-r",
      @footer && "border-t border-[#d9dcff]",
      !@footer && "border-b border-slate-200",
      @positive && !@footer && @value > 0 && "font-semibold text-rose-700"
    ]}>
      {@value}
    </td>
    """
  end

  defp normalize_params(socket, %{"filters" => filters}) do
    normalize_params(socket, filters)
  end

  defp normalize_params(socket, params) do
    current_filters = socket.assigns.filters

    %{
      "date_from" => Map.get(params, "date_from", current_filters.date_from),
      "date_to" => Map.get(params, "date_to", current_filters.date_to),
      "test_name" => Map.get(params, "test_name", current_filters.test_name),
      "age_group" => Map.get(params, "age_group", current_filters.age_group)
    }
  end

  defp active_filter_count(filters) do
    today = Date.utc_today()
    default_from = Date.to_iso8601(Date.beginning_of_month(today))
    default_to = Date.to_iso8601(today)

    [
      filters.test_name != "",
      filters.age_group != "",
      filters.date_from != default_from,
      filters.date_to != default_to
    ]
    |> Enum.count(& &1)
  end

  defp load_report(socket, display_filters) do
    query_filters = %{
      date_from: parse_date!(display_filters.date_from),
      date_to: parse_date!(display_filters.date_to),
      test_name: display_filters.test_name,
      age_group: display_filters.age_group
    }

    report = LabSurveillance.report(query_filters)

    socket
    |> Phoenix.Component.assign(:filters, display_filters)
    |> Phoenix.Component.assign(:available_test_names, report.test_names)
    |> Phoenix.Component.assign(:report, report)
  end

  defp parse_date(value), do: Date.from_iso8601(value)
  defp parse_date!(value), do: Date.from_iso8601!(value)

  defp validate_range(date_from, date_to) do
    if Date.compare(date_from, date_to) in [:lt, :eq], do: :ok, else: {:error, :invalid_range}
  end
end
