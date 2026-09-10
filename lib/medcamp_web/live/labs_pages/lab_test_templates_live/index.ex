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
    <div class="bg-white rounded-lg shadow-card border border-slate-200">
      <.header class="p-6 border-b border-slate-200">
        <div class="flex items-center">
          <div class="w-12 h-12 rounded-xl bg-brand-accent flex items-center justify-center mr-4">
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
            <p class="text-sm text-slate-600 mt-1">
              {@total_count} {if @total_count == 1, do: "template", else: "templates"}
            </p>
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
              class="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-slate-400"
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
              class="block w-full pl-10 pr-4 py-2.5 border border-slate-300 rounded-lg focus:ring-brand-accent focus:border-brand-accent"
              phx-debounce="300"
            />
          </div>
        </form>

        <%= if @total_count == 0 do %>
          <div class="text-center py-12 bg-slate-50 rounded-lg border border-dashed border-slate-300">
            <svg
              class="mx-auto h-16 w-16 text-slate-400"
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
            <h3 class="mt-4 text-lg font-medium text-slate-900">No templates yet</h3>
            <p class="mt-2 text-sm text-slate-500">Get started by creating a new test template.</p>
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
          <.data_table id="templates" rows={@streams.templates} row_id={fn {id, _template} -> id end}>
            <:col :let={{_id, template}} label="Template Name">
              <span class="font-medium text-slate-900">{template.name}</span>
            </:col>
            <:col :let={{_id, template}} label="Short Name">
              <span class="inline-flex rounded-full bg-slate-100 px-2.5 py-1 text-xs font-medium text-slate-700">
                {template.short_name}
              </span>
            </:col>
            <:col :let={{_id, template}} label="Category" hide_below="md">
              {template.category && template.category.name}
            </:col>
            <:col :let={{_id, template}} label="Parameters" hide_below="sm">
              <% count = length(template.field_definitions) %>
              {count} {if count == 1, do: "field", else: "fields"}
            </:col>
            <:action :let={{id, template}}>
              <.link
                patch={~p"/lab/lab_test_templates/#{template}/preview"}
                class="text-sm font-medium text-brand-primary hover:underline"
              >
                Preview
              </.link>
              <.link
                patch={~p"/lab/lab_test_templates/#{template}/edit"}
                class="text-sm font-medium text-brand-primary hover:underline"
              >
                Edit
              </.link>
              <.link
                phx-click={JS.push("delete", value: %{id: template.id}) |> hide("##{id}")}
                data-confirm-message="Are you sure you want to delete this template?"
                class="text-sm font-medium text-red-600 hover:underline"
              >
                Delete
              </.link>
            </:action>
            <:footer>
              <.pagination
                page={@page}
                total_pages={@total_pages}
                total_count={@total_count}
                per_page={@per_page}
              />
            </:footer>
          </.data_table>
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
