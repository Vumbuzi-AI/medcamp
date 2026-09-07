defmodule MedcampWeb.ProcedureLive.Index do
  use MedcampWeb, :admin_live_view

  alias Medcamp.Procedures
  alias Medcamp.Procedures.Procedure

  @default_filters %{search: ""}
  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :nurse_procedures)
     |> assign(:filters, @default_filters)
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> assign(:total_count, 0)
     |> assign(:total_pages, 0)
     |> assign_procedures(@default_filters, 1)}
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
     |> assign_procedures(filters, 1)}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply,
     socket
     |> assign(:filters, @default_filters)
     |> assign_procedures(@default_filters, 1)}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply, assign_procedures(socket, socket.assigns.filters, page)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    procedure = Procedures.get_procedure!(id)
    {:ok, _} = Procedures.delete_procedure(procedure)

    {:noreply, assign_procedures(socket, socket.assigns.filters, socket.assigns.page)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Procedure")
    |> assign(:procedure, Procedures.get_procedure!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Procedure")
    |> assign(:procedure, %Procedure{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Procedures")
    |> assign(:procedure, nil)
  end

  @impl true
  def handle_info({MedcampWeb.ProcedureLive.FormComponent, {:saved, _procedure}}, socket) do
    {:noreply, assign_procedures(socket, socket.assigns.filters, socket.assigns.page)}
  end

  defp assign_procedures(socket, filters, page) do
    page = normalize_page(page)
    total_count = Procedures.count_procedures(filters)
    total_pages = max(1, div(total_count + @per_page - 1, @per_page))
    page = min(page, total_pages)

    procedure_collection = Procedures.filter_procedures_paginated(filters, page, @per_page)

    socket
    |> assign(:page, page)
    |> assign(:per_page, @per_page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:procedure_collection, procedure_collection)
  end

  defp normalize_page(page) when is_binary(page) do
    case Integer.parse(page) do
      {value, _} when value > 0 -> value
      _ -> 1
    end
  end

  defp normalize_page(page) when is_integer(page) and page > 0, do: page
  defp normalize_page(_), do: 1
end
