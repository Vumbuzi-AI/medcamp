defmodule MedcampWeb.AdminLabTestLive.Index do
  use MedcampWeb, :admin_live_view

  alias Medcamp.LabTests
  alias Medcamp.LabTests.LabTest

  @per_page 10

  @default_filters %{search: "", date_from: nil, date_to: nil, subsidy: nil}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :lab_tests)
     |> assign(:filters, @default_filters)
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> load_lab_tests()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  # The search box and the filter drawer submit independently (two separate
  # <form>s), so a submission from either one only carries its own fields.
  # Merging onto a stringified version of the current filters means a key
  # absent from this submission is left unchanged rather than reset.
  defp stringify_filters(filters), do: Map.new(filters, fn {k, v} -> {Atom.to_string(k), v} end)

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
      filter_chip(filters.subsidy, "subsidy", subsidy_label(filters.subsidy))
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp subsidy_label("subsidized"), do: "Subsidized"
  defp subsidy_label("standard"), do: "Standard"
  defp subsidy_label(other), do: other

  @impl true
  def handle_event("apply_filters", %{"filters" => filters}, socket) do
    filters = Map.merge(stringify_filters(socket.assigns.filters), filters)

    filters = %{
      search: filters["search"] || "",
      date_from: filters["date_from"] || nil,
      date_to: filters["date_to"] || nil,
      subsidy: filters["subsidy"] || nil
    }

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign(:page, 1)
     |> load_lab_tests()}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply,
     socket
     |> assign(:filters, @default_filters)
     |> assign(:page, 1)
     |> load_lab_tests()}
  end

  @impl true
  def handle_event("clear_chip", %{"field" => field}, socket) do
    handle_event("apply_filters", %{"filters" => %{field => ""}}, socket)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    lab_test = LabTests.get_lab_test!(id)
    {:ok, _} = LabTests.delete_lab_test(lab_test)

    {:noreply, load_lab_tests(socket)}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply, socket |> assign(:page, max(1, String.to_integer(page))) |> load_lab_tests()}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Lab test")
    |> assign(:lab_test, LabTests.get_lab_test!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Lab test")
    |> assign(:lab_test, %LabTest{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Lab Tests")
    |> assign(:lab_test, nil)
  end

  defp load_lab_tests(socket) do
    filters = socket.assigns.filters
    per_page = socket.assigns.per_page
    page = socket.assigns.page

    total_count = LabTests.count_lab_tests(filters)
    total_pages = Medcamp.Pagination.total_pages(total_count, per_page)
    page = min(max(1, page), total_pages)
    lab_tests = LabTests.filter_lab_tests_paginated(filters, page, per_page)

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:lab_tests, lab_tests)
  end
end
