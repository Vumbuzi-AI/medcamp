defmodule MedcampWeb.SuperadminDashboardLive.Index do
  @moduledoc """
  Platform-level dashboard for superadmins.

  This view stays outside tenant context for the organisation directory, and
  uses scoped aggregate queries only for high-level operational counts.
  Detailed clinical records should still be viewed one organisation at a time.
  """

  use MedcampWeb, :superadmin_live_view

  import Ecto.Query, warn: false

  alias Medcamp.DrugAllocations.DrugAllocation
  alias Medcamp.LabResults.LabResult
  alias Medcamp.Organisations
  alias Medcamp.PatientVisits.PatientVisit
  alias Medcamp.Patients.Patient
  alias Medcamp.Repo

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :dashboard)
     |> assign(:page_title, "Platform Dashboard")
     |> assign(:search, "")
     |> assign(:page, 1)
     |> assign(:per_page, 10)
     |> assign(:stats, Organisations.organisation_stats())
     |> load_activity()}
  end

  @impl true
  def handle_event("search", %{"search" => term}, socket) do
    {:noreply, socket |> assign(:search, term) |> assign(:page, 1) |> load_activity()}
  end

  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, Medcamp.Pagination.normalize_page(page))
     |> load_activity()}
  end

  # Only the visible page's rows get the per-organisation aggregate queries.
  defp load_activity(socket) do
    %{rows: rows, count: count} =
      Organisations.paged_organisations(
        search: socket.assigns.search,
        page: socket.assigns.page,
        per_page: socket.assigns.per_page
      )

    socket
    |> assign(:organisations, rows)
    |> assign(:summaries, organisation_summaries(rows))
    |> assign(:total_count, count)
    |> assign(:total_pages, Medcamp.Pagination.total_pages(count, socket.assigns.per_page))
  end

  defp organisation_summaries(organisations) do
    org_ids = Enum.map(organisations, & &1.id)

    patient_counts = count_by_org(Patient, org_ids)
    active_visit_counts = count_by_org(PatientVisit, org_ids, status_not: "completed")
    lab_pending_counts = count_by_org(LabResult, org_ids, report_complete: false)
    pharmacy_pending_counts = count_by_org(DrugAllocation, org_ids, has_been_assigned: false)

    Map.new(organisations, fn org ->
      {org.id,
       %{
         patient_count: Map.get(patient_counts, org.id, 0),
         active_visit_count: Map.get(active_visit_counts, org.id, 0),
         lab_pending_count: Map.get(lab_pending_counts, org.id, 0),
         pharmacy_pending_count: Map.get(pharmacy_pending_counts, org.id, 0)
       }}
    end)
  end

  defp count_by_org(schema, org_ids, filters \\ [])
  defp count_by_org(_schema, [], _filters), do: %{}

  defp count_by_org(schema, org_ids, filters) do
    schema
    |> where([r], r.organisation_id in ^org_ids)
    |> apply_count_filters(filters)
    |> group_by([r], r.organisation_id)
    |> select([r], {r.organisation_id, count(r.id)})
    |> Repo.all(skip_org_id: true)
    |> Map.new()
  end

  defp apply_count_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {:status_not, value}, query -> where(query, [r], r.status != ^value)
      {:report_complete, value}, query -> where(query, [r], r.report_complete == ^value)
      {:has_been_assigned, value}, query -> where(query, [r], r.has_been_assigned == ^value)
    end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-5">
      <div class="rounded-2xl border border-slate-200 bg-white shadow-card p-6">
        <div class="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
          <div>
            <h1 class="text-2xl font-bold tracking-[-0.01em] text-[#0C2765]">Platform Dashboard</h1>
            <p class="mt-2 text-sm leading-relaxed text-slate-600">
              Monitor organisations and spot camps that need approval or operational attention.
            </p>
          </div>
          <.link
            navigate={~p"/superadmin/organisations"}
            class="inline-flex shrink-0 items-center justify-center gap-2 rounded-full bg-[#0C2765] px-5 py-2.5 text-sm font-semibold text-white transition-colors duration-150 hover:bg-[#16418f]"
          >
            <Heroicons.icon name="building-office-2" type="outline" class="h-4 w-4" />
            Manage organisations
          </.link>
        </div>
      </div>

      <.link
        :if={@stats.pending > 0}
        navigate={~p"/superadmin/organisations"}
        class="flex items-center justify-between gap-4 rounded-2xl border border-amber-200 bg-amber-50 px-5 py-4 transition-colors duration-150 hover:bg-amber-100"
      >
        <span class="flex items-center gap-3 text-sm font-semibold text-amber-900">
          <Heroicons.icon name="clock" type="outline" class="h-5 w-5 shrink-0 text-amber-600" />
          {@stats.pending} awaiting approval — staff can't sign in until reviewed
        </span>
        <span class="shrink-0 text-sm font-semibold text-amber-900">Review →</span>
      </.link>

      <.summary_card_grid cards={summary_cards(assigns)} />

      <div class="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-card">
        <div class="flex flex-col gap-3 border-b border-slate-200 px-5 py-4 sm:flex-row sm:items-center sm:justify-between">
          <h2 class="text-base font-semibold text-[#0C2765]">Organisation activity</h2>
          <form phx-change="search" class="sm:w-72">
            <div class="relative">
              <Heroicons.icon
                name="magnifying-glass"
                type="outline"
                class="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400"
              />
              <input
                type="text"
                name="search"
                value={@search}
                placeholder="Search organisations"
                phx-debounce="300"
                class="h-9 w-full rounded-lg border border-slate-300 pl-9 pr-4 text-sm text-slate-900 placeholder:text-slate-400 focus:border-[#52B2D8] focus:outline-none focus:ring-0"
              />
            </div>
          </form>
        </div>

        <.data_table id="platform-activity" rows={@organisations} row_id={&"platform-org-#{&1.id}"}>
          <:col :let={org} label="Organisation">
            <div class="flex items-center gap-3">
              <div class="flex h-9 w-9 shrink-0 items-center justify-center overflow-hidden rounded-xl border border-slate-200 bg-[#e9f6fb] text-xs font-bold text-[#0C2765]">
                <%= if org.logo do %>
                  <img src={org.logo} alt={org.name} class="h-full w-full object-contain" />
                <% else %>
                  {Organisations.initials(org)}
                <% end %>
              </div>
              <div class="min-w-0">
                <p class="truncate text-sm font-semibold text-slate-900">{org.name}</p>
                <p class="mt-0.5 truncate text-xs italic text-slate-400">{org.slug}</p>
              </div>
            </div>
          </:col>
          <:col :let={org} label="Status">
            <.organisation_status_pill organisation={org} />
          </:col>
          <:col :let={org} label="Patients" align="right">
            {@summaries[org.id].patient_count}
          </:col>
          <:col :let={org} label="Active visits" align="right" hide_below="md">
            {@summaries[org.id].active_visit_count}
          </:col>
          <:col :let={org} label="Lab" align="right" hide_below="md">
            {@summaries[org.id].lab_pending_count}
          </:col>
          <:col :let={org} label="Pharmacy" align="right" hide_below="lg">
            {@summaries[org.id].pharmacy_pending_count}
          </:col>
          <:action :let={org}>
            <.link
              navigate={~p"/superadmin/organisations/#{org.id}/medical-camp"}
              class="inline-flex items-center gap-1 rounded-md px-2.5 py-1.5 text-xs font-semibold text-[#0C2765] transition-colors duration-150 hover:text-[#52B2D8]"
            >
              <Heroicons.icon name="chart-bar-square" type="outline" class="h-3.5 w-3.5" />
              Camp dashboard
            </.link>
          </:action>
          <:empty>
            {if @search == "",
              do: "No organisations yet.",
              else: "No organisations match “#{@search}”."}
          </:empty>
          <:footer>
            <.pagination
              page={@page}
              total_pages={@total_pages}
              total_count={@total_count}
              per_page={@per_page}
            />
          </:footer>
        </.data_table>
      </div>
    </div>
    """
  end

  defp summary_cards(assigns) do
    summary_cards_for(
      [:platform_organisations, :platform_active_organisations, :platform_pending_approvals],
      %{
        platform_organisations: {assigns.stats.total, "Tenant workspaces"},
        platform_active_organisations: {assigns.stats.active, "Approved and live"},
        platform_pending_approvals: {assigns.stats.pending, "Awaiting review"}
      }
    )
  end
end
