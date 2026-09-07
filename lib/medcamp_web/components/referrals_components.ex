defmodule MedcampWeb.ReferralsComponents do
  use Phoenix.Component
  import MedcampWeb.CoreComponents

  def referrals_card(assigns) do
    ~H"""
    <div class="bg-white mt-4 rounded-lg shadow border border-gray-200 overflow-hidden">
      <div class="px-6 py-4 bg-gradient-to-r from-green-50 to-green-100 border-b border-gray-200">
        <h2 class="text-xl font-semibold text-green-800">Referrals</h2>
      </div>

      <div class="p-6">
        <div class="flex justify-between items-center mb-4">
          <h3 class="text-lg font-semibold text-green-800">Patient Referrals</h3>

          <.link patch={"/doctor/patients/#{@patient.id}/notes/#{@doctor_note.id}/refer_patient?tab=referral&subtab=admission"}>
            <.button class="bg-green-500 hover:bg-green-600">
              <span class="flex items-center">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-4 w-4 mr-1"
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
                Add Referral
              </span>
            </.button>
          </.link>
        </div>

        <%= if Enum.empty?(@referrals) do %>
          <div class="text-center py-8 bg-gray-50 rounded-lg border border-dashed border-gray-300">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="mx-auto h-12 w-12 text-gray-400"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
              />
            </svg>
            <h3 class="mt-2 text-sm font-medium text-gray-900">No referrals</h3>
            <p class="mt-1 text-sm text-gray-500">
              No referrals have been created for this patient yet.
            </p>
          </div>
        <% else %>
          <div class="space-y-4">
            <%= for referral <- @referrals do %>
              <div class="border border-gray-200 rounded-lg overflow-hidden">
                <div class="px-4 py-3 bg-gray-50 border-b border-gray-200 flex justify-between items-start">
                  <div>
                    <h4 class="font-medium text-gray-900">Referral to {referral.hospital}</h4>
                    <div class="flex items-center mt-1 text-sm text-gray-500">
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        class="h-4 w-4 mr-1"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
                        />
                      </svg>
                      {Calendar.strftime(referral.date, "%d %b %Y")}

                      <%= if referral.time do %>
                        <svg
                          xmlns="http://www.w3.org/2000/svg"
                          class="h-4 w-4 ml-3 mr-1"
                          fill="none"
                          viewBox="0 0 24 24"
                          stroke="currentColor"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                          />
                        </svg>
                        {Calendar.strftime(referral.time, "%H:%M")}
                      <% end %>
                    </div>
                  </div>

                  <div class="flex items-center space-x-2">
                    <p class="inline-flex items-center px-3 py-2 border border-blue-300 text-sm leading-4 font-medium rounded-md text-blue-700 bg-white hover:bg-blue-50">
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        class="h-4 w-4 mr-1"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z"
                        />
                      </svg>
                      Print
                    </p>

                    <button
                      phx-click="delete_referral"
                      phx-value-id={referral.id}
                      data-confirm="Are you sure you want to delete this referral?"
                      class="inline-flex items-center px-3 py-2 border border-red-300 text-sm leading-4 font-medium rounded-md text-red-700 bg-white hover:bg-red-50"
                    >
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        class="h-4 w-4 mr-1"
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
                    </button>
                  </div>
                </div>

                <div class="p-4">
                  <div class="mb-4">
                    <h5 class="text-sm font-medium text-gray-700 mb-2">Referral Note</h5>
                    <div class="p-3 bg-gray-50 rounded-lg border border-gray-100 whitespace-pre-line">
                      {referral.referral_note || "No referral note provided."}
                    </div>
                  </div>

                  <div class="flex justify-between items-center text-sm text-gray-500 border-t border-gray-200 pt-3 mt-3">
                    <div>
                      Referred by: Dr. {referral.doctor.name}
                    </div>
                    <div>
                      Created: {Calendar.strftime(referral.inserted_at, "%d %b %Y, %H:%M")}
                    </div>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def referrals_card_for_nurse(assigns) do
    ~H"""
    <div class="bg-white mt-4 rounded-lg shadow border border-gray-200 overflow-hidden">
      <div class="px-6 py-4 bg-gradient-to-r from-green-50 to-green-100 border-b border-gray-200">
        <h2 class="text-xl font-semibold text-green-800">Referrals</h2>
      </div>

      <div class="p-6">
        <div class="flex justify-between items-center mb-4">
          <h3 class="text-lg font-semibold text-green-800">Patient Referrals</h3>
        </div>

        <%= if Enum.empty?(@referrals) do %>
          <div class="text-center py-8 bg-gray-50 rounded-lg border border-dashed border-gray-300">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="mx-auto h-12 w-12 text-gray-400"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
              />
            </svg>
            <h3 class="mt-2 text-sm font-medium text-gray-900">No referrals</h3>
            <p class="mt-1 text-sm text-gray-500">
              No referrals have been created for this patient yet.
            </p>
          </div>
        <% else %>
          <div class="space-y-4">
            <%= for referral <- @referrals do %>
              <div class="border border-gray-200 rounded-lg overflow-hidden">
                <div class="px-4 py-3 bg-gray-50 border-b border-gray-200 flex justify-between items-start">
                  <div>
                    <h4 class="font-medium text-gray-900">Referral to {referral.hospital}</h4>
                    <div class="flex items-center mt-1 text-sm text-gray-500">
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        class="h-4 w-4 mr-1"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
                        />
                      </svg>
                      {Calendar.strftime(referral.date, "%d %b %Y")}

                      <%= if referral.time do %>
                        <svg
                          xmlns="http://www.w3.org/2000/svg"
                          class="h-4 w-4 ml-3 mr-1"
                          fill="none"
                          viewBox="0 0 24 24"
                          stroke="currentColor"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                          />
                        </svg>
                        {Calendar.strftime(referral.time, "%H:%M")}
                      <% end %>
                    </div>
                  </div>

                  <div class="flex items-center space-x-2">
                    <p class="inline-flex items-center px-3 py-2 border border-blue-300 text-sm leading-4 font-medium rounded-md text-blue-700 bg-white hover:bg-blue-50">
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        class="h-4 w-4 mr-1"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z"
                        />
                      </svg>
                      Print
                    </p>

                    <button
                      phx-click="delete_referral"
                      phx-value-id={referral.id}
                      data-confirm="Are you sure you want to delete this referral?"
                      class="inline-flex items-center px-3 py-2 border border-red-300 text-sm leading-4 font-medium rounded-md text-red-700 bg-white hover:bg-red-50"
                    >
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        class="h-4 w-4 mr-1"
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
                    </button>
                  </div>
                </div>

                <div class="p-4">
                  <div class="mb-4">
                    <h5 class="text-sm font-medium text-gray-700 mb-2">Referral Note</h5>
                    <div class="p-3 bg-gray-50 rounded-lg border border-gray-100 whitespace-pre-line">
                      {referral.referral_note || "No referral note provided."}
                    </div>
                  </div>

                  <div class="flex justify-between items-center text-sm text-gray-500 border-t border-gray-200 pt-3 mt-3">
                    <div>
                      Referred by: Dr. {referral.doctor.name}
                    </div>
                    <div>
                      Created: {Calendar.strftime(referral.inserted_at, "%d %b %Y, %H:%M")}
                    </div>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def referrals_card_for_a_patient(assigns) do
    ~H"""
    <div class="bg-white mt-4 rounded-lg shadow border border-gray-200 overflow-hidden">
      <div class="px-6 py-4 bg-gradient-to-r from-green-50 to-green-100 border-b border-gray-200">
        <h2 class="text-xl font-semibold text-green-800">Referrals</h2>
      </div>

      <div class="p-6">
        <div class="flex justify-between items-center mb-4">
          <h3 class="text-lg font-semibold text-green-800">Patient Referrals</h3>
        </div>

        <%= if Enum.empty?(@referrals) do %>
          <div class="text-center py-8 bg-gray-50 rounded-lg border border-dashed border-gray-300">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="mx-auto h-12 w-12 text-gray-400"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
              />
            </svg>
            <h3 class="mt-2 text-sm font-medium text-gray-900">No referrals</h3>
            <p class="mt-1 text-sm text-gray-500">
              No referrals have been created for this patient yet.
            </p>
          </div>
        <% else %>
          <div class="space-y-4">
            <%= for referral <- @referrals do %>
              <div class="border border-gray-200 rounded-lg overflow-hidden">
                <div class="px-4 py-3 bg-gray-50 border-b border-gray-200 flex justify-between items-start">
                  <div>
                    <h4 class="font-medium text-gray-900">Referral to {referral.hospital}</h4>
                    <div class="flex items-center mt-1 text-sm text-gray-500">
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        class="h-4 w-4 mr-1"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
                        />
                      </svg>
                      {Calendar.strftime(referral.date, "%d %b %Y")}

                      <%= if referral.time do %>
                        <svg
                          xmlns="http://www.w3.org/2000/svg"
                          class="h-4 w-4 ml-3 mr-1"
                          fill="none"
                          viewBox="0 0 24 24"
                          stroke="currentColor"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                          />
                        </svg>
                        {Calendar.strftime(referral.time, "%H:%M")}
                      <% end %>
                    </div>
                  </div>

                  <div class="flex items-center space-x-2">
                    <p class="inline-flex items-center px-3 py-2 border border-blue-300 text-sm leading-4 font-medium rounded-md text-blue-700 bg-white hover:bg-blue-50">
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        class="h-4 w-4 mr-1"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z"
                        />
                      </svg>
                      Print
                    </p>
                  </div>
                </div>

                <div class="p-4">
                  <div class="mb-4">
                    <h5 class="text-sm font-medium text-gray-700 mb-2">Referral Note</h5>
                    <div class="p-3 bg-gray-50 rounded-lg border border-gray-100 whitespace-pre-line">
                      {referral.referral_note || "No referral note provided."}
                    </div>
                  </div>

                  <div class="flex justify-between items-center text-sm text-gray-500 border-t border-gray-200 pt-3 mt-3">
                    <div>
                      Referred by: Dr. {referral.doctor.name}
                    </div>
                    <div>
                      Created: {Calendar.strftime(referral.inserted_at, "%d %b %Y, %H:%M")}
                    </div>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
