defmodule MedcampWeb.SuperadminCampsLive.Index do
  @moduledoc """
  Platform-wide view of every camp across every organisation. Read-only -
  managing a camp still happens inside its organisation (`/admin/camps`).
  """

  use MedcampWeb, :superadmin_live_view

  alias Medcamp.Camps

  @impl true
  def mount(_params, _session, socket) do
    rows = Camps.list_all_camps_with_counts()

    {:ok,
     socket
     |> assign(:active_tab, :camps)
     |> assign(:page_title, "Camps")
     |> assign(:search, "")
     |> assign(:analytics, Camps.platform_camp_analytics())
     |> assign(:all_rows, rows)
     |> assign(:rows, rows)}
  end

  @impl true
  def handle_event("search", %{"search" => term}, socket) do
    {:noreply, socket |> assign(:search, term) |> filter()}
  end

  def handle_event("clear_filters", _params, socket) do
    {:noreply, socket |> assign(:search, "") |> filter()}
  end

  defp filter(socket) do
    term = socket.assigns.search |> to_string() |> String.trim() |> String.downcase()

    rows =
      if term == "" do
        socket.assigns.all_rows
      else
        Enum.filter(socket.assigns.all_rows, fn {camp, _count} ->
          String.contains?(String.downcase(camp.name || ""), term) or
            String.contains?(String.downcase(org_name(camp)), term)
        end)
      end

    assign(socket, :rows, rows)
  end

  defp org_name(%{organisation: %{name: name}}) when is_binary(name), do: name
  defp org_name(_), do: ""

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-5">
      <div :if={@search == ""} class="space-y-5">
        <.summary_card_grid cards={kpi_cards(@analytics)} />

        <div class="grid gap-5 lg:grid-cols-2">
          <div class="rounded-2xl border border-slate-200 bg-white shadow-card p-5">
            <h2 class="text-base font-semibold text-[#0C2765]">Busiest camps</h2>
            <p class="mt-1 text-xs text-slate-500">By total clinical records logged.</p>
            <ol class="mt-4 space-y-2">
              <li :if={@analytics.top_camps == []} class="text-sm text-slate-500">
                No camp activity yet.
              </li>
              <li
                :for={{{camp, count}, idx} <- Enum.with_index(@analytics.top_camps, 1)}
                class="flex items-center gap-3"
              >
                <span class="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-[#e9f6fb] text-xs font-bold text-[#0C2765]">
                  {idx}
                </span>
                <span class="min-w-0 flex-1">
                  <span class="block truncate text-sm font-medium text-slate-900">{camp.name}</span>
                  <span class="block truncate text-xs text-slate-500">{org_name(camp)}</span>
                </span>
                <span class="shrink-0 text-sm font-semibold text-slate-900">{count}</span>
              </li>
            </ol>
          </div>

          <div class="rounded-2xl border border-slate-200 bg-white shadow-card p-5">
            <h2 class="text-base font-semibold text-[#0C2765]">New vs returning patients</h2>
            <p class="mt-1 text-xs text-slate-500">
              Returning = seen at more than one camp in the same organisation.
            </p>
            <% total = max(@analytics.patients, 1) %>
            <div class="mt-4 flex h-3 overflow-hidden rounded-full bg-slate-100">
              <div
                class="bg-[#0C2765]"
                style={"width: #{Float.round(@analytics.new_patients / total * 100, 1)}%"}
              >
              </div>
              <div
                class="bg-[#52B2D8]"
                style={"width: #{Float.round(@analytics.returning_patients / total * 100, 1)}%"}
              >
              </div>
            </div>
            <div class="mt-3 flex items-center justify-between text-sm">
              <span class="flex items-center gap-1.5 text-slate-600">
                <span class="h-2.5 w-2.5 rounded-full bg-[#0C2765]"></span>
                New <span class="font-semibold text-slate-900">{@analytics.new_patients}</span>
              </span>
              <span class="flex items-center gap-1.5 text-slate-600">
                <span class="h-2.5 w-2.5 rounded-full bg-[#52B2D8]"></span>
                Returning
                <span class="font-semibold text-slate-900">{@analytics.returning_patients}</span>
              </span>
            </div>
            <p class="mt-4 text-xs text-slate-500">
              Avg <span class="font-semibold text-slate-700">{@analytics.avg_records_per_camp}</span>
              records per camp.
            </p>
          </div>
        </div>
      </div>

      <.list_page
        icon_path="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 0 1 2.25-2.25h13.5A2.25 2.25 0 0 1 21 7.5v11.25m-18 0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75m-18 0v-7.5A2.25 2.25 0 0 1 5.25 9h13.5A2.25 2.25 0 0 1 21 11.25v7.5"
        title="Camps"
        subtitle={"#{length(@all_rows)} camp#{if length(@all_rows) != 1, do: "s", else: ""} across all organisations"}
      >
        <:toolbar>
          <form phx-change="search" class="flex-1">
            <.search_input name="search" value={@search} placeholder="Search by camp or organisation" />
          </form>
        </:toolbar>

        <%= if @rows == [] do %>
          <.blank_state
            icon_path="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 0 1 2.25-2.25h13.5A2.25 2.25 0 0 1 21 7.5v11.25m-18 0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75m-18 0v-7.5A2.25 2.25 0 0 1 5.25 9h13.5A2.25 2.25 0 0 1 21 11.25v7.5"
            title="No camps"
            description={
              if @search != "",
                do: "No camps match the search.",
                else: "No organisation has created a camp yet."
            }
          >
            <:actions :if={@search != ""}>
              <button phx-click="clear_filters" class="text-xs text-[#0C2765] hover:underline">
                Clear search
              </button>
            </:actions>
          </.blank_state>
        <% else %>
          <.data_table id="superadmin-camps" rows={@rows} row_id={fn {c, _} -> "camp-#{c.id}" end}>
            <:col :let={{camp, _count}} label="Camp">
              <p class="font-medium text-slate-900">{camp.name}</p>
              <p :if={camp.location} class="text-xs text-slate-500">{camp.location}</p>
            </:col>
            <:col :let={{camp, _count}} label="Organisation">
              <span class="text-slate-700">{org_name(camp)}</span>
            </:col>
            <:col :let={{camp, _count}} label="Status">
              <span
                :if={camp.is_active}
                class="inline-flex items-center gap-1 rounded-full bg-green-50 px-2.5 py-0.5 text-xs font-medium text-green-700 ring-1 ring-green-600/20"
              >
                <span class="h-1.5 w-1.5 rounded-full bg-green-500"></span> Active
              </span>
              <span
                :if={!camp.is_active}
                class="inline-flex items-center rounded-full bg-slate-100 px-2.5 py-0.5 text-xs font-medium text-slate-600"
              >
                Inactive
              </span>
            </:col>
            <:col :let={{camp, _count}} label="Dates">
              <span class="text-sm text-slate-600">
                {Medcamp.Camps.Camp.date_range(camp) || "—"}
              </span>
            </:col>
            <:col :let={{_camp, count}} label="Records" align="right">
              <span class="font-semibold text-slate-900">{count}</span>
            </:col>
            <:action :let={{camp, _count}}>
              <.link
                navigate={~p"/superadmin/camps/#{camp.id}"}
                class="inline-flex items-center gap-1 rounded-md px-2.5 py-1.5 text-xs font-medium text-[#0C2765] transition-colors duration-150 hover:text-[#52B2D8]"
              >
                View
              </.link>
              <.link
                navigate={~p"/superadmin/organisations/#{camp.organisation_id}"}
                class="inline-flex items-center gap-1 rounded-md px-2.5 py-1.5 text-xs font-medium text-[#0C2765] transition-colors duration-150 hover:text-[#52B2D8]"
              >
                Organisation
              </.link>
              <.link
                navigate={~p"/superadmin/organisations/#{camp.organisation_id}/medical-camp"}
                class="inline-flex items-center gap-1 rounded-md px-2.5 py-1.5 text-xs font-medium text-white bg-[#0C2765] transition-colors duration-150 hover:bg-[#16418f]"
              >
                Camp dashboard
              </.link>
            </:action>
          </.data_table>
        <% end %>
      </.list_page>
    </div>
    """
  end

  defp kpi_cards(analytics) do
    summary_cards_for(
      [
        :platform_total_camps,
        :platform_active_camps,
        :platform_camp_patients,
        :platform_camp_records,
        :platform_returning_patients
      ],
      %{
        platform_total_camps: {analytics.total_camps, "Across all organisations"},
        platform_active_camps: {analytics.active_camps, "Currently accepting records"},
        platform_camp_patients: {analytics.patients, "Distinct patients with attendance"},
        platform_camp_records: {analytics.total_records, "Clinical rows logged"},
        platform_returning_patients: {analytics.returning_patients, "Seen at more than one camp"}
      }
    )
  end
end
