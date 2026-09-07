defmodule MedcampWeb.ChatLive.Index do
  use MedcampWeb, :live_view

  alias Medcamp.Chatbot
  alias Medcamp.Accounts

  @impl true
  def mount(_params, session, socket) do
    current_user = Accounts.get_user_by_session_token(session["user_token"])

    {:ok,
     socket
     |> assign(:messages, [])
     |> assign(:current_user, current_user)
     |> assign(:current_message, "")
     |> assign(:loading, false)
     |> assign(:error_message, nil)
     |> assign(:chat_started, false)
     |> assign(:suggestions, get_role_suggestions(current_user.role))}
  end

  @impl true
  def handle_event("send_message", %{"message" => message}, socket) do
    if String.trim(message) == "" do
      {:noreply, socket}
    else
      send_message(socket, String.trim(message))
    end
  end

  @impl true
  def handle_event("send_suggestion", %{"suggestion" => suggestion}, socket) do
    send_message(socket, suggestion)
  end

  @impl true
  def handle_event("clear_chat", _params, socket) do
    {:noreply,
     socket
     |> assign(:messages, [])
     |> assign(:current_message, "")
     |> assign(:chat_started, false)
     |> assign(:error_message, nil)}
  end

  @impl true
  def handle_event("update_message", %{"message" => message}, socket) do
    {:noreply, assign(socket, :current_message, message)}
  end

  defp send_message(socket, message) do
    user_role = socket.assigns.current_user.role

    user_message = %{
      id: System.unique_integer([:positive]),
      content: message,
      sender: :user,
      timestamp: DateTime.utc_now()
    }

    updated_socket =
      socket
      |> assign(:messages, socket.assigns.messages ++ [user_message])
      |> assign(:current_message, "")
      |> assign(:loading, true)
      |> assign(:error_message, nil)
      |> assign(:chat_started, true)

    # Send async request to chatbot
    pid = self()

    Task.start(fn ->
      case Chatbot.validate_role(user_role) do
        {:ok, role} ->
          response = Chatbot.get_chatbot_response(role, message)
          send(pid, {:chatbot_response, response})

        {:error, reason} ->
          send(pid, {:chatbot_error, reason})
      end
    end)

    {:noreply, updated_socket}
  end

  @impl true
  def handle_info({:chatbot_response, response}, socket) do
    bot_message = %{
      id: System.unique_integer([:positive]),
      content: response,
      sender: :bot,
      timestamp: DateTime.utc_now()
    }

    {:noreply,
     socket
     |> assign(:messages, socket.assigns.messages ++ [bot_message])
     |> assign(:loading, false)}
  end

  @impl true
  def handle_info({:chatbot_error, error}, socket) do
    {:noreply,
     socket
     |> assign(:loading, false)
     |> assign(:error_message, "Error: #{error}")}
  end

  @impl true

  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-screen bg-[#f8f8ff]">
      <!-- Header with Back Button -->
      <div class="bg-white shadow-sm border-b border-gray-100 px-6 py-4">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-4">
            <!-- Back to Panel Button -->
            <.link
              navigate={get_panel_url(@current_user.role)}
              class="flex items-center gap-2 px-4 py-2 text-sm bg-[#373896] text-white rounded-lg hover:bg-[#6667ab] transition-colors"
            >
              <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M15 19l-7-7 7-7"
                />
              </svg>
              Back to Panel
            </.link>

            <div class="w-10 h-10 bg-[#373896] rounded-full flex items-center justify-center">
              <svg class="w-6 h-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-3.582 8-8 8a8.959 8.959 0 01-4.906-1.456L3 21l2.456-5.094A8.959 8.959 0 013 12c0-4.418 3.582-8 8-8s8 3.582 8 8z"
                />
              </svg>
            </div>
            <div>
              <h1 class="text-xl font-bold text-[#373896]">GHC AI Assistant</h1>
              <p class="text-sm text-gray-600">
                {String.upcase(@current_user.role)} Support - Ask me anything about the system
              </p>
            </div>
          </div>

          <div class="flex items-center gap-3">
            <%= if @chat_started do %>
              <button
                phx-click="clear_chat"
                class="px-4 py-2 text-sm bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors flex items-center gap-2"
              >
                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                  />
                </svg>
                Clear Chat
              </button>
            <% end %>

            <div class="flex items-center gap-2 text-sm text-gray-500">
              <div class="w-2 h-2 bg-green-500 rounded-full"></div>
              Online
            </div>
          </div>
        </div>
      </div>
      
    <!-- Chat Messages -->
      <div class="flex-1 overflow-y-auto p-6" id="chat-messages" phx-hook="ScrollToBottom">
        <%= if not @chat_started do %>
          <!-- Welcome Screen -->
          <div class="max-w-2xl mx-auto text-center py-12">
            <div class="mb-8">
              <div class="w-20 h-20 bg-[#373896] rounded-full flex items-center justify-center mx-auto mb-4">
                <svg
                  class="w-10 h-10 text-white"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"
                  />
                </svg>
              </div>
              <h2 class="text-2xl font-bold text-[#373896] mb-2">Welcome to GHC AI Assistant</h2>
              <p class="text-gray-600 mb-6">
                I'm here to help you navigate the hospital management system efficiently.
                As a <span class="font-medium text-[#373896]"><%= String.upcase(@current_user.role) %></span>,
                I can guide you through your specific workflows and features.
              </p>
            </div>
            
    <!-- Role-specific suggestions -->
            <div class="bg-white rounded-lg border border-gray-100 p-6 shadow-sm">
              <h3 class="text-lg font-semibold text-[#373896] mb-4">Quick Start - Try asking:</h3>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                <%= for suggestion <- @suggestions do %>
                  <button
                    phx-click="send_suggestion"
                    phx-value-suggestion={suggestion}
                    class="p-3 text-left bg-[#f0f0ff] border border-[#e7e7ff] rounded-lg hover:bg-[#e7e7ff] transition-colors text-sm"
                  >
                    <div class="flex items-start gap-2">
                      <svg
                        class="w-4 h-4 text-[#373896] mt-0.5 flex-shrink-0"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                        />
                      </svg>
                      <span class="text-gray-700">{suggestion}</span>
                    </div>
                  </button>
                <% end %>
              </div>
            </div>
          </div>
        <% else %>
          <!-- Chat Messages -->
          <div class="max-w-4xl mx-auto space-y-4">
            <%= for message <- @messages do %>
              <div class={[
                "flex",
                if(message.sender == :user, do: "justify-end", else: "justify-start")
              ]}>
                <div class={[
                  "flex items-start gap-3 max-w-[80%]",
                  if(message.sender == :user, do: "flex-row-reverse", else: "flex-row")
                ]}>
                  <!-- Avatar -->
                  <div class={[
                    "w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0",
                    if(message.sender == :user, do: "bg-[#6667ab]", else: "bg-[#373896]")
                  ]}>
                    <%= if message.sender == :user do %>
                      <svg
                        class="w-4 h-4 text-white"
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
                    <% else %>
                      <svg
                        class="w-4 h-4 text-white"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"
                        />
                      </svg>
                    <% end %>
                  </div>
                  
    <!-- Message Content -->
                  <div class={[
                    "rounded-lg px-4 py-3 shadow-sm",
                    if(message.sender == :user,
                      do: "bg-[#373896] text-white",
                      else: "bg-white border border-gray-100"
                    )
                  ]}>
                    <div class={[
                      "text-sm leading-relaxed",
                      if(message.sender == :user, do: "text-white", else: "text-gray-800")
                    ]}>
                      {Phoenix.HTML.raw(message.content)}
                    </div>
                    <div class={[
                      "text-xs mt-2",
                      if(message.sender == :user, do: "text-blue-100", else: "text-gray-500")
                    ]}>
                      {format_timestamp(message.timestamp)}
                    </div>
                  </div>
                </div>
              </div>
            <% end %>
            
    <!-- Loading indicator -->
            <%= if @loading do %>
              <div class="flex justify-start">
                <div class="flex items-start gap-3 max-w-[80%]">
                  <div class="w-8 h-8 rounded-full bg-[#373896] flex items-center justify-center flex-shrink-0">
                    <svg
                      class="w-4 h-4 text-white"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"
                      />
                    </svg>
                  </div>
                  <div class="bg-white border border-gray-100 rounded-lg px-4 py-3 shadow-sm">
                    <div class="flex items-center gap-2">
                      <div class="flex space-x-1">
                        <div class="w-2 h-2 bg-[#373896] rounded-full animate-bounce"></div>
                        <div
                          class="w-2 h-2 bg-[#373896] rounded-full animate-bounce"
                          style="animation-delay: 0.1s"
                        >
                        </div>
                        <div
                          class="w-2 h-2 bg-[#373896] rounded-full animate-bounce"
                          style="animation-delay: 0.2s"
                        >
                        </div>
                      </div>
                      <span class="text-sm text-gray-600">AI is thinking...</span>
                    </div>
                  </div>
                </div>
              </div>
            <% end %>
            
    <!-- Error message -->
            <%= if @error_message do %>
              <div class="flex justify-center">
                <div class="bg-red-50 border border-red-200 rounded-lg px-4 py-3 max-w-md">
                  <div class="flex items-center gap-2">
                    <svg
                      class="w-5 h-5 text-red-500"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z"
                      />
                    </svg>
                    <span class="text-sm text-red-700">{@error_message}</span>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
      
    <!-- Chat Input -->
      <div class="bg-white border-t border-gray-100 px-6 py-4">
        <div class="max-w-4xl mx-auto">
          <form phx-submit="send_message" class="flex gap-3">
            <div class="flex-1 relative">
              <input
                type="text"
                name="message"
                value={@current_message}
                phx-change="update_message"
                placeholder={get_placeholder(@current_user.role)}
                disabled={@loading}
                class="w-full px-4 py-3 border border-gray-200 rounded-lg focus:ring-2 focus:ring-[#373896] focus:border-transparent resize-none disabled:opacity-50 disabled:cursor-not-allowed"
                autocomplete="off"
              />
            </div>
            <button
              type="submit"
              disabled={@loading or String.trim(@current_message) == ""}
              class="px-6 py-3 bg-[#373896] text-white rounded-lg hover:bg-[#6667ab] disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center gap-2"
            >
              <%= if @loading do %>
                <svg class="w-4 h-4 animate-spin" fill="none" viewBox="0 0 24 24">
                  <circle
                    class="opacity-25"
                    cx="12"
                    cy="12"
                    r="10"
                    stroke="currentColor"
                    stroke-width="4"
                  >
                  </circle>
                  <path
                    class="opacity-75"
                    fill="currentColor"
                    d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                  >
                  </path>
                </svg>
              <% else %>
                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8"
                  />
                </svg>
              <% end %>
              Send
            </button>
          </form>

          <div class="flex items-center justify-between mt-3 text-xs text-gray-500">
            <div class="flex items-center gap-4">
              <span>Connected as {String.upcase(@current_user.role)}</span>
              <span>•</span>
              <span>AI Assistant Ready</span>
            </div>
            <div class="text-right">
              <span>Press Enter to send</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- JavaScript for auto-scrolling -->
    <script>
      window.ScrollToBottom = {
        mounted() {
          this.scrollToBottom();
        },
        updated() {
          this.scrollToBottom();
        },
        scrollToBottom() {
          const container = document.getElementById("chat-messages");
          if (container) {
            container.scrollTop = container.scrollHeight;
          }
        }
      };
    </script>
    """
  end

  # Helper functions
  defp format_timestamp(datetime) do
    datetime
    |> DateTime.shift_zone!("Africa/Nairobi")
    |> Calendar.strftime("%I:%M %p")
  end

  defp get_placeholder(role) do
    case role do
      "doctor" -> "Ask about patient management, prescriptions, lab results..."
      "nurse" -> "Ask about patient care, room assignments, procedures..."
      "receptionist" -> "Ask about patient registration, visits, appointments..."
      "pharmacist" -> "Ask about drug dispensing, prescriptions, inventory..."
      "lab_technician" -> "Ask about lab results, sample processing..."
      "radiologist" -> "Ask about imaging studies, radiology reports..."
      "admin" -> "Ask about system administration, user management..."
      "inventory_manager" -> "Ask about inventory management, suppliers..."
      _ -> "Ask me anything about the hospital system..."
    end
  end

  defp get_role_suggestions(role) do
    case role do
      "doctor" ->
        [
          "How do I prescribe medication to a patient?",
          "How do I view pending patient visits?",
          "How do I order lab tests for a patient?",
          "How do I create doctor notes?"
        ]

      "nurse" ->
        [
          "How do I assign a room to a patient?",
          "How do I create a patient triage?",
          "How do I document nursing procedures?",
          "How do I update patient vital signs?"
        ]

      "reception" ->
        [
          "How do I register a new patient?",
          "How do I check in a patient for a visit?",
          "How do I schedule an appointment?",
          "How do I process payment for a visit?"
        ]

      "pharmacist" ->
        [
          "How do I dispense medication to a patient?",
          "How do I view pending prescriptions?",
          "How do I check drug inventory?",
          "How do I print medication labels?"
        ]

      "labtechnician" ->
        [
          "How do I process lab samples?",
          "How do I enter lab results?",
          "How do I view pending lab orders?",
          "How do I print lab reports?"
        ]

      "radiologist" ->
        [
          "How do I view radiology orders?",
          "How do I generate radiology reports?",
          "How do I access patient imaging studies?",
          "How do I process urgent radiology requests?"
        ]

      "admin" ->
        [
          "How do I create a new user account?",
          "How do I manage system pricing?",
          "How do I configure lab tests?",
          "How do I view payment reports?"
        ]

      "inventory_manager" ->
        [
          "How do I receive new inventory?",
          "How do I manage supplier information?",
          "How do I track inventory batches?",
          "How do I issue inventory to departments?"
        ]

      _ ->
        [
          "How do I navigate the system?",
          "What features are available to me?",
          "How do I scan patients?",
          "How do I access patient information?"
        ]
    end
  end

  # Helper function to get the appropriate panel URL based on user role
  defp get_panel_url(role) do
    case role do
      "doctor" -> "/doctor/patients"
      "nurse" -> "/nurse/scan"
      "reception" -> "/reception/scan"
      "pharmacist" -> "/pharmacist/scan"
      "labtechnician" -> "/lab/scan"
      "radiologist" -> "/radiologist/scan"
      "admin" -> "/admin/users"
      "inventory_manager" -> "/inventory_manager/inventories_received"
      "supplier" -> "/supplier/dashboard"
      "procurement_officer" -> "/procurement/dashboard"
      "stores_officer" -> "/procurement/dashboard"
      "finance_officer" -> "/procurement/dashboard"
      _ -> "/"
    end
  end
end
