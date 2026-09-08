defmodule MedcampWeb.AuditLogLive.Show do
  use MedcampWeb, :admin_live_view
  alias Medcamp.Audit

  @impl true

  def mount(params, _session, socket) do
    audit_log = Audit.get_audit_log!(params["id"])

    {:ok,
     socket
     |> assign(:active_tab, :audit_logs)
     |> assign(:audit_log, audit_log)
     |> assign(:patch, ~p"/admin/audit_logs")}
  end

  @impl true

  def render(assigns) do
    ~H"""
    <div>
      <.header class="text-brand-primary border-b border-gray-100 pb-4 mb-6">
        <div class="flex items-center">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-5 w-5 mr-2 text-brand-accent"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
            />
          </svg>
          Audit Log Details
        </div>
      </.header>
      
    <!-- Overview Card -->
      <div class="bg-gradient-to-r from-brand-accent to-brand-primary rounded-lg p-6 mb-6 text-white">
        <div class="flex items-start justify-between">
          <div>
            <div class="flex items-center mb-2">
              <%= case action_badge(@audit_log.action) do %>
                <% {label, emoji} -> %>
                  <span class="text-3xl mr-2">{emoji}</span>
                  <h2 class="text-2xl font-bold">{label}</h2>
              <% end %>
            </div>
            <p class="text-white/80 text-sm">
              {format_table_name(@audit_log.table_name)} • Record ID: {@audit_log.record_id}
            </p>
          </div>
          <div class="text-right">
            <p class="text-xs text-white/60 mb-1">Timestamp</p>
            <p class="text-sm font-medium">
              {Calendar.strftime(@audit_log.inserted_at, "%B %d, %Y")}
            </p>
            <p class="text-sm font-medium">
              {Calendar.strftime(@audit_log.inserted_at, "%I:%M:%S %p")}
            </p>
          </div>
        </div>
      </div>
      
    <!-- User Information -->
      <div class="bg-white border border-gray-200 rounded-lg p-6 mb-6">
        <h3 class="text-lg font-semibold text-gray-900 mb-4 flex items-center">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-5 w-5 mr-2 text-brand-accent"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
            />
          </svg>
          Performed By
        </h3>
        <%= if @audit_log.user do %>
          <div class="flex items-center">
            <div class="flex-shrink-0 h-12 w-12 rounded-full bg-brand-accent flex items-center justify-center text-white font-bold text-lg">
              {String.first(@audit_log.user.email) |> String.upcase()}
            </div>
            <div class="ml-4">
              <p class="text-base font-semibold text-gray-900">{@audit_log.user.email}</p>
              <p class="text-sm text-gray-500">
                Role:
                <span class="font-medium">{String.capitalize(@audit_log.user.role || "N/A")}</span>
              </p>
              <p class="text-xs text-gray-400 mt-1">User ID: {@audit_log.user_id}</p>
            </div>
          </div>
        <% else %>
          <div class="flex items-center text-gray-400">
            <div class="flex-shrink-0 h-12 w-12 rounded-full bg-gray-200 flex items-center justify-center text-gray-500 font-bold text-lg">
              ?
            </div>
            <div class="ml-4">
              <p class="text-base font-semibold">Unknown User</p>
              <p class="text-sm">User information not available</p>
            </div>
          </div>
        <% end %>
      </div>
      
    <!-- Changed Fields (for updates) -->
      <%= if @audit_log.action == "update" && @audit_log.changed_fields && length(@audit_log.changed_fields) > 0 do %>
        <div class="bg-white border border-gray-200 rounded-lg p-6 mb-6">
          <h3 class="text-lg font-semibold text-gray-900 mb-4 flex items-center">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-5 w-5 mr-2 text-brand-accent"
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
            Modified Fields ({length(@audit_log.changed_fields)})
          </h3>
          <div class="flex flex-wrap gap-2">
            <%= for field <- @audit_log.changed_fields do %>
              <span class="px-3 py-1.5 text-sm font-medium bg-purple-100 text-purple-800 rounded-lg">
                {String.replace(field, "_", " ") |> String.capitalize()}
              </span>
            <% end %>
          </div>
        </div>
      <% end %>
      
    <!-- State Comparison (for updates) -->
      <%= if @audit_log.action == "update" && @audit_log.previous_state && @audit_log.new_state do %>
        <div class="bg-white border border-gray-200 rounded-lg p-6 mb-6">
          <h3 class="text-lg font-semibold text-gray-900 mb-4 flex items-center">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-5 w-5 mr-2 text-brand-accent"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4"
              />
            </svg>
            Changes Made
          </h3>

          <div class="space-y-4">
            <%= for field <- @audit_log.changed_fields do %>
              <% field_atom = String.to_existing_atom(field) %>
              <% previous_value =
                Map.get(@audit_log.previous_state, field_atom) ||
                  Map.get(@audit_log.previous_state, field) %>
              <% new_value =
                Map.get(@audit_log.new_state, field_atom) || Map.get(@audit_log.new_state, field) %>
              <div class="border border-gray-200 rounded-lg p-4 bg-gray-50">
                <p class="text-sm font-semibold text-gray-700 mb-2">
                  {String.replace(field, "_", " ") |> String.capitalize()}
                </p>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <!-- Previous Value -->
                  <div class="bg-red-50 border border-red-200 rounded p-3">
                    <div class="flex items-center mb-1">
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        class="h-4 w-4 mr-1 text-red-600"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M18 12H6"
                        />
                      </svg>
                      <span class="text-xs font-medium text-red-700">Previous</span>
                    </div>
                    <p class="text-sm text-red-900 font-mono break-all">
                      {format_value(previous_value)}
                    </p>
                  </div>
                  <!-- New Value -->
                  <div class="bg-green-50 border border-green-200 rounded p-3">
                    <div class="flex items-center mb-1">
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        class="h-4 w-4 mr-1 text-green-600"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M12 6v6m0 0v6m0-6h6m-6 0H6"
                        />
                      </svg>
                      <span class="text-xs font-medium text-green-700">New</span>
                    </div>
                    <p class="text-sm text-green-900 font-mono break-all">
                      {format_value(new_value)}
                    </p>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>
      
    <!-- Previous State (for deletes) -->
      <%= if @audit_log.action == "delete" && @audit_log.previous_state do %>
        <div class="bg-white border border-gray-200 rounded-lg p-6 mb-6">
          <h3 class="text-lg font-semibold text-gray-900 mb-4 flex items-center">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-5 w-5 mr-2 text-red-600"
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
            Deleted Record State
          </h3>
          <div class="bg-red-50 border border-red-200 rounded-lg p-4">
            <pre class="text-sm text-gray-800 overflow-x-auto">{Jason.encode!(@audit_log.previous_state, pretty: true)}</pre>
          </div>
        </div>
      <% end %>
      
    <!-- New State (for inserts) -->
      <%= if @audit_log.action == "insert" && @audit_log.new_state do %>
        <div class="bg-white border border-gray-200 rounded-lg p-6 mb-6">
          <h3 class="text-lg font-semibold text-gray-900 mb-4 flex items-center">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-5 w-5 mr-2 text-green-600"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M12 4v16m8-8H4"
              />
            </svg>
            Created Record State
          </h3>
          <div class="bg-green-50 border border-green-200 rounded-lg p-4">
            <pre class="text-sm text-gray-800 overflow-x-auto">{Jason.encode!(@audit_log.new_state, pretty: true)}</pre>
          </div>
        </div>
      <% end %>
      
    <!-- Raw Data (Collapsible) -->
      <details class="bg-white border border-gray-200 rounded-lg p-6">
        <summary class="text-lg font-semibold text-gray-900 cursor-pointer flex items-center">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-5 w-5 mr-2 text-brand-accent"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4"
            />
          </svg>
          Raw JSON Data
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-4 w-4 ml-2 text-gray-400"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
          </svg>
        </summary>
        <div class="mt-4 space-y-4">
          <%= if @audit_log.previous_state do %>
            <div>
              <h4 class="text-sm font-medium text-gray-700 mb-2">Previous State</h4>
              <div class="bg-gray-900 rounded-lg p-4 overflow-x-auto">
                <pre class="text-sm text-green-400">{Jason.encode!(@audit_log.previous_state, pretty: true)}</pre>
              </div>
            </div>
          <% end %>
          <%= if @audit_log.new_state do %>
            <div>
              <h4 class="text-sm font-medium text-gray-700 mb-2">New State</h4>
              <div class="bg-gray-900 rounded-lg p-4 overflow-x-auto">
                <pre class="text-sm text-green-400">{Jason.encode!(@audit_log.new_state, pretty: true)}</pre>
              </div>
            </div>
          <% end %>
        </div>
      </details>
      
    <!-- Actions -->
      <div class="mt-6 flex justify-end gap-3">
        <.link
          patch={@patch}
          class="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50"
        >
          Close
        </.link>
      </div>
    </div>
    """
  end

  defp action_badge(action) do
    case action do
      "insert" -> {"Record Created", "➕"}
      "update" -> {"Record Updated", "✏️"}
      "delete" -> {"Record Deleted", "🗑️"}
      _ -> {String.capitalize(action), "📝"}
    end
  end

  defp format_table_name(table_name) do
    table_name
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  defp format_value(nil), do: "nil"
  defp format_value(value) when is_binary(value), do: value
  defp format_value(value) when is_boolean(value), do: to_string(value)
  defp format_value(value) when is_number(value), do: to_string(value)
  defp format_value(%DateTime{} = dt), do: Calendar.strftime(dt, "%B %d, %Y at %I:%M:%S %p")

  defp format_value(%NaiveDateTime{} = ndt),
    do: Calendar.strftime(ndt, "%B %d, %Y at %I:%M:%S %p")

  defp format_value(%Date{} = date), do: Calendar.strftime(date, "%B %d, %Y")
  defp format_value(value) when is_map(value), do: Jason.encode!(value)
  defp format_value(value) when is_list(value), do: Enum.join(value, ", ")
  defp format_value(value), do: inspect(value)
end
