defmodule MedcampWeb.InventoryReceivedLive.FormComponent do
  use MedcampWeb, :live_component

  alias Medcamp.InventoriesReceived
  alias Medcamp.Suppliers
  alias Medcamp.Rooms
  alias Medcamp.VerifyGtin

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto">
      <!-- GTIN Verification Step -->
      <div
        :if={@gtin_received == nil}
        class="bg-white rounded-lg shadow-sm border border-gray-200 p-6"
      >
        <div class="text-center mb-6">
          <div class="mx-auto w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center mb-4">
            <i class="fa fa-barcode text-2xl text-blue-600"></i>
          </div>
          <h2 class="text-2xl font-bold text-gray-900 mb-2">Scan Product GTIN</h2>
          <p class="text-gray-600">Enter or scan the GTIN barcode to begin adding inventory</p>
        </div>

        <.simple_form
          for={@form}
          id="gtin-verification-form"
          phx-target={@myself}
          phx-submit="check_gtin"
          phx-debounce="1000"
          class="space-y-6"
        >
          <div class="relative">
            <.input
              field={@form[:gtin]}
              type="text"
              label="GTIN Barcode"
              placeholder="Scan or enter GTIN number"
              class="text-center text-lg font-mono tracking-wider"
            />
            <div class="absolute top-1/2 inset-y-0 right-0 pr-3 flex items-center pointer-events-none">
              <i class="fa fa-qrcode text-gray-400"></i>
            </div>
          </div>

          <:actions>
            <.button
              class="w-full flex items-center justify-center bg-blue-600 hover:bg-blue-700 text-white font-semibold py-3 px-6 rounded-lg transition-colors"
              phx-disable-with="Verifying..."
            >
              <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
                >
                </path>
              </svg>
              Verify GTIN
            </.button>
          </:actions>
        </.simple_form>
      </div>
      
    <!-- Product Information Form -->
      <div
        :if={@gtin_received || @action == :edit}
        class="bg-white rounded-lg shadow-sm border border-gray-200"
      >
        <!-- Header -->
        <div class="border-b border-gray-200 px-6 py-4">
          <div class="flex items-center justify-between">
            <div>
              <h2 class="text-xl font-semibold text-gray-900">{@title}</h2>
              <div :if={@action == :new} class="mt-1">
                <%= if @is_verified_gtin do %>
                  <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                    <svg class="w-3 h-3 mr-1" fill="currentColor" viewBox="0 0 20 20">
                      <path
                        fill-rule="evenodd"
                        d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                        clip-rule="evenodd"
                      >
                      </path>
                    </svg>
                    GS1 Verified GTIN
                  </span>
                  <span
                    :if={@check_gtin_exist}
                    class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800"
                  >
                    <svg class="w-3 h-3 mr-1" fill="currentColor" viewBox="0 0 20 20">
                      <path
                        fill-rule="evenodd"
                        d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z"
                        clip-rule="evenodd"
                      >
                      </path>
                    </svg>
                    This product already exist in the inventory
                  </span>
                <% else %>
                  <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800">
                    <svg class="w-3 h-3 mr-1" fill="currentColor" viewBox="0 0 20 20">
                      <path
                        fill-rule="evenodd"
                        d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z"
                        clip-rule="evenodd"
                      >
                      </path>
                    </svg>
                    New GTIN - Will Be Created
                  </span>

                  <span>
                    <svg class="w-3 h-3 mr-1" fill="currentColor" viewBox="0 0 20 20">
                      <path
                        fill-rule="evenodd"
                        d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z"
                        clip-rule="evenodd"
                      >
                      </path>
                    </svg>
                    Manufacturer: {@manufacturer}
                  </span>
                <% end %>
              </div>
            </div>
          </div>
        </div>
        
    <!-- Form Content -->
        <div class="px-6 py-6">
          <.simple_form
            for={@form}
            id="inventory_received-form"
            phx-target={@myself}
            phx-change="validate"
            phx-submit="save"
            class="space-y-6"
          >
            <!-- Basic Information -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div class="space-y-6">
                <.input :if={@action == :edit} field={@form[:gtin]} type="text" label="GTIN" readonly />
                <.input field={@form[:brand_name]} required type="text" label="Brand Name" />
                <.input field={@form[:generic_name]} type="text" label="Generic Name" />
                <.input
                  field={@form[:category]}
                  type="select"
                  options={[
                    "Anaesthetics",
                    "Analgesics",
                    "ANS Drugs",
                    "Antibiotics",
                    "Anticoagulants",
                    "Antifungals",
                    "Antihistamins",
                    "Antihyperglycemics",
                    "Antineoplastics",
                    "Antiprotozoals",
                    "Antivirals",
                    "Arthritics",
                    "Cardiovascular",
                    "CNS",
                    "Dermatologicals",
                    "Disinfectants",
                    "FP",
                    "GIT",
                    "Hematinics",
                    "Ophthalmological Agents",
                    "Probiotics",
                    "Renal",
                    "Vitamins/Minerals",
                    "Water & Electrolite Balance",
                    "sutures",
                    "OTCs",
                    "ENTs",
                    "Antiemetics",
                    "PPIs",
                    "Topicals",
                    "Antimalarials",
                    "Asthmatics",
                    "Suppliments",
                    "Non- Pharma",
                    "Injectables",
                    "Antispasmodics",
                    "Cough Syrup",
                    "Pessaries",
                    "Steroids",
                    "Hormonals",
                    "NSAIDs",
                    "Laxatives",
                    "Vaccines",
                    "Needles",
                    "Syranges",
                    "Lozenges",
                    "Tripple Therapy",
                    "Antifibronolytics"
                  ]}
                  prompt="Select Category"
                  label="Category"
                />

                <.input field={@form[:description]} required type="textarea" label="Description" />
                <.input field={@form[:supplier]} type="text" label="Manufacturer" />
              </div>
              
    <!-- Product Image Upload -->

              <div class="flex flex-col space-y-4">
                <label class="block text-sm font-medium text-gray-700">Product Image</label>

                <img :if={@image} src={@image} alt="Product image" class="w-70 h-70 object-cover" />
              </div>

              <div :if={is_nil(@image)} class="space-y-4">
                <label class="block text-sm font-medium text-gray-700">Product Image</label>
                <div
                  class="border-2 border-dashed border-gray-300 rounded-lg p-6"
                  phx-drop-target={@uploads.image.ref}
                >
                  <div class="text-center">
                    <svg
                      class="mx-auto h-12 w-12 text-gray-400"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"
                      >
                      </path>
                    </svg>
                    <div class="mt-2">
                      <.live_file_input upload={@uploads.image} class="hidden" />
                      <label for={@uploads.image.ref} class="cursor-pointer">
                        <span class="text-sm text-gray-600">Drop image here or</span>
                        <span class="text-sm font-medium text-blue-600 hover:text-blue-500">
                          browse
                        </span>
                      </label>
                    </div>
                  </div>
                  
    <!-- Image Previews -->
                  <div :if={length(@uploads.image.entries) > 0} class="mt-4 space-y-3">
                    <article :for={entry <- @uploads.image.entries} class="relative">
                      <div class="flex items-center space-x-3 p-3 bg-gray-50 rounded-lg">
                        <.live_img_preview entry={entry} class="h-16 w-16 object-cover rounded" />
                        <div class="flex-1 min-w-0">
                          <p class="text-sm font-medium text-gray-900 truncate">
                            {entry.client_name}
                          </p>
                          <div class="mt-1 flex items-center space-x-2">
                            <div class="flex-1 bg-gray-200 rounded-full h-2">
                              <div
                                class="bg-blue-600 h-2 rounded-full"
                                style={"width: #{entry.progress}%"}
                              >
                              </div>
                            </div>
                            <span class="text-xs text-gray-500">{entry.progress}%</span>
                          </div>
                        </div>
                        <button
                          type="button"
                          phx-click="cancel-upload"
                          phx-value-ref={entry.ref}
                          phx-target={@myself}
                          class="text-gray-400 hover:text-red-500"
                        >
                          <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              stroke-width="2"
                              d="M6 18L18 6M6 6l12 12"
                            >
                            </path>
                          </svg>
                        </button>
                      </div>
                      <div
                        :for={err <- upload_errors(@uploads.image, entry)}
                        class="mt-1 text-sm text-red-600"
                      >
                        {error_to_string(err)}
                      </div>
                    </article>
                  </div>

                  <div :for={err <- upload_errors(@uploads.image)} class="mt-2 text-sm text-red-600">
                    {error_to_string(err)}
                  </div>
                </div>
              </div>
            </div>
            
    <!-- Product Specifications -->
            <div class="border-t border-gray-200 pt-6">
              <h3 class="text-lg font-medium text-gray-900 mb-4">Product Specifications</h3>
              <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                <.input field={@form[:strength]} type="text" label="Strength" />
                <.input field={@form[:weight]} type="text" label="Weight/Volume" />

                <.input
                  field={@form[:uom]}
                  type="select"
                  options={[
                    {"KILOGRAM", "KGM"},
                    {"GRAM", "GRM"},
                    {"MILIGRAM", "MGM"},
                    {"LITRE", "LTR"},
                    {"MILLILITRE", "MLT"},
                    {"CENTILITRE", "CTL"},
                    {"METRE", "MTR"},
                    {"CENTIMETER", "CMT"},
                    {"MILLIMETRE", "MLT"},
                    {"INCH", "INH"},
                    {"TABLET", "U2"},
                    {"PIECE", "H87"},
                    {"AMPERE", "AMP"},
                    {"PACK", "PK"},
                    {"PACKET", "PA"},
                    {"DOZEN", "DZN"},
                    {"PAIR", "PR"},
                    {"PAGE", "ZP"},
                    {"KILOWATT", "KWT"},
                    {"WATT", "WTT"},
                    {"VOLT", "VLT"},
                    {"KILOVOLT", "KVT"},
                    {"TON", "LTN"},
                    {"CAPSULE", "AV"},
                    {"OUNCE", "ONZ"},
                    {"ROLL", "RO"}
                  ]}
                  prompt="Select Unit"
                  label="Unit of Measurement"
                />
              </div>
            </div>
            
    <!-- Classification & Location -->
            <div class="border-t border-gray-200 pt-6">
              <h3 class="text-lg font-medium text-gray-900 mb-4">Classification & Location</h3>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <.input
                  field={@form[:type]}
                  type="select"
                  prompt="Select Type"
                  options={[
                    {"Medicine", "Medicine"},
                    {"Equipment", "Equipment"},
                    {"Consumable", "Consumable"}
                  ]}
                  label="Product Type"
                />
                <%!-- <.input
                  field={@form[:room_id]}
                  type="select"
                  prompt="Select Location"
                  options={@rooms}
                  label="Storage Location"
                /> --%>
              </div>
            </div>
            
    <!-- Form Actions -->
            <div class="border-t border-gray-200 pt-6 flex justify-end space-x-3">
              <button
                type="button"
                class="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50"
              >
                Cancel
              </button>

              <.button
                class="bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 px-6 rounded-md transition-colors"
                phx-disable-with="Saving..."
              >
                <div class="flex w-[100%] flex gap-3 items-center justify-center">
                  <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M5 13l4 4L19 7"
                    >
                    </path>
                  </svg>
                  Save Inventory Item
                </div>
              </.button>
            </div>
          </.simple_form>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def update(%{inventory_received: inventory_received} = assigns, socket) do
    # Initialize all assigns that might be used in the template
    # For edit mode, pull values from the existing inventory_received record
    # For new mode, set them to nil/empty strings
    is_edit_mode = assigns[:action] == :edit

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:gtin_received, if(is_edit_mode, do: inventory_received.gtin, else: nil))
     |> assign(:is_verified_gtin, false)
     |> assign(:check_gtin_exist, false)
     |> assign(:suppliers, Suppliers.list_suppliers_for_select())
     |> assign(:uploaded_files, [])
     |> assign(:current_user, assigns[:current_user])
     |> assign(:brand, if(is_edit_mode, do: inventory_received.brand_name, else: ""))
     |> assign(:desc, if(is_edit_mode, do: inventory_received.description, else: ""))
     |> assign(:manufacturer, if(is_edit_mode, do: inventory_received.supplier, else: ""))
     |> assign(:weight, if(is_edit_mode, do: inventory_received.weight, else: ""))
     |> assign(:uom, if(is_edit_mode, do: inventory_received.uom, else: nil))
     |> assign(:image, if(is_edit_mode, do: inventory_received.image, else: nil))
     |> assign(:rooms, Rooms.list_rooms_for_select())
     |> allow_upload(:image, accept: ~w(.jpg .jpeg .png), max_entries: 1)
     |> assign_new(:form, fn ->
       to_form(InventoriesReceived.change_inventory_received(inventory_received))
     end)}
  end

  @impl true

  def handle_event("check_gtin", %{"inventory_received" => %{"gtin" => gtin}}, socket) do
    case Medcamp.Gtin.validate(gtin) do
      {:ok, _body} ->
        {:ok, resp} = VerifyGtin.verify("0" <> gtin)

        IO.inspect(resp, label: "GTIN VERIFICATION RESPONSE")

        first_drug = resp |> Enum.at(0) |> IO.inspect(label: "FIRST DRUG")

        brand =
          case first_drug["brandName"] do
            [first | _] -> Map.get(first, "value")
            _ -> nil
          end

        manufacturer =
          case first_drug["gs1Licence"] do
            %{"licenseeName" => name} when not is_nil(name) -> name
            _ -> nil
          end

        desc =
          case first_drug["productDescription"] do
            [first | _] -> Map.get(first, "value")
            _ -> nil
          end

        weight =
          case first_drug["netContent"] do
            [first | _] -> Map.get(first, "value")
            _ -> nil
          end

        uom =
          case first_drug["netContent"] do
            [first | _] -> Map.get(first, "unitCode")
            _ -> nil
          end

        image =
          case first_drug["productImageUrl"] do
            [first | _] -> Map.get(first, "value")
            _ -> nil
          end

        prefilled_params = %{
          "brand_name" => brand,
          "description" => desc,
          "supplier" => manufacturer,
          "weight" => weight,
          "uom" => uom
        }

        prefilled_form =
          to_form(
            InventoriesReceived.change_inventory_received(
              socket.assigns.inventory_received,
              prefilled_params
            )
          )

        {:noreply,
         socket
         |> assign(gtin_received: gtin)
         |> assign(manufacturer: manufacturer)
         |> assign(brand: brand)
         |> assign(desc: desc)
         |> assign(weight: weight)
         |> assign(uom: uom)
         |> assign(image: image)
         |> assign(form: prefilled_form)
         |> assign(
           check_gtin_exist:
             if is_nil(InventoriesReceived.gtin_exists(gtin)) do
               false
             else
               true
             end
         )
         |> assign(is_verified_gtin: true)}

      _ ->
        {:noreply,
         socket
         |> assign(:is_verified_gtin, false)
         |> assign(:manufacturer, "")
         |> assign(:brand, "")
         |> assign(:desc, "")
         |> assign(:weight, "")
         |> assign(:uom, nil)
         |> assign(:image, nil)
         |> assign(gtin_received: gtin)}
    end
  end

  def handle_event("validate", %{"inventory_received" => inventory_received_params}, socket) do
    changeset =
      InventoriesReceived.change_inventory_received(
        socket.assigns.inventory_received,
        inventory_received_params
      )

    {:noreply,
     socket
     |> assign(form: to_form(changeset, action: :validate))
     |> assign(:manufacturer, inventory_received_params["supplier"] || "")
     |> assign(:brand, inventory_received_params["brand_name"] || "")
     |> assign(:desc, inventory_received_params["description"] || "")
     |> assign(:weight, inventory_received_params["weight"] || "")
     |> assign(:uom, inventory_received_params["uom"])}
  end

  def handle_event("gtin-lookup", %{"gtin" => gtin}, socket) do
    case InventoriesReceived.get_inventory_received_by_gtin(gtin) do
      nil ->
        {:noreply, assign(socket, gtin_received: gtin)}

      inventory_received ->
        {:noreply,
         socket
         |> put_flash(:error, "GTIN already exists")
         |> assign(gtin_received: "")
         |> assign(
           form: to_form(InventoriesReceived.change_inventory_received(inventory_received))
         )}
    end
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :image, ref)}
  end

  def handle_event("save", %{"inventory_received" => inventory_received_params}, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :image, fn %{path: path}, _entry ->
        dest = Path.join(Application.app_dir(:medcamp, "priv/uploads"), Path.basename(path))
        # You will need to create `priv/static/uploads` for `File.cp!/2` to work.
        File.cp!(path, dest)
        {:ok, ~p"/uploads/#{Path.basename(dest)}"}
      end)

    inventory_received_params =
      inventory_received_params
      |> Map.put("user_id", socket.assigns.current_user.id)
      |> Map.put("image", Enum.at(uploaded_files, 0))

    save_inventory_received(socket, socket.assigns.action, inventory_received_params)
  end

  defp save_inventory_received(socket, :edit, inventory_received_params) do
    case InventoriesReceived.update_inventory_received(
           socket.assigns.inventory_received,
           inventory_received_params
         ) do
      {:ok, _inventory_received} ->
        {:noreply,
         socket
         |> put_flash(:info, "Inventory received updated successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_inventory_received(socket, :new, inventory_received_params) do
    if socket.assigns.is_verified_gtin do
      inventory_received_params =
        inventory_received_params
        |> Map.put("gtin", socket.assigns.gtin_received)

      case InventoriesReceived.create_inventory_received(inventory_received_params) do
        {:ok, inventory_received} ->
          {:noreply,
           socket
           |> put_flash(:info, "Inventory received created successfully")
           |> push_navigate(
             to: "/inventory_manager/inventories_received/#{inventory_received.id}"
           )}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign(socket, form: to_form(changeset))}
      end
    else
      case Medcamp.CreateGtin.create(
             inventory_received_params["brand_name"],
             inventory_received_params["description"],
             inventory_received_params["uom"]
           ) do
        {:ok, response} ->
          response = Jason.decode!(response.body)

          inventory_received_params =
            inventory_received_params
            |> Map.put("gtin", response["gtin"])

          case InventoriesReceived.create_inventory_received(inventory_received_params) do
            {:ok, inventory_received} ->
              {:noreply,
               socket
               |> put_flash(:info, "Inventory received created successfully")
               |> push_navigate(
                 to: "/inventory_manager/inventories_received/#{inventory_received.id}"
               )}

            {:error, %Ecto.Changeset{} = changeset} ->
              {:noreply, assign(socket, form: to_form(changeset))}
          end

        {:error, reason} ->
          {:noreply,
           socket
           |> put_flash(:error, "Failed to create GTIN: #{reason}")}
      end
    end
  end

  def get_unit_name(code) when is_binary(code) do
    units = [
      {"KILOGRAM", "KGM"},
      {"GRAM", "GRM"},
      {"MILIGRAM", "MGM"},
      {"LITRE", "LTR"},
      {"MILLILITRE", "MLT"},
      {"CENTILITRE", "CTL"},
      {"METRE", "MTR"},
      {"CENTIMETER", "CMT"},
      {"MILLIMETRE", "MLT"},
      {"INCH", "INH"},
      {"TABLET", "U2"},
      {"PIECE", "H87"},
      {"AMPERE", "AMP"},
      {"PACK", "PK"},
      {"PACKET", "PA"},
      {"DOZEN", "DZN"},
      {"PAIR", "PR"},
      {"PAGE", "ZP"},
      {"KILOWATT", "KWT"},
      {"WATT", "WTT"},
      {"VOLT", "VLT"},
      {"KILOVOLT", "KVT"},
      {"TON", "LTN"},
      {"CAPSULE", "AV"},
      {"OUNCE", "ONZ"},
      {"ROLL", "RO"}
    ]

    case Enum.find(units, fn {_name, c} -> c == String.upcase(code) end) do
      {name, _} -> name
      nil -> "UNKNOWN"
    end
  end

  def get_unit_name(nil), do: ""

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
end
