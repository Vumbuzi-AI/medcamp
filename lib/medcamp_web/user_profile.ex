defmodule MedcampWeb.UserLive.Profile do
  use MedcampWeb, :live_view

  alias Medcamp.Accounts

  @impl true
  def mount(%{"gsrn" => gsrn} = _params, _session, socket) do
    user = Accounts.get_user_by_gsrn(gsrn)

    case user do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "User not found")
         |> assign(:user, nil)
         |> assign(:user_id, nil)}

      user ->
        {:ok,
         socket
         |> assign(:user, user)
         |> assign(:user_id, user.id)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-[#f8f8ff] flex flex-col">
      <div class="flex-1 flex items-center justify-center p-4">
        <%= if @user do %>
          <div class="w-full max-w-4xl bg-white rounded-lg shadow-lg border border-gray-100 overflow-hidden">
            <div class="bg-[#373896] px-6 py-4">
              <div class="flex justify-between items-center">
                <div class="flex items-center gap-4">
                  <div>
                    <h1 class="text-white text-2xl font-bold">Staff Profile</h1>
                    <p class="text-blue-100 text-sm">Glocal Health Centre</p>
                  </div>
                </div>
                <div class="text-right flex items-center gap-3">
                  <div class={[
                    "text-white text-xs px-3 py-1 rounded-full font-medium",
                    if(@user.is_active, do: "bg-green-500", else: "bg-red-500")
                  ]}>
                    {if @user.is_active, do: "ACTIVE", else: "INACTIVE"}
                  </div>
                </div>
              </div>
            </div>
            
    <!-- Main Content -->
            <div class="p-6">
              <!-- User Info Header -->
              <div class="flex flex-col lg:flex-row gap-6 mb-6">
                <!-- Profile Image & Basic Info -->
                <div class="lg:w-1/3">
                  <div class="bg-[#f0f0ff] border border-[#e7e7ff] rounded-lg p-6 text-center">
                    <div class="mb-4">
                      <%= if @user.image do %>
                        <img
                          src={@user.image}
                          alt={@user.name}
                          class="w-24 h-24 rounded-full mx-auto object-cover border-4 border-white shadow-lg"
                        />
                      <% else %>
                        <div class="w-24 h-24 rounded-full mx-auto bg-[#373896] flex items-center justify-center text-white text-2xl font-bold shadow-lg">
                          {get_initials(@user.name)}
                        </div>
                      <% end %>
                    </div>

                    <h2 class="text-xl font-bold text-[#373896] mb-1">
                      {@user.name}
                    </h2>

                    <div class="mb-3">
                      <span class={[
                        "inline-block px-3 py-1 rounded-full text-sm font-medium",
                        role_badge_class(@user.role)
                      ]}>
                        <%= if @user.role == "labtechnician" do %>
                          Lab Technologist
                        <% else %>
                          {String.upcase(@user.role)}
                        <% end %>
                      </span>
                    </div>

                    <%= if @user.experience do %>
                      <p class="text-gray-600 text-sm">
                        {@user.experience}
                      </p>
                    <% end %>
                  </div>
                </div>
                
    <!-- Contact & Professional Details -->
                <div class="lg:w-2/3">
                  <div class="bg-[#f0f0ff] border border-[#e7e7ff] rounded-lg p-6">
                    <h3 class="text-lg font-semibold text-[#373896] mb-4 flex items-center">
                      <svg class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
                        />
                      </svg>
                      Professional Information
                    </h3>

                    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                      <!-- Contact Information -->
                      <div class="space-y-4">
                        <h4 class="font-medium text-gray-900 text-sm uppercase tracking-wide">
                          Contact Details
                        </h4>

                        <div>
                          <label class="text-sm text-gray-500 block mb-1">Email Address</label>
                          <div class="flex items-center text-gray-900">
                            <a
                              href={"mailto:#{@user.email}"}
                              class="text-[#373896] hover:text-[#6667ab]"
                            >
                              {@user.email}
                            </a>
                          </div>
                        </div>

                        <%= if @user.phone_number do %>
                          <div>
                            <label class="text-sm text-gray-500 block mb-1">Phone Number</label>
                            <div class="flex items-center text-gray-900">
                              <svg
                                class="h-4 w-4 mr-2 text-[#373896]"
                                fill="none"
                                viewBox="0 0 24 24"
                                stroke="currentColor"
                              >
                                <path
                                  stroke-linecap="round"
                                  stroke-linejoin="round"
                                  stroke-width="2"
                                  d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"
                                />
                              </svg>
                              <a
                                href={"tel:#{@user.phone_number}"}
                                class="text-[#373896] hover:text-[#6667ab]"
                              >
                                {format_phone(@user.phone_number)}
                              </a>
                            </div>
                          </div>
                        <% end %>
                      </div>
                      
    <!-- Professional Information -->
                      <div class="space-y-4">
                        <h4 class="font-medium text-gray-900 text-sm uppercase tracking-wide">
                          Professional Details
                        </h4>

                        <%= if @user.id_number do %>
                          <div>
                            <label class="text-sm text-gray-500 block mb-1">ID Number</label>
                            <p class="text-gray-900 font-mono text-sm bg-gray-100 px-2 py-1 rounded">
                              {@user.id_number}
                            </p>
                          </div>
                        <% end %>

                        <%= if @user.license_number do %>
                          <div>
                            <label class="text-sm text-gray-500 block mb-1">License Number</label>
                            <p class="text-gray-900 font-mono text-sm bg-gray-100 px-2 py-1 rounded">
                              {@user.license_number}
                            </p>
                          </div>
                        <% end %>

                        <%= if @user.gsrn do %>
                          <div>
                            <label class="text-sm text-gray-500 block mb-1">GSRN</label>
                            <p class="text-gray-900 font-mono text-sm bg-gray-100 px-2 py-1 rounded">
                              {@user.gsrn}
                            </p>
                          </div>
                        <% end %>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
              
    <!-- Account Status & Activity -->
              <div class="w-[100%] gap-6 mb-6">
                <!-- Account Status -->
                <div class="bg-white border border-gray-200 rounded-lg p-5 shadow-sm">
                  <h3 class="text-lg font-semibold text-[#373896] mb-4 flex items-center">
                    <svg class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
                      />
                    </svg>
                    Account Status
                  </h3>

                  <div class="space-y-3">
                    <div class="flex justify-between items-center">
                      <span class="text-gray-600">Account Status</span>
                      <span class={[
                        "px-2 py-1 rounded-full text-xs font-medium",
                        if(@user.is_active,
                          do: "bg-green-100 text-green-800",
                          else: "bg-red-100 text-red-800"
                        )
                      ]}>
                        {if @user.is_active, do: "Active", else: "Inactive"}
                      </span>
                    </div>

                    <div class="flex justify-between items-center">
                      <span class="text-gray-600">Member Since</span>
                      <span class="text-gray-900">
                        {format_date(@user.inserted_at)}
                      </span>
                    </div>
                  </div>
                </div>
              </div>
              
    <!-- Navigation -->
              <div class="flex justify-center">
                <a
                  href="/"
                  class="inline-flex items-center px-6 py-3 bg-[#373896] text-white font-medium rounded-lg hover:bg-[#6667ab] transition-colors"
                >
                  <svg class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M15 19l-7-7 7-7"
                    />
                  </svg>
                  Back Home
                </a>
              </div>
            </div>
            
    <!-- Footer -->
            <div class="bg-[#f8f8ff] px-6 py-4 border-t border-gray-100">
              <div class="text-center text-sm text-gray-500">
                <p>&copy; {Date.utc_today().year} Glocal Health Centre. All Rights Reserved.</p>
                <p class="mt-1">
                  Staff profile information is confidential and for authorized personnel only.
                </p>
              </div>
            </div>
          </div>
        <% else %>
          <!-- User Not Found -->
          <div class="w-full max-w-md bg-white rounded-lg shadow-lg border border-gray-100 p-8 text-center">
            <div class="mx-auto flex items-center justify-center h-16 w-16 rounded-full bg-red-100 mb-4">
              <svg class="h-8 w-8 text-red-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
                />
              </svg>
            </div>

            <h2 class="text-xl font-semibold text-gray-900 mb-2">User Not Found</h2>
            <p class="text-gray-600 mb-6">
              The user with ID
              <span class="font-mono bg-gray-100 px-2 py-1 rounded text-sm">{@user_id}</span>
              could not be found in our system.
            </p>

            <a
              href="/"
              class="inline-flex items-center px-4 py-2 bg-[#373896] text-white text-sm font-medium rounded-md hover:bg-[#6667ab] transition-colors"
            >
              <svg class="h-4 w-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M15 19l-7-7 7-7"
                />
              </svg>
              Back to Dashboard
            </a>
          </div>
        <% end %>
      </div>
    </div>

    <!-- Print Styles -->
    <style>
      @media print {
        body * {
          visibility: hidden;
        }
        .print-content, .print-content * {
          visibility: visible;
        }
        .print-content {
          position: absolute;
          left: 0;
          top: 0;
          width: 100%;
        }
        .no-print {
          display: none !important;
        }
      }
    </style>
    """
  end

  # Helper functions
  defp format_date(date) do
    case date do
      nil -> "N/A"
      date -> Calendar.strftime(date, "%B %d, %Y")
    end
  end

  defp format_phone(phone) when is_binary(phone) do
    # Format phone number (e.g., +254712345678 -> +254 712 345 678)
    case String.length(phone) do
      13 ->
        "+#{String.slice(phone, 1, 3)} #{String.slice(phone, 4, 3)} #{String.slice(phone, 7, 3)} #{String.slice(phone, 10, 3)}"

      10 ->
        "#{String.slice(phone, 0, 3)}-#{String.slice(phone, 3, 3)}-#{String.slice(phone, 6, 4)}"

      _ ->
        phone
    end
  end

  defp format_phone(_phone), do: "N/A"

  defp get_initials(name) when is_binary(name) do
    name
    |> String.split(" ")
    |> Enum.take(2)
    |> Enum.map(&String.first/1)
    |> Enum.join("")
    |> String.upcase()
  end

  defp get_initials(_), do: "GH"

  defp role_badge_class(role) do
    case role do
      "doctor" -> "bg-blue-100 text-blue-800"
      "nurse" -> "bg-green-100 text-green-800"
      "admin" -> "bg-purple-100 text-purple-800"
      "pharmacist" -> "bg-orange-100 text-orange-800"
      "receptionist" -> "bg-pink-100 text-pink-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end
end
