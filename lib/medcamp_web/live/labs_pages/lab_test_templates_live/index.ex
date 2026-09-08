defmodule MedcampWeb.LabPagesLabTestTemplateLive.Index do
  use MedcampWeb, :lab_live_view

  alias Medcamp.LabTestTemplates
  alias Medcamp.LabTestTemplates.LabTestTemplate

  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :lab_test_templates)
     |> assign(:search_query, "")
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> stream_templates()}
  end

  defp stream_templates(socket) do
    query = String.trim(socket.assigns.search_query || "")

    all_templates =
      if query == "" do
        LabTestTemplates.list_templates()
      else
        LabTestTemplates.search_templates(query)
      end

    total_count = length(all_templates)
    total_pages = Medcamp.Pagination.total_pages(total_count, socket.assigns.per_page)
    page = min(max(1, socket.assigns.page || 1), total_pages)

    templates =
      Enum.slice(all_templates, (page - 1) * socket.assigns.per_page, socket.assigns.per_page)

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> stream(:templates, templates, reset: true)
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Template")
    |> assign(:template, LabTestTemplates.get_template!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Template")
    |> assign(:template, %LabTestTemplate{field_definitions: []})
  end

  defp apply_action(socket, :preview, %{"id" => id}) do
    socket
    |> assign(:page_title, "Preview Template")
    |> assign(:template, LabTestTemplates.get_template!(id))
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Lab Test Templates")
    |> assign(:template, nil)
  end

  @impl true
  def handle_info(
        {MedcampWeb.LabPagesLabTestTemplateLive.FormComponent, {:saved, _template}},
        socket
      ) do
    {:noreply, stream_templates(socket)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    template = LabTestTemplates.get_template!(id)
    {:ok, _} = LabTestTemplates.delete_template(template)

    {:noreply, stream_templates(socket)}
  end

  def handle_event("search", %{"query" => query}, socket) do
    {:noreply,
     socket
     |> assign(:search_query, query)
     |> assign(:page, 1)
     |> stream_templates()}
  end

  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, max(1, String.to_integer(page)))
     |> stream_templates()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-100">
      <.header class="p-6 border-b border-gray-100">
        <div class="flex items-center">
          <div class="w-12 h-12 rounded-xl bg-gradient-to-br from-brand-accent to-[#8384c9] flex items-center justify-center mr-4">
            <svg class="w-6 h-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
              />
            </svg>
          </div>
          <div>
            <h1 class="text-2xl font-bold text-brand-primary">Lab Test Templates</h1>
            <p class="text-sm text-gray-600 mt-1">Manage laboratory test templates and parameters</p>
          </div>
        </div>
        <:actions>
          <.link patch={~p"/lab/lab_test_templates/new"}>
            <.button class="bg-brand-accent flex gap-1 items-center hover:bg-brand-accent-dark">
              <svg
                class="w-5 h-5 mr-2"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
                stroke-width="2"
              >
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4" />
              </svg>
              New Template
            </.button>
          </.link>
        </:actions>
      </.header>

      <div class="p-6">
        <form phx-change="search" phx-submit="search" class="mb-6">
          <div class="relative">
            <svg
              class="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-gray-400"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
              />
            </svg>
            <input
              type="text"
              name="query"
              value={@search_query}
              placeholder="Search templates by name or short name (e.g., FBC, HIV, Urinalysis)..."
              class="block w-full pl-10 pr-4 py-2.5 border border-gray-300 rounded-lg focus:ring-brand-accent focus:border-brand-accent"
              phx-debounce="300"
            />
          </div>
        </form>

        <%= if @total_count == 0 do %>
          <div class="text-center py-12 bg-gray-50 rounded-lg border border-dashed border-gray-300">
            <svg
              class="mx-auto h-16 w-16 text-gray-400"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
              />
            </svg>
            <h3 class="mt-4 text-lg font-medium text-gray-900">No templates yet</h3>
            <p class="mt-2 text-sm text-gray-500">Get started by creating a new test template.</p>
            <div class="mt-6">
              <.link patch={~p"/lab/lab_test_templates/new"}>
                <.button class="bg-brand-accent hover:bg-brand-accent-dark">
                  <svg class="w-5 h-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M12 4v16m8-8H4"
                    />
                  </svg>
                  Create Template
                </.button>
              </.link>
            </div>
          </div>
        <% else %>
          <!-- Desktop View -->
          <div class="hidden lg:block overflow-hidden rounded-xl border border-gray-200">
            <table class="min-w-full divide-y divide-gray-200">
              <thead class="bg-gray-50">
                <tr>
                  <th class="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
                    Template Name
                  </th>
                  <th class="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
                    Short Name
                  </th>
                  <th class="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
                    Category
                  </th>
                  <th class="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
                    Parameters
                  </th>
                  <th class="px-6 py-4 text-right text-xs font-semibold text-gray-600 uppercase tracking-wider">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody id="templates" phx-update="stream" class="bg-white divide-y divide-gray-100">
                <tr
                  :for={{id, template} <- @streams.templates}
                  id={id}
                  class="hover:bg-gray-50 transition-colors"
                >
                  <td class="px-6 py-4">
                    <div class="flex items-center">
                      <div class="w-10 h-10 rounded-lg bg-brand-accent/10 flex items-center justify-center mr-3">
                        <svg
                          class="w-5 h-5 text-brand-accent"
                          fill="none"
                          viewBox="0 0 24 24"
                          stroke="currentColor"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                          />
                        </svg>
                      </div>
                      <div>
                        <div class="text-sm font-medium text-gray-900">{template.name}</div>
                      </div>
                    </div>
                  </td>
                  <td class="px-6 py-4">
                    <span class="px-2.5 py-1 text-xs font-medium rounded-full bg-blue-100 text-blue-800">
                      {template.short_name}
                    </span>
                  </td>
                  <td class="px-6 py-4">
                    <span class="text-sm text-gray-700">
                      {template.category && template.category.name}
                    </span>
                  </td>
                  <td class="px-6 py-4">
                    <div class="flex items-center">
                      <svg
                        class="w-4 h-4 text-gray-400 mr-2"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z"
                        />
                      </svg>
                      <span class="text-sm text-gray-600">
                        {length(template.field_definitions)} fields
                      </span>
                    </div>
                  </td>
                  <td class="px-6 py-4 text-right">
                    <div class="flex items-center justify-end gap-2">
                      <.link
                        patch={~p"/lab/lab_test_templates/#{template}/preview"}
                        class="inline-flex items-center px-3 py-1.5 text-sm font-medium text-emerald-700 bg-emerald-50 rounded-lg hover:bg-emerald-100 transition-colors"
                      >
                        <svg
                          class="w-4 h-4 mr-1"
                          fill="none"
                          viewBox="0 0 24 24"
                          stroke="currentColor"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                          />
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"
                          />
                        </svg>
                        Preview
                      </.link>
                      <.link
                        patch={~p"/lab/lab_test_templates/#{template}/edit"}
                        class="inline-flex items-center px-3 py-1.5 text-sm font-medium text-brand-accent bg-brand-accent/10 rounded-lg hover:bg-brand-accent/20 transition-colors"
                      >
                        <svg
                          class="w-4 h-4 mr-1"
                          fill="none"
                          viewBox="0 0 24 24"
                          stroke="currentColor"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
                          />
                        </svg>
                        Edit
                      </.link>
                      <.link
                        phx-click={JS.push("delete", value: %{id: template.id}) |> hide("##{id}")}
                        data-confirm="Are you sure you want to delete this template?"
                        class="inline-flex items-center px-3 py-1.5 text-sm font-medium text-red-600 bg-red-50 rounded-lg hover:bg-red-100 transition-colors"
                      >
                        <svg
                          class="w-4 h-4 mr-1"
                          fill="none"
                          viewBox="0 0 24 24"
                          stroke="currentColor"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                          />
                        </svg>
                        Delete
                      </.link>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          
    <!-- Mobile View -->
          <div class="lg:hidden space-y-4">
            <div
              :for={{id, template} <- @streams.templates}
              id={id}
              class="bg-white border border-gray-200 rounded-xl p-4 hover:shadow-md transition-shadow"
            >
              <div class="flex items-start justify-between mb-3">
                <div class="flex items-center flex-1">
                  <div class="w-12 h-12 rounded-xl bg-brand-accent/10 flex items-center justify-center mr-3">
                    <svg
                      class="w-6 h-6 text-brand-accent"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                      />
                    </svg>
                  </div>
                  <div class="flex-1 min-w-0">
                    <h3 class="text-sm font-semibold text-gray-900 truncate">{template.name}</h3>
                    <p class="text-xs text-gray-500 mt-1">
                      {template.category && template.category.name}
                    </p>
                  </div>
                </div>
                <span class="px-2.5 py-1 text-xs font-medium rounded-full bg-blue-100 text-blue-800 ml-2">
                  {template.short_name}
                </span>
              </div>

              <div class="flex items-center text-sm text-gray-600 mb-4">
                <svg
                  class="w-4 h-4 text-gray-400 mr-2"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z"
                  />
                </svg>
                <span>{length(template.field_definitions)} parameters</span>
              </div>

              <div class="flex gap-2">
                <.link
                  patch={~p"/lab/lab_test_templates/#{template}/preview"}
                  class="flex-1 inline-flex items-center justify-center px-3 py-2 text-sm font-medium text-emerald-700 bg-emerald-50 rounded-lg hover:bg-emerald-100 transition-colors"
                >
                  <svg class="w-4 h-4 mr-1.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                    />
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"
                    />
                  </svg>
                  Preview
                </.link>
                <.link
                  patch={~p"/lab/lab_test_templates/#{template}/edit"}
                  class="flex-1 inline-flex items-center justify-center px-3 py-2 text-sm font-medium text-brand-accent bg-brand-accent/10 rounded-lg hover:bg-brand-accent/20 transition-colors"
                >
                  <svg class="w-4 h-4 mr-1.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
                    />
                  </svg>
                  Edit
                </.link>
                <.link
                  phx-click={JS.push("delete", value: %{id: template.id}) |> hide("##{id}")}
                  data-confirm="Are you sure?"
                  class="flex-1 inline-flex items-center justify-center px-3 py-2 text-sm font-medium text-red-600 bg-red-50 rounded-lg hover:bg-red-100 transition-colors"
                >
                  <svg class="w-4 h-4 mr-1.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                    />
                  </svg>
                  Delete
                </.link>
              </div>
            </div>
          </div>
          <.pagination
            page={@page}
            total_pages={@total_pages}
            total_count={@total_count}
            per_page={@per_page}
          />
        <% end %>
      </div>
    </div>

    <.modal
      :if={@live_action in [:new, :edit]}
      id="template-modal"
      show
      on_cancel={JS.patch(~p"/lab/lab_test_templates")}
    >
      <.live_component
        module={MedcampWeb.LabPagesLabTestTemplateLive.FormComponent}
        id={@template.id || :new}
        title={@page_title}
        action={@live_action}
        template={@template}
        patch={~p"/lab/lab_test_templates"}
      />
    </.modal>

    <.modal
      :if={@live_action == :preview}
      id="template-preview-modal"
      show
      on_cancel={JS.patch(~p"/lab/lab_test_templates")}
    >
      <.live_component
        module={MedcampWeb.LabPagesLabTestTemplateLive.PreviewComponent}
        id={{:preview, @template.id}}
        template={@template}
      />
    </.modal>
    """
  end
end
