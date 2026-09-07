defmodule MedcampWeb.NurseProcedureLive.Index do
  use MedcampWeb, :nurse_live_view

  alias Medcamp.NurseProcedures
  alias Medcamp.NurseProcedures.NurseProcedure

  @default_filters %{"status" => "", "payment_type" => ""}
  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :nurse_procedures)
     |> assign(:search, "")
     |> assign(:filters, @default_filters)
     |> assign(:payment_types, NurseProcedures.list_distinct_payment_types())
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> load_nurse_procedures()}
  end

  defp load_nurse_procedures(socket) do
    nurse_id = socket.assigns.current_user.id

    query_filters = %{
      search: socket.assigns.search,
      status: socket.assigns.filters["status"],
      payment_type: socket.assigns.filters["payment_type"]
    }

    total_count = NurseProcedures.count_nurse_procedures_for_nurse(nurse_id, query_filters)
    total_pages = Medcamp.Pagination.total_pages(total_count, socket.assigns.per_page)
    page = min(max(1, socket.assigns.page || 1), total_pages)

    nurse_procedures =
      NurseProcedures.list_nurse_procedures_for_nurse_paginated(
        nurse_id,
        query_filters,
        page,
        socket.assigns.per_page
      )

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:nurse_procedures, nurse_procedures)
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Nurse procedure")
    |> assign(:nurse_procedure, NurseProcedures.get_nurse_procedure!(id))
  end

  defp apply_action(socket, :trigger_payment, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Nurse procedure")
    |> assign(:nurse_procedure, NurseProcedures.get_nurse_procedure!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Nurse procedure")
    |> assign(:nurse_procedure, %NurseProcedure{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Nurse procedures")
    |> assign(:nurse_procedure, nil)
  end

  @impl true
  def handle_info({MedcampWeb.NurseProcedureLive.FormComponent, {:saved, _nurse_procedure}}, socket) do
    {:noreply, load_nurse_procedures(socket)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    nurse_procedure = NurseProcedures.get_nurse_procedure!(id)
    {:ok, _} = NurseProcedures.delete_nurse_procedure(nurse_procedure)

    {:noreply,
     socket
     |> put_flash(:info, "Nurse procedure deleted successfully")
     |> load_nurse_procedures()}
  end

  @impl true
  def handle_event("search", %{"search" => term}, socket) do
    {:noreply,
     socket
     |> assign(:search, term)
     |> assign(:page, 1)
     |> load_nurse_procedures()}
  end

  @impl true
  def handle_event("apply_filters", %{"filters" => filters}, socket) do
    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign(:page, 1)
     |> load_nurse_procedures()}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply,
     socket
     |> assign(:filters, @default_filters)
     |> assign(:search, "")
     |> assign(:page, 1)
     |> load_nurse_procedures()}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, max(1, String.to_integer(page)))
     |> load_nurse_procedures()}
  end

  @impl true
  def handle_event("clear_chip", %{"field" => field}, socket) do
    filters = Map.put(socket.assigns.filters, field, "")

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign(:page, 1)
     |> load_nurse_procedures()}
  end

  defp count_active_filters(filters) do
    filters
    |> Map.values()
    |> Enum.count(&(&1 not in [nil, ""]))
  end

  defp filter_chips(filters) do
    [
      filter_chip(filters["status"], "status", status_chip_label(filters["status"])),
      filter_chip(filters["payment_type"], "payment_type", filters["payment_type"])
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp status_chip_label("paid"), do: "Paid"
  defp status_chip_label("not_paid"), do: "Not Paid"
  defp status_chip_label(other), do: other
end
