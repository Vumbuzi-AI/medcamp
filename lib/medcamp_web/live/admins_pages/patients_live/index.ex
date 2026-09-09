defmodule MedcampWeb.AdminPatientsLive.Index do
  use MedcampWeb, :admin_live_view

  alias Medcamp.Patients

  @per_page 10

  @default_filters %{
    search: "",
    date_from: nil,
    date_to: nil,
    gender: nil,
    age_group: nil
  }

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :patients)
     |> assign(:filters, @default_filters)
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> load_patients()}
  end

  def handle_event("apply_filters", %{"filters" => filters}, socket) do
    filters = Map.merge(stringify_filters(socket.assigns.filters), filters)

    filters = %{
      search: normalize_blank(filters["search"]),
      date_from: normalize_blank(filters["date_from"]),
      date_to: normalize_blank(filters["date_to"]),
      gender: normalize_blank(filters["gender"]),
      age_group: normalize_blank(filters["age_group"])
    }

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign(:page, 1)
     |> load_patients()}
  end

  def handle_event("clear_filters", _params, socket) do
    {:noreply,
     socket
     |> assign(:filters, @default_filters)
     |> assign(:page, 1)
     |> load_patients()}
  end

  def handle_event("clear_chip", %{"field" => field}, socket) do
    handle_event("apply_filters", %{"filters" => %{field => ""}}, socket)
  end

  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply, socket |> assign(:page, max(1, String.to_integer(page))) |> load_patients()}
  end

  def handle_event("update_pin", %{"pin" => pin, "patient_id" => patient_id}, socket) do
    patient = Patients.get_patient!(patient_id)

    pin = String.to_integer(pin)

    case Patients.update_patient(patient, %{"pin" => pin}) do
      {:ok, _patient} ->
        {:noreply,
         socket
         |> put_flash(:info, "Patient PIN updated successfully.")}

      {:error, changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to update patient PIN: #{changeset.errors[:pin]}")}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-slate-100 p-4">
      <.page_header
        icon_path="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
        title="Patients"
        subtitle="Search, filter and manage registered patients."
      />

      <div class="flex flex-wrap items-center gap-3 mb-4">
        <form phx-change="apply_filters" class="flex-1">
          <.search_input
            name="filters[search]"
            value={@filters.search}
            placeholder="Search by name, phone, ID, or GSRN"
          />
        </form>

        <.camp_switcher camps={assigns[:camp_options] || []} camp_filter={assigns[:camp_filter]} />

        <.filter_drawer
          id="patients-filters"
          title="Filter patients"
          apply_event="apply_filters"
          active_count={count_active_filters(@filters)}
        >
          <:group label="Date Range">
            <.date_range_fields
              from_name="filters[date_from]"
              to_name="filters[date_to]"
              from_value={@filters.date_from}
              to_value={@filters.date_to}
              from_label="Registered From"
              to_label="Registered To"
            />
          </:group>

          <:group label="Patient Details">
            <.age_gender_fields
              age_group_value={@filters.age_group || ""}
              gender_value={@filters.gender || ""}
            />
          </:group>

          <:chip
            :for={chip <- filter_chips(@filters)}
            label={chip.label}
            clear={JS.push("clear_chip", value: %{"field" => chip.field})}
          />
        </.filter_drawer>
      </div>

      <.admin_patients_table
        patients={@patients}
        page={@page}
        total_pages={@total_pages}
        total_count={@total_count}
        per_page={@per_page}
        filters_active={@filters.search != "" or count_active_filters(@filters) > 0}
      />
    </div>
    """
  end

  defp load_patients(socket) do
    filters = socket.assigns.filters
    per_page = socket.assigns.per_page
    page = socket.assigns.page

    total_count = Patients.count_patients(filters)
    total_pages = Medcamp.Pagination.total_pages(total_count, per_page)
    page = min(max(1, page), total_pages)
    patients = Patients.filter_patients_paginated(filters, page, per_page)

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:patients, patients)
  end

  defp normalize_blank(nil), do: nil
  defp normalize_blank(""), do: nil
  defp normalize_blank(value), do: value

  # The search box and the filter drawer submit independently (two separate
  # <form>s), so a submission from either one only carries its own fields.
  # Merging onto a stringified version of the current filters means a key
  # absent from this submission is left unchanged rather than reset.
  defp stringify_filters(filters) do
    Map.new(filters, fn {key, value} -> {Atom.to_string(key), value || ""} end)
  end

  defp count_active_filters(filters) do
    filters
    |> Map.drop([:search])
    |> Map.values()
    |> Enum.count(&(&1 not in [nil, ""]))
  end

  defp filter_chips(filters) do
    [
      filter_chip(filters.date_from, "date_from", "From #{filters.date_from}"),
      filter_chip(filters.date_to, "date_to", "To #{filters.date_to}"),
      filter_chip(filters.gender, "gender", filters.gender),
      filter_chip(filters.age_group, "age_group", filters.age_group)
    ]
    |> Enum.reject(&is_nil/1)
  end
end
