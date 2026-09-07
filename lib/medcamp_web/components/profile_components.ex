defmodule MedcampWeb.ProfileComponents do
  use Phoenix.Component
  import MedcampWeb.CoreComponents

  def profile_section(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-5">
      <div class="bg-white rounded-xl shadow-md p-6 mb-5">
        <h2 class="text-xl spartan-bold text-gray-900 mb-5">Profile Information</h2>

        <.form
          for={@form}
          id="profile-form"
          phx-submit="save-profile"
          phx-change="validate-profile"
          class="space-y-5"
        >
          <div class="flex flex-col items-center mb-6" phx-drop-target={@uploads.image.ref}>
            <label for="profile_image_input" class="cursor-pointer block">
              <div class="relative group">
                <%= if @current_user.image do %>
                  <img
                    src={@current_user.image}
                    alt="Profile Photo"
                    class="h-40 w-40 rounded-full object-cover border-4 border-blue-100"
                  />
                  <div class="absolute inset-0 flex items-center justify-center bg-black bg-opacity-40 rounded-full opacity-0 group-hover:opacity-100 transition-opacity">
                    <div class="absolute inset-0 flex items-center justify-center bg-black bg-opacity-30 rounded-full opacity-0 group-hover:opacity-100 transition-opacity">
                      <div class="text-white flex flex-col justify-center text-center text-center">
                        <i class="fa fa-user text-xl"></i>

                        <label class="mt-4 inline-flex items-center px-4  rounded-md shadow-sm text-sm font-medium text-white  cursor-pointer">
                          <p class="text-xs">Change Photo</p>
                          <.live_file_input upload={@uploads.image} class="hidden" />
                        </label>
                      </div>
                    </div>
                  </div>
                <% else %>
                  <div class="h-40 w-40 rounded-full bg-[#0047AB]  flex items-center justify-center text-blue-500 text-4xl">
                    <i class="fa fa-user text-white"></i>
                    <div class="absolute inset-0 flex items-center justify-center bg-black bg-opacity-30 rounded-full opacity-0 group-hover:opacity-100 transition-opacity">
                      <div class="text-white flex flex-col justify-center text-center text-center">
                        <i class="fa fa-user text-xl"></i>

                        <label class="mt-4 inline-flex items-center px-4  rounded-md shadow-sm text-sm font-medium text-white  cursor-pointer">
                          <p class="text-xs">Upload Photo</p>
                          <.live_file_input upload={@uploads.image} class="hidden" />
                        </label>
                      </div>
                    </div>
                  </div>
                <% end %>
              </div>
            </label>
            <p class="text-gray-500 spartan-regular text-xl">Tap to change profile photo</p>

            <%= for entry <- @uploads.image.entries do %>
              <div class="mt-2 w-full max-w-xs">
                <div class="relative pt-1">
                  <div class="text-xs text-center mb-1">
                    {entry.client_name}
                  </div>
                  <div class="overflow-hidden h-2 text-xs flex rounded bg-blue-200">
                    <div
                      style={"width: #{entry.progress}%"}
                      class="shadow-none flex flex-col text-center whitespace-nowrap text-white justify-center bg-blue-500 transition-all duration-500"
                    >
                    </div>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
          <div class="w-[100%] gap-5">
            <div>
              <label
                for="first_name"
                class="block text-sm font-medium text-gray-700 mb-1 spartan-medium"
              >
                Email
              </label>

              <.input
                field={@form[:email]}
                disabled
                type="text"
                class="text-lg py-4 px-4 rounded-xl text-[#3D3D3D] placeholder-[#3D3D3D] border-2 h-32 w-full"
              />
            </div>
          </div>

          <div class="grid grid-cols-2 gap-5">
            <div>
              <label
                for="first_name"
                class="block text-sm font-medium text-gray-700 mb-1 spartan-medium"
              >
                Name
              </label>

              <.input
                field={@form[:name]}
                type="text"
                class="text-lg py-4 px-4 rounded-xl text-[#3D3D3D] placeholder-[#3D3D3D] border-2 h-32 w-full"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1 spartan-medium">
                License Number
              </label>

              <.input
                field={@form[:license_number]}
                type="text"
                class="text-lg py-4 px-4 rounded-xl text-[#3D3D3D] placeholder-[#3D3D3D] border-2 h-32 w-full"
              />
            </div>
          </div>

          <div class="grid grid-cols-2 gap-5">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1 spartan-medium">
                Phone Number
              </label>

              <.input
                field={@form[:phone_number]}
                type="text"
                class="text-lg py-4 px-4 rounded-xl text-[#3D3D3D] placeholder-[#3D3D3D] border-2 h-32 w-full"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1 spartan-medium">
                ID Number
              </label>

              <.input
                field={@form[:id_number]}
                type="text"
                class="text-lg py-4 px-4 rounded-xl text-[#3D3D3D] placeholder-[#3D3D3D] border-2 h-32 w-full"
              />
            </div>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1 spartan-medium">
              Experience
            </label>

            <.input
              field={@form[:experience]}
              type="textarea"
              class="text-lg py-4 px-4 rounded-xl text-[#3D3D3D] placeholder-[#3D3D3D] border-2 h-32 w-full"
            />
          </div>

          <div class="pt-2">
            <button
              type="submit"
              class="w-full bg-[#0047AB] text-white py-3 px-4 rounded-lg text-lg spartan-medium shadow-md hover:bg-blue-700 transition-colors"
            >
              Save Profile
            </button>
          </div>
        </.form>
      </div>
    </div>
    """
  end
end
