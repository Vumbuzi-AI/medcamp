defmodule MedcampWeb.AdminMinistryReportingLive.Index do
  use MedcampWeb, :admin_live_view

  alias Medcamp.MinistryReporting
  alias Medcamp.MinistryReporting.AIMappingAdvisor

  @impl true
  def mount(_params, _session, socket) do
    today = Date.utc_today()
    date_from = Date.new!(today.year, today.month, 1)

    {:ok,
     socket
     |> assign(:active_tab, :ministry_reporting)
     |> assign(:page_title, "Ministry Reporting")
     |> assign(:forms, MinistryReporting.forms())
     |> assign(:selected_form, nil)
     |> assign(:values, %{})
     |> assign(:date_from, Date.to_iso8601(date_from))
     |> assign(:date_to, Date.to_iso8601(today))
     |> assign(:auto_fill_summary, nil)
     |> assign(:ai_mapping_suggestions, nil)
     |> assign(:definition_open?, false)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    form_id = params["form"] || MinistryReporting.default_form_id()

    form =
      MinistryReporting.get_form(form_id) ||
        MinistryReporting.get_form(MinistryReporting.default_form_id())

    {:noreply,
     socket
     |> assign(:selected_form, form)
     |> assign(:values, empty_values(form))
     |> assign(:auto_fill_summary, nil)
     |> assign(:ai_mapping_suggestions, nil)}
  end

  @impl true
  def handle_event("select_form", %{"form_id" => form_id}, socket) do
    {:noreply, push_patch(socket, to: "/admin/reporting?form=#{form_id}")}
  end

  @impl true
  def handle_event("update_form", values, socket) do
    {:noreply, assign(socket, :values, Map.drop(values, ["_target"]))}
  end

  @impl true
  def handle_event("clear_form", _params, socket) do
    {:noreply,
     socket
     |> assign(:values, empty_values(socket.assigns.selected_form))
     |> assign(:auto_fill_summary, nil)
     |> assign(:ai_mapping_suggestions, nil)}
  end

  @impl true
  def handle_event(
        "auto_fill",
        %{"date_from" => date_from, "date_to" => date_to},
        socket
      ) do
    form = socket.assigns.selected_form

    case MinistryReporting.auto_fill(form["id"], date_from, date_to) do
      {:ok, report} ->
        values = Map.merge(empty_values(form), report.values)
        summary = report.summary

        message =
          "Filled #{summary.matched_entries} of #{summary.source_entries} #{summary.source_label}."

        {:noreply,
         socket
         |> assign(:date_from, date_from)
         |> assign(:date_to, date_to)
         |> assign(:values, values)
         |> assign(:auto_fill_summary, summary)
         |> assign(:ai_mapping_suggestions, nil)
         |> put_flash(:info, message)}

      {:error, :invalid_range} ->
        {:noreply, put_flash(socket, :error, "The start date must be on or before the end date.")}

      {:error, :invalid_date} ->
        {:noreply, put_flash(socket, :error, "Choose a valid start and end date.")}

      {:error, :unsupported_form} ->
        {:noreply,
         put_flash(socket, :error, "Automatic filling is not mapped for this report yet.")}
    end
  end

  @impl true
  def handle_event("suggest_mappings", _params, socket) do
    source_items =
      socket.assigns.auto_fill_summary
      |> case do
        nil -> []
        summary -> Map.get(summary, :unmatched_tests, [])
      end

    case AIMappingAdvisor.suggest(socket.assigns.selected_form["id"], source_items) do
      {:ok, result} ->
        {:noreply,
         socket
         |> assign(:ai_mapping_suggestions, result["suggestions"])
         |> put_flash(:info, "AI mapping suggestions are ready for human review.")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, ai_mapping_error(reason))}
    end
  end

  @impl true
  def handle_event("toggle_definition", _params, socket) do
    {:noreply, update(socket, :definition_open?, &(!&1))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="ministry-reporting-page bg-white">
      <style>
        <%= Phoenix.HTML.raw(print_css(@selected_form)) %>

        .report-html-page {
          width: min(100%, var(--report-page-width));
          min-height: var(--report-page-height);
          margin-inline: auto;
          padding: clamp(14px, 2.2vw, 28px);
          color: #111;
          background: #fff;
          border: 1px solid #4b5563;
          box-shadow: 0 1px 3px rgb(15 23 42 / 0.12), 0 10px 30px rgb(15 23 42 / 0.1);
          font-family: Arial, Helvetica, sans-serif;
        }

        .report-html-page--portrait {
          --report-page-width: 860px;
          --report-page-height: 1110px;
        }

        .report-html-page--landscape {
          --report-page-width: 1240px;
          --report-page-height: 850px;
        }

        .report-view-toolbar {
          grid-column: 1 / -1;
          display: flex;
          align-items: center;
          justify-content: space-between;
          gap: 12px;
          min-width: 0;
          border: 1px solid #d1d5db;
          background: #fff;
          padding: 8px;
        }

        .report-view-controls {
          display: inline-flex;
          flex: 0 0 auto;
          align-items: center;
          border: 1px solid #d1d5db;
          border-radius: 6px;
          overflow: hidden;
          background: #fff;
        }

        .report-view-control {
          display: inline-flex;
          width: 38px;
          height: 36px;
          align-items: center;
          justify-content: center;
          border: 0;
          border-right: 1px solid #d1d5db;
          color: #374151;
          background: #fff;
        }

        .report-view-control:last-child {
          border-right: 0;
        }

        .report-view-control:hover,
        .report-view-control[aria-pressed="true"] {
          color: #45468f;
          background: #eef2ff;
        }

        .report-view-zoom {
          width: 58px;
          color: #4b5563;
          font-size: 12px;
          font-variant-numeric: tabular-nums;
          font-weight: 700;
          text-align: center;
        }

        .report-document-stage {
          min-width: 0;
          height: max(580px, calc(100vh - 250px));
          overflow: auto;
          border: 1px solid #d1d5db;
          padding: 18px;
          background: #e5e7eb;
          overscroll-behavior: contain;
        }

        .report-html-pages {
          zoom: var(--report-zoom, 1);
        }

        .ministry-reporting-workspace.report-source-hidden {
          grid-template-columns: minmax(0, 1fr) !important;
        }

        .ministry-reporting-workspace.report-source-hidden .report-source-panel {
          display: none;
        }

        .ministry-reporting-workspace:fullscreen {
          width: 100vw;
          height: 100vh;
          grid-template-rows: auto minmax(0, 1fr);
          margin: 0;
          padding: 12px;
          overflow: hidden;
          background: #f3f4f6;
        }

        .ministry-reporting-workspace:fullscreen .report-source-panel,
        .ministry-reporting-workspace:fullscreen .report-document-stage {
          height: 100%;
          min-height: 0;
          overflow: auto;
        }

        @media (max-width: 1279px) {
          .report-view-toolbar {
            position: sticky;
            top: 0;
            z-index: 20;
          }

          .report-source-panel {
            max-height: 360px;
            overflow: auto;
          }

          .report-document-stage {
            height: 72vh;
            min-height: 480px;
          }
        }

        .report-document-header {
          display: grid;
          grid-template-columns: minmax(90px, 0.8fr) minmax(0, 4fr) minmax(90px, 0.8fr);
          align-items: end;
          gap: 10px;
          border-bottom: 2px solid #111;
          padding-bottom: 8px;
          text-align: center;
        }

        .report-document-header__side {
          font-size: 10px;
          font-weight: 700;
          text-transform: uppercase;
        }

        .report-document-header h1 {
          margin: 3px 0 0;
          font-size: 16px;
          font-weight: 800;
          line-height: 1.12;
          text-transform: uppercase;
        }

        .report-document-header p {
          margin: 0;
          font-size: 9px;
          font-weight: 700;
          text-transform: uppercase;
        }

        .report-meta-grid {
          display: grid;
          grid-template-columns: repeat(3, minmax(0, 1fr));
          margin-top: 10px;
          border-top: 1px solid #555;
          border-left: 1px solid #555;
        }

        .report-instructions {
          margin-top: 8px;
          border: 1px solid #555;
          padding: 5px 7px;
          font-size: 8px;
          line-height: 1.25;
          text-align: center;
        }

        .report-html-page--landscape .report-meta-grid {
          grid-template-columns: repeat(6, minmax(0, 1fr));
        }

        .report-meta-field {
          display: grid;
          grid-template-rows: auto 28px;
          border-right: 1px solid #555;
          border-bottom: 1px solid #555;
        }

        .report-meta-field span {
          padding: 3px 5px 0;
          font-size: 8px;
          font-weight: 700;
          text-transform: uppercase;
        }

        .report-meta-field input {
          width: 100%;
          min-width: 0;
          border: 0;
          padding: 2px 5px;
          background: transparent;
          font-size: 11px;
          outline: 0;
        }

        .report-section {
          margin-top: 12px;
          break-inside: avoid;
        }

        .report-block-grid {
          display: grid;
          grid-template-columns: repeat(12, minmax(0, 1fr));
          gap: 8px;
          margin-top: 12px;
          align-items: start;
        }

        .report-block-grid .report-section {
          min-width: 0;
          margin-top: 0;
        }

        .report-flow-grid {
          display: grid;
          grid-template-columns: repeat(2, minmax(0, 1fr));
          gap: 12px;
          margin-top: 12px;
          align-items: start;
        }

        .report-flow-column {
          min-width: 0;
        }

        .report-flow-column .report-section {
          margin-top: 0;
          margin-bottom: 8px;
        }

        .report-section__title {
          margin: 0;
          border: 1px solid #444;
          border-bottom: 0;
          padding: 4px 6px;
          background: #d8d8d8;
          font-size: 10px;
          font-weight: 800;
          line-height: 1.1;
          text-transform: uppercase;
        }

        .report-section-fields {
          display: grid;
          grid-template-columns: repeat(2, minmax(0, 1fr));
          border-top: 1px solid #555;
          border-left: 1px solid #555;
        }

        .report-html-page--landscape .report-section-fields {
          grid-template-columns: repeat(4, minmax(0, 1fr));
        }

        .report-field {
          min-width: 0;
          border-right: 1px solid #555;
          border-bottom: 1px solid #555;
        }

        .report-field--input {
          display: grid;
          grid-template-columns: auto minmax(60px, 1fr);
          align-items: center;
          min-height: 30px;
          gap: 5px;
          padding-left: 6px;
        }

        .report-field--input span {
          font-size: 8px;
          font-weight: 700;
          text-transform: uppercase;
        }

        .report-field--input input {
          width: 100%;
          min-width: 0;
          height: 29px;
          border: 0;
          border-left: 1px solid #aaa;
          padding: 2px 5px;
          background: transparent;
          font-size: 11px;
          outline: 0;
        }

        .report-field--checkbox {
          display: flex;
          min-height: 30px;
          align-items: center;
          gap: 7px;
          padding: 4px 7px;
          font-size: 9px;
          font-weight: 700;
        }

        .report-field--checkbox input {
          width: 15px;
          height: 15px;
          border-radius: 0;
          accent-color: #111;
        }

        .report-table-wrap {
          width: 100%;
          overflow-x: auto;
        }

        .report-table {
          width: 100%;
          border-collapse: collapse;
          table-layout: fixed;
          font-size: 8px;
        }

        .report-table th,
        .report-table td {
          border: 1px solid #555;
        }

        .report-table thead th {
          height: 30px;
          padding: 3px;
          background: #e2e2e2;
          font-weight: 800;
          line-height: 1.05;
          text-align: center;
          text-transform: uppercase;
        }

        .report-table thead th:first-child {
          width: 25%;
          text-align: left;
        }

        .report-table[data-label-columns="2"] thead tr:last-child th:first-child {
          width: 7%;
        }

        .report-table[data-label-columns="2"] thead tr:last-child th:nth-child(2) {
          width: 23%;
          text-align: left;
        }

        .report-html-page--landscape .report-table thead th:first-child {
          width: 18%;
        }

        .report-table--vertical thead tr:last-child th:nth-child(n + 3) {
          height: 92px;
          padding: 4px 2px;
          writing-mode: vertical-rl;
          transform: rotate(180deg);
          white-space: nowrap;
        }

        .report-table tbody th {
          height: 25px;
          padding: 3px 5px;
          font-weight: 600;
          line-height: 1.05;
          text-align: left;
        }

        .report-table td {
          height: 25px;
          padding: 0;
          position: relative;
        }

        .report-cell-code {
          display: block;
          padding: 1px 2px 0;
          color: #444;
          font-size: 5px;
          line-height: 1;
          white-space: nowrap;
        }

        .report-table td input {
          width: 100%;
          height: 24px;
          min-width: 0;
          border: 0;
          padding: 1px 3px;
          background: transparent;
          font-size: 9px;
          text-align: center;
          outline: 0;
        }

        .report-table tr.report-table-row--emphasis th,
        .report-table tr.report-table-row--emphasis td {
          font-weight: 800;
          background: #ededed;
        }

        .report-section--compact .report-table tbody th,
        .report-section--compact .report-table td {
          height: 20px;
        }

        .report-section--compact .report-table td input {
          height: 19px;
        }

        .report-section--micro .report-table {
          font-size: 5px;
        }

        .report-section--micro .report-table thead th {
          height: 17px;
          padding: 1px;
        }

        .report-section--micro .report-table tbody th,
        .report-section--micro .report-table td {
          height: 8px;
          padding-block: 0;
        }

        .report-section--micro .report-table td input {
          height: 7px;
          padding: 0 1px;
          font-size: 5px;
        }

        .report-meta-field input:focus,
        .report-field input:focus,
        .report-table td input:focus {
          background: #eef2ff;
          box-shadow: inset 0 0 0 2px #6667ab;
        }

        @media print {
          aside,
          .ministry-reporting-print-hidden,
          .flash-group {
            display: none !important;
          }

          html,
          body,
          main,
          .layout-content,
          .ministry-reporting-page,
          .ministry-reporting-workspace {
            margin: 0 !important;
            padding: 0 !important;
            border: 0 !important;
            background: white !important;
            box-shadow: none !important;
            overflow: visible !important;
          }

          .report-html-page {
            width: 100% !important;
            min-height: 0 !important;
            margin: 0 !important;
            border: 0 !important;
            box-shadow: none !important;
            break-after: page;
            page-break-after: always;
          }

          .report-html-pages {
            zoom: 1 !important;
          }

          .report-html-pages > article:last-child {
            break-after: auto;
            page-break-after: auto;
          }

          input {
            color: #000 !important;
            box-shadow: none !important;
          }
        }
      </style>

      <div class="ministry-reporting-print-hidden border border-gray-100 bg-white p-4 shadow-sm">
        <.page_header
          icon_path="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414A1 1 0 0119 9.414V19a2 2 0 01-2 2z"
          title="Ministry Reporting"
          subtitle="Complete structured Ministry of Health forms and export them as PDF."
        />

        <div class="mt-4 flex flex-wrap items-end gap-3">
          <form phx-change="select_form" class="min-w-64 flex-1">
            <label class="mb-1 block text-xs font-semibold uppercase text-gray-500">
              Report template
            </label>
            <select
              name="form_id"
              class="h-10 w-full rounded-md border border-gray-300 px-3 text-sm focus:border-[#6667ab] focus:ring-[#6667ab]"
            >
              <%= for form <- @forms do %>
                <option value={form["id"]} selected={form["id"] == @selected_form["id"]}>
                  {form["code"]} - {form["title"]}
                </option>
              <% end %>
            </select>
          </form>

          <form phx-submit="auto_fill" class="flex flex-wrap items-end gap-2">
            <div>
              <label
                for="report-date-from"
                class="mb-1 block text-xs font-semibold uppercase text-gray-500"
              >
                From
              </label>
              <input
                id="report-date-from"
                type="date"
                name="date_from"
                value={@date_from}
                required
                class="h-10 rounded-md border border-gray-300 px-3 text-sm focus:border-[#6667ab] focus:ring-[#6667ab]"
              />
            </div>
            <div>
              <label
                for="report-date-to"
                class="mb-1 block text-xs font-semibold uppercase text-gray-500"
              >
                To
              </label>
              <input
                id="report-date-to"
                type="date"
                name="date_to"
                value={@date_to}
                required
                class="h-10 rounded-md border border-gray-300 px-3 text-sm focus:border-[#6667ab] focus:ring-[#6667ab]"
              />
            </div>
            <button
              type="submit"
              disabled={!MinistryReporting.auto_fill_supported?(@selected_form["id"])}
              title={
                if MinistryReporting.auto_fill_supported?(@selected_form["id"]),
                  do: "Fill this report from recorded clinical data",
                  else: "Automatic filling has not been mapped for this report yet"
              }
              class="inline-flex h-10 items-center justify-center gap-2 rounded-md bg-emerald-700 px-4 text-sm font-semibold text-white hover:bg-emerald-800 disabled:cursor-not-allowed disabled:bg-gray-300"
            >
              <.icon name="hero-sparkles" class="h-4 w-4" /> Auto-fill
            </button>
          </form>

          <button
            type="button"
            phx-click="toggle_definition"
            title="View JSON definition"
            class="inline-flex h-10 w-10 items-center justify-center rounded-md border border-gray-300 text-gray-700 hover:bg-gray-50"
          >
            <.icon name="hero-code-bracket-square" class="h-4 w-4" />
          </button>

          <button
            type="button"
            phx-click="clear_form"
            title="Clear form"
            class="inline-flex h-10 w-10 items-center justify-center rounded-md border border-gray-300 text-gray-700 hover:bg-gray-50"
          >
            <.icon name="hero-arrow-path" class="h-4 w-4" />
          </button>

          <button
            type="button"
            onclick="window.print()"
            class="inline-flex h-10 items-center justify-center gap-2 rounded-md bg-[#6667ab] px-4 text-sm font-semibold text-white hover:bg-[#5556a0]"
          >
            <.icon name="hero-arrow-down-tray" class="h-4 w-4" /> Download PDF
          </button>
        </div>

        <div class="mt-4 flex flex-wrap items-center gap-x-4 gap-y-2 border-t border-gray-100 pt-3 text-sm">
          <p class="font-semibold text-gray-900">
            {@selected_form["code"]} - {@selected_form["title"]}
          </p>
          <span class="inline-flex items-center gap-1.5 text-xs font-medium uppercase text-gray-500">
            <.icon name={orientation_icon(@selected_form)} class="h-4 w-4" />
            {orientation(@selected_form)}
          </span>
          <span class="text-xs text-gray-500">
            {length(pages(@selected_form))} {page_label(@selected_form)}
          </span>
          <span
            :if={!MinistryReporting.auto_fill_supported?(@selected_form["id"])}
            class="text-xs font-medium text-amber-700"
          >
            Manual entry only — mapping pending
          </span>
        </div>

        <div
          :if={@auto_fill_summary}
          class="mt-3 rounded-md border border-emerald-200 bg-emerald-50 px-3 py-2 text-sm text-emerald-950"
        >
          <p>
            Counted <strong>{@auto_fill_summary.matched_entries}</strong>
            of <strong>{@auto_fill_summary.source_entries}</strong>
            {@auto_fill_summary.source_label}.
          </p>
          <p :if={@auto_fill_summary.unmatched_tests != []} class="mt-1 text-xs text-amber-800">
            Not counted because no approved MOH mapping exists: {Enum.join(
              @auto_fill_summary.unmatched_tests,
              ", "
            )}.
          </p>
          <button
            :if={@auto_fill_summary.unmatched_tests != []}
            type="button"
            phx-click="suggest_mappings"
            class="mt-2 inline-flex h-8 items-center gap-1.5 rounded-md border border-amber-300 bg-white px-3 text-xs font-semibold text-amber-900 hover:bg-amber-100"
          >
            <.icon name="hero-sparkles" class="h-3.5 w-3.5" /> Suggest mappings with AI
          </button>
          <p
            :for={limitation <- Map.get(@auto_fill_summary, :limitations, [])}
            class="mt-1 text-xs text-amber-800"
          >
            {limitation}
          </p>
        </div>

        <div
          :if={is_list(@ai_mapping_suggestions)}
          class="mt-3 rounded-md border border-indigo-200 bg-indigo-50 px-3 py-3 text-sm text-indigo-950"
        >
          <p class="font-semibold">AI suggestions — review only</p>
          <p class="mt-1 text-xs text-indigo-800">
            These suggestions have not changed any report value or approved mapping.
          </p>
          <p :if={@ai_mapping_suggestions == []} class="mt-2 text-xs text-gray-600">
            No defensible mapping was suggested.
          </p>
          <div
            :for={suggestion <- @ai_mapping_suggestions}
            class="mt-2 border-t border-indigo-200 pt-2"
          >
            <p class="font-medium">
              {suggestion["source_item"]} → {suggestion["candidate"]["section"]}: {suggestion[
                "candidate"
              ]["row_label"]}
            </p>
            <p class="mt-0.5 text-xs text-indigo-800">
              Confidence: {round(suggestion["confidence"] * 100)}% · {suggestion["reason"]}
            </p>
          </div>
        </div>
      </div>

      <div
        :if={@definition_open?}
        class="ministry-reporting-definition ministry-reporting-print-hidden mt-4 border border-gray-200 bg-slate-950 p-4 shadow-sm"
      >
        <pre class="max-h-96 overflow-auto text-xs text-slate-100"><%= Jason.encode!(@selected_form, pretty: true) %></pre>
      </div>

      <div
        id="ministry-reporting-workspace"
        phx-hook="ReportWorkspace"
        class="ministry-reporting-workspace mt-4 grid gap-4 xl:grid-cols-[300px_minmax(0,1fr)]"
      >
        <div class="report-view-toolbar ministry-reporting-print-hidden">
          <div class="min-w-0">
            <p class="truncate text-sm font-semibold text-gray-900">
              {@selected_form["code"]} - {@selected_form["title"]}
            </p>
            <p class="text-xs text-gray-500">{orientation(@selected_form)} document</p>
          </div>

          <div class="flex items-center gap-2">
            <div class="report-view-controls">
              <button
                type="button"
                data-report-action="toggle-source"
                class="report-view-control"
                title="Show or hide source reference"
                aria-label="Show or hide source reference"
                aria-pressed="true"
              >
                <.icon name="hero-photo" class="h-4 w-4" />
              </button>
              <button
                type="button"
                data-report-action="fit-width"
                class="report-view-control"
                title="Fit document width"
                aria-label="Fit document width"
              >
                <.icon name="hero-arrows-right-left" class="h-4 w-4" />
              </button>
              <button
                type="button"
                data-report-action="fit-page"
                class="report-view-control"
                title="Fit whole page"
                aria-label="Fit whole page"
              >
                <.icon name="hero-viewfinder-circle" class="h-4 w-4" />
              </button>
            </div>

            <div class="report-view-controls">
              <button
                type="button"
                data-report-action="zoom-out"
                class="report-view-control"
                title="Zoom out"
                aria-label="Zoom out"
              >
                <.icon name="hero-minus" class="h-4 w-4" />
              </button>
              <output data-report-zoom class="report-view-zoom">100%</output>
              <button
                type="button"
                data-report-action="zoom-in"
                class="report-view-control"
                title="Zoom in"
                aria-label="Zoom in"
              >
                <.icon name="hero-plus" class="h-4 w-4" />
              </button>
            </div>

            <button
              type="button"
              data-report-action="fullscreen"
              class="report-view-control rounded-md border border-gray-300"
              title="Open fullscreen"
              aria-label="Open fullscreen"
              aria-pressed="false"
            >
              <.icon name="hero-arrows-pointing-out" class="h-4 w-4" />
            </button>
          </div>
        </div>

        <aside class="report-source-panel ministry-reporting-print-hidden border border-gray-200 bg-gray-50 p-3">
          <div class="mb-3 flex items-center justify-between">
            <h2 class="text-sm font-semibold text-gray-900">Source reference</h2>
            <span class="text-xs font-medium text-gray-500">
              {length(pages(@selected_form))} {page_label(@selected_form)}
            </span>
          </div>

          <div class="space-y-3">
            <%= for page <- pages(@selected_form) do %>
              <a
                href={page["image"]}
                target="_blank"
                rel="noreferrer"
                title="Open full-size reference"
                class="block overflow-hidden border border-gray-300 bg-white"
              >
                <div class="flex items-center justify-between gap-2 border-b border-gray-200 px-2 py-1.5 text-xs font-semibold text-gray-700">
                  <span>{page["label"]}</span>
                  <.icon name="hero-arrows-pointing-out" class="h-3.5 w-3.5" />
                </div>
                <img
                  src={page["image"]}
                  alt={"Reference for #{page["label"]}"}
                  class="max-h-96 w-full object-contain"
                />
              </a>
            <% end %>
          </div>
        </aside>

        <main class="report-document-stage" data-report-stage>
          <form phx-change="update_form" class="min-w-0">
            <div class="report-html-pages space-y-5" data-report-pages>
              <%= for {page, page_index} <- Enum.with_index(pages(@selected_form), 1) do %>
                <article class={[
                  "report-html-page",
                  "report-html-page--#{orientation(@selected_form)}"
                ]}>
                  <.document_header form={@selected_form} page={page} page_index={page_index} />

                  <div :if={page_index == 1} class="report-meta-grid">
                    <%= for field <- Map.get(@selected_form, "meta_fields", []) do %>
                      <.meta_field field={field} values={@values} />
                    <% end %>
                  </div>

                  <p
                    :if={page_index == 1 && Map.get(@selected_form, "instructions")}
                    class="report-instructions"
                  >
                    {@selected_form["instructions"]}
                  </p>

                  <%= if flow_layout?(@selected_form, page_index) do %>
                    <div class="report-flow-grid">
                      <%= for column <- 1..2 do %>
                        <div class="report-flow-column">
                          <%= for section <- flow_sections(@selected_form, page_index, column) do %>
                            <.report_section section={section} values={@values} flow />
                          <% end %>
                        </div>
                      <% end %>
                    </div>
                  <% else %>
                    <div class="report-block-grid">
                      <%= for section <- sections_for_page(@selected_form, page_index) do %>
                        <.report_section section={section} values={@values} />
                      <% end %>
                    </div>
                  <% end %>

                  <p
                    :if={
                      page_index == length(pages(@selected_form)) &&
                        Map.get(@selected_form, "footer")
                    }
                    class="report-instructions"
                  >
                    {@selected_form["footer"]}
                  </p>
                </article>
              <% end %>
            </div>
          </form>
        </main>
      </div>
    </div>
    """
  end

  attr :form, :map, required: true
  attr :page, :map, required: true
  attr :page_index, :integer, required: true

  defp document_header(assigns) do
    ~H"""
    <header :if={Map.get(@page, "show_header", true)} class="report-document-header">
      <div class="report-document-header__side">Republic of Kenya</div>
      <div>
        <p>Ministry of Health</p>
        <h1>{@form["title"]}</h1>
      </div>
      <div class="report-document-header__side">
        <div>{@form["code"]}</div>
        <div :if={Map.get(@form, "version")}>{@form["version"]}</div>
        <div :if={length(pages(@form)) > 1}>{@page["label"]}</div>
      </div>
    </header>
    """
  end

  attr :field, :map, required: true
  attr :values, :map, required: true

  defp meta_field(assigns) do
    assigns = assign(assigns, :value, Map.get(assigns.values, assigns.field["id"], ""))

    ~H"""
    <label class="report-meta-field">
      <span>{@field["label"]}</span>
      <input type={input_type(@field["type"])} name={@field["id"]} value={@value} />
    </label>
    """
  end

  attr :field, :map, required: true
  attr :values, :map, required: true

  defp report_field(assigns) do
    assigns =
      assigns
      |> assign(:field_type, assigns.field["type"] || "text")
      |> assign(:value, Map.get(assigns.values, assigns.field["id"], ""))

    ~H"""
    <label :if={@field_type == "checkbox"} class="report-field report-field--checkbox">
      <input type="checkbox" name={@field["id"]} value="true" checked={checked?(@value)} />
      <span>{@field["label"]}</span>
    </label>

    <label :if={@field_type != "checkbox"} class="report-field report-field--input">
      <span>{@field["label"]}</span>
      <input type={input_type(@field_type)} name={@field["id"]} value={@value} />
    </label>
    """
  end

  attr :section, :map, required: true
  attr :values, :map, required: true
  attr :flow, :boolean, default: false

  defp report_section(assigns) do
    ~H"""
    <section
      class={[
        "report-section",
        Map.get(@section, "compact", false) && "report-section--compact",
        Map.get(@section, "micro", false) && "report-section--micro"
      ]}
      style={!@flow && section_style(@section)}
    >
      <h2 class="report-section__title">{@section["title"]}</h2>

      <div :if={Map.get(@section, "fields", []) != []} class="report-section-fields">
        <%= for field <- Map.get(@section, "fields", []) do %>
          <.report_field field={field} values={@values} />
        <% end %>
      </div>

      <.report_table :if={Map.has_key?(@section, "columns")} section={@section} values={@values} />
    </section>
    """
  end

  attr :section, :map, required: true
  attr :values, :map, required: true

  defp report_table(assigns) do
    assigns =
      assigns
      |> assign(:section_id, MinistryReporting.slug(assigns.section["title"]))
      |> assign(:columns, Map.get(assigns.section, "columns", []))
      |> assign(:rows, section_rows(assigns.section))
      |> assign(:label_columns, Map.get(assigns.section, "label_columns", 1))
      |> assign(:column_groups, Map.get(assigns.section, "column_groups", []))

    ~H"""
    <div class="report-table-wrap">
      <table
        class={[
          "report-table",
          Map.get(@section, "vertical_headers", false) && "report-table--vertical"
        ]}
        data-label-columns={@label_columns}
      >
        <thead>
          <tr :if={@column_groups != []}>
            <%= for group <- @column_groups do %>
              <th colspan={group["colspan"]}>{group["label"]}</th>
            <% end %>
          </tr>
          <tr>
            <%= for column <- @columns do %>
              <th>{column_label(column)}</th>
            <% end %>
          </tr>
        </thead>
        <tbody>
          <%= for {row, row_index} <- Enum.with_index(@rows) do %>
            <tr class={row_emphasis?(row) && "report-table-row--emphasis"}>
              <th :if={@label_columns == 2}>{row_code(row)}</th>
              <th>{row_label(row)}</th>
              <%= for {column, cell_index} <- Enum.with_index(Enum.drop(@columns, @label_columns)) do %>
                <% cell_id =
                  table_cell_id(
                    @section_id,
                    row_index,
                    row_key(row),
                    cell_index,
                    column_key(column)
                  ) %>
                <td>
                  <span :if={row_cell_code(row, cell_index)} class="report-cell-code">
                    {row_cell_code(row, cell_index)}
                  </span>
                  <input
                    :if={row_input?(row)}
                    type="text"
                    name={cell_id}
                    value={Map.get(@values, cell_id, "")}
                    aria-label={"#{row_label(row)}, #{column_label(column)}"}
                  />
                </td>
              <% end %>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end

  defp pages(form), do: MinistryReporting.pages(form)

  defp orientation(form), do: MinistryReporting.orientation(form)

  defp sections_for_page(form, page_index) do
    form
    |> Map.get("sections", [])
    |> Enum.filter(&(Map.get(&1, "page", 1) == page_index))
  end

  defp flow_layout?(form, page_index) do
    form
    |> sections_for_page(page_index)
    |> Enum.any?(&Map.has_key?(&1, "flow_column"))
  end

  defp flow_sections(form, page_index, column) do
    form
    |> sections_for_page(page_index)
    |> Enum.filter(&(Map.get(&1, "flow_column") == column))
  end

  defp section_rows(section) do
    case Map.get(section, "rows") do
      rows when is_list(rows) ->
        rows

      _ ->
        for group <- Map.get(section, "row_groups", []),
            template <- Map.get(section, "row_templates", []) do
          %{
            "id" => "#{Map.get(group, "id", group["label"])}_#{template["id"]}",
            "code" => group["label"],
            "label" => template["label"],
            "emphasis" => Map.get(template, "emphasis", false)
          }
        end
    end
  end

  defp section_style(section) do
    start = Map.get(section, "column_start", 1)
    span = Map.get(section, "column_span", 12)
    row = Map.get(section, "grid_row")

    row_style = if row, do: " grid-row: #{row};", else: ""
    "grid-column: #{start} / span #{span};#{row_style}"
  end

  defp orientation_icon(form) do
    if orientation(form) == "landscape", do: "hero-arrows-right-left", else: "hero-arrows-up-down"
  end

  defp page_label(form) do
    if length(pages(form)) == 1, do: "page", else: "pages"
  end

  defp empty_values(form) do
    form
    |> MinistryReporting.field_ids()
    |> Kernel.++(MinistryReporting.table_cell_ids(form))
    |> Map.new(&{&1, ""})
  end

  defp input_type(type) when type in ["date", "month", "number"], do: type
  defp input_type(_type), do: "text"

  defp checked?(value), do: value in ["true", true, "on", "1", 1]

  defp row_code(row) when is_map(row), do: Map.get(row, "code", "")
  defp row_code(_row), do: ""

  defp row_label(row) when is_map(row), do: Map.get(row, "label", "")
  defp row_label(row), do: row

  defp row_key(row) when is_map(row) do
    Map.get(row, "id") || "#{Map.get(row, "code", "")}_#{Map.get(row, "label", "")}"
  end

  defp row_key(row), do: row

  defp row_emphasis?(row) when is_map(row), do: Map.get(row, "emphasis", false)
  defp row_emphasis?(_row), do: false

  defp row_input?(row) when is_map(row), do: Map.get(row, "input", true)
  defp row_input?(_row), do: true

  defp row_cell_code(row, index) when is_map(row) do
    row
    |> Map.get("cell_codes", [])
    |> Enum.at(index)
  end

  defp row_cell_code(_row, _index), do: nil

  defp column_label(column) when is_map(column), do: Map.get(column, "label", "")
  defp column_label(column), do: column

  defp column_key(column) when is_map(column), do: Map.get(column, "id", column["label"])
  defp column_key(column), do: column

  defp table_cell_id(section_id, row_index, row, column_index, column) do
    "table_#{section_id}_r#{row_index}_#{MinistryReporting.slug(row)}_c#{column_index}_#{MinistryReporting.slug(column)}"
  end

  defp print_css(form) do
    "@page { size: A4 #{orientation(form)}; margin: 8mm; }"
  end

  defp ai_mapping_error(reason) when is_binary(reason), do: reason
  defp ai_mapping_error(:invalid_source_items), do: "There are no unmatched labels to review."
  defp ai_mapping_error(:unknown_form), do: "The selected report definition was not found."
  defp ai_mapping_error(reason), do: "AI mapping suggestions failed: #{inspect(reason)}"
end
