defmodule MedcampWeb.RadiologyTestLive.Index do
  use MedcampWeb, :admin_live_view

  alias Medcamp.RadiologyTests
  alias Medcamp.RadiologyTests.RadiologyTest

  @default_filters %{search: ""}
  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :radiology_tests)
     |> assign(:filters, @default_filters)
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> load_radiology_tests()}
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
     |> load_radiology_tests()}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply,
     socket
     |> assign(:filters, @default_filters)
     |> assign(:page, 1)
     |> load_radiology_tests()}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    radiology_test = RadiologyTests.get_radiology_test!(id)
    {:ok, _} = RadiologyTests.delete_radiology_test(radiology_test)

    {:noreply, load_radiology_tests(socket)}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply, socket |> assign(:page, max(1, String.to_integer(page))) |> load_radiology_tests()}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Radiology test")
    |> assign(:radiology_test, RadiologyTests.get_radiology_test!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Radiology test")
    |> assign(:radiology_test, %RadiologyTest{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Radiology tests")
    |> assign(:radiology_test, nil)
  end

  @impl true
  def handle_info({MedcampWeb.RadiologyTestLive.FormComponent, {:saved, _radiology_test}}, socket) do
    {:noreply, load_radiology_tests(socket)}
  end

  defp load_radiology_tests(socket) do
    filters = socket.assigns.filters
    per_page = socket.assigns.per_page
    page = socket.assigns.page

    total_count = RadiologyTests.count_radiology_tests(filters)
    total_pages = Medcamp.Pagination.total_pages(total_count, per_page)
    page = min(max(1, page), total_pages)
    radiology_tests = RadiologyTests.filter_radiology_tests_paginated(filters, page, per_page)

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:radiology_tests, radiology_tests)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-4">
      <.page_header
        icon_path="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
        title="Radiology Tests"
        subtitle="Search and manage radiology tests."
      >
        <:actions>
          <.link patch={~p"/admin/radiology_tests/new"}>
            <.button class="bg-[#6667ab] hover:bg-[#5556a0]">New Radiology Test</.button>
          </.link>
        </:actions>
      </.page_header>

      <form phx-change="apply_filters" class="mb-6">
        <.search_input name="filters[search]" value={@filters.search} placeholder="Search by name" />
      </form>

      <.table id="radiology_tests" rows={@radiology_tests}
        row_id={&"radiology_tests-#{&1.id}"}
      >
        <:empty_state>
          <tr>
            <td class="px-6 py-4 text-sm">
              <p class="font-semibold text-gray-900">
                {if @filters.search != "",
                  do: "No radiology tests match the current filters",
                  else: "No radiology tests available"}
              </p>
              <p class="mt-1 text-sm text-gray-400">—</p>
            </td>
            <td class="px-6 py-4 text-sm text-gray-400">—</td>
            <td class="px-6 py-4 text-sm text-gray-400">—</td>
            <td class="px-6 py-4 text-sm text-gray-400">—</td>
          </tr>
        </:empty_state>

        <:col :let={radiology_test} label="Name">{radiology_test.name}</:col>
        <:col :let={radiology_test} label="Description">{radiology_test.description}</:col>
        <:col :let={radiology_test} label="Price">{radiology_test.price}</:col>
        <:action :let={radiology_test}>
          <.link patch={~p"/admin/radiology_tests/#{radiology_test}/edit"}>Edit</.link>
        </:action>
        <:action :let={radiology_test}>
          <.link
            phx-click={JS.push("delete", value: %{id: radiology_test.id}) |> hide("#radiology_tests-#{radiology_test.id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>

      <.pagination
        page={@page}
        total_pages={@total_pages}
        total_count={@total_count}
        per_page={@per_page}
        show_when_empty={true}
      />

      <.modal
        :if={@live_action in [:new, :edit]}
        id="radiology_test-modal"
        show
        on_cancel={JS.patch(~p"/admin/radiology_tests")}
      >
        <.live_component
          module={MedcampWeb.RadiologyTestLive.FormComponent}
          id={@radiology_test.id || :new}
          title={@page_title}
          current_user={@current_user}
          action={@live_action}
          radiology_test={@radiology_test}
          patch={~p"/admin/radiology_tests"}
        />
      </.modal>
    </div>
    """
  end
end
