defmodule MedcampWeb.BatchLive.Index do
  use MedcampWeb, :inventory_manager_live_view

  alias Medcamp.Batches
  alias Medcamp.Batches.Batch
  alias Medcamp.ExpiryFilter
  alias Medcamp.InventoriesReceived
  alias Medcamp.Suppliers

  @per_page 10

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    inventory_received = InventoriesReceived.get_inventory_received!(id)

    {:ok,
     socket
     |> assign(:active_tab, :inventories_received)
     |> assign(:inventory_received, inventory_received)
     |> assign(:suppliers, Suppliers.list_suppliers_for_selection())
     |> assign(:filters, default_filters())
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> assign(:total_count, 0)
     |> assign(:total_pages, 0)
     |> assign_batches(id, 1)}
  end

  defp default_filters, do: %{expiry_status: "", expiry_from: "", expiry_to: ""}

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"batch_id" => id}) do
    socket
    |> assign(:page_title, "Edit Batch")
    |> assign(:batch, Batches.get_batch!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Batch")
    |> assign(:batch, %Batch{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Batches")
    |> assign(:batch, nil)
  end

  defp apply_action(socket, :print_preview, %{"batch_id" => batch_id}) do
    socket
    |> assign(:page_title, "Listing Batches")
    |> assign(:batch, Batches.get_batch!(batch_id))
  end

  @impl true
  def handle_info({MedcampWeb.BatchLive.FormComponent, {:saved, _batch}}, socket) do
    {:noreply, assign_batches(socket, socket.assigns.inventory_received.id, socket.assigns.page)}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply, assign_batches(socket, socket.assigns.inventory_received.id, page)}
  end

  @impl true
  def handle_event("filter", %{"filters" => filters}, socket) do
    # The drawer submits only its own fields, so merge onto the current filters
    # rather than replacing them (a chip removal carries just one key).
    current = stringify_filters(socket.assigns.filters)
    filters = Map.merge(current, filters)

    {:noreply,
     socket
     |> assign(:filters, %{
       expiry_status: ExpiryFilter.normalize(filters["expiry_status"]),
       expiry_from: filters["expiry_from"] || "",
       expiry_to: filters["expiry_to"] || ""
     })
     |> assign_batches(socket.assigns.inventory_received.id, 1)}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply,
     socket
     |> assign(:filters, default_filters())
     |> assign_batches(socket.assigns.inventory_received.id, 1)}
  end

  @impl true
  def handle_event("clear_chip", %{"field" => field}, socket) do
    handle_event("filter", %{"filters" => %{field => ""}}, socket)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    batch = Batches.get_batch!(id)
    {:ok, _} = Batches.delete_batch(batch)

    {:noreply, assign_batches(socket, socket.assigns.inventory_received.id, socket.assigns.page)}
  end

  defp stringify_filters(filters) do
    Map.new(filters, fn {key, value} -> {Atom.to_string(key), value || ""} end)
  end

  defp count_active_filters(filters) do
    Enum.count(
      [filters[:expiry_status], filters[:expiry_from], filters[:expiry_to]],
      &(&1 not in [nil, ""])
    )
  end

  defp filter_chips(filters) do
    [
      filter_chip(
        filters[:expiry_status],
        "expiry_status",
        "Expiry: #{ExpiryFilter.label(filters[:expiry_status])}"
      ),
      filter_chip(filters[:expiry_from], "expiry_from", "Expiry from #{filters[:expiry_from]}"),
      filter_chip(filters[:expiry_to], "expiry_to", "Expiry to #{filters[:expiry_to]}")
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp assign_batches(socket, inventory_received_id, page) do
    page = normalize_page(page)
    filters = socket.assigns[:filters] || default_filters()
    total_count = Batches.count_batches_for_inventory_received(inventory_received_id, filters)
    total_pages = max(1, div(total_count + @per_page - 1, @per_page))
    page = min(page, total_pages)

    batches =
      Batches.list_batches_for_inventory_received_paginated(
        inventory_received_id,
        page,
        @per_page,
        filters
      )

    socket
    |> assign(:page, page)
    |> assign(:per_page, @per_page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:batches, batches)
  end

  defp normalize_page(page) when is_binary(page) do
    case Integer.parse(page) do
      {value, _} when value > 0 -> value
      _ -> 1
    end
  end

  defp normalize_page(page) when is_integer(page) and page > 0, do: page
  defp normalize_page(_), do: 1

  def parse_and_convert(nil) do
    ""
  end

  def parse_and_convert(date) do
    date = Timex.parse!(date, "{YYYY}-{0M}-{0D}")
    Timex.format!(date, "{YY} {0M} {0D}")
  end

  def maybe_add_serial(batch) do
    if batch.serial do
      batch.serial
    else
      ""
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-4">
      <.header class="text-[#373896] border-b border-gray-100 pb-4 mb-4">
        <div class="flex flex-col gap-2 items-start">
          <div class="flex items-center">
            <.back navigate={~p"/inventory_manager/inventories_received/#{@inventory_received}"}>
              Back to {@inventory_received.brand_name}
            </.back>
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
                d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"
              />
            </svg>
          </div>
          Listing Batches for {@inventory_received.brand_name}
        </div>
        <:actions>
          <.link patch={
            ~p"/inventory_manager/inventories_received/#{@inventory_received}/batches/new"
          }>
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
                New Batch
              </div>
            </.button>
          </.link>
        </:actions>
      </.header>

      <div class="flex flex-wrap items-center justify-end gap-3 mb-4">
        <.filter_drawer
          id="item-batches-filters"
          title="Filter batches"
          apply_event="filter"
          clear_event="clear_filters"
          active_count={count_active_filters(@filters)}
        >
          <:group label="Expiry">
            <.expiry_filter_fields
              status_value={@filters[:expiry_status]}
              from_value={@filters[:expiry_from]}
              to_value={@filters[:expiry_to]}
            />
          </:group>

          <:chip
            :for={chip <- filter_chips(@filters)}
            label={chip.label}
            clear={JS.push("clear_chip", value: %{"field" => chip.field})}
          />
        </.filter_drawer>
      </div>

      <%= if Enum.empty?(@batches) do %>
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
              d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"
            />
          </svg>
          <h3 class="mt-2 text-sm font-medium text-gray-900">No batches</h3>
          <p class="mt-1 text-sm text-gray-500">
            <%= if count_active_filters(@filters) == 0 do %>
              Get started by adding a new batch for {@inventory_received.brand_name}.
            <% else %>
              No batches match the current expiry filter.
            <% end %>
          </p>
        </div>
      <% else %>
        <.table id="batches" rows={@batches}>
          <:col :let={batch} label="Data Matrix">
            <.link
              class="bg-[#f0f0ff] text-[#373896] p-1  text-center rounded-md"
              patch={"/inventory_manager/inventories_received/#{@inventory_received.id}/batches/print_preview/#{batch.id}"}
            >
              Print
            </.link>
          </:col>
          <:col :let={batch} label="GTIN">
            <div class="flex items-center py-3">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-4 w-4 mr-1 text-[#6667ab]"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M7 21a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v12a4 4 0 01-4 4zm0 0h12a2 2 0 002-2v-4a2 2 0 00-2-2h-2.343M11 7.343l1.657-1.657a2 2 0 012.828 0l2.829 2.829a2 2 0 010 2.828l-8.486 8.485M7 17h.01"
                />
              </svg>
              <span class="text-gray-700">{batch.gtin}</span>
            </div>
          </:col>

          <:col :let={batch} label="Batch">
            <div class="flex items-center py-3">
              <span class="px-2 py-1 text-xs rounded-full bg-[#f0f0ff] text-[#373896]">
                {batch.batch}
              </span>
            </div>
          </:col>

          <:col :let={batch} label="Expiry">
            <div class="flex items-center py-3">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-4 w-4 mr-1 text-[#6667ab]"
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
              <span class="text-gray-700">{batch.expiry}</span>
            </div>
          </:col>

          <:col :let={batch} label="Manufacture">
            <div class="flex items-center py-3">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-4 w-4 mr-1 text-[#6667ab]"
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
              <span class="text-gray-700">{batch.manufacture_date}</span>
            </div>
          </:col>
          <:col :let={batch} label="Cost Per Unit">
            <div class="flex items-center py-3">
              <span class="font-medium text-gray-900">
                KSh {batch.cost_per_unit}
              </span>
            </div>
          </:col>

          <:col :let={batch} label="Price Per Unit">
            <div class="flex items-center py-3">
              <span class="font-medium text-gray-900">
                KSh {batch.price_per_unit}
              </span>
            </div>
          </:col>

          <:col :let={batch} label="Weight">
            <div class="flex items-center py-3">
              <span class="text-gray-700">
                {batch.weight} {batch.uom}
              </span>
            </div>
          </:col>

          <:col :let={batch} label="Manufacturer">
            <div class="flex items-center py-3">
              <span class="text-gray-700">
                {batch.manufacturer}
              </span>
            </div>
          </:col>

          <:col :let={batch} label="Supplier">
            <div class="flex items-center py-3">
              <span class="text-gray-700">
                <%= if batch.supplier do %>
                  {batch.supplier.name}
                <% else %>
                  —
                <% end %>
              </span>
            </div>
          </:col>

          <:col :let={batch} label="Serial">
            <div class="flex items-center py-3">
              <span class="text-gray-700 font-mono text-sm">
                {batch.serial}
              </span>
            </div>
          </:col>

          <:col :let={batch} label="Quantity">
            <div class="flex items-center py-3">
              <span class="px-2 py-1 text-xs rounded-full bg-blue-100 text-blue-800 font-medium">
                {batch.quantity} units
              </span>
            </div>
          </:col>

          <:col :let={batch} label="Remaining Quantity">
            <div class="flex items-center py-3">
              <span class="px-2 py-1 text-xs rounded-full bg-red-100 text-red-800 font-medium">
                {batch.remaining_quantity} units
              </span>
            </div>
          </:col>

          <:action :let={batch}>
            <div class="flex items-center justify-center gap-2">
              <%= if (batch.remaining_quantity || 0) > 0 do %>
                <.link
                  navigate={
                    "/inventory_manager/inventories_issued/new?batch_id=#{batch.id}&inventory_received_id=#{@inventory_received.id}"
                  }
                  class="flex items-center text-green-600 hover:text-green-800 text-sm font-medium"
                >
                  <.icon name="hero-arrow-right-on-rectangle" class="h-4 w-4 mr-1" /> Issue inventory
                </.link>
              <% end %>
              <.link
                patch={
                  ~p"/inventory_manager/inventories_received/#{@inventory_received}/batches/#{batch}/edit"
                }
                class="flex items-center text-[#6667ab] hover:text-[#373896]"
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
                    d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
                  />
                </svg>
                Edit
              </.link>
            </div>
          </:action>

          <:action :let={batch}>
            <div class="flex items-center justify-center">
              <.link
                phx-click={JS.push("delete", value: %{id: batch.id})}
                data-confirm="Are you sure?"
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
      <% end %>

      <.pagination
        page={@page}
        total_pages={@total_pages}
        total_count={@total_count}
        per_page={@per_page}
      />

      <.modal
        :if={@live_action in [:new, :edit]}
        id="batch-modal"
        show
        on_cancel={
          JS.patch(~p"/inventory_manager/inventories_received/#{@inventory_received}/batches")
        }
      >
        <.live_component
          module={MedcampWeb.BatchLive.FormComponent}
          id={@batch.id || :new}
          title={@page_title}
          inventory_received={@inventory_received}
          action={@live_action}
          current_user={@current_user}
          batch={@batch}
          suppliers={@suppliers}
          patch={~p"/inventory_manager/inventories_received/#{@inventory_received}/batches"}
        />
      </.modal>

      <.modal
        :if={@live_action in [:print_preview]}
        id="inventory_received-modal"
        show
        on_cancel={
          JS.patch(~p"/inventory_manager/inventories_received/#{@inventory_received}/batches")
        }
      >
        <.live_component
          module={MedcampWeb.BatchLive.PrintPreview}
          id={@inventory_received.id || :new}
          title={@page_title}
          action={@live_action}
          current_user={@current_user}
          batch={@batch}
          patch={~p"/inventory_manager/inventories_received/#{@inventory_received}/batches"}
        />
      </.modal>
    </div>
    """
  end
end
