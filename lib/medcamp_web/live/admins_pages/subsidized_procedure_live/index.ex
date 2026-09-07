defmodule MedcampWeb.SubsidizedProcedureLive.Index do
  use MedcampWeb, :admin_live_view

  alias Medcamp.SubsidizedProcedures
  alias Medcamp.SubsidizedProcedures.SubsidizedProcedure

  @default_filters %{search: ""}
  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :subsidized_procedures)
     |> assign(:filters, @default_filters)
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> load_subsidized_procedures()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("apply_filters", %{"filters" => filters}, socket) do
    filters = %{search: filters["search"] || ""}

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign(:page, 1)
     |> load_subsidized_procedures()}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply,
     socket
     |> assign(:filters, @default_filters)
     |> assign(:page, 1)
     |> load_subsidized_procedures()}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    subsidized_procedure = SubsidizedProcedures.get_subsidized_procedure!(id)
    {:ok, _} = SubsidizedProcedures.delete_subsidized_procedure(subsidized_procedure)

    {:noreply, load_subsidized_procedures(socket)}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket |> assign(:page, max(1, String.to_integer(page))) |> load_subsidized_procedures()}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Subsidized Procedure")
    |> assign(:subsidized_procedure, SubsidizedProcedures.get_subsidized_procedure!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Subsidized Procedure")
    |> assign(:subsidized_procedure, %SubsidizedProcedure{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Subsidized Procedures")
    |> assign(:subsidized_procedure, nil)
  end

  @impl true
  def handle_info(
        {MedcampWeb.SubsidizedProcedureLive.FormComponent, {:saved, _subsidized_procedure}},
        socket
      ) do
    {:noreply, load_subsidized_procedures(socket)}
  end

  defp load_subsidized_procedures(socket) do
    filters = socket.assigns.filters
    per_page = socket.assigns.per_page
    page = socket.assigns.page

    total_count = SubsidizedProcedures.count_subsidized_procedures(filters)
    total_pages = Medcamp.Pagination.total_pages(total_count, per_page)
    page = min(max(1, page), total_pages)

    subsidized_procedures =
      SubsidizedProcedures.filter_subsidized_procedures_paginated(filters, page, per_page)

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:subsidized_procedures, subsidized_procedures)
  end
end
