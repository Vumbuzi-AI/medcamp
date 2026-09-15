defmodule MedcampWeb.LabPagesLabTestLive.Index do
  use MedcampWeb, :lab_live_view

  alias Medcamp.LabTests
  alias Medcamp.Pagination

  @per_page 10

  @impl true
  def mount(_, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :lab_tests)
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> load_lab_tests()}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply, socket |> assign(:page, Pagination.normalize_page(page)) |> load_lab_tests()}
  end

  defp load_lab_tests(socket) do
    per_page = socket.assigns.per_page
    total_count = LabTests.count_lab_tests(%{})
    total_pages = Pagination.total_pages(total_count, per_page)
    page = Pagination.clamp_page(socket.assigns.page, total_pages)
    lab_tests = LabTests.filter_lab_tests_paginated(%{}, page, per_page)

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> stream(:lab_tests, lab_tests, reset: true)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-slate-100 p-4">
      <.page_header
        icon_path="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
        title="Lab Tests"
        subtitle="Browse configured lab tests and pricing."
      />

      <.blank_state
        :if={@total_count == 0}
        icon_path="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
        title="No lab tests found"
        description="No lab tests have been configured yet."
      />

      <.data_table :if={@total_count > 0} id="lab_tests" rows={@streams.lab_tests}>
        <:col :let={{_id, lab_test}} label="Name">{lab_test.name}</:col>
        <:col :let={{_id, lab_test}} label="Description">{lab_test.description}</:col>
        <:col :let={{_id, lab_test}} label="Price">{lab_test.price}</:col>

        <:footer>
          <.pagination
            page={@page}
            total_pages={@total_pages}
            total_count={@total_count}
            per_page={@per_page}
          />
        </:footer>
      </.data_table>
    </div>
    """
  end
end
