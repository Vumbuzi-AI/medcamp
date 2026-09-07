defmodule MedcampWeb.CostingLive.Index do
  use MedcampWeb, :admin_live_view

  alias Medcamp.Costings
  alias Medcamp.Costings.Costing

  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :costings)
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> load_costings()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Costing")
    |> assign(:costing, Costings.get_costing!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Costing")
    |> assign(:costing, %Costing{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Costings")
    |> assign(:costing, nil)
  end

  @impl true
  def handle_info({MedcampWeb.CostingLive.FormComponent, {:saved, _costing}}, socket) do
    {:noreply, load_costings(socket)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    costing = Costings.get_costing!(id)
    {:ok, _} = Costings.delete_costing(costing)

    {:noreply, load_costings(socket)}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply, socket |> assign(:page, max(1, String.to_integer(page))) |> load_costings()}
  end

  defp load_costings(socket) do
    per_page = socket.assigns.per_page
    page = socket.assigns.page

    total_count = Costings.count_costings()
    total_pages = Medcamp.Pagination.total_pages(total_count, per_page)
    page = min(max(1, page), total_pages)
    costings = Costings.list_costings_paginated(page, per_page)

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:costings, costings)
  end
end
