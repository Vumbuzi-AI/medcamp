defmodule MedcampWeb.AdminDoctorNoteQualityLive.Index do
  use MedcampWeb, :admin_live_view

  alias Medcamp.Accounts
  alias Medcamp.DoctorNotes
  alias Medcamp.DoctorNotes.Quality

  @impl true
  def mount(_params, _session, socket) do
    today = Date.utc_today()

    {:ok,
     socket
     |> assign(:active_tab, :doctor_note_quality)
     |> assign(:page_title, "Doctor Note Data Quality")
     |> assign(:date_from, Date.beginning_of_month(today))
     |> assign(:date_to, today)
     |> assign(:doctor_id, "all")
     |> assign(:doctors, Accounts.list_all_doctors_for_selection())
     |> load_quality()}
  end

  @impl true
  def handle_event("filter", params, socket) do
    {:noreply,
     socket
     |> assign(:date_from, parse_date(params["date_from"]))
     |> assign(:date_to, parse_date(params["date_to"]))
     |> assign(:doctor_id, params["doctor_id"] || "all")
     |> load_quality()}
  end

  def handle_event("clear_filters", _params, socket) do
    today = Date.utc_today()

    {:noreply,
     socket
     |> assign(:date_from, Date.beginning_of_month(today))
     |> assign(:date_to, today)
     |> assign(:doctor_id, "all")
     |> load_quality()}
  end

  defp load_quality(socket) do
    notes =
      DoctorNotes.list_doctor_notes_for_quality(%{
        date_from: socket.assigns.date_from,
        date_to: socket.assigns.date_to,
        doctor_id: parse_doctor_id(socket.assigns.doctor_id)
      })

    assign(socket, :quality, Quality.summarize(notes))
  end

  defp parse_date(nil), do: nil
  defp parse_date(""), do: nil

  defp parse_date(value) do
    case Date.from_iso8601(value) do
      {:ok, date} -> date
      _ -> nil
    end
  end

  defp parse_doctor_id(value) when value in [nil, "", "all"], do: nil

  defp parse_doctor_id(value) do
    case Integer.parse(to_string(value)) do
      {id, ""} -> id
      _ -> nil
    end
  end

  defp date_value(nil), do: ""
  defp date_value(date), do: Date.to_iso8601(date)

  defp percentage(value), do: :erlang.float_to_binary(value / 1, decimals: 1) <> "%"

  defp quality_colour(value) when value >= 90, do: "text-emerald-700 bg-emerald-50"
  defp quality_colour(value) when value >= 70, do: "text-amber-700 bg-amber-50"
  defp quality_colour(_value), do: "text-rose-700 bg-rose-50"

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-slate-50 -m-4 p-4 sm:-m-6 sm:p-6">
      <div class="mx-auto w-[95%] space-y-6">
        <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6">
          <div class="flex flex-col gap-5 lg:flex-row lg:items-end lg:justify-between">
            <div>
              <p class="text-sm font-semibold text-brand-accent">Clinical documentation</p>
              <h1 class="mt-1 text-2xl font-bold tracking-tight text-slate-900">
                Doctor Note Data Quality
              </h1>
              <p class="mt-2 max-w-3xl text-sm text-slate-600">
                Review documentation completeness across doctor notes and identify the fields
                and clinicians that need follow-up.
              </p>
            </div>

            <form phx-submit="filter" class="grid gap-3 sm:grid-cols-4 lg:min-w-[680px]">
              <label class="block">
                <span class="mb-1 block text-xs font-semibold text-slate-600">From</span>
                <input
                  type="date"
                  name="date_from"
                  value={date_value(@date_from)}
                  class="w-full rounded-lg border-slate-300 text-sm focus:border-brand-accent focus:ring-brand-accent"
                />
              </label>
              <label class="block">
                <span class="mb-1 block text-xs font-semibold text-slate-600">To</span>
                <input
                  type="date"
                  name="date_to"
                  value={date_value(@date_to)}
                  class="w-full rounded-lg border-slate-300 text-sm focus:border-brand-accent focus:ring-brand-accent"
                />
              </label>
              <label class="block">
                <span class="mb-1 block text-xs font-semibold text-slate-600">Doctor</span>
                <select
                  name="doctor_id"
                  class="w-full rounded-lg border-slate-300 text-sm focus:border-brand-accent focus:ring-brand-accent"
                >
                  <option value="all" selected={@doctor_id == "all"}>All doctors</option>
                  <option
                    :for={{name, id} <- @doctors}
                    value={id}
                    selected={to_string(id) == @doctor_id}
                  >
                    {name}
                  </option>
                </select>
              </label>
              <div class="flex items-end gap-2">
                <button
                  type="submit"
                  class="h-[42px] flex-1 rounded-lg bg-brand-accent px-4 text-sm font-semibold text-white hover:bg-[#55569a]"
                >
                  Apply
                </button>
                <button
                  type="button"
                  phx-click="clear_filters"
                  class="h-[42px] rounded-lg border border-slate-300 px-3 text-sm font-semibold text-slate-600 hover:bg-slate-50"
                >
                  Reset
                </button>
              </div>
            </form>
          </div>
        </div>

        <%= if @quality.total_notes == 0 do %>
          <div class="rounded-2xl border border-dashed border-slate-300 bg-white px-6 py-16 text-center">
            <.icon name="hero-document-magnifying-glass" class="mx-auto h-10 w-10 text-slate-400" />
            <h2 class="mt-3 text-base font-semibold text-slate-900">No doctor notes found</h2>
            <p class="mt-1 text-sm text-slate-500">
              No notes match the selected date range and doctor.
            </p>
          </div>
        <% else %>
          <div class="grid gap-4 sm:grid-cols-2 xl:grid-cols-5">
            <.metric_card
              label="Notes evaluated"
              value={@quality.total_notes}
              detail="In this report"
            />
            <.metric_card
              label="Fully complete"
              value={percentage(@quality.complete_percentage)}
              detail={"#{@quality.complete_notes} notes"}
              tone={quality_colour(@quality.complete_percentage)}
            />
            <.metric_card
              label="Average completion"
              value={percentage(@quality.average_completion)}
              detail="Across 6 core fields"
              tone={quality_colour(@quality.average_completion)}
            />
            <.metric_card
              label="Missing impression"
              value={percentage(@quality.missing_impression_percentage)}
              detail={"#{@quality.missing_impression} notes"}
              tone="text-rose-700 bg-rose-50"
            />
            <.metric_card
              label="Missing investigations"
              value={percentage(@quality.missing_investigations_percentage)}
              detail={"#{@quality.missing_investigations} notes"}
              tone="text-amber-700 bg-amber-50"
            />
          </div>

          <div class="grid gap-6 xl:grid-cols-[minmax(0,0.9fr)_minmax(0,1.6fr)]">
            <section class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
              <div>
                <h2 class="text-base font-bold text-slate-900">Missing fields</h2>
                <p class="mt-1 text-sm text-slate-500">Share of notes where each field is blank.</p>
              </div>
              <div class="mt-5 space-y-5">
                <div :for={gap <- @quality.gaps}>
                  <div class="mb-1.5 flex items-center justify-between gap-4 text-sm">
                    <span class="font-medium text-slate-700">{gap.label}</span>
                    <span class="font-semibold text-slate-900">
                      {gap.missing_count} ({percentage(gap.missing_percentage)})
                    </span>
                  </div>
                  <div class="h-2 overflow-hidden rounded-full bg-slate-100">
                    <div
                      class="h-full rounded-full bg-rose-400"
                      style={"width: #{gap.missing_percentage}%"}
                    />
                  </div>
                </div>
              </div>
            </section>

            <section class="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
              <div class="border-b border-slate-200 px-5 py-4">
                <h2 class="text-base font-bold text-slate-900">Quality by doctor</h2>
                <p class="mt-1 text-sm text-slate-500">
                  Doctors needing the most documentation support appear first.
                </p>
              </div>
              <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-slate-200">
                  <thead class="bg-slate-50">
                    <tr>
                      <th class="px-5 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                        Doctor
                      </th>
                      <th class="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-slate-500">
                        Notes
                      </th>
                      <th class="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-slate-500">
                        Fully complete
                      </th>
                      <th class="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-slate-500">
                        Avg. score
                      </th>
                      <th class="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-slate-500">
                        No impression
                      </th>
                      <th class="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-slate-500">
                        No investigations
                      </th>
                      <th class="px-5 py-3 text-right text-xs font-semibold uppercase tracking-wide text-slate-500">
                        No plan
                      </th>
                    </tr>
                  </thead>
                  <tbody class="divide-y divide-slate-100">
                    <tr :for={doctor <- @quality.by_doctor} class="hover:bg-slate-50/70">
                      <td class="whitespace-nowrap px-5 py-4 text-sm font-semibold text-slate-900">
                        Dr. {doctor.doctor_name}
                      </td>
                      <td class="px-4 py-4 text-right text-sm text-slate-700">
                        {doctor.total_notes}
                      </td>
                      <td class="px-4 py-4 text-right text-sm">
                        <span class={[
                          "rounded-full px-2.5 py-1 font-semibold",
                          quality_colour(doctor.complete_percentage)
                        ]}>
                          {percentage(doctor.complete_percentage)}
                        </span>
                      </td>
                      <td class="px-4 py-4 text-right text-sm font-semibold text-slate-800">
                        {percentage(doctor.average_completion)}
                      </td>
                      <td class="px-4 py-4 text-right text-sm text-slate-700">
                        {doctor.missing_impression} ({percentage(doctor.missing_impression_percentage)})
                      </td>
                      <td class="px-4 py-4 text-right text-sm text-slate-700">
                        {doctor.missing_investigations} ({percentage(
                          doctor.missing_investigations_percentage
                        )})
                      </td>
                      <td class="px-5 py-4 text-right text-sm text-slate-700">
                        {doctor.missing_management} ({percentage(doctor.missing_management_percentage)})
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </section>
          </div>

          <div class="rounded-xl border border-blue-200 bg-blue-50 px-4 py-3 text-sm text-blue-900">
            <span class="font-semibold">How completeness is calculated:</span>
            A note is fully complete when complaints, clinical notes, past medical history,
            impression, management, and investigations all contain a value.
            Entering “None” or “Not indicated” documents that a field was considered.
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :value, :any, required: true
  attr :detail, :string, required: true
  attr :tone, :string, default: "text-brand-primary bg-brand-50"

  defp metric_card(assigns) do
    ~H"""
    <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
      <div class={["inline-flex rounded-lg px-2.5 py-1 text-xs font-semibold", @tone]}>
        {@label}
      </div>
      <p class="mt-3 text-3xl font-bold tracking-tight text-slate-900">{@value}</p>
      <p class="mt-1 text-sm text-slate-500">{@detail}</p>
    </div>
    """
  end
end
