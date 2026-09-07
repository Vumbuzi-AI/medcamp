defmodule MedcampWeb.PrescribeMedicineComponent do
  alias Medcamp.InventoriesReceived
  use MedcampWeb, :live_component
  alias Medcamp.DrugAllocations
  alias Medcamp.Drugs

  @impl true
  @drug_categories [
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
  ]
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Prescribe Medicine for {[@patient.first_name, @patient.middle_name, @patient.last_name]
        |> Enum.filter(&(&1 != nil))
        |> Enum.join(" ")}
      </.header>

      <.simple_form
        for={@form}
        id="drug_allocation-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="mb-4">
          <div class="flex justify-between items-center mb-2">
            <h3 class="text-lg font-medium">Selected Drugs</h3>
            <.button type="button" phx-click="open_drug_modal" phx-target={@myself}>
              <.icon name="hero-plus" class="mr-1 h-4 w-4" /> Add Drug
            </.button>
          </div>

          <div class="bg-gray-50 rounded-md p-3">
            <%= if Enum.empty?(@selected_drugs) do %>
              <p class="text-gray-500 italic">No drugs selected yet</p>
            <% else %>
              <div class="space-y-3">
                <%= for {drug, index} <- Enum.with_index(@selected_drugs) do %>
                  <div class="flex items-start justify-between bg-white p-3 rounded border">
                    <div>
                      <h4 class="font-medium">
                        {drug.inventory_received.strength} {drug.brand_name}
                      </h4>
                      <p class="text-sm text-gray-600">{drug.generic_name}</p>
                      <p class="text-sm">
                        {drug.quantity} | {drug.frequency} | {drug.duration_in_days} days
                        | {drug.route_of_administration}
                      </p>
                      <p class="text-sm font-medium text-green-600">
                        Price: {drug.price} KES
                      </p>
                    </div>
                    <button
                      type="button"
                      class="text-red-500 hover:text-red-700"
                      phx-click="remove_drug"
                      phx-target={@myself}
                      phx-value-index={index}
                    >
                      <.icon name="hero-trash" class="h-5 w-5" />
                    </button>
                  </div>
                <% end %>

                <div class="mt-4 text-right">
                  <span class="text-gray-600">Total:</span>
                  <span class="font-bold text-lg ml-2">{@total_price || 0} KES</span>
                </div>
              </div>
            <% end %>
          </div>
        </div>

        <.input
          field={@form[:prescription]}
          type="textarea"
          label="Prescription note to pharmacist.."
        />

        <.input
          field={@form[:payment_type]}
          type="select"
          options={["Mpesa", "Insurance"]}
          prompt="Select payment type"
          label="Payment Type"
        />

        <%= if @payment_type == "Insurance" do %>
          <.input
            field={@form[:insurance_name]}
            type="select"
            prompt="Select insurance provider"
            options={["GHCE", "Altiora School"]}
            label="Insurance Provider"
            required={true}
          />
        <% end %>

        <:actions>
          <.button phx-disable-with="Saving...">Prescribe Drug</.button>
        </:actions>
      </.simple_form>

      <%= if @show_drug_modal do %>
        <.modal
          id="drug-modal"
          show={@show_drug_modal}
          on_cancel={JS.push("close_drug_modal", target: @myself)}
        >
          <.header>Add Drug</.header>
          <.simple_form
            for={@drug_form}
            id="drug-form"
            phx-target={@myself}
            phx-submit="add_drug"
            class="flex flex-col gap-2"
          >
            <div :if={@selected_drug == nil} class="mb-4">
              <label class="block text-sm font-medium text-gray-700 mb-1">Search For Drugssd</label>
              <.input
                type="select"
                field={@form[:query]}
                options={@drug_categories}
                prompt="Filter by category"
                label="Filter by category"
                phx-change="filter_drugs"
              />
              <input
                type="text"
                name="query"
                value={@searched_query}
                phx-change="search_drugs"
                phx-target={@myself}
                class="block mt-4 w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              />
            </div>

            <%= if @searched_drugs && length(@searched_drugs) > 0 && @selected_drug == nil  do %>
              <div class="mt-2 mb-4">
                <label class="block text-sm font-medium mb-1">Select a drug</label>
                <div class="max-h-48 overflow-y-auto border rounded-md">
                  <%= for {drug, index} <- Enum.with_index(@searched_drugs) do %>
                    <div
                      class="p-2 hover:bg-gray-100 cursor-pointer border-b last:border-b-0"
                      phx-click="select_drug"
                      phx-target={@myself}
                      phx-value-id={drug.id}
                    >
                      <div class="flex items-center justify-between gap-3">
                        <p class="font-medium">
                          {drug.inventory_received.strength} {drug.inventory_received.weight} {drug.inventory_received.uom} - {drug.brand_name}
                        </p>
                        <span
                          :if={index == 0}
                          class="inline-flex items-center rounded-full bg-green-100 px-2 py-1 text-xs font-medium text-green-700"
                        >
                          Give this first
                        </span>
                      </div>
                      <p class="text-sm text-gray-600">{drug.generic_name}</p>
                      <.available_batches_preview drug={drug} />
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>

            <%= if @selected_drug do %>
              <div>
                Only {Medcamp.DrugBatches.check_available_quantity(@selected_drug.inventory_received_id)} units available
              </div>
              <div class="bg-blue-50 p-3 rounded-md mb-4">
                <p class="font-medium">{@selected_drug.brand_name}</p>
                <p class="text-sm">{@selected_drug.generic_name}</p>
              </div>

              <input type="hidden" name="drug_form[brand_name]" value={@selected_drug.brand_name} />
              <input type="hidden" name="drug_form[generic_name]" value={@selected_drug.generic_name} />
              <input type="hidden" name="drug_form[inventory_received_id]" value={@selected_drug.id} />

              <div class="mb-4">
                <label for="drug_form_frequency" class="block text-sm font-medium text-gray-700 mb-1">
                  Frequency
                </label>
                <select
                  id="drug_form_frequency"
                  name="drug_form[frequency]"
                  class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                >
                  <option value="">Select frequency</option>
                  <option value="Once daily">Once daily</option>
                  <option value="Twice daily">Twice daily</option>
                  <option value="Three times daily">Three times daily</option>
                  <option value="Four times daily">Four times daily</option>
                  <option value="As needed">As needed</option>
                  <option value="Stat dose">Stat dose</option>
                </select>
              </div>

              <div class="mb-4">
                <label
                  for="drug_form_duration_in_days"
                  class="block text-sm font-medium text-gray-700 mb-1"
                >
                  Duration (days)
                </label>
                <input
                  id="drug_form_duration_in_days"
                  name="drug_form[duration_in_days]"
                  type="number"
                  min="1"
                  value={@drug_form[:duration_in_days] && @drug_form[:duration_in_days].value}
                  class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                />
              </div>
              <div class="mb-4">
                <label
                  for="drug_form_route_of_administration"
                  class="block text-sm font-medium text-gray-700 mb-1"
                >
                  Route of Administration
                </label>
                <select
                  id="drug_form_route_of_administration"
                  name="drug_form[route_of_administration]"
                  class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                >
                  <option value="">Select route</option>
                  <option value="Oral">Oral</option>
                  <option value="Intravenous">Intravenous</option>
                  <option value="Intramuscular">Intramuscular</option>
                  <option value="Topical">Topical</option>
                  <option value="Inhalation">Inhalation</option>
                  <option value="Subcutaneous">Subcutaneous</option>
                  <option value="Rectal">Rectal</option>
                  <option value="Buccal">Buccal</option>
                  <option value="Vaginal">Vaginal</option>
                  <option value="Ophthalmic">Ophthalmic</option>
                  <option value="Sublingual">Sublingual</option>
                  <option value="Otic">Otic</option>
                  <option value="Transdermal">Transdermal</option>
                  <option value="Nasal">Nasal</option>
                </select>
              </div>
              <div class="mb-4">
                <label for="drug_form_quantity" class="block text-sm font-medium text-gray-700 mb-1">
                  Quantity
                </label>
                <input
                  id="drug_form_quantity"
                  name="drug_form[quantity]"
                  type="number"
                  min="1"
                  value={@drug_form[:quantity] && @drug_form[:quantity].value}
                  class={[
                    "block w-full rounded-md shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm",
                    if(@drug_form[:quantity] && @drug_form[:quantity].errors != [],
                      do: "border-red-300",
                      else: "border-gray-300"
                    )
                  ]}
                />
                <%= if @drug_form[:quantity] && @drug_form[:quantity].errors != [] do %>
                  <div class="mt-1 text-sm text-red-600">
                    {error_message(@drug_form[:quantity].errors)}
                  </div>
                <% end %>
              </div>

              <div class="mb-4">
                <label
                  for="drug_form_duration_in_days"
                  class="block text-sm font-medium text-gray-700 mb-1"
                >
                  Prescription Note
                </label>
                <textarea
                  id="drug_form_prescription_note"
                  name="drug_form[prescription_note]"
                  placeholder="Note to Print on Prescription eg 2 x 1"
                  value={@drug_form[:prescription_note] && @drug_form[:prescription_note].value}
                  class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                />
              </div>
              <p class="text-red-500">
                Fill in all fields to add the drug to the prescription.
              </p>
            <% end %>

            <div class="flex justify-end space-x-2 mt-4">
              <button
                type="button"
                phx-click="close_drug_modal"
                phx-target={@myself}
                class="px-4 py-2 bg-gray-300 hover:bg-gray-400 rounded-md text-gray-800"
              >
                Cancel
              </button>
              <button
                type="submit"
                class="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 rounded-md text-white"
                disabled={is_nil(@selected_drug)}
              >
                Add Drug
              </button>
            </div>
          </.simple_form>
        </.modal>
      <% end %>
    </div>
    """
  end

  @impl true
  def update(%{drug_allocation: drug_allocation} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:searched_query, "")
     |> assign(:filtered_query, "")
     |> assign(:searched_drugs, [])
     |> assign(:selected_drugs, [])
     |> assign(:total_price, 0)
     |> assign(:show_drug_modal, false)
     |> assign(:drug_categories, @drug_categories)
     |> assign(:selected_drug, nil)
     |> assign(:payment_type, assigns[:payment_type] || drug_allocation.payment_type || "")
     |> assign_new(:form, fn ->
       to_form(DrugAllocations.change_drug_allocation(drug_allocation))
     end)
     |> assign_new(:drug_form, fn ->
       to_form(
         Medcamp.DrugAllocations.DrugAssigned.changeset(%Medcamp.DrugAllocations.DrugAssigned{}, %{})
       )
     end)}
  end

  @impl true
  def handle_event("search_drugs", %{"drug_allocation" => %{"query" => query}}, socket) do
    searched_drugs =
      Drugs.search_drugs(query)
      |> Enum.filter(fn test ->
        test.inventory_received.brand_name not in Enum.map(
          socket.assigns.selected_drugs,
          & &1.brand_name
        )
      end)

    {:noreply,
     socket
     |> assign(searched_query: query)
     |> assign(searched_drugs: searched_drugs)}
  end

  def handle_event("filter_drugs", %{"drug_allocation" => %{"query" => query}}, socket) do
    searched_drugs =
      Drugs.search_drugs_by_category(query)

    {:noreply,
     socket
     |> assign(filtered_query: query)
     |> assign(searched_drugs: searched_drugs)}
  end

  def handle_event("search_drugs", %{"query" => query}, socket) do
    searched_drugs =
      Drugs.search_drugs(query)
      |> Enum.filter(fn test ->
        test.inventory_received.brand_name not in Enum.map(
          socket.assigns.selected_drugs,
          & &1.brand_name
        )
      end)

    {:noreply,
     socket
     |> assign(searched_query: query)
     |> assign(searched_drugs: searched_drugs)}
  end

  @impl true
  def handle_event("open_drug_modal", _, socket) do
    {:noreply,
     socket
     |> assign(:show_drug_modal, true)
     |> assign_new(:drug_form, fn ->
       to_form(
         Medcamp.DrugAllocations.DrugAssigned.changeset(%Medcamp.DrugAllocations.DrugAssigned{}, %{})
       )
     end)}
  end

  @impl true
  def handle_event("close_drug_modal", _, socket) do
    {:noreply,
     socket
     |> assign(:show_drug_modal, false)
     |> assign(:searched_query, "")
     |> assign(:searched_drugs, [])
     |> assign(:selected_drug, nil)}
  end

  def handle_event("select_drug", %{"id" => id}, socket) do
    drug = Drugs.get_drug!(id)

    {:noreply,
     socket
     |> assign(:selected_drug, drug)
     |> assign(:drug_form, to_form(%{}))}
  end

  @impl true

  def handle_event("add_drug", %{"drug_form" => params}, socket) do
    params =
      params
      |> Map.put("inventory_received_id", socket.assigns.selected_drug.inventory_received_id)

    changeset =
      Medcamp.DrugAllocations.DrugAssigned.changeset(%Medcamp.DrugAllocations.DrugAssigned{}, params)

    if changeset.valid? do
      # Get the drug data
      drug_data = Ecto.Changeset.apply_changes(changeset)

      # Calculate price
      inventory_received_id = drug_data.inventory_received_id
      quantity = drug_data.quantity
      inventory_received = InventoriesReceived.get_inventory_received!(inventory_received_id)

      case Medcamp.DrugAllocations.calculate_price(inventory_received_id, quantity) do
        %{total_price: total_price, allocations: allocations} ->
          # Add price and batch allocation info to the drug data
          drug_data =
            Map.merge(drug_data, %{
              price: total_price,
              batch_allocations: allocations,
              inventory_received: inventory_received
            })

          # Add the new drug to the selected drugs list
          selected_drugs = socket.assigns.selected_drugs ++ [drug_data]

          # Calculate total price of all selected drugs
          total_price =
            Enum.reduce(selected_drugs, 0, fn drug, acc ->
              acc + (drug.price || 0)
            end)

          {:noreply,
           socket
           |> assign(:selected_drugs, selected_drugs)
           |> assign(:total_price, total_price)
           |> assign(:show_drug_modal, false)
           |> assign(:searched_query, "")
           |> assign(:searched_drugs, [])
           |> assign(:selected_drug, nil)}

        _ ->
          # Handle error case
          changeset = Ecto.Changeset.add_error(changeset, :quantity, "Unable to calculate price")
          {:noreply, assign(socket, :drug_form, to_form(changeset, action: :validate))}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("remove_drug", %{"index" => index}, socket) do
    index = String.to_integer(index)
    selected_drugs = List.delete_at(socket.assigns.selected_drugs, index)

    {:noreply, assign(socket, :selected_drugs, selected_drugs)}
  end

  def handle_event("remove_drug-" <> id, _, socket) do
    selected_drugs =
      socket.assigns.selected_drugs |> Enum.reject(&(&1.id == String.to_integer(id)))

    searched_drugs =
      Drugs.search_drugs(socket.assigns.searched_query)
      |> Enum.filter(fn test ->
        test.id not in Enum.map(selected_drugs, & &1.id)
      end)

    {:noreply,
     socket
     |> assign(searched_drugs: searched_drugs)
     |> assign(selected_drugs: selected_drugs)}
  end

  def handle_event("validate", %{"drug_allocation" => drug_allocation_params}, socket) do
    payment_type = drug_allocation_params["payment_type"] || socket.assigns.payment_type

    changeset =
      DrugAllocations.change_drug_allocation(
        socket.assigns.drug_allocation,
        drug_allocation_params
      )

    {:noreply,
     socket
     |> assign(:payment_type, payment_type)
     |> assign(form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"drug_allocation" => drug_allocation_params}, socket) do
    drugs_assigned =
      socket.assigns.selected_drugs
      |> Enum.map(fn drug ->
        %{
          brand_name: drug.brand_name,
          generic_name: drug.generic_name,
          inventory_received_id: drug.inventory_received_id,
          quantity: drug.quantity,
          frequency: drug.frequency,
          duration_in_days: drug.duration_in_days,
          route_of_administration: drug.route_of_administration,
          prescription_note: drug.prescription_note,
          price: drug.price
        }
      end)

    is_insurance = drug_allocation_params["payment_type"] == "Insurance"

    drug_allocation_params =
      drug_allocation_params
      |> Map.put("doctor_id", socket.assigns.current_user.id)
      |> Map.put("doctor_note_id", socket.assigns.doctor_note.id)
      |> Map.put("drugs_assigned", drugs_assigned)
      |> Map.put("patient_id", socket.assigns.patient.id)
      |> Map.put("has_paid", is_insurance)

    case DrugAllocations.create_drug_allocation(drug_allocation_params) do
      {:ok, _drug_allocation} ->
        {:noreply,
         socket
         |> put_flash(:info, "Drug prescribed successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp error_message(errors) do
    Enum.map(errors, fn {msg, _opts} -> msg end) |> Enum.join(", ")
  end
end
