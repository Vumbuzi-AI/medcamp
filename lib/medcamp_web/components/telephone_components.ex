defmodule MedcampWeb.TelephoneComponents do
  use Phoenix.Component

  def telephone_directory(assigns) do
    ~H"""
    <div class="bg-[#f8f8ff] min-h-screen py-8">
      <div class="container mx-auto px-4 max-w-6xl">
        <!-- Header -->
        <div class="text-center mb-8">
          <h1 class="text-3xl font-bold text-[#373896] mb-2">Hospital Telephone Directory</h1>
          <p class="text-gray-600">Glocal Health Care Centre of Excellence</p>
          <div class="w-24 h-1 bg-[#373896] mx-auto mt-4 rounded"></div>
        </div>
        
    <!-- Emergency Notice -->
        <div class="bg-red-50 border-l-4 border-red-500 p-4 mb-8 rounded-lg">
          <div class="flex items-center">
            <svg
              class="w-6 h-6 text-red-500 mr-3"
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
            <div>
              <h3 class="text-red-800 font-semibold">Emergency Services</h3>
              <p class="text-red-700">
                For medical emergencies, dial <strong>102</strong>
                or contact emergency services immediately
              </p>
            </div>
          </div>
        </div>
        
    <!-- Telephone Directory Cards -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
          <.telephone_card
            station="Reception"
            extension="100"
            description="Main reception desk"
            icon="phone"
            color_scheme="brand"
          />

          <.telephone_card
            station="Triage"
            extension="101"
            description="Patient assessment"
            icon="clipboard"
            color_scheme="orange"
          />

          <.telephone_card
            station="Emergency"
            extension="102"
            description="24/7 Emergency services"
            icon="exclamation"
            color_scheme="red"
            emergency={true}
          />

          <.telephone_card
            station="Laboratory"
            extension="103"
            description="Lab services & results"
            icon="beaker"
            color_scheme="green"
          />

          <.telephone_card
            station="Pharmacy"
            extension="104"
            description="Medication services"
            icon="briefcase"
            color_scheme="blue"
          />

          <.telephone_card
            station="Consultation Room 1"
            extension="105"
            description="Doctor consultations"
            icon="user"
            color_scheme="secondary"
          />

          <.telephone_card
            station="Consultation Room 2"
            extension="106"
            description="Doctor consultations"
            icon="user"
            color_scheme="secondary"
          />

          <.telephone_card
            station="Nurse Office"
            extension="107"
            description="Nursing services"
            icon="heart"
            color_scheme="pink"
          />

          <.telephone_card
            station="Radiology"
            extension="108"
            description="Imaging services"
            icon="camera"
            color_scheme="purple"
          />

          <.telephone_card
            station="Phlebotomy"
            extension="109"
            description="Blood collection"
            icon="droplet"
            color_scheme="red-light"
          />

          <.telephone_card
            station="Theater"
            extension="110"
            description="Operating theater"
            icon="scissors"
            color_scheme="indigo"
          />

          <.telephone_card
            station="Ward Area"
            extension="111"
            description="Patient wards"
            icon="building"
            color_scheme="teal"
          />

          <.telephone_card
            station="Kitchen"
            extension="112"
            description="Food services"
            icon="chef"
            color_scheme="yellow"
          />

          <.telephone_card
            station="Office"
            extension="113"
            description="Administrative office"
            icon="office"
            color_scheme="gray"
          />
        </div>
        
    <!-- Footer -->
        <div class="text-center mt-12 pt-8 border-t border-gray-200">
          <p class="text-gray-600">
            &copy; 2025 Glocal Health Care Centre of Excellence. All rights reserved.
          </p>
          <p class="text-sm text-gray-500 mt-2">
            For external calls, please dial the main number first: +254 700 000 000
          </p>
        </div>
      </div>
    </div>
    """
  end

  defp telephone_card(assigns) do
    assigns = assign_new(assigns, :emergency, fn -> false end)

    ~H"""
    <div class={[
      "bg-white rounded-lg shadow-lg border overflow-hidden hover:shadow-xl transition-shadow duration-300",
      if(@emergency, do: "border-red-200", else: "border-gray-100")
    ]}>
      <div class={[
        "px-6 py-4",
        get_header_color(@color_scheme)
      ]}>
        <div class="flex items-center">
          <.icon name={@icon} class="w-6 h-6 text-white mr-3" />
          <h3 class="text-white font-semibold text-lg">{@station}</h3>
        </div>
      </div>
      <div class="p-6">
        <div class="text-center">
          <div class={[
            "text-3xl font-bold mb-2",
            get_text_color(@color_scheme)
          ]}>
            {@extension}
          </div>
          <p class="text-gray-600 text-sm">{@description}</p>
        </div>
      </div>
    </div>
    """
  end

  defp icon(%{name: "phone"} = assigns) do
    ~H"""
    <svg class={@class} fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"
      />
    </svg>
    """
  end

  defp icon(%{name: "clipboard"} = assigns) do
    ~H"""
    <svg class={@class} fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
      />
    </svg>
    """
  end

  defp icon(%{name: "exclamation"} = assigns) do
    ~H"""
    <svg class={@class} fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z"
      />
    </svg>
    """
  end

  defp icon(%{name: "beaker"} = assigns) do
    ~H"""
    <svg class={@class} fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"
      />
    </svg>
    """
  end

  defp icon(%{name: "briefcase"} = assigns) do
    ~H"""
    <svg class={@class} fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"
      />
    </svg>
    """
  end

  defp icon(%{name: "user"} = assigns) do
    ~H"""
    <svg class={@class} fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
      />
    </svg>
    """
  end

  defp icon(%{name: "heart"} = assigns) do
    ~H"""
    <svg class={@class} fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"
      />
    </svg>
    """
  end

  defp icon(%{name: "camera"} = assigns) do
    ~H"""
    <svg class={@class} fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M9 3v2m6-2v2M9 19v2m6-2v2M5 9H3m2 6H3m18-6h-2m2 6h-2M7 19h10a2 2 0 002-2V7a2 2 0 00-2-2H7a2 2 0 00-2 2v10a2 2 0 002 2zM9 9h6v6H9V9z"
      />
    </svg>
    """
  end

  defp icon(%{name: "droplet"} = assigns) do
    ~H"""
    <svg class={@class} fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M17.657 18.657A8 8 0 016.343 7.343S7 9 9 10c0-2 .5-5 2.986-7C14 5 16.09 5.777 17.656 7.343A7.975 7.975 0 0120 13a7.975 7.975 0 01-2.343 5.657z"
      />
    </svg>
    """
  end

  defp icon(%{name: "scissors"} = assigns) do
    ~H"""
    <svg class={@class} fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"
      />
    </svg>
    """
  end

  defp icon(%{name: "building"} = assigns) do
    ~H"""
    <svg class={@class} fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z"
      />
    </svg>
    """
  end

  defp icon(%{name: "chef"} = assigns) do
    ~H"""
    <svg class={@class} fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 100 4m0-4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0 100 4m0-4v2m0-6V4"
      />
    </svg>
    """
  end

  defp icon(%{name: "office"} = assigns) do
    ~H"""
    <svg class={@class} fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"
      />
    </svg>
    """
  end

  defp get_header_color("brand"), do: "bg-[#373896]"
  defp get_header_color("secondary"), do: "bg-[#6667ab]"
  defp get_header_color("orange"), do: "bg-orange-500"
  defp get_header_color("red"), do: "bg-red-500"
  defp get_header_color("green"), do: "bg-green-500"
  defp get_header_color("blue"), do: "bg-blue-500"
  defp get_header_color("pink"), do: "bg-pink-500"
  defp get_header_color("purple"), do: "bg-slate-500"
  defp get_header_color("red-light"), do: "bg-red-400"
  defp get_header_color("indigo"), do: "bg-indigo-500"
  defp get_header_color("teal"), do: "bg-teal-500"
  defp get_header_color("yellow"), do: "bg-yellow-500"
  defp get_header_color("gray"), do: "bg-gray-600"

  defp get_text_color("brand"), do: "text-[#373896]"
  defp get_text_color("secondary"), do: "text-[#6667ab]"
  defp get_text_color("orange"), do: "text-orange-500"
  defp get_text_color("red"), do: "text-red-500"
  defp get_text_color("green"), do: "text-green-500"
  defp get_text_color("blue"), do: "text-blue-500"
  defp get_text_color("pink"), do: "text-pink-500"
  defp get_text_color("purple"), do: "text-slate-500"
  defp get_text_color("red-light"), do: "text-red-400"
  defp get_text_color("indigo"), do: "text-indigo-500"
  defp get_text_color("teal"), do: "text-teal-500"
  defp get_text_color("yellow"), do: "text-yellow-500"
  defp get_text_color("gray"), do: "text-gray-600"
end
