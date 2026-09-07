defmodule MedcampWeb.RoomGlnLive.Index do
  use MedcampWeb, :live_view

  alias Medcamp.Rooms

  @impl true
  def mount(%{"gln" => gln} = _params, _session, socket) do
    # Preload room equipments when fetching the room
    room = Rooms.get_room_by_room_number_with_equipments(gln)

    {:ok,
     socket
     |> assign(:room, room)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-8">
      <.navbar_user />

      <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-6">
        <div class="flex gap-2 text-[#373896] font-semibold items-center mb-6">
          <.link navigate="/" class="hover:text-[#6667ab] transition-colors">
            <Heroicons.icon name="arrow-left" type="outline" class="h-5 w-5" />
          </.link>
          <p class="text-lg">
            Room Details / #{@room.name}
          </p>
        </div>

        <div class="flex flex-col lg:flex-row gap-6">
          <!-- Room summary card -->
          <div class="w-full lg:w-1/3 bg-[#f8f8ff] rounded-lg p-5 shadow-sm border border-gray-100">
            <div>
              <div class="bg-white rounded-lg shadow-md mx-auto my-5 p-4 border border-gray-200 relative overflow-hidden print:shadow-none print:m-0">
                <div class="absolute top-0 right-0 w-full h-full bg-gradient-to-br from-transparent to-[#e7e7ff] opacity-20 -z-10">
                </div>

                <div class="flex justify-between items-center w-[100%] border-b-2 border-[#373896] pb-2 mb-3">
                  <div class="text-[#373896]">
                    <div class="font-bold text-xs">GHC Excellence</div>
                    <div class="text-xs">Room Information</div>
                  </div>

                  <div>
                    <img src="/images/logo.png" alt="Logo" class="h-12 w-12 rounded-full" />
                  </div>
                </div>

                <div class="flex justify-between">
                  <div class="flex-1">
                    <h2 class="text-base font-bold text-[#373896] m-0">
                      {@room.name}
                    </h2>
                  </div>
                </div>
              </div>
            </div>
            
    <!-- Room Image Section -->
            <%= if @room.image do %>
              <div class="mt-4">
                <h3 class="text-sm font-semibold text-[#373896] mb-2">Room Image</h3>
                <div class="relative overflow-hidden rounded-lg border border-gray-200 shadow-sm">
                  <img
                    src={@room.image}
                    alt={"#{@room.name} image"}
                    class="w-full h-48 object-cover hover:scale-105 transition-transform duration-300"
                  />
                </div>
              </div>
            <% end %>

            <div class="border-t border-gray-200 my-4"></div>
            
    <!-- Room Info Summary -->
            <div class="space-y-3">
              <div>
                <span class="text-xs font-medium text-gray-500 uppercase tracking-wide">
                  Room Number
                </span>
                <p class="text-sm font-semibold text-[#373896]">{@room.room_number || "N/A"}</p>
              </div>

              <div>
                <span class="text-xs font-medium text-gray-500 uppercase tracking-wide">
                  Room Type
                </span>
                <p class="text-sm font-semibold text-[#373896]">{@room.type || "N/A"}</p>
              </div>

              <div>
                <span class="text-xs font-medium text-gray-500 uppercase tracking-wide">
                  Total Equipment
                </span>
                <p class="text-sm font-semibold text-[#373896]">
                  {length(@room.room_equipments || [])} items
                </p>
              </div>
            </div>
          </div>
          
    <!-- Room Equipment Section -->
          <div class="w-full lg:w-2/3">
            <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-6">
              <h3 class="text-lg font-semibold text-[#373896] mb-4 flex items-center gap-2">
                <Heroicons.icon name="wrench-screwdriver" type="outline" class="h-5 w-5" />
                Room Equipment
              </h3>

              <%= if @room.room_equipments && length(@room.room_equipments) > 0 do %>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <%= for equipment <- @room.room_equipments do %>
                    <div class="bg-gray-50 rounded-lg p-4 border border-gray-200 hover:shadow-md transition-shadow">
                      <%= if equipment.image do %>
                        <div class="mb-3">
                          <img
                            src={equipment.image}
                            alt={"#{equipment.name} image"}
                            class="w-full h-32 object-cover rounded-md border border-gray-300"
                          />
                        </div>
                      <% end %>

                      <div>
                        <h4 class="font-semibold text-[#373896] text-sm mb-1">
                          {equipment.name}
                        </h4>

                        <%= if equipment.description do %>
                          <p class="text-xs text-gray-600 leading-relaxed">
                            {equipment.description}
                          </p>
                        <% end %>
                      </div>
                    </div>
                  <% end %>
                </div>
              <% else %>
                <div class="text-center py-8">
                  <div class="mx-auto h-16 w-16 text-gray-400 mb-4">
                    <Heroicons.icon name="wrench-screwdriver" type="outline" class="h-full w-full" />
                  </div>
                  <h4 class="text-sm font-medium text-gray-600 mb-2">No Equipment Found</h4>
                  <p class="text-xs text-gray-500">
                    This room doesn't have any equipment registered yet.
                  </p>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </div>

      <.footer_user />
    </div>
    """
  end
end
