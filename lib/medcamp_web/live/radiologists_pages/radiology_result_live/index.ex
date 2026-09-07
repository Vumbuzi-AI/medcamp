defmodule MedcampWeb.RadiologistPages.RadiologyResultLive.Index do
  use MedcampWeb, :radiologist_live_view

  alias Medcamp.RadiologyResults
  alias Medcamp.RadiologyResults.RadiologyResult

  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :radiology_results)
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> assign(:total_count, 0)
     |> assign(:total_pages, 0)
     |> assign(:filters, %{"search" => "", "urgency" => "", "report_complete" => ""})
     |> assign_radiology_results(1)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Radiology result")
    |> assign(:radiology_result, RadiologyResults.get_radiology_result!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Radiology result")
    |> assign(:radiology_result, %RadiologyResult{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Radiology results")
    |> assign(:radiology_result, nil)
  end

  @impl true
  def handle_info(
        {MedcampWeb.RadiologyResultLive.FormComponent, {:saved, _radiology_result}},
        socket
      ) do
    {:noreply, assign_radiology_results(socket, socket.assigns.page)}
  end

  @impl true
  def handle_event("search", %{"search" => query}, socket) do
    filters = Map.put(socket.assigns.filters, "search", query)

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign_radiology_results(1)}
  end

  @impl true
  def handle_event("filter", %{"filters" => filter_params}, socket) do
    filters =
      socket.assigns.filters
      |> Map.put("urgency", filter_params["urgency"] || "")
      |> Map.put("report_complete", filter_params["report_complete"] || "")

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign_radiology_results(1)}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    filters = Map.merge(socket.assigns.filters, %{"urgency" => "", "report_complete" => ""})

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign_radiology_results(1)}
  end

  @impl true
  def handle_event("clear_chip", %{"field" => field}, socket) do
    filters = Map.put(socket.assigns.filters, field, "")

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign_radiology_results(1)}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply, assign_radiology_results(socket, page)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    radiology_result = RadiologyResults.get_radiology_result!(id)
    {:ok, _} = RadiologyResults.delete_radiology_result(radiology_result)

    {:noreply, assign_radiology_results(socket, socket.assigns.page)}
  end

  defp assign_radiology_results(socket, page) do
    page = normalize_page(page)
    filters = socket.assigns.filters
    total_count = RadiologyResults.count_radiology_results(filters)
    total_pages = max(1, div(total_count + @per_page - 1, @per_page))
    page = min(page, total_pages)

    radiology_results =
      RadiologyResults.list_radiology_results_paginated(page, @per_page, filters)

    socket
    |> assign(:page, page)
    |> assign(:per_page, @per_page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:radiology_results, radiology_results)
  end

  defp normalize_page(page) when is_binary(page) do
    case Integer.parse(page) do
      {value, _} when value > 0 -> value
      _ -> 1
    end
  end

  defp normalize_page(page) when is_integer(page) and page > 0, do: page
  defp normalize_page(_), do: 1

  defp count_active_filters(filters) do
    [filters["urgency"] != "", filters["report_complete"] != ""]
    |> Enum.count(& &1)
  end

  defp filter_chips(filters) do
    [
      filter_chip(filters["urgency"], "urgency", filters["urgency"]),
      filter_chip(
        filters["report_complete"],
        "report_complete",
        report_complete_label(filters["report_complete"])
      )
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp report_complete_label("true"), do: "Complete"
  defp report_complete_label("false"), do: "Pending"
  defp report_complete_label(other), do: other
end
