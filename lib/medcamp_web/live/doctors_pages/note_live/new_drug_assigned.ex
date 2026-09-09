defmodule MedcampWeb.NewDrugAssignedComponent do
  use MedcampWeb, :live_component
  alias Medcamp.DrugAllocations
  alias Medcamp.Drugs

  @impl true
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

          <div class="bg-slate-50 rounded-md p-3">
            <%= if Enum.empty?(@selected_drugs) do %>
              <p class="text-slate-500 italic">No drugs selected yet</p>
            <% else %>
              <div class="space-y-3">
                <%= for {drug, index} <- Enum.with_index(@selected_drugs) do %>
                  <div class="flex items-start justify-between bg-white p-3 rounded border">
                    <div>
                      <h4 class="font-medium">{drug.brand_name}</h4>
                      <p class="text-sm text-slate-600">{drug.generic_name}</p>
                      <p class="text-sm">
                        {drug.quantity} {drug.unit_of_measurement} | {drug.frequency} | {drug.duration_in_days} days
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
                  <span class="text-slate-600">Total:</span>
                  <span class="font-bold text-lg ml-2">{@total_price || 0} KES</span>
                </div>
              </div>
            <% end %>
          </div>
        </div>

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
          <.simple_form for={@drug_form} id="drug-form" phx-target={@myself} phx-submit="add_drug">
            <div :if={@selected_drug == nil} class="mb-4">
              <label class="block text-sm font-medium text-slate-700 mb-1">Search For Drugs</label>
              <input
                type="text"
                name="query"
                value={@searched_query}
                phx-change="search_drugs"
                phx-target={@myself}
                class="block w-full rounded-md border-slate-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              />
            </div>

            <%= if @searched_drugs && length(@searched_drugs) > 0 && @selected_drug == nil  do %>
              <div class="mt-2 mb-4">
                <label class="block text-sm font-medium mb-1">Select a drug</label>
                <div class="max-h-48 overflow-y-auto border rounded-md">
                  <%= for {drug, index} <- Enum.with_index(@searched_drugs) do %>
                    <div
                      class="p-2 hover:bg-slate-100 cursor-pointer border-b last:border-b-0"
                      phx-click="select_drug"
                      phx-target={@myself}
                      phx-value-id={drug.id}
                    >
                      <div class="flex items-center justify-between gap-3">
                        <p class="font-medium">
                          {drug.inventory_received.strength} {drug.brand_name}
                        </p>
                        <span
                          :if={index == 0}
                          class="inline-flex items-center rounded-full bg-green-100 px-2 py-1 text-xs font-medium text-green-700"
                        >
                          Give this first
                        </span>
                      </div>
                      <p class="text-sm text-slate-600">{drug.generic_name}</p>
                      <.available_batches_preview drug={drug} />
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>

            <%= if @selected_drug do %>
              <div class="bg-blue-50 p-3 rounded-md mb-4">
                <p class="font-medium">{@selected_drug.brand_name}</p>
                <p class="text-sm">{@selected_drug.generic_name}</p>
              </div>

              <input type="hidden" name="drug_form[brand_name]" value={@selected_drug.brand_name} />
              <input type="hidden" name="drug_form[generic_name]" value={@selected_drug.generic_name} />
              <input
                type="hidden"
                name="drug_form[inventory_received_id]"
                value={@selected_drug.inventory_received_id}
              />
              <div class="mb-4">
                <label for="drug_form_strength" class="block text-sm font-medium text-slate-700 mb-1">
                  Strength (625 mg, 500 mg, etc.)
                </label>
                <input
                  id="drug_form_strength"
                  name="drug_form[strength]"
                  type="text"
                  value={@drug_form[:strength] && @drug_form[:strength].value}
                  class="block w-full rounded-md border-slate-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                />
              </div>

              <div class="mb-4">
                <label for="drug_form_frequency" class="block text-sm font-medium text-slate-700 mb-1">
                  Frequency
                </label>
                <select
                  id="drug_form_frequency"
                  name="drug_form[frequency]"
                  class="block w-full rounded-md border-slate-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
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
                  class="block text-sm font-medium text-slate-700 mb-1"
                >
                  Duration (days)
                </label>
                <input
                  id="drug_form_duration_in_days"
                  name="drug_form[duration_in_days]"
                  type="number"
                  min="1"
                  value={@drug_form[:duration_in_days] && @drug_form[:duration_in_days].value}
                  class="block w-full rounded-md border-slate-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                />
              </div>
              <div class="mb-4">
                <label
                  for="drug_form_route_of_administration"
                  class="block text-sm font-medium text-slate-700 mb-1"
                >
                  Route of Administration
                </label>
                <select
                  id="drug_form_route_of_administration"
                  name="drug_form[route_of_administration]"
                  class="block w-full rounded-md border-slate-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
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
                <label for="drug_form_quantity" class="block text-sm font-medium text-slate-700 mb-1">
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
                      else: "border-slate-300"
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
                  class="block text-sm font-medium text-slate-700 mb-1"
                >
                  Prescription Notewer
                </label>
                <input
                  id="drug_form_prescription_note"
                  name="drug_form[prescription_note]"
                  type="textarea"
                  placeholder="Note to Print on Prescription eg 2 x 1"
                  value={@drug_form[:prescription_note] && @drug_form[:prescription_note].value}
                  class="block w-full rounded-md border-slate-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                />
              </div>
            <% end %>

            <div class="flex justify-end space-x-2 mt-4">
              <button
                type="button"
                phx-click="close_drug_modal"
                phx-target={@myself}
                class="px-4 py-2 bg-slate-300 hover:bg-slate-400 rounded-md text-slate-800"
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
     |> assign(:searched_drugs, [])
     |> assign(:selected_drugs, [])
     |> assign(:total_price, 0)
     |> assign(:show_drug_modal, false)
     |> assign(:searched_query, "")
     |> assign(:selected_drug, nil)
     |> assign_new(:form, fn ->
       to_form(DrugAllocations.change_drug_allocation(drug_allocation))
     end)
     |> assign_new(:drug_form, fn ->
       to_form(
         Medcamp.DrugAllocations.DrugAssigned.changeset(
           %Medcamp.DrugAllocations.DrugAssigned{},
           %{}
         )
       )
     end)}
  end

  @impl true
  def handle_event("search_drugs", %{"drug_allocation" => %{"query" => query}}, socket) do
    searched_drugs = search_available_drugs(query, socket.assigns.selected_drugs)

    {:noreply,
     socket
     |> assign(searched_query: query)
     |> assign(searched_drugs: searched_drugs)}
  end

  def handle_event("search_drugs", %{"query" => query}, socket) do
    searched_drugs = search_available_drugs(query, socket.assigns.selected_drugs)

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
         Medcamp.DrugAllocations.DrugAssigned.changeset(
           %Medcamp.DrugAllocations.DrugAssigned{},
           %{}
         )
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
      Map.put(params, "inventory_received_id", socket.assigns.selected_drug.inventory_received_id)

    changeset =
      Medcamp.DrugAllocations.DrugAssigned.changeset(
        %Medcamp.DrugAllocations.DrugAssigned{},
        params
      )

    if changeset.valid? do
      # Get the drug data
      drug_data = Ecto.Changeset.apply_changes(changeset)

      if dispensed_drug_exists?(
           socket.assigns.drug_allocation.drugs_assigned,
           drug_data.inventory_received_id
         ) do
        changeset =
          Ecto.Changeset.add_error(
            changeset,
            :brand_name,
            "This drug has already been dispensed on this prescription"
          )

        {:noreply,
         socket
         |> put_flash(:error, "This drug has already been dispensed on this prescription")
         |> assign(:drug_form, to_form(changeset, action: :validate))}
      else
        inventory_received_id = drug_data.inventory_received_id
        quantity = drug_data.quantity

        case Medcamp.DrugAllocations.calculate_price(inventory_received_id, quantity) do
          %{total_price: total_price, allocations: allocations} ->
            drug_data =
              Map.merge(drug_data, %{
                price: total_price,
                batch_allocations: allocations
              })

            selected_drugs = upsert_selected_drug(socket.assigns.selected_drugs, drug_data)

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
            changeset =
              Ecto.Changeset.add_error(changeset, :quantity, "Unable to calculate price")

            {:noreply, assign(socket, :drug_form, to_form(changeset, action: :validate))}
        end
      end
    else
      {:noreply, assign(socket, :drug_form, to_form(changeset, action: :validate))}
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
      socket.assigns.selected_drugs
      |> Enum.reject(fn drug ->
        to_string(drug_inventory_received_id(drug)) == id or to_string(Map.get(drug, :id)) == id
      end)

    searched_drugs = search_available_drugs(socket.assigns.searched_query, selected_drugs)

    {:noreply,
     socket
     |> assign(searched_drugs: searched_drugs)
     |> assign(selected_drugs: selected_drugs)}
  end

  def handle_event("validate", %{"drug_allocation" => drug_allocation_params}, socket) do
    changeset =
      DrugAllocations.change_drug_allocation(
        socket.assigns.drug_allocation,
        drug_allocation_params
      )

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", _, socket) do
    # First convert existing drug_allocation.drugs_assigned to maps
    existing_drugs_assigned =
      socket.assigns.drug_allocation.drugs_assigned
      |> Enum.map(&normalize_drug_assignment/1)

    # Format the new drugs to be added
    new_drugs_assigned =
      socket.assigns.selected_drugs
      |> Enum.map(fn drug ->
        %{
          brand_name: drug.brand_name,
          generic_name: drug.generic_name,
          inventory_received_id: drug.inventory_received_id,
          quantity: drug.quantity,
          unit_of_measurement: drug.unit_of_measurement,
          frequency: drug.frequency,
          strength: drug.strength,
          duration_in_days: drug.duration_in_days,
          route_of_administration: drug.route_of_administration,
          prescription_note: drug.prescription_note,
          price: drug.price
        }
      end)

    merged_drugs_assigned =
      merge_existing_and_selected_drugs(existing_drugs_assigned, new_drugs_assigned)

    # Combine the lists and update the drug_allocation
    case DrugAllocations.update_drug_allocation(
           socket.assigns.drug_allocation,
           %{
             drugs_assigned: merged_drugs_assigned
           }
         ) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Prescription updated successfully")
         |> push_navigate(to: socket.assigns.return_url)}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(:form, to_form(changeset, action: :validate))
         |> put_flash(:error, "Failed to assign drugs")}
    end
  end

  defp error_message(errors) do
    Enum.map(errors, fn {msg, _opts} -> msg end) |> Enum.join(", ")
  end

  defp search_available_drugs(query, selected_drugs) do
    selected_inventory_ids =
      selected_drugs
      |> Enum.map(&drug_inventory_received_id/1)
      |> MapSet.new()

    Drugs.search_drugs(query)
    |> Enum.reject(fn drug ->
      MapSet.member?(selected_inventory_ids, drug.inventory_received_id)
    end)
  end

  defp upsert_selected_drug(selected_drugs, new_drug) do
    selected_drugs
    |> Enum.reject(fn drug ->
      drug_inventory_received_id(drug) == new_drug.inventory_received_id
    end)
    |> Kernel.++([new_drug])
  end

  defp dispensed_drug_exists?(drugs_assigned, inventory_received_id) do
    Enum.any?(drugs_assigned, fn drug ->
      drug_inventory_received_id(drug) == inventory_received_id and drug_has_been_given?(drug)
    end)
  end

  defp merge_existing_and_selected_drugs(existing_drugs_assigned, new_drugs_assigned) do
    Enum.reduce(new_drugs_assigned, existing_drugs_assigned, fn selected_drug, acc ->
      case Enum.find_index(acc, fn existing_drug ->
             drug_inventory_received_id(existing_drug) == selected_drug.inventory_received_id and
               not drug_has_been_given?(existing_drug)
           end) do
        nil ->
          acc ++ [selected_drug]

        index ->
          existing_drug = Enum.at(acc, index)
          List.replace_at(acc, index, merge_drug_assignment(existing_drug, selected_drug))
      end
    end)
  end

  defp merge_drug_assignment(existing_drug, selected_drug) do
    existing_id = Map.get(existing_drug, :id)
    pharmacist_note = Map.get(existing_drug, :pharmacist_note)
    has_been_given = Map.get(existing_drug, :has_been_given, false)

    selected_drug
    |> Map.put(:has_been_given, has_been_given)
    |> maybe_put(:id, existing_id)
    |> maybe_put(:pharmacist_note, pharmacist_note)
  end

  defp normalize_drug_assignment(%{__struct__: _} = drug),
    do: drug |> Map.from_struct() |> Map.delete(:__struct__)

  defp normalize_drug_assignment(drug) when is_map(drug), do: drug

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp drug_inventory_received_id(drug) do
    Map.get(drug, :inventory_received_id) || Map.get(drug, "inventory_received_id")
  end

  defp drug_has_been_given?(drug) do
    Map.get(drug, :has_been_given, Map.get(drug, "has_been_given", false))
  end
end
