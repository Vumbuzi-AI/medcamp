defmodule MedcampWeb.AdminDoctorNoteSearchLive.Index do
  use MedcampWeb, :admin_live_view

  alias Medcamp.DoctorNoteSearch

  @impl true
  def mount(_params, _session, socket) do
    today = Date.utc_today()

    filters = %{
      query: "",
      date_from: Date.to_iso8601(Date.beginning_of_month(today)),
      date_to: Date.to_iso8601(today),
      age_from: "",
      age_to: "",
      sex: ""
    }

    {:ok,
     socket
     |> assign(:active_tab, :doctor_note_search)
     |> assign(:page_title, "Doctor Note Search")
     |> assign(:filters, filters)
     |> assign(:report, DoctorNoteSearch.search(%{query: ""}))}
  end

  @impl true
  def handle_event("search", %{"filters" => params}, socket) do
    case parse_filters(params) do
      {:ok, display_filters, search_filters} ->
        {:noreply,
         socket
         |> assign(:filters, display_filters)
         |> assign(:report, DoctorNoteSearch.search(search_filters))}

      {:error, message} ->
        {:noreply, put_flash(socket, :error, message)}
    end
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply, elem(mount(%{}, %{}, socket), 1)}
  end

  defp parse_filters(params) do
    display_filters = %{
      query: params |> Map.get("query", "") |> String.trim(),
      date_from: Map.get(params, "date_from", ""),
      date_to: Map.get(params, "date_to", ""),
      age_from: Map.get(params, "age_from", ""),
      age_to: Map.get(params, "age_to", ""),
      sex: Map.get(params, "sex", "")
    }

    with :ok <- require_query(display_filters.query),
         {:ok, date_from} <- Date.from_iso8601(display_filters.date_from),
         {:ok, date_to} <- Date.from_iso8601(display_filters.date_to),
         :ok <-
           validate_range(date_from, date_to, "The start date must be on or before the end date."),
         {:ok, age_from} <- parse_age(display_filters.age_from),
         {:ok, age_to} <- parse_age(display_filters.age_to),
         :ok <-
           validate_range(age_from, age_to, "The minimum age must not exceed the maximum age.") do
      {:ok, display_filters,
       %{
         query: display_filters.query,
         date_from: date_from,
         date_to: date_to,
         age_from: age_from,
         age_to: age_to,
         sex: display_filters.sex
       }}
    else
      {:error, :query_required} -> {:error, "Enter a word or phrase to search for."}
      {:error, :invalid_age} -> {:error, "Ages must be whole numbers from 0 to 130."}
      {:error, message} when is_binary(message) -> {:error, message}
      _ -> {:error, "Choose a valid start and end date."}
    end
  end

  defp require_query(""), do: {:error, :query_required}
  defp require_query(_query), do: :ok

  defp parse_age(""), do: {:ok, nil}

  defp parse_age(value) do
    case Integer.parse(value) do
      {age, ""} when age in 0..130 -> {:ok, age}
      _ -> {:error, :invalid_age}
    end
  end

  defp validate_range(nil, _to, _message), do: :ok
  defp validate_range(_from, nil, _message), do: :ok

  defp validate_range(%Date{} = from, %Date{} = to, message) do
    if Date.compare(from, to) in [:lt, :eq], do: :ok, else: {:error, message}
  end

  defp validate_range(from, to, message) when is_integer(from) and is_integer(to) do
    if from <= to, do: :ok, else: {:error, message}
  end

  defp patient_name(patient) do
    [patient.first_name, patient.middle_name, patient.last_name]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(" ")
  end

  defp format_date(nil), do: "—"
  defp format_date(date), do: Calendar.strftime(date, "%d %b %Y")

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-slate-50 -m-4 p-4 sm:-m-6 sm:p-6">
      <div class="mx-auto w-[95%] space-y-6">
        <section class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6">
          <p class="text-sm font-semibold text-brand-accent">Clinical documentation</p>
          <h1 class="mt-1 text-2xl font-bold tracking-tight text-slate-900">
            Doctor Note Master Search
          </h1>
          <p class="mt-2 max-w-4xl text-sm text-slate-600">
            Search every narrative field in doctor notes and analyse occurrences by date,
            patient age and sex.
          </p>

          <form
            id="doctor-note-search-form"
            phx-submit="search"
            class="mt-6 grid gap-4 md:grid-cols-2 xl:grid-cols-7 xl:items-end"
          >
            <label class="block md:col-span-2 xl:col-span-2">
              <span class="mb-1 block text-xs font-semibold text-slate-600">Word or phrase</span>
              <input
                id="doctor-note-search-query"
                type="search"
                name="filters[query]"
                value={@filters.query}
                placeholder="e.g. typhoid"
                required
                class="h-[42px] w-full rounded-lg border-slate-300 text-sm focus:border-brand-accent focus:ring-brand-accent"
              />
            </label>
            <label class="block">
              <span class="mb-1 block text-xs font-semibold text-slate-600">From</span>
              <input
                type="date"
                name="filters[date_from]"
                value={@filters.date_from}
                required
                class="h-[42px] w-full rounded-lg border-slate-300 text-sm focus:border-brand-accent focus:ring-brand-accent"
              />
            </label>
            <label class="block">
              <span class="mb-1 block text-xs font-semibold text-slate-600">To</span>
              <input
                type="date"
                name="filters[date_to]"
                value={@filters.date_to}
                required
                class="h-[42px] w-full rounded-lg border-slate-300 text-sm focus:border-brand-accent focus:ring-brand-accent"
              />
            </label>
            <div class="grid grid-cols-2 gap-2">
              <label class="block">
                <span class="mb-1 block text-xs font-semibold text-slate-600">Min age</span>
                <input
                  type="number"
                  name="filters[age_from]"
                  value={@filters.age_from}
                  min="0"
                  max="130"
                  placeholder="Any"
                  class="h-[42px] w-full rounded-lg border-slate-300 text-sm focus:border-brand-accent focus:ring-brand-accent"
                />
              </label>
              <label class="block">
                <span class="mb-1 block text-xs font-semibold text-slate-600">Max age</span>
                <input
                  type="number"
                  name="filters[age_to]"
                  value={@filters.age_to}
                  min="0"
                  max="130"
                  placeholder="Any"
                  class="h-[42px] w-full rounded-lg border-slate-300 text-sm focus:border-brand-accent focus:ring-brand-accent"
                />
              </label>
            </div>
            <label class="block">
              <span class="mb-1 block text-xs font-semibold text-slate-600">Sex</span>
              <select
                name="filters[sex]"
                class="h-[42px] w-full rounded-lg border-slate-300 text-sm focus:border-brand-accent focus:ring-brand-accent"
              >
                <option value="">All</option>
                <option value="male" selected={@filters.sex == "male"}>Male</option>
                <option value="female" selected={@filters.sex == "female"}>Female</option>
                <option value="other" selected={@filters.sex == "other"}>Other</option>
              </select>
            </label>
            <div class="flex gap-2">
              <button
                type="submit"
                class="h-[42px] flex-1 rounded-lg bg-brand-accent px-4 text-sm font-semibold text-white hover:bg-[#55569a]"
              >
                Search
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
        </section>

        <section
          :if={@report.query == ""}
          class="rounded-2xl border border-dashed border-slate-300 bg-white px-6 py-16 text-center"
        >
          <.icon name="hero-document-magnifying-glass" class="mx-auto h-10 w-10 text-slate-400" />
          <h2 class="mt-3 text-base font-semibold text-slate-900">Enter a word or phrase</h2>
          <p class="mt-1 text-sm text-slate-500">
            The search checks diagnoses, symptoms, clinical notes, impressions,
            investigations, management plans, medication and other narrative fields.
          </p>
        </section>

        <%= if @report.query != "" do %>
          <div class="grid gap-4 sm:grid-cols-3">
            <.metric_card
              label="Total occurrences"
              value={@report.total_occurrences}
              detail={"“#{@report.query}” across all matching fields"}
            />
            <.metric_card
              label="Matching notes"
              value={@report.matching_notes}
              detail="Each note counted once"
            />
            <.metric_card
              label="Patients"
              value={@report.unique_patients}
              detail="Unique matching patients"
            />
          </div>

          <div
            :if={@report.matches == []}
            class="rounded-2xl border border-dashed border-slate-300 bg-white px-6 py-16 text-center"
          >
            <.icon name="hero-magnifying-glass" class="mx-auto h-10 w-10 text-slate-400" />
            <h2 class="mt-3 text-base font-semibold text-slate-900">No matching doctor notes</h2>
            <p class="mt-1 text-sm text-slate-500">
              Try a different word, wider date range, or broader patient filters.
            </p>
          </div>

          <div
            :if={@report.matches != []}
            class="grid gap-6 xl:grid-cols-[minmax(0,0.65fr)_minmax(0,2fr)]"
          >
            <section class="h-fit overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
              <div class="border-b border-slate-200 px-5 py-4">
                <h2 class="font-bold text-slate-900">Occurrences by field</h2>
              </div>
              <div class="divide-y divide-slate-100">
                <div
                  :for={field <- @report.field_counts}
                  class="flex items-center justify-between gap-3 px-5 py-3 text-sm"
                >
                  <span class="text-slate-600">{field.label}</span>
                  <span class="rounded-full bg-brand-50 px-2.5 py-1 font-bold text-brand-primary">
                    {field.count}
                  </span>
                </div>
              </div>
            </section>

            <section class="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
              <div class="border-b border-slate-200 px-5 py-4">
                <h2 class="font-bold text-slate-900">Matching doctor notes</h2>
                <p class="mt-1 text-sm text-slate-500">
                  Open a row to see which fields contain the search term.
                </p>
              </div>
              <div id="doctor-note-search-results" class="divide-y divide-slate-200">
                <details
                  :for={match <- @report.matches}
                  id={"doctor-note-match-#{match.note.id}"}
                  class="group"
                >
                  <summary class="grid cursor-pointer list-none gap-3 px-5 py-4 hover:bg-slate-50 sm:grid-cols-[minmax(0,1.3fr)_minmax(0,0.8fr)_auto] sm:items-center">
                    <div>
                      <.link
                        navigate={~p"/admin/patients/#{match.note.patient_id}"}
                        class="font-semibold text-slate-900 hover:text-brand-accent hover:underline"
                      >
                        {patient_name(match.note.patient)}
                      </.link>
                      <p class="mt-1 text-xs text-slate-500">
                        {match.age || "Age unknown"} · {match.note.patient.gender || "Sex unknown"}
                      </p>
                    </div>
                    <div class="text-sm text-slate-600">
                      <p>{format_date(match.note.date)}</p>
                      <p class="mt-1 text-xs text-slate-500">
                        Dr. {if match.note.doctor, do: match.note.doctor.name, else: "Unknown"}
                      </p>
                    </div>
                    <span class="justify-self-start rounded-full bg-brand-50 px-3 py-1 text-sm font-bold text-brand-primary sm:justify-self-end">
                      {match.occurrence_count} occurrence{if match.occurrence_count == 1,
                        do: "",
                        else: "s"}
                    </span>
                  </summary>
                  <div class="space-y-3 border-t border-slate-100 bg-slate-50/70 px-5 py-4">
                    <div
                      :for={field <- match.field_matches}
                      class="rounded-lg border border-slate-200 bg-white p-3"
                    >
                      <div class="flex items-center justify-between gap-3">
                        <p class="text-xs font-bold uppercase tracking-wide text-slate-500">
                          {field.label}
                        </p>
                        <span class="text-xs font-semibold text-brand-accent">
                          {field.count} found
                        </span>
                      </div>
                      <p class="mt-2 text-sm leading-6 text-slate-700">{field.snippet}</p>
                    </div>
                  </div>
                </details>
              </div>
            </section>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :value, :integer, required: true
  attr :detail, :string, required: true

  defp metric_card(assigns) do
    ~H"""
    <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
      <p class="text-xs font-bold uppercase tracking-wide text-slate-500">{@label}</p>
      <p class="mt-2 text-3xl font-bold tracking-tight text-slate-900">{@value}</p>
      <p class="mt-1 text-sm text-slate-500">{@detail}</p>
    </div>
    """
  end
end
