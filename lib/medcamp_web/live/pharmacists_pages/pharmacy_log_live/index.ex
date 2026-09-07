defmodule MedcampWeb.PharmacistsLive.PharmacyLogIndex do
  use MedcampWeb, :pharmacist_live_view

  alias Medcamp.PharmacyLogs.PharmacyLog

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :pharmacy_logs)
     |> assign(:log_types, PharmacyLog.log_types())}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, assign(socket, :page_title, "Temperature & Humidity Logs")}
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
              d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
            />
          </svg>
          Temperature & Humidity Logs
        </div>
      </.header>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mt-6">
        <%= for log_type <- @log_types do %>
          <.link
            navigate={~p"/pharmacist/pharmacy_logs/#{log_type}"}
            class="block p-6 bg-gradient-to-br from-[#e7e7ff] to-[#d4d5f7] rounded-lg hover:from-[#d4d5f7] hover:to-[#c1c2e6] transition-all shadow-sm hover:shadow-md"
          >
            <div class="flex items-center justify-between mb-3">
              <h3 class="text-lg font-semibold text-[#373896]">
                {PharmacyLog.log_type_label(log_type)}
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
              <%= if PharmacyLog.has_humidity?(log_type) do %>
                Monitor temperature & humidity readings
              <% else %>
                Monitor temperature readings
              <% end %>
            </p>
            <p class="text-xs text-gray-500 mt-2 font-medium">
              {PharmacyLog.normal_range(log_type)}
            </p>
          </.link>
        <% end %>
      </div>
    </div>
    """
  end
end
