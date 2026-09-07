defmodule MedcampWeb.LabAllocationLive.Show do
  use MedcampWeb, :lab_live_view

  alias Medcamp.Batches
  alias Medcamp.LabAllocations
  alias Medcamp.LabConsumables
  alias Medcamp.LabConsumables.LabConsumable

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :lab_allocations)}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _, socket) do
    lab_allocation = LabAllocations.get_lab_allocation!(id)
    consumables = LabConsumables.list_lab_consumables_for_allocation(lab_allocation.id)

    total_consumed =
      consumables
      |> Enum.map(&String.to_integer(&1.consumed_quantity))
      |> Enum.sum()

    quantity_in_store = quantity_in_store_for(lab_allocation)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:lab_allocation, lab_allocation)
     |> assign(:total_consumed, total_consumed)
     |> assign(:quantity_in_store, quantity_in_store)
     |> assign(:requisition_prefill, nil)
     |> assign(:lab_consumables_count, length(consumables))
     |> stream(:lab_consumables, consumables)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp quantity_in_store_for(lab_allocation) do
    case lab_allocation.inventory_issued && lab_allocation.inventory_issued.inventory_received_id do
      nil ->
        nil

      inventory_received_id ->
        case Batches.get_inventory_by_received_id(inventory_received_id) do
          %{quantity_in_stock: total} -> total
          _ -> 0
        end
    end
  end

  defp apply_action(socket, :edit, _params) do
    socket
  end

  defp apply_action(socket, :new_consumable, _params) do
    socket
    |> assign(:lab_consumable, %LabConsumable{lab_allocation_id: socket.assigns.lab_allocation.id})
  end

  defp apply_action(socket, :show, _params) do
    socket
    |> assign(:lab_consumable, nil)
    |> assign(:requisition_prefill, nil)
  end

  @impl true
  def handle_info(
        {MedcampWeb.RequisitionLive.RequisitionForItemComponent, {:saved, _requisition}},
        socket
      ) do
    {:noreply, socket}
  end

  def handle_info({MedcampWeb.LabConsumableLive.FormComponent, {:saved, lab_consumable}}, socket) do
    lab_consumable = Medcamp.Repo.preload(lab_consumable, :patient)

    # Update remaining quantity after consumption
    updated_allocation =
      update_remaining_quantity(socket.assigns.lab_allocation, lab_consumable.consumed_quantity)

    # Recalculate total consumed
    new_total_consumed =
      socket.assigns.total_consumed + String.to_integer(lab_consumable.consumed_quantity)

    {:noreply,
     socket
     |> assign(:lab_allocation, updated_allocation)
     |> assign(:total_consumed, new_total_consumed)
     |> assign(:lab_consumables_count, socket.assigns.lab_consumables_count + 1)
     |> stream_insert(:lab_consumables, lab_consumable)}
  end

  defp update_remaining_quantity(lab_allocation, consumed_quantity) do
    consumed = String.to_integer(consumed_quantity)
    new_remaining = lab_allocation.remaining_quantity - consumed

    case LabAllocations.update_lab_allocation(lab_allocation, %{remaining_quantity: new_remaining}) do
      {:ok, updated_allocation} -> updated_allocation
      {:error, _} -> lab_allocation
    end
  end

  defp page_title(:show), do: "Show Lab allocation"
  defp page_title(:edit), do: "Edit Lab allocation"
  defp page_title(:new_consumable), do: "New Lab consumable"

  @impl true
  def handle_event("close_requisition_modal", _params, socket) do
    {:noreply, assign(socket, :requisition_prefill, nil)}
  end

  def handle_event("open_requisition_modal", _params, socket) do
    allocation = socket.assigns.lab_allocation
    ir = allocation.inventory_issued && allocation.inventory_issued.inventory_received

    prefill =
      if allocation.inventory_issued && allocation.inventory_issued.inventory_received_id do
        %{
          inventory_received_id: allocation.inventory_issued.inventory_received_id,
          item_title: "#{(ir && (ir.brand_name || ir.generic_name)) || "Item"}",
          item_description: (ir && ir.generic_name) || ""
        }
      else
        nil
      end

    {:noreply, assign(socket, :requisition_prefill, prefill)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-6">
      <.header class="text-[#373896] border-b border-gray-100 pb-4 mb-6">
        <div class="flex items-center">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-6 w-6 mr-3 text-[#6667ab]"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M9 3v2m6-2v2M9 19v2m6-2v2M5 9H3m2 6H3m18-6h-2m2 6h-2M7 19h10a2 2 0 002-2V7a2 2 0 00-2-2H7a2 2 0 00-2 2v10a2 2 0 002 2zM9 9h6v6H9V9z"
            />
          </svg>
          <div>
            <h1 class="text-xl font-semibold">Lab Allocation #{@lab_allocation.id}</h1>
            <p class="text-sm text-gray-600 mt-1">
              {[
                @lab_allocation.inventory_issued.inventory_received.brand_name ||
                  @lab_allocation.inventory_issued.inventory_received.generic_name
              ]}
            </p>
          </div>
        </div>
        <:actions>
          <.button
            :if={
              @lab_allocation.inventory_issued &&
                @lab_allocation.inventory_issued.inventory_received_id
            }
            type="button"
            phx-click="open_requisition_modal"
            class="mr-2 bg-[#373896] hover:bg-[#5556a0]"
          >
            Make requisition for this item
          </.button>
          <.link patch={~p"/lab/lab_allocations/#{@lab_allocation}/consumables/new"}>
            <.button class="bg-[#6667ab] hover:bg-[#5556a0]">
              <div class="flex items-center">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-4 w-4 mr-2"
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
                Add Consumption
              </div>
            </.button>
          </.link>
        </:actions>
      </.header>
      
    <!-- Quantity Overview Cards -->
      <div class="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <div class="bg-blue-50 rounded-lg p-4 border border-blue-200">
          <div class="flex items-center">
            <div class="p-2 bg-blue-100 rounded-md">
              <svg class="h-6 w-6 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"
                />
              </svg>
            </div>
            <div class="ml-4">
              <p class="text-sm font-medium text-blue-600">Allocated</p>
              <p class="text-2xl font-semibold text-blue-900">
                {@lab_allocation.allocated_quantity}
              </p>
              <p class="text-xs text-blue-600 mt-1">{@lab_allocation.uom}</p>
            </div>
          </div>
        </div>

        <div class="bg-red-50 rounded-lg p-4 border border-red-200">
          <div class="flex items-center">
            <div class="p-2 bg-red-100 rounded-md">
              <svg class="h-6 w-6 text-red-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 12H4" />
              </svg>
            </div>
            <div class="ml-4">
              <p class="text-sm font-medium text-red-600">Logged Consumption</p>
              <p class="text-2xl font-semibold text-red-900">
                {@total_consumed}
              </p>
              <p class="text-xs text-red-600 mt-1">{@lab_allocation.uom}</p>
            </div>
          </div>
        </div>

        <div class="bg-green-50 rounded-lg p-4 border border-green-200">
          <div class="flex items-center">
            <div class="p-2 bg-green-100 rounded-md">
              <svg
                class="h-6 w-6 text-green-600"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
            </div>
            <div class="ml-4">
              <p class="text-sm font-medium text-green-600">Remaining (this allocation)</p>
              <p class="text-2xl font-semibold text-green-900">
                {@lab_allocation.remaining_quantity}
              </p>
              <p class="text-xs text-green-600 mt-1">{@lab_allocation.uom}</p>
            </div>
          </div>
        </div>

        <div class="bg-indigo-50 rounded-lg p-4 border border-indigo-200">
          <div class="flex items-center">
            <div class="p-2 bg-indigo-100 rounded-md">
              <svg
                class="h-6 w-6 text-indigo-600"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z"
                />
              </svg>
            </div>
            <div class="ml-4">
              <p class="text-sm font-medium text-indigo-600">Quantity in Store</p>
              <p class="text-2xl font-semibold text-indigo-900">
                <%= if @quantity_in_store == nil do %>
                  -
                <% else %>
                  {@quantity_in_store}
                <% end %>
              </p>
              <p class="text-xs text-indigo-600 mt-1">
                Across all batches
              </p>
            </div>
          </div>
        </div>
      </div>
      
    <!-- Progress Bar -->
      <div class="mb-6">
        <div class="flex justify-between text-sm text-gray-600 mb-2">
          <span>Logged Consumption vs. Allocated</span>
          <span>
            <%= if @lab_allocation.allocated_quantity > 0 do %>
              {Float.round(@total_consumed / @lab_allocation.allocated_quantity * 100, 1)}%
            <% else %>
              0%
            <% end %>
          </span>
        </div>
        <div class="w-full bg-gray-200 rounded-full h-3">
          <div
            class={"h-3 rounded-full transition-all duration-300 #{if @lab_allocation.remaining_quantity <= 0, do: "bg-red-600", else: if(@lab_allocation.remaining_quantity < @lab_allocation.allocated_quantity * 0.2, do: "bg-yellow-600", else: "bg-green-600")}"}
            style={"width: #{if @lab_allocation.allocated_quantity > 0, do: min(@total_consumed / @lab_allocation.allocated_quantity * 100, 100), else: 0}%"}
          >
          </div>
        </div>
      </div>
      
    <!-- Expiry Date Card -->
      <div class="bg-slate-50 rounded-lg p-4 border border-purple-200 mb-6">
        <div class="flex items-center">
          <div class="p-2 bg-purple-100 rounded-md">
            <svg class="h-6 w-6 text-purple-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
              />
            </svg>
          </div>
          <div class="ml-4">
            <p class="text-sm font-medium text-purple-600">Expiry Date</p>
            <p class="text-lg font-semibold text-purple-900">
              <%= if @lab_allocation.expiry_date do %>
                {Calendar.strftime(@lab_allocation.expiry_date, "%b %d, %Y")}
              <% else %>
                No expiry date
              <% end %>
            </p>
          </div>
        </div>
      </div>
      
    <!-- Allocation Details -->
      <div class="bg-gray-50 rounded-lg p-4 mb-6">
        <h3 class="text-lg font-semibold text-gray-900 mb-4">Allocation Details</h3>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <p class="text-sm font-medium text-gray-500">Allocated To</p>
            <p class="mt-1 text-sm text-gray-900">{@lab_allocation.allocated_to_user.name}</p>
          </div>
          <div>
            <p class="text-sm font-medium text-gray-500">Allocated By</p>
            <p class="mt-1 text-sm text-gray-900">{@lab_allocation.allocated_by_user.name}</p>
          </div>
          <div>
            <p class="text-sm font-medium text-gray-500">GTIN</p>
            <p class="mt-1 text-sm text-gray-900">{@lab_allocation.inventory_issued.gtin}</p>
          </div>
          <div>
            <p class="text-sm font-medium text-gray-500">Location</p>
            <p class="mt-1 text-sm text-gray-900">{@lab_allocation.inventory_issued.location}</p>
          </div>
        </div>
      </div>
      
    <!-- Source / Supply Details -->
      <% batch = @lab_allocation.inventory_issued && @lab_allocation.inventory_issued.batch %>
      <div class="bg-white border border-slate-200 rounded-lg p-4 mb-6">
        <h3 class="text-lg font-semibold text-gray-900 mb-4 flex items-center">
          <svg
            class="h-5 w-5 mr-2 text-[#6667ab]"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"
            />
          </svg>
          Source / Supply Details
        </h3>
        <%= if batch do %>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <p class="text-sm font-medium text-gray-500">Lot / Batch Number</p>
              <p class="mt-1 text-sm font-semibold text-gray-900">{batch.batch || "-"}</p>
            </div>
            <div>
              <p class="text-sm font-medium text-gray-500">Manufacturer</p>
              <p class="mt-1 text-sm text-gray-900">{batch.manufacturer || "-"}</p>
            </div>
            <div>
              <p class="text-sm font-medium text-gray-500">Supplier</p>
              <p class="mt-1 text-sm text-gray-900">
                {(batch.supplier && batch.supplier.name) || "-"}
              </p>
            </div>
            <div>
              <p class="text-sm font-medium text-gray-500">Date Received</p>
              <p class="mt-1 text-sm text-gray-900">
                <%= if batch.received_date do %>
                  {Calendar.strftime(batch.received_date, "%b %d, %Y")}
                <% else %>
                  -
                <% end %>
              </p>
            </div>
          </div>
        <% else %>
          <p class="text-sm text-gray-500">No batch information available for this allocation.</p>
        <% end %>
      </div>
      
    <!-- Consumption History -->
      <div class="mt-6">
        <h3 class="text-lg font-semibold text-gray-900 mb-4 flex items-center">
          <svg
            class="h-5 w-5 mr-2 text-[#6667ab]"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
            />
          </svg>
          Consumption History
        </h3>

        <%= if @lab_consumables_count == 0 do %>
          <div class="text-center py-8 bg-gray-50 rounded-lg border border-dashed border-gray-300">
            <svg
              class="mx-auto h-12 w-12 text-gray-400"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
              />
            </svg>
            <h3 class="mt-2 text-sm font-medium text-gray-900">No consumption records</h3>
            <p class="mt-1 text-sm text-gray-500">
              No items have been consumed from this allocation yet.
            </p>
          </div>
        <% else %>
          <div class="space-y-4">
            <%= for {_id, consumable} <- @streams.lab_consumables do %>
              <div class="bg-white border border-gray-200 rounded-lg p-4">
                <div class="flex justify-between items-start">
                  <div class="flex-1">
                    <div class="flex items-center space-x-4">
                      <div class="bg-red-50 p-2 rounded-md">
                        <svg
                          class="h-5 w-5 text-red-600"
                          fill="none"
                          viewBox="0 0 24 24"
                          stroke="currentColor"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M20 12H4"
                          />
                        </svg>
                      </div>
                      <div>
                        <h4 class="font-medium text-gray-900">
                          Consumed: {consumable.consumed_quantity} {@lab_allocation.uom}
                        </h4>
                        <p class="text-sm text-gray-600">Purpose: {consumable.purpose}</p>
                        <p class="text-xs text-gray-500">Date: {consumable.date}</p>
                      </div>
                    </div>
                  </div>
                  <%= if consumable.patient do %>
                    <div class="ml-4">
                      <span class="px-2 py-1 text-xs rounded-full bg-blue-100 text-blue-800">
                        Patient: {consumable.patient.first_name} {consumable.patient.last_name}
                      </span>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>

      <div class="mt-6 pt-4 border-t border-gray-200">
        <.back navigate={~p"/lab/lab_allocations"} class="text-[#6667ab] hover:text-[#373896]">
          Back to lab allocations
        </.back>
      </div>
    </div>

    <.modal
      :if={@live_action == :edit}
      id="lab_allocation-modal"
      show
      on_cancel={JS.patch(~p"/lab/lab_allocations/#{@lab_allocation}")}
    >
      <.live_component
        module={MedcampWeb.LabAllocationLive.FormComponent}
        id={@lab_allocation.id}
        title={@page_title}
        action={@live_action}
        lab_allocation={@lab_allocation}
        patch={~p"/lab/lab_allocations/#{@lab_allocation}"}
      />
    </.modal>

    <.modal
      :if={@live_action == :new_consumable}
      id="lab_consumable-modal"
      show
      on_cancel={JS.patch(~p"/lab/lab_allocations/#{@lab_allocation}")}
    >
      <.live_component
        module={MedcampWeb.LabConsumableLive.FormComponent}
        id={:new}
        title={@page_title}
        action={:new}
        lab_consumable={@lab_consumable}
        lab_allocation={@lab_allocation}
        patch={~p"/lab/lab_allocations/#{@lab_allocation}"}
      />
    </.modal>

    <%= if @requisition_prefill do %>
      <.modal id="requisition-for-item-modal" show on_cancel={JS.push("close_requisition_modal")}>
        <.live_component
          module={MedcampWeb.RequisitionLive.RequisitionForItemComponent}
          id="requisition-for-item-lab"
          inventory_received_id={@requisition_prefill.inventory_received_id}
          item_title={@requisition_prefill.item_title}
          item_description={@requisition_prefill.item_description}
          current_user={@current_user}
          patch={~p"/lab/lab_allocations/#{@lab_allocation}"}
        />
      </.modal>
    <% end %>
    """
  end
end
