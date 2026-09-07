defmodule MedcampWeb.NursesPages.AllNurseProcedureIndex do
  use MedcampWeb, :nurse_live_view

  alias Medcamp.Procedures

  @impl true
  def mount(_params, _session, socket) do
    procedure_collection = Procedures.list_procedure()

    {:ok,
     socket
     |> assign(:active_tab, :all_procedures)
     |> assign(:search, "")
     |> assign(:procedure_collection_count, length(procedure_collection))
     |> stream(:procedure_collection, procedure_collection)}
  end

  @impl true
  def handle_event("search", %{"search" => term}, socket) do
    procedure_collection = Procedures.filter_procedures(%{search: term})

    {:noreply,
     socket
     |> assign(:search, term)
     |> assign(:procedure_collection_count, length(procedure_collection))
     |> stream(:procedure_collection, procedure_collection, reset: true)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-4">
      <.page_header
        icon_path="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"
        title="All Procedures"
        subtitle="Search all procedures available to nurses."
      />

      <form phx-change="search" class="mb-4">
        <.search_input name="search" value={@search} placeholder="Search by name" />
      </form>

      <%= if @procedure_collection_count == 0 do %>
        <.blank_state
          icon_path="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"
          title="No procedures"
          description={
            if @search != "",
              do: "No procedures match the current search.",
              else: "No procedures have been added yet."
          }
        />
      <% else %>
        <.table id="procedure" rows={@streams.procedure_collection}>
          <:col :let={{_id, procedure}} label="Name">
            <div class="flex items-center py-3">
              <div class="h-8 w-8 rounded-full bg-[#e7e7ff] flex items-center justify-center text-[#373896] font-medium mr-2 text-sm">
                {String.first(procedure.name || "")}
              </div>
              <span class="font-medium text-gray-900">
                {procedure.name}
              </span>
            </div>
          </:col>

          <:col :let={{_id, procedure}} label="Price">
            <div class="flex items-center py-3">
              <span class="font-medium text-gray-900">
                KES {procedure.price} /=
              </span>
            </div>
          </:col>

          <:col :let={{_id, procedure}} label="Description">
            <div class="max-w-xs py-3">
              <span class="text-gray-700 line-clamp-2">{procedure.description}</span>
            </div>
          </:col>
        </.table>
      <% end %>
    </div>
    """
  end
end
