defmodule MedcampWeb.NursesPages.TriageIndex do
  use MedcampWeb, :nurse_live_view

  alias Medcamp.Triages
  alias Medcamp.Triages.Triage

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :triages)
     |> assign(:filters, default_filters())
     |> assign_triages(Triages.list_triages())}
  end

  defp default_filters do
    %{
      search: "",
      date_from: "",
      date_to: "",
      time_from: "",
      time_to: "",
      age_group: nil,
      gender: nil,
      diagnosis: "",
      visit_type: nil
    }
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"triage_id" => id}) do
    socket
    |> assign(:page_title, "Edit Triage")
    |> assign(:triage, Triages.get_triage!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Triage")
    |> assign(:triage, %Triage{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Triages")
    |> assign(:triage, nil)
  end

  # The search box and the filter drawer submit independently (two separate
  # <form>s), so a submission from either one only carries its own fields.
  # Merging onto the stringified current filters means a key absent from
  # this submission is left unchanged rather than reset.
  defp stringify_filters(filters) do
    Map.new(filters, fn {key, value} -> {Atom.to_string(key), value || ""} end)
  end

  @impl true
  def handle_event("filter", %{"filters" => filters}, socket) do
    filters = Map.merge(stringify_filters(socket.assigns.filters), filters)

    filter_params = %{
      search: filters["search"] || "",
      date_from: parse_date(filters["date_from"]),
      date_to: parse_date(filters["date_to"]),
      time_from: parse_time(filters["time_from"]),
      time_to: parse_time(filters["time_to"]),
      age_group: empty_to_nil(filters["age_group"]),
      gender: empty_to_nil(filters["gender"]),
      diagnosis: empty_to_nil(filters["diagnosis"]),
      visit_type: empty_to_nil(filters["visit_type"])
    }

    display_filters = %{
      search: filters["search"] || "",
      date_from: filters["date_from"] || "",
      date_to: filters["date_to"] || "",
      time_from: filters["time_from"] || "",
      time_to: filters["time_to"] || "",
      age_group: filter_params.age_group,
      gender: filter_params.gender,
      diagnosis: filters["diagnosis"] || "",
      visit_type: filter_params.visit_type
    }

    triages = Triages.filter_triages(filter_params)

    {:noreply,
     socket
     |> assign(:filters, display_filters)
     |> assign_triages(triages)}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply,
     socket
     |> assign(:filters, default_filters())
     |> assign_triages(Triages.list_triages())}
  end

  @impl true
  def handle_event("clear_chip", %{"field" => field}, socket) do
    handle_event("filter", %{"filters" => %{field => ""}}, socket)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    triage = Triages.get_triage!(id)
    {:ok, _} = Triages.delete_triage(triage)

    {:noreply,
     socket
     |> assign(:triages_count, socket.assigns.triages_count - 1)
     |> assign(:triages, Enum.reject(socket.assigns.triages, &(&1.id == triage.id)))}
  end

  # The triages table is expandable, so it renders its rows eagerly rather than
  # under `phx-update="stream"`. It must be fed a plain list assign — a stream
  # would render empty on the first re-render that isn't a reset.
  defp assign_triages(socket, triages) do
    socket
    |> assign(:triages_count, length(triages))
    |> assign(:triages, triages)
  end

  defp empty_to_nil(""), do: nil
  defp empty_to_nil(nil), do: nil
  defp empty_to_nil(v), do: v

  defp parse_date(""), do: nil
  defp parse_date(nil), do: nil

  defp parse_date(s) do
    case Date.from_iso8601(s) do
      {:ok, d} -> d
      _ -> nil
    end
  end

  defp parse_time(""), do: nil
  defp parse_time(nil), do: nil

  defp parse_time(s) do
    case Time.from_iso8601(s <> ":00") do
      {:ok, t} -> t
      _ -> nil
    end
  end

  defp count_active_filters(filters) do
    filters
    |> Map.take([
      :date_from,
      :date_to,
      :time_from,
      :time_to,
      :age_group,
      :gender,
      :diagnosis,
      :visit_type
    ])
    |> Map.values()
    |> Enum.count(&(&1 not in [nil, ""]))
  end

  @visit_type_labels [
    {"inpatient", "Inpatient"},
    {"outpatient", "Outpatient"},
    {"MCH", "MCH"},
    {"referral in", "Referral In"},
    {"referral out", "Referral Out"}
  ]

  defp filter_chips(filters) do
    [
      filter_chip(filters[:date_from], "date_from", "From #{filters[:date_from]}"),
      filter_chip(filters[:date_to], "date_to", "To #{filters[:date_to]}"),
      filter_chip(filters[:time_from], "time_from", "From #{filters[:time_from]}"),
      filter_chip(filters[:time_to], "time_to", "To #{filters[:time_to]}"),
      filter_chip(filters[:age_group], "age_group", filters[:age_group]),
      filter_chip(filters[:gender], "gender", filters[:gender]),
      filter_chip(filters[:diagnosis], "diagnosis", filters[:diagnosis]),
      filter_chip(filters[:visit_type], "visit_type", visit_type_label(filters[:visit_type]))
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp visit_type_label(nil), do: nil

  defp visit_type_label(value) do
    case Enum.find(@visit_type_labels, fn {v, _label} -> v == value end) do
      {_v, label} -> label
      nil -> value
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-[100%]">
      <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-4 mb-4">
        <.page_header
          icon_path="M16 8v8m-4-5v5m-4-2v2m-2 4h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"
          title="Triages"
          subtitle="Search, filter and manage triage records."
        />

        <div class="flex flex-wrap items-center gap-3">
          <form phx-change="filter" class="flex-1">
            <.search_input
              name="filters[search]"
              value={@filters[:search] || ""}
              placeholder="Search by patient name, email, or GSRN"
            />
          </form>

          <.filter_drawer
            id="triage-filters"
            title="Filter triages"
            apply_event="filter"
            active_count={count_active_filters(@filters)}
          >
            <:group label="Date and Time">
              <.date_range_fields
                from_name="filters[date_from]"
                to_name="filters[date_to]"
                from_value={@filters[:date_from] || ""}
                to_value={@filters[:date_to] || ""}
              />
              <.time_range_fields
                from_name="filters[time_from]"
                to_name="filters[time_to]"
                from_value={@filters[:time_from] || ""}
                to_value={@filters[:time_to] || ""}
              />
            </:group>

            <:group label="Patient Details">
              <.age_gender_fields
                age_group_value={@filters[:age_group] || ""}
                gender_value={@filters[:gender] || ""}
              />
            </:group>

            <:group label="Visit Details">
              <.diagnosis_visit_type_fields
                diagnosis_value={@filters[:diagnosis] || ""}
                visit_type_value={@filters[:visit_type] || ""}
              />
            </:group>

            <:chip
              :for={chip <- filter_chips(@filters)}
              label={chip.label}
              clear={JS.push("clear_chip", value: %{"field" => chip.field})}
            />
          </.filter_drawer>
        </div>
      </div>

      <.triages_table
        show_header={false}
        route_prefix="/nurse/triages"
        new_triage_url="/nurse/triages/new"
        triages={@triages}
        count={@triages_count}
        show_new_link={false}
        show_clear_filters={(@filters[:search] || "") != "" or count_active_filters(@filters) > 0}
      />

      <.modal
        :if={@live_action in [:new, :edit]}
        id="triage-modal"
        show
        on_cancel={JS.patch("/nurse/triages")}
      >
        <.live_component
          module={MedcampWeb.NursesPage.TriageFormComponent}
          id={@triage.id || :new}
          title={@page_title}
          selected_patient={nil}
          current_user={@current_user}
          action={@live_action}
          triage={@triage}
          patch="/nurse/triages"
        />
      </.modal>
    </div>
    """
  end
end
