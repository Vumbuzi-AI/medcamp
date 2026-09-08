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
    filters = %{
      date_from: Map.get(params, "date_from", ""),
      date_to: Map.get(params, "date_to", ""),
      test_name: Map.get(params, "test_name", ""),
      age_group: Map.get(params, "age_group", "")
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

      <div class="no-print rounded-xl border border-gray-100 bg-white p-5 shadow-sm">
        <.page_header
          icon_path="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"
          title="Lab Surveillance"
          subtitle="Completed tests grouped by test name, result and patient age at the time of testing."
        />

        <form
          id="lab-surveillance-filters"
          phx-submit="filter"
          class="mt-5 grid gap-4 lg:grid-cols-5 lg:items-end"
        >
          <div>
            <label for="surveillance-date-from" class="mb-1 block text-sm font-medium text-gray-700">
              Date from
            </label>
            <input
              id="surveillance-date-from"
              name="filters[date_from]"
              type="date"
              value={@filters.date_from}
              required
              class="h-10 w-full rounded-md border border-gray-300 px-3 text-sm focus:border-brand-accent focus:ring-brand-accent"
            />
          </div>
          <div>
            <label for="surveillance-date-to" class="mb-1 block text-sm font-medium text-gray-700">
              Date to
            </label>
            <input
              id="surveillance-date-to"
              name="filters[date_to]"
              type="date"
              value={@filters.date_to}
              required
              class="h-10 w-full rounded-md border border-gray-300 px-3 text-sm focus:border-brand-accent focus:ring-brand-accent"
            />
          </div>
          <div>
            <label for="surveillance-test-name" class="mb-1 block text-sm font-medium text-gray-700">
              Lab test
            </label>
            <select
              id="surveillance-test-name"
              name="filters[test_name]"
              class="h-10 w-full rounded-md border border-gray-300 px-3 text-sm focus:border-brand-accent focus:ring-brand-accent"
            >
              <option value="">All tests</option>
              <option
                :for={name <- @available_test_names}
                value={name}
                selected={@filters.test_name == name}
              >
                {name}
              </option>
            </select>
          </div>
          <div>
            <label for="surveillance-age-group" class="mb-1 block text-sm font-medium text-gray-700">
              Age group
            </label>
            <select
              id="surveillance-age-group"
              name="filters[age_group]"
              class="h-10 w-full rounded-md border border-gray-300 px-3 text-sm focus:border-brand-accent focus:ring-brand-accent"
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
          <div class="flex gap-2">
            <button
              type="submit"
              class="h-10 flex-1 rounded-md bg-brand-accent px-4 text-sm font-semibold text-white hover:bg-brand-accent-dark"
            >
              Apply filters
            </button>
            <button
              type="button"
              phx-click="clear_filters"
              class="h-10 rounded-md border border-gray-300 px-3 text-sm font-semibold text-gray-700 hover:bg-gray-50"
            >
              Clear
            </button>
          </div>
        </form>
      </div>

      <section class="lab-surveillance-report overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm">
        <div class="flex flex-wrap items-center justify-between gap-3 border-b border-gray-200 px-5 py-4">
          <div>
            <h2 class="text-lg font-bold text-gray-900">Laboratory Surveillance Summary</h2>
            <p class="mt-1 text-sm text-gray-500">
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

        <div class="grid grid-cols-2 gap-px bg-gray-200 sm:grid-cols-4">
          <.summary_card label="Tests done" value={@report.totals.total_tested} />
          <.summary_card label="Positive" value={@report.totals.total_positive} />
          <.summary_card label="Under 5 tested" value={@report.totals.under_five_tested} />
          <.summary_card label="5+ tested" value={@report.totals.five_plus_tested} />
        </div>

        <div class="overflow-x-auto">
          <table id="lab-surveillance-table" class="min-w-full border-collapse text-sm">
            <thead>
              <tr class="bg-gray-50 text-gray-700">
                <th
                  rowspan="2"
                  class="border-b border-r border-gray-200 px-4 py-3 text-left font-semibold"
                >
                  Lab test
                </th>
                <th
                  colspan="2"
                  class="border-b border-r border-gray-200 px-4 py-2 text-center font-semibold"
                >
                  Under 5 years
                </th>
                <th
                  colspan="2"
                  class="border-b border-r border-gray-200 px-4 py-2 text-center font-semibold"
                >
                  5 years and above
                </th>
                <th colspan="2" class="border-b border-gray-200 px-4 py-2 text-center font-semibold">
                  Total
                </th>
              </tr>
              <tr class="bg-gray-50 text-xs uppercase tracking-wide text-gray-500">
                <th class="border-b border-r border-gray-200 px-3 py-2 text-center">Tested</th>
                <th class="border-b border-r border-gray-200 px-3 py-2 text-center">Positive</th>
                <th class="border-b border-r border-gray-200 px-3 py-2 text-center">Tested</th>
                <th class="border-b border-r border-gray-200 px-3 py-2 text-center">Positive</th>
                <th class="border-b border-r border-gray-200 px-3 py-2 text-center">Tested</th>
                <th class="border-b border-gray-200 px-3 py-2 text-center">Positive</th>
              </tr>
            </thead>
            <tbody>
              <tr :if={@report.rows == []}>
                <td colspan="7" class="px-6 py-14 text-center text-gray-500">
                  No completed lab tests match these filters.
                </td>
              </tr>
              <tr :for={row <- @report.rows} class="even:bg-gray-50/60">
                <td class="border-b border-r border-gray-200 px-4 py-3 font-medium text-gray-900">
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
        <p class="border-t border-gray-200 px-5 py-3 text-xs text-gray-500">
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
      <p class="text-xs font-semibold uppercase tracking-wide text-gray-500">{@label}</p>
      <p class="mt-1 text-2xl font-bold text-gray-900">{@value}</p>
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
      !@footer && "border-b border-gray-200",
      @positive && !@footer && @value > 0 && "font-semibold text-rose-700"
    ]}>
      {@value}
    </td>
    """
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
