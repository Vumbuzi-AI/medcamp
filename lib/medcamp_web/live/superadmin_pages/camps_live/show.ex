defmodule MedcampWeb.SuperadminCampsLive.Show do
  @moduledoc """
  Read-only platform-console drilldown into one camp, across the tenant
  boundary. Managing a camp still happens inside its organisation.
  """

  use MedcampWeb, :superadmin_live_view

  alias Medcamp.Accounts.User
  alias Medcamp.Camps
  alias Medcamp.Repo

  import Ecto.Query, warn: false

  @tabs [:overview, :patients, :staff]

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    case Camps.get_camp_across_orgs(id) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "That camp could not be found.")
         |> push_navigate(to: ~p"/superadmin/camps")}

      camp ->
        {:ok,
         socket
         |> assign(:active_tab, :camps)
         |> assign(:page_title, camp.name)
         |> assign(:camp, camp)
         |> assign(:tab, :overview)
         |> assign(:breakdown, Camps.camp_record_breakdown(camp.id))
         |> assign(:patient_stats, Camps.camp_patient_stats(camp.id))
         |> assign_new(:camp_patients, fn -> nil end)
         |> assign_new(:staff, fn -> nil end)}
    end
  end

  @impl true
  def handle_event("tab", %{"tab" => tab}, socket) do
    tab = String.to_existing_atom(tab)
    tab = if tab in @tabs, do: tab, else: :overview

    {:noreply, socket |> assign(:tab, tab) |> load_tab(tab)}
  end

  defp load_tab(%{assigns: %{camp_patients: nil}} = socket, :patients),
    do: assign(socket, :camp_patients, Camps.camp_patients(socket.assigns.camp.id))

  defp load_tab(%{assigns: %{staff: nil}} = socket, :staff),
    do: assign(socket, :staff, list_staff(socket.assigns.camp.organisation_id))

  defp load_tab(socket, _), do: socket

  defp list_staff(org_id) do
    Repo.all(
      from(u in User,
        where: u.organisation_id == ^org_id,
        order_by: [asc: u.role, asc: u.name]
      ),
      skip_org_id: true
    )
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-5">
      <.link
        navigate={~p"/superadmin/camps"}
        class="inline-flex items-center gap-1 text-sm font-semibold text-[#0C2765] transition-colors duration-150 hover:text-[#52B2D8]"
      >
        <Heroicons.icon name="arrow-left" type="outline" class="h-4 w-4" /> All camps
      </.link>

      <div class="rounded-2xl border border-slate-200 bg-white shadow-card p-6">
        <div class="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
          <div class="min-w-0">
            <div class="flex items-center gap-2">
              <h1 class="text-2xl font-bold tracking-[-0.01em] text-[#0C2765]">{@camp.name}</h1>
              <span
                :if={@camp.is_active}
                class="inline-flex items-center gap-1 rounded-full bg-green-50 px-2.5 py-0.5 text-xs font-medium text-green-700 ring-1 ring-green-600/20"
              >
                <span class="h-1.5 w-1.5 rounded-full bg-green-500"></span> Active
              </span>
              <span
                :if={!@camp.is_active}
                class="inline-flex items-center rounded-full bg-slate-100 px-2.5 py-0.5 text-xs font-medium text-slate-600"
              >
                Inactive
              </span>
            </div>
            <p class="mt-1 text-sm text-slate-600">
              {@camp.organisation && @camp.organisation.name}
              <span :if={@camp.location}>· {@camp.location}</span>
              <span :if={Camps.Camp.date_range(@camp)}>· {Camps.Camp.date_range(@camp)}</span>
            </p>
          </div>
          <.link
            navigate={~p"/superadmin/organisations/#{@camp.organisation_id}/medical-camp"}
            class="inline-flex shrink-0 items-center justify-center gap-2 rounded-full bg-[#0C2765] px-5 py-2.5 text-sm font-semibold text-white transition-colors duration-150 hover:bg-[#16418f]"
          >
            <Heroicons.icon name="chart-bar-square" type="outline" class="h-4 w-4" /> Camp dashboard
          </.link>
        </div>
      </div>

      <div class="flex gap-1 rounded-xl border border-slate-200 bg-white p-1 shadow-card">
        <button
          :for={{tab, label} <- [overview: "Overview", patients: "Patients", staff: "Staff"]}
          type="button"
          phx-click="tab"
          phx-value-tab={tab}
          class={[
            "flex-1 rounded-lg px-3 py-2 text-sm font-semibold transition-colors duration-150",
            (@tab == tab && "bg-[#0C2765] text-white") ||
              "text-slate-600 hover:bg-slate-100"
          ]}
        >
          {label}
        </button>
      </div>

      <div :if={@tab == :overview} class="space-y-5">
        <div class="grid gap-5 sm:grid-cols-3">
          <div class="rounded-2xl border border-slate-200 bg-white shadow-card p-5">
            <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">Patients</p>
            <p class="mt-1 text-2xl font-bold text-[#0C2765]">{@patient_stats.total}</p>
          </div>
          <div class="rounded-2xl border border-slate-200 bg-white shadow-card p-5">
            <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">New</p>
            <p class="mt-1 text-2xl font-bold text-[#0C2765]">{@patient_stats.new}</p>
          </div>
          <div class="rounded-2xl border border-slate-200 bg-white shadow-card p-5">
            <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">Returning</p>
            <p class="mt-1 text-2xl font-bold text-[#0C2765]">{@patient_stats.returning}</p>
          </div>
        </div>

        <div class="rounded-2xl border border-slate-200 bg-white shadow-card p-5">
          <h2 class="text-base font-semibold text-[#0C2765]">Records logged</h2>
          <dl class="mt-4 divide-y divide-slate-100">
            <div :for={{label, count} <- @breakdown} class="flex items-center justify-between py-2.5">
              <dt class="text-sm text-slate-600">{label}</dt>
              <dd class="text-sm font-semibold text-slate-900">{count}</dd>
            </div>
          </dl>
        </div>

        <p
          :if={@camp.description}
          class="rounded-2xl border border-slate-200 bg-white shadow-card p-5 text-sm text-slate-600"
        >
          {@camp.description}
        </p>
      </div>

      <.data_table
        :if={@tab == :patients}
        id="camp-patients"
        rows={@camp_patients || []}
        row_id={&"camp-patient-#{&1.patient.id}"}
      >
        <:col :let={row} label="Patient" class="font-medium text-slate-900">
          {patient_name(row.patient)}
        </:col>
        <:col :let={row} label="GSRN" class="font-mono text-xs text-slate-500">
          {row.patient.gsrn}
        </:col>
        <:col :let={row} label="First seen" hide_below="sm">
          {row.first_seen_at && Calendar.strftime(row.first_seen_at, "%Y-%m-%d")}
        </:col>
        <:empty>No patients recorded for this camp yet.</:empty>
      </.data_table>

      <.data_table
        :if={@tab == :staff}
        id="camp-staff"
        rows={@staff || []}
        row_id={&"camp-staff-#{&1.id}"}
      >
        <:col :let={user} label="Name">
          <p class="text-sm font-medium text-slate-900">{user.name}</p>
          <p class="text-xs text-slate-500">{user.email}</p>
        </:col>
        <:col :let={user} label="Role" class="capitalize">
          {user.role}
        </:col>
        <:col :let={user} label="Status" class="capitalize" hide_below="sm">
          {User.status(user)}
        </:col>
        <:empty>This organisation has no staff accounts.</:empty>
      </.data_table>
    </div>
    """
  end

  defp patient_name(patient) do
    [patient.first_name, patient.middle_name, patient.last_name]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(" ")
  end
end
