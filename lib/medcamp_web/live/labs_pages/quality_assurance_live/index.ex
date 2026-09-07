defmodule MedcampWeb.LabPagesQualityAssuranceLive.Index do
  use MedcampWeb, :lab_live_view

  alias Medcamp.QualityAssurance.Chart

  @chart_types Chart.chart_types()

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :quality_assurance)
     |> assign(:chart_types, @chart_types)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Quality Assurance")
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-4">
      <.header class="text-[#373896] border-b border-gray-100 pb-4 mb-4">
        <div class="flex items-center">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-5 w-5 mr-2 text-[#6667ab]"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
            />
          </svg>
          Quality Assurance
        </div>
      </.header>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mt-6">
        <%= for chart_type <- @chart_types do %>
          <.link
            navigate={~p"/lab/quality_assurance/#{chart_type}"}
            class="block p-6 bg-gradient-to-br from-[#e7e7ff] to-[#d4d5f7] rounded-lg hover:from-[#d4d5f7] hover:to-[#c1c2e6] transition-all shadow-sm hover:shadow-md"
          >
            <div class="flex items-center justify-between mb-3">
              <h3 class="text-lg font-semibold text-[#373896]">
                {Chart.chart_type_label(chart_type)}
              </h3>
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-6 w-6 text-[#6667ab]"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M9 5l7 7-7 7"
                />
              </svg>
            </div>
            <p class="text-sm text-gray-600">
              <%= if Chart.is_temperature_chart?(chart_type) do %>
                Monitor temperature readings
              <% else %>
                Track maintenance activities
              <% end %>
            </p>
          </.link>
        <% end %>
      </div>
    </div>
    """
  end
end
