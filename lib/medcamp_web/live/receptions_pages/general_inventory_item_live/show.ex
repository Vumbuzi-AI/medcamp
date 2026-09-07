defmodule MedcampWeb.GeneralInventoryItemLive.Show do
  use MedcampWeb, :reception_live_view

  alias Medcamp.Inventories
  alias Medcamp.Inventories.GeneralInventoryTransaction

  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :general_inventory)
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    item = Inventories.get_general_inventory_item!(id)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:general_inventory_item, item)
     |> assign(:general_inventory_transaction, nil)
     |> load_transactions()}
  end

  defp load_transactions(socket) do
    item_id = socket.assigns.general_inventory_item.id
    total_count = Inventories.count_transactions_for_item(item_id)
    total_pages = Medcamp.Pagination.total_pages(total_count, socket.assigns.per_page)
    page = min(max(1, socket.assigns.page || 1), total_pages)

    transactions =
      Inventories.list_transactions_for_item_paginated(item_id, page, socket.assigns.per_page)

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:transactions, transactions)
  end

  @impl true
  def handle_event("delete_transaction", %{"id" => id}, socket) do
    transaction = Inventories.get_general_inventory_transaction!(id)
    {:ok, _} = Inventories.delete_general_inventory_transaction(transaction)

    {:noreply,
     socket
     |> put_flash(:info, "Transaction deleted successfully")
     |> assign(
       :general_inventory_item,
       Inventories.get_general_inventory_item!(socket.assigns.general_inventory_item.id)
     )
     |> load_transactions()}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, max(1, String.to_integer(page)))
     |> load_transactions()}
  end

  @impl true
  def handle_info(
        {MedcampWeb.GeneralInventoryTransactionLive.FormComponent, {:saved, _transaction}},
        socket
      ) do
    {:noreply,
     socket
     |> assign(
       :general_inventory_item,
       Inventories.get_general_inventory_item!(socket.assigns.general_inventory_item.id)
     )
     |> load_transactions()}
  end

  @impl true
  def handle_info(
        {MedcampWeb.RequisitionLive.RequisitionForItemComponent, {:saved, _requisition}},
        socket
      ) do
    {:noreply, socket}
  end

  defp page_title(:show), do: "Inventory Item Details"
  defp page_title(:edit), do: "Edit Inventory Item"
  defp page_title(:new_transaction), do: "New Transaction"
  defp page_title(:edit_transaction), do: "Edit Transaction"
  defp page_title(:new_requisition), do: "Make Requisition"

  defp stock_status(item) do
    cond do
      Decimal.compare(item.current_quantity, Decimal.new(0)) == :lt or
          Decimal.compare(item.current_quantity, Decimal.new(0)) == :eq ->
        {:out_of_stock, "Out of Stock", "bg-red-100 text-red-800"}

      Decimal.compare(item.current_quantity, item.reorder_level) == :lt ->
        {:low_stock, "Low Stock", "bg-yellow-100 text-yellow-800"}

      true ->
        {:in_stock, "In Stock", "bg-green-100 text-green-800"}
    end
  end

  defp transaction_type_badge(type) do
    case type do
      "received" -> {"Received", "bg-green-100 text-green-800"}
      "used" -> {"Used", "bg-blue-100 text-blue-800"}
      "destroyed" -> {"Destroyed", "bg-red-100 text-red-800"}
      "adjustment" -> {"Adjustment", "bg-purple-100 text-purple-800"}
      _ -> {to_string(type), "bg-gray-100 text-gray-800"}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <!-- Back Navigation -->
      <.back navigate={~p"/reception/general_inventory"} class="text-[#6667ab] hover:text-[#373896]">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="h-4 w-4 inline mr-1"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
        </svg>
        Back to General Inventory
      </.back>
      
    <!-- Item Details Card -->
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
                d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"
              />
            </svg>
            <div>
              <h1 class="text-2xl font-bold">{@general_inventory_item.name}</h1>
              <p class="text-sm text-gray-600">{@general_inventory_item.category}</p>
            </div>
          </div>
          <:actions>
            <.link patch={~p"/reception/general_inventory/#{@general_inventory_item}/requisition"}>
              <.button class="bg-green-600 hover:bg-green-700 flex gap-2 items-center">
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
                    d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                  />
                </svg>
                Make Requisition
              </.button>
            </.link>
            <.link
              patch={~p"/reception/general_inventory/#{@general_inventory_item}/show/edit"}
              phx-click={JS.push_focus()}
            >
              <.button class="bg-[#6667ab] hover:bg-[#5556a0] flex gap-2 items-center">
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
                    d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
                  />
                </svg>
                Edit Item
              </.button>
            </.link>
          </:actions>
        </.header>
        
    <!-- Stock Status Overview -->
        <div class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-6">
          <div class="bg-gradient-to-br from-[#6667ab] to-[#5556a0] rounded-lg p-4 text-white">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm opacity-90">Current Stock</p>
                <p class="text-3xl font-bold mt-1">
                  {Decimal.to_string(@general_inventory_item.current_quantity)}
                </p>
                <p class="text-xs opacity-75 mt-1">{@general_inventory_item.unit_of_measure}</p>
              </div>
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-12 w-12 opacity-30"
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
            </div>
          </div>

          <div class="bg-white border border-gray-200 rounded-lg p-4">
            <p class="text-sm text-gray-600">Status</p>
            <%= case stock_status(@general_inventory_item) do %>
              <% {_, label, classes} -> %>
                <span class={"mt-2 inline-flex px-3 py-1 text-sm font-medium rounded-full #{classes}"}>
                  {label}
                </span>
            <% end %>
            <p class="text-xs text-gray-500 mt-2">
              Reorder at: {Decimal.to_string(@general_inventory_item.reorder_level)} {@general_inventory_item.unit_of_measure}
            </p>
          </div>

          <div class="bg-white border border-gray-200 rounded-lg p-4">
            <p class="text-sm text-gray-600">Unit Cost</p>
            <p class="text-2xl font-bold text-gray-900 mt-1">
              KES {Number.Delimit.number_to_delimited(@general_inventory_item.unit_cost, precision: 2)}
            </p>
            <p class="text-xs text-gray-500 mt-2">per {@general_inventory_item.unit_of_measure}</p>
          </div>

          <div class="bg-white border border-gray-200 rounded-lg p-4">
            <p class="text-sm text-gray-600">Total Value</p>
            <p class="text-2xl font-bold text-gray-900 mt-1">
              KES {Number.Delimit.number_to_delimited(
                Decimal.mult(
                  @general_inventory_item.current_quantity,
                  @general_inventory_item.unit_cost
                ),
                precision: 2
              )}
            </p>
            <p class="text-xs text-gray-500 mt-2">at current stock</p>
          </div>
        </div>
        
    <!-- Item Details -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div class="space-y-4">
            <div>
              <p class="text-sm font-medium text-gray-600">Supplier</p>
              <p class="text-gray-900 mt-1">
                {@general_inventory_item.supplier || "Not specified"}
              </p>
            </div>

            <div>
              <p class="text-sm font-medium text-gray-600">Manufacturer</p>
              <p class="text-gray-900 mt-1">
                {@general_inventory_item.manufacturer || "Not specified"}
              </p>
            </div>
          </div>
          <div>
            <p class="text-sm font-medium text-gray-600">Notes</p>
            <p class="text-gray-900 mt-1 text-sm">
              {@general_inventory_item.notes || "No additional notes"}
            </p>
          </div>
        </div>
      </div>
      
    <!-- Transactions Section -->
      <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-6">
        <.header class="text-[#373896] border-b border-gray-100 pb-4 mb-4">
          <div class="flex items-center">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-5 w-5 mr-2 text-[#6667ab]"
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
            Transaction History
          </div>
          <:actions>
            <.link patch={~p"/reception/general_inventory/#{@general_inventory_item}/transaction/new"}>
              <.button class="bg-[#6667ab] hover:bg-[#5556a0] flex items-center">
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
                Add Transaction
              </.button>
            </.link>
          </:actions>
        </.header>

        <%= if @total_count == 0 do %>
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
            <h3 class="mt-2 text-sm font-medium text-gray-900">No transactions yet</h3>
            <p class="mt-1 text-sm text-gray-500">
              Record when items are received, used, or destroyed.
            </p>
          </div>
        <% else %>
          <.table id="transactions" rows={@transactions}
            row_id={&"transactions-#{&1.id}"}
          >
            <:col :let={transaction} label="Date">
              <div class="py-3">
                <span class="font-medium text-gray-900">
                  {Calendar.strftime(transaction.transaction_date, "%b %d, %Y")}
                </span>
              </div>
            </:col>

            <:col :let={transaction} label="Type">
              <div class="py-3">
                <%= case transaction_type_badge(transaction.transaction_type) do %>
                  <% {label, classes} -> %>
                    <span class={"px-3 py-1 text-xs font-medium rounded-full #{classes}"}>
                      {label}
                    </span>
                <% end %>
              </div>
            </:col>

            <:col :let={transaction} label="Quantity">
              <div class="py-3">
                <span class="font-semibold text-gray-900">
                  <%= if transaction.transaction_type in ["received", "adjustment"] do %>
                    <span class="text-green-600">+{Decimal.to_string(transaction.quantity)}</span>
                  <% else %>
                    <span class="text-red-600">-{Decimal.to_string(transaction.quantity)}</span>
                  <% end %>
                  {@general_inventory_item.unit_of_measure}
                </span>
              </div>
            </:col>

            <:col :let={transaction} label="Reason">
              <div class="py-3">
                <span class="text-gray-700">{transaction.reason || "—"}</span>
              </div>
            </:col>

            <:col :let={transaction} label="Recorded By">
              <div class="py-3">
                <span class="text-gray-600 text-sm">{transaction.recorded_by || "System"}</span>
              </div>
            </:col>

            <:col :let={transaction} label="Notes">
              <div class="py-3">
                <span class="text-gray-600 text-sm">{transaction.notes || "—"}</span>
              </div>
            </:col>

            <:action :let={transaction}>
              <div class="flex items-center justify-center">
                <.link
                  phx-click={
                    JS.push("delete_transaction", value: %{id: transaction.id}) |> hide("#transactions-#{transaction.id}")
                  }
                  data-confirm="Are you sure you want to delete this transaction? This will affect stock levels."
                  class="flex items-center text-red-600 hover:text-red-800"
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
                </.link>
              </div>
            </:action>
          </.table>
          <.pagination
            page={@page}
            total_pages={@total_pages}
            total_count={@total_count}
            per_page={@per_page}
          />
        <% end %>
      </div>
    </div>

    <!-- Modals -->
    <.modal
      :if={@live_action == :edit}
      id="general_inventory_item-modal"
      show
      on_cancel={JS.patch(~p"/reception/general_inventory/#{@general_inventory_item}")}
    >
      <.live_component
        module={MedcampWeb.GeneralInventoryItemLive.FormComponent}
        id={@general_inventory_item.id}
        title={@page_title}
        action={@live_action}
        current_user={@current_user}
        general_inventory_item={@general_inventory_item}
        patch={~p"/reception/general_inventory/#{@general_inventory_item}"}
      />
    </.modal>

    <.modal
      :if={@live_action in [:new_transaction, :edit_transaction]}
      id="transaction-modal"
      show
      on_cancel={JS.patch(~p"/reception/general_inventory/#{@general_inventory_item}")}
    >
      <.live_component
        module={MedcampWeb.GeneralInventoryTransactionLive.FormComponent}
        id={(@general_inventory_transaction && @general_inventory_transaction.id) || :new}
        title={@page_title}
        action={@live_action}
        current_user={@current_user}
        general_inventory_item={@general_inventory_item}
        general_inventory_transaction={
          @general_inventory_transaction || %GeneralInventoryTransaction{}
        }
        patch={~p"/reception/general_inventory/#{@general_inventory_item}"}
      />
    </.modal>

    <.modal
      :if={@live_action == :new_requisition}
      id="requisition-modal"
      show
      on_cancel={JS.patch(~p"/reception/general_inventory/#{@general_inventory_item}")}
    >
      <.live_component
        module={MedcampWeb.RequisitionLive.RequisitionForItemComponent}
        id="requisition-for-item"
        general_inventory_item_id={@general_inventory_item.id}
        item_title={@general_inventory_item.name}
        item_description={"#{@general_inventory_item.category} — #{@general_inventory_item.supplier}"}
        current_user={@current_user}
        patch={~p"/reception/general_inventory/#{@general_inventory_item}"}
      />
    </.modal>
    """
  end
end
