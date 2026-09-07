defmodule MedcampWeb.NursingAllocationLive.Show do
  use MedcampWeb, :nurse_live_view

  alias Medcamp.Nursing
  alias Medcamp.NursingConsumables.NursingConsumable

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :nurse_allocations)
     |> assign(:scan_form, to_form(%{}))
     |> assign(:scan_data, nil)
     |> assign(:scan_error, nil)
     |> assign(:scan_verified, false)}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _, socket) do
    allocation = Nursing.get_nursing_allocation!(id)
    consumables = Nursing.list_consumables_for_allocation(id)

    total_consumed =
      consumables
      |> Enum.map(& &1.consumed_quantity)
      |> Enum.sum()

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:nursing_allocation, allocation)
     |> assign(:total_consumed, total_consumed)
     |> assign(:requisition_prefill, nil)
     |> assign(:nursing_consumables_count, length(consumables))
     |> stream(:nursing_consumables, consumables)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new_consumable, _params) do
    socket
    |> assign(:nursing_consumable, %NursingConsumable{
      nursing_allocation_id: socket.assigns.nursing_allocation.id
    })
  end

  defp apply_action(socket, :show, _params) do
    socket
    |> assign(:nursing_consumable, nil)
    |> assign(:requisition_prefill, nil)
  end

  @impl true
  def handle_info(
        {MedcampWeb.NursingConsumableLive.FormComponent,
         {:saved, %{consumable: consumable, allocation: allocation}}},
        socket
      ) do
    new_total_consumed = socket.assigns.total_consumed + consumable.consumed_quantity

    {:noreply,
     socket
     |> assign(:nursing_allocation, allocation)
     |> assign(:total_consumed, new_total_consumed)
     |> assign(:nursing_consumables_count, socket.assigns.nursing_consumables_count + 1)
     |> stream_insert(:nursing_consumables, consumable)}
  end

  def handle_info({MedcampWeb.NursingConsumableLive.FormComponent, {:saved, consumable}}, socket) do
    updated_allocation = Nursing.get_nursing_allocation!(socket.assigns.nursing_allocation.id)

    total_consumed =
      Nursing.list_consumables_for_allocation(socket.assigns.nursing_allocation.id)
      |> Enum.map(& &1.consumed_quantity)
      |> Enum.sum()

    {:noreply,
     socket
     |> assign(:nursing_allocation, updated_allocation)
     |> assign(:total_consumed, total_consumed)
     |> assign(:nursing_consumables_count, socket.assigns.nursing_consumables_count + 1)
     |> stream_insert(:nursing_consumables, consumable)}
  end

  defp page_title(:show), do: "Allocation Details"
  defp page_title(:new_consumable), do: "Record Usage"

  def handle_event("show_scan_modal", _params, socket) do
    allocation = socket.assigns.nursing_allocation
    details = Nursing.allocation_item_details(allocation)

    {:noreply,
     socket
     |> assign(:scan_data, %{
       gtin: details.gtin,
       brand_name: details.brand_name,
       generic_name: details.generic_name,
       batch_number: details.batch_number
     })
     |> assign(:scan_error, nil)}
  end

  def handle_event("close_scan_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:scan_data, nil)
     |> assign(:scan_error, nil)}
  end

  def handle_event("verify_item", %{"scanned_code" => scanned_code}, socket) do
    scan_data = socket.assigns.scan_data
    expected_gtin = scan_data && scan_data.gtin

    scanned = String.trim(scanned_code)
    normalized_scanned = String.pad_leading(scanned, 14, "0")
    normalized_expected = expected_gtin && String.pad_leading(to_string(expected_gtin), 14, "0")

    cond do
      scanned == "" ->
        {:noreply, assign(socket, :scan_error, "Please enter or scan a code.")}

      is_nil(expected_gtin) ->
        {:noreply,
         socket
         |> assign(:scan_data, nil)
         |> assign(:scan_error, nil)
         |> assign(:scan_verified, true)
         |> put_flash(:info, "Item verified — no GTIN stored for this allocation.")}

      normalized_scanned == normalized_expected or scanned == expected_gtin ->
        {:noreply,
         socket
         |> assign(:scan_data, nil)
         |> assign(:scan_error, nil)
         |> assign(:scan_verified, true)
         |> put_flash(:info, "Item verified successfully!")}

      true ->
        {:noreply,
         assign(socket, :scan_error, "GTIN mismatch. Expected #{expected_gtin}, got #{scanned}.")}
    end
  end

  @impl true
  def handle_event("close_requisition_modal", _params, socket) do
    {:noreply, assign(socket, :requisition_prefill, nil)}
  end

  def handle_event("open_requisition_modal", _params, socket) do
    allocation = socket.assigns.nursing_allocation
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
      <.header class="text-teal-900 border-b border-gray-100 pb-4 mb-6">
        <div class="flex items-center">
          <div class="p-2 bg-teal-100 rounded-lg mr-3">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-6 w-6 text-teal-600"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"
              />
            </svg>
          </div>
          <div>
            <% details = Medcamp.Nursing.allocation_item_details(@nursing_allocation) %>
            <h1 class="text-xl font-semibold">Nursing Allocation #{@nursing_allocation.id}</h1>
            <p class="text-sm font-medium text-gray-800 mt-1">{details.display_name}</p>
            <div class="text-sm text-gray-600 mt-1 space-y-0.5">
              <p>
                <span class="text-gray-500">Brand:</span> {(details.brand_name &&
                                                              String.trim(details.brand_name || "") !=
                                                                "" && details.brand_name) || "—"}
              </p>
              <p>
                <span class="text-gray-500">Generic:</span> {(details.generic_name &&
                                                                String.trim(
                                                                  details.generic_name || ""
                                                                ) != "" && details.generic_name) ||
                  "—"}
              </p>
              <p>
                <span class="text-gray-500">Batch:</span> {(details.batch_number &&
                                                              String.trim(
                                                                to_string(details.batch_number || "")
                                                              ) != "" && details.batch_number) || "—"}
              </p>
              <%= if details.size_gauge do %>
                <p>Size/Gauge: {details.size_gauge}</p>
              <% end %>
              <p>GTIN: {details.gtin || "—"}</p>
            </div>
          </div>
        </div>
        <:actions>
          <%= if @scan_verified do %>
            <span class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-green-100 text-green-800 text-sm font-medium mr-2">
              <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M5 13l4 4L19 7"
                />
              </svg>
              Item Verified
            </span>
          <% end %>
          <.button
            type="button"
            phx-click="show_scan_modal"
            class="mr-2 bg-amber-500 hover:bg-amber-600"
          >
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
                  d="M12 4v1m6 11h2m-6 0h-2v4m0-11v3m0 0h.01M12 12h4.01M16 20h4M4 12h4m12 0h.01M5 8h2a1 1 0 001-1V5a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1zm12 0h2a1 1 0 001-1V5a1 1 0 00-1-1h-2a1 1 0 00-1 1v2a1 1 0 001 1zM5 20h2a1 1 0 001-1v-2a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1z"
                />
              </svg>
              Scan to Verify
            </div>
          </.button>
          <.button
            :if={
              @nursing_allocation.inventory_issued &&
                @nursing_allocation.inventory_issued.inventory_received_id
            }
            type="button"
            phx-click="open_requisition_modal"
            class="mr-2 bg-[#373896] hover:bg-[#5556a0]"
          >
            Make requisition for this item
          </.button>
          <.link patch={~p"/nurse/allocations/#{@nursing_allocation}/consumables/new"}>
            <.button class="bg-teal-600 hover:bg-teal-700">
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
                Record Usage
              </div>
            </.button>
          </.link>
        </:actions>
      </.header>

      <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
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
                {@nursing_allocation.allocated_quantity}
              </p>
              <p class="text-xs text-blue-600 mt-1">{@nursing_allocation.uom}</p>
            </div>
          </div>
        </div>

        <div class="bg-slate-50 rounded-lg p-4 border border-slate-200">
          <div class="flex items-center">
            <div class="p-2 bg-slate-100 rounded-md">
              <svg
                class="h-6 w-6 text-slate-600"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-10V6m0 12v2m9-8a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
            </div>
            <div class="ml-4">
              <p class="text-sm font-medium text-slate-600">Unit Price</p>
              <p class="text-2xl font-semibold text-slate-900">
                KES {format_currency(Nursing.unit_price_for_allocation(@nursing_allocation))}
              </p>
              <p class="text-xs text-slate-600 mt-1">Per {@nursing_allocation.uom || "unit"}</p>
            </div>
          </div>
        </div>

        <div class="bg-orange-50 rounded-lg p-4 border border-orange-200">
          <div class="flex items-center">
            <div class="p-2 bg-orange-100 rounded-md">
              <svg
                class="h-6 w-6 text-orange-600"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 12H4" />
              </svg>
            </div>
            <div class="ml-4">
              <p class="text-sm font-medium text-orange-600">Total Consumed</p>
              <p class="text-2xl font-semibold text-orange-900">{@total_consumed}</p>
              <p class="text-xs text-orange-600 mt-1">{@nursing_allocation.uom}</p>
            </div>
          </div>
        </div>

        <div class={"#{if @nursing_allocation.remaining_quantity <= 0, do: "bg-red-50 border-red-200", else: "bg-emerald-50 border-emerald-200"} rounded-lg p-4 border"}>
          <div class="flex items-center">
            <div class={"p-2 #{if @nursing_allocation.remaining_quantity <= 0, do: "bg-red-100", else: "bg-emerald-100"} rounded-md"}>
              <svg
                class={"h-6 w-6 #{if @nursing_allocation.remaining_quantity <= 0, do: "text-red-600", else: "text-emerald-600"}"}
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
              <p class={"text-sm font-medium #{if @nursing_allocation.remaining_quantity <= 0, do: "text-red-600", else: "text-emerald-600"}"}>
                Remaining
              </p>
              <p class={"text-2xl font-semibold #{if @nursing_allocation.remaining_quantity <= 0, do: "text-red-900", else: "text-emerald-900"}"}>
                {@nursing_allocation.remaining_quantity}
              </p>
              <p class={"text-xs #{if @nursing_allocation.remaining_quantity <= 0, do: "text-red-600", else: "text-emerald-600"} mt-1"}>
                {@nursing_allocation.uom}
              </p>
            </div>
          </div>
        </div>
      </div>

      <div class="mb-6">
        <div class="flex justify-between text-sm text-gray-600 mb-2">
          <span>Usage Progress</span>
          <span>
            <%= if @nursing_allocation.allocated_quantity > 0 do %>
              {Float.round(@total_consumed / @nursing_allocation.allocated_quantity * 100, 1)}%
            <% else %>
              0%
            <% end %>
          </span>
        </div>
        <div class="w-full bg-gray-200 rounded-full h-3">
          <div
            class={"h-3 rounded-full transition-all duration-300 #{cond do
              @nursing_allocation.remaining_quantity <= 0 -> "bg-red-600"
              @nursing_allocation.remaining_quantity < @nursing_allocation.allocated_quantity * 0.2 -> "bg-amber-500"
              true -> "bg-emerald-500"
            end}"}
            style={"width: #{if @nursing_allocation.allocated_quantity > 0, do: min(@total_consumed / @nursing_allocation.allocated_quantity * 100, 100), else: 0}%"}
          >
          </div>
        </div>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
        <div class="bg-slate-50 rounded-lg p-4 border border-purple-200">
          <div class="flex items-center">
            <div class="p-2 bg-purple-100 rounded-md">
              <svg
                class="h-6 w-6 text-purple-600"
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
            </div>
            <div class="ml-4">
              <p class="text-sm font-medium text-purple-600">Expiry Date</p>
              <p class="text-lg font-semibold text-purple-900">
                <%= if @nursing_allocation.expiry_date do %>
                  {Calendar.strftime(@nursing_allocation.expiry_date, "%b %d, %Y")}
                <% else %>
                  No expiry date
                <% end %>
              </p>
            </div>
          </div>
        </div>

        <div class="bg-gray-50 rounded-lg p-4 border border-gray-200">
          <% details = Medcamp.Nursing.allocation_item_details(@nursing_allocation) %>
          <div class="grid grid-cols-2 gap-4">
            <div>
              <p class="text-xs font-medium text-gray-500 uppercase">Allocated To</p>
              <p class="text-sm text-gray-900 font-medium">
                {@nursing_allocation.allocated_to_user.name}
              </p>
            </div>
            <div>
              <p class="text-xs font-medium text-gray-500 uppercase">GTIN</p>
              <p class="text-sm text-gray-900 font-medium">{details.gtin || "—"}</p>
            </div>
            <%= if details.batch_number && String.trim(to_string(details.batch_number || "")) != "" do %>
              <div>
                <p class="text-xs font-medium text-gray-500 uppercase">Batch Number</p>
                <p class="text-sm text-gray-900 font-medium">{details.batch_number}</p>
              </div>
            <% end %>
            <%= if details.size_gauge do %>
              <div>
                <p class="text-xs font-medium text-gray-500 uppercase">Size/Gauge</p>
                <p class="text-sm text-gray-900 font-medium">{details.size_gauge}</p>
              </div>
            <% end %>
          </div>
        </div>
      </div>

      <%= if batch = @nursing_allocation.inventory_issued && @nursing_allocation.inventory_issued.batch do %>
        <div class="mb-6 rounded-xl border border-slate-200 bg-slate-50 p-5">
          <div class="mb-4 flex items-center justify-between gap-4">
            <div>
              <h3 class="text-lg font-semibold text-slate-900">Batch Details</h3>
              <p class="text-sm text-slate-600">
                This allocation is currently being served from batch {batch.batch || batch.serial ||
                  "—"}.
              </p>
            </div>
            <div class="rounded-lg bg-white px-4 py-3 text-right shadow-sm ring-1 ring-slate-200">
              <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">
                Batch Unit Price
              </p>
              <p class="text-xl font-semibold text-slate-900">
                KES {format_currency(batch.price_per_unit)}
              </p>
            </div>
          </div>

          <div class="grid grid-cols-1 gap-4 md:grid-cols-4">
            <div class="rounded-lg bg-white p-4 shadow-sm ring-1 ring-slate-200">
              <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">Batch Number</p>
              <p class="mt-1 text-sm font-medium text-slate-900">{batch.batch || "—"}</p>
            </div>

            <div class="rounded-lg bg-white p-4 shadow-sm ring-1 ring-slate-200">
              <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">Serial</p>
              <p class="mt-1 text-sm font-medium text-slate-900">{batch.serial || "—"}</p>
            </div>

            <div class="rounded-lg bg-white p-4 shadow-sm ring-1 ring-slate-200">
              <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">Supplier</p>
              <p class="mt-1 text-sm font-medium text-slate-900">
                {(batch.supplier && batch.supplier.name) || "—"}
              </p>
            </div>

            <div class="rounded-lg bg-white p-4 shadow-sm ring-1 ring-slate-200">
              <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">Manufacturer</p>
              <p class="mt-1 text-sm font-medium text-slate-900">{batch.manufacturer || "—"}</p>
            </div>

            <div class="rounded-lg bg-white p-4 shadow-sm ring-1 ring-slate-200">
              <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">
                Batch Quantity
              </p>
              <p class="mt-1 text-sm font-medium text-slate-900">{batch.quantity || 0}</p>
            </div>

            <div class="rounded-lg bg-white p-4 shadow-sm ring-1 ring-slate-200">
              <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">
                Batch Remaining
              </p>
              <p class="mt-1 text-sm font-medium text-slate-900">{batch.remaining_quantity || 0}</p>
            </div>

            <div class="rounded-lg bg-white p-4 shadow-sm ring-1 ring-slate-200">
              <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">
                Received Date
              </p>
              <p class="mt-1 text-sm font-medium text-slate-900">
                {format_date(batch.received_date)}
              </p>
            </div>

            <div class="rounded-lg bg-white p-4 shadow-sm ring-1 ring-slate-200">
              <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">Batch GTIN</p>
              <p class="mt-1 text-sm font-medium text-slate-900">{batch.gtin || "—"}</p>
            </div>
          </div>
        </div>
      <% end %>

      <div class="mt-8">
        <h3 class="text-lg font-semibold text-gray-900 mb-4 flex items-center">
          <svg
            class="h-5 w-5 mr-2 text-teal-600"
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

        <div id="nursing_consumables" phx-update="stream" class="space-y-3">
          <%= for {id, consumable} <- @streams.nursing_consumables do %>
            <div
              id={id}
              class="bg-white border border-gray-200 rounded-lg p-4 hover:border-teal-200 transition-colors"
            >
              <div class="flex justify-between items-start">
                <div class="flex items-center space-x-4">
                  <div class="bg-orange-50 p-2 rounded-md">
                    <svg
                      class="h-5 w-5 text-orange-600"
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
                      Consumed: {consumable.consumed_quantity} {@nursing_allocation.uom}
                    </h4>
                    <p class="text-sm font-medium text-gray-700">
                      Unit Price: KES {format_currency(
                        Nursing.unit_price_for_allocation(@nursing_allocation)
                      )}
                      <span class="text-gray-400 px-1">|</span>
                      Total: KES {format_currency(consumption_total(consumable, @nursing_allocation))}
                    </p>
                    <p class="text-sm text-gray-600">
                      {consumable.purpose || "No purpose specified"}
                    </p>
                    <p class="text-xs text-gray-400 mt-1">{consumable.date}</p>
                    <%= if consumable.doctor_note_id do %>
                      <p class="text-xs text-slate-500 mt-1">
                        Linked to doctor note ##{consumable.doctor_note_id} for later billing review
                      </p>
                    <% end %>
                  </div>
                </div>
                <div class="flex flex-col items-end gap-2">
                  <%= if consumable.patient do %>
                    <span class="px-2 py-1 text-xs font-medium rounded-full bg-blue-100 text-blue-800">
                      Patient: {consumable.patient.first_name} {consumable.patient.last_name}
                    </span>
                  <% end %>

                  <%= if consumable.patient_charge do %>
                    <span class={[
                      "px-2 py-1 text-xs font-medium rounded-full",
                      charge_badge_class(consumable.patient_charge.status)
                    ]}>
                      {charge_badge_label(consumable.patient_charge.status)}
                    </span>
                  <% end %>
                </div>
              </div>
            </div>
          <% end %>
        </div>

        <%= if @nursing_consumables_count == 0 do %>
          <div class="text-center py-12 bg-gray-50 rounded-lg border border-dashed border-gray-300">
            <p class="text-gray-500">No consumption records found for this allocation.</p>
          </div>
        <% end %>
      </div>

      <div class="mt-8 pt-4 border-t border-gray-200 text-teal-600 hover:text-teal-800">
        <.back navigate={~p"/nurse/allocations"}>
          Back to allocations
        </.back>
      </div>
    </div>

    <.modal
      :if={@live_action == :new_consumable}
      id="nursing_consumable-modal"
      show
      on_cancel={JS.patch(~p"/nurse/allocations/#{@nursing_allocation}")}
    >
      <.live_component
        module={MedcampWeb.NursingConsumableLive.FormComponent}
        id={:new}
        title={@page_title}
        action={:new}
        nursing_consumable={@nursing_consumable}
        nursing_allocation={@nursing_allocation}
        current_user={@current_user}
        patch={~p"/nurse/allocations/#{@nursing_allocation}"}
      />
    </.modal>

    <%= if @requisition_prefill do %>
      <.modal
        id="requisition-for-item-modal"
        show
        on_cancel={JS.dispatch("close_requisition_modal", to: "#requisition-for-item-modal")}
      >
        <.live_component
          module={MedcampWeb.RequisitionLive.RequisitionForItemComponent}
          id="requisition-for-item-nurse"
          inventory_received_id={@requisition_prefill.inventory_received_id}
          item_title={@requisition_prefill.item_title}
          item_description={@requisition_prefill.item_description}
          current_user={@current_user}
          patch={~p"/nurse/allocations/#{@nursing_allocation}"}
        />
      </.modal>
    <% end %>

    <%= if @scan_data do %>
      <div class="fixed inset-0 z-50 overflow-y-auto">
        <div class="flex items-center justify-center min-h-screen px-4 pt-4 pb-20 text-center sm:block sm:p-0">
          <div class="fixed inset-0 transition-opacity bg-gray-500 bg-opacity-75" aria-hidden="true">
          </div>
          <span
            phx-click="close_scan_modal"
            class="hidden sm:inline-block sm:align-middle sm:h-screen"
            aria-hidden="true"
          >
            &#8203;
          </span>
          <div
            class="inline-block align-bottom bg-white rounded-lg px-4 pt-5 pb-4 text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full sm:p-6"
            phx-click-away="close_scan_modal"
            phx-window-keydown="close_scan_modal"
            phx-key="escape"
          >
            <div class="flex items-center justify-between mb-4">
              <h3 class="text-lg font-medium leading-6 text-gray-900">Verify Item</h3>
              <button
                type="button"
                phx-click="close_scan_modal"
                class="text-gray-400 hover:text-gray-500"
              >
                <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M6 18L18 6M6 6l12 12"
                  />
                </svg>
              </button>
            </div>

            <div class="mb-4 p-4 bg-gray-50 rounded-lg text-sm space-y-2">
              <div class="flex justify-between">
                <span class="text-gray-500">Brand:</span>
                <span class="font-medium text-gray-900">{@scan_data.brand_name || "—"}</span>
              </div>
              <div class="flex justify-between">
                <span class="text-gray-500">Generic:</span>
                <span class="font-medium text-gray-900">{@scan_data.generic_name || "—"}</span>
              </div>
              <div class="flex justify-between">
                <span class="text-gray-500">Batch:</span>
                <span class="font-medium text-gray-900">{@scan_data.batch_number || "—"}</span>
              </div>
              <div class="flex justify-between">
                <span class="text-gray-500">Expected GTIN:</span>
                <span class="font-mono font-medium text-gray-900">{@scan_data.gtin || "—"}</span>
              </div>
            </div>

            <.form for={@scan_form} phx-submit="verify_item">
              <div class="space-y-4">
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-2">
                    Scan Barcode / Enter GTIN
                  </label>
                  <input
                    type="text"
                    name="scanned_code"
                    placeholder="Scan barcode or enter GTIN manually"
                    autocomplete="off"
                    autofocus
                    class="block w-full rounded-md border-gray-300 shadow-sm focus:border-teal-500 focus:ring-teal-500 sm:text-sm"
                  />
                </div>
                <%= if @scan_error do %>
                  <div class="rounded-md bg-red-50 p-3 flex items-start gap-2">
                    <svg
                      class="h-5 w-5 text-red-400 flex-shrink-0 mt-0.5"
                      viewBox="0 0 20 20"
                      fill="currentColor"
                    >
                      <path
                        fill-rule="evenodd"
                        d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 9.586 8.707 8.293z"
                        clip-rule="evenodd"
                      />
                    </svg>
                    <p class="text-sm text-red-800">{@scan_error}</p>
                  </div>
                <% end %>
              </div>

              <div class="mt-6 flex items-center justify-end gap-3">
                <button
                  type="button"
                  phx-click="close_scan_modal"
                  class="rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  class="rounded-md bg-teal-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-teal-700"
                >
                  Verify Item
                </button>
              </div>
            </.form>
          </div>
        </div>
      </div>
    <% end %>
    """
  end

  defp charge_badge_class("pending_review"), do: "bg-amber-100 text-amber-800"
  defp charge_badge_class("approved"), do: "bg-indigo-100 text-indigo-800"
  defp charge_badge_class("paid"), do: "bg-emerald-100 text-emerald-800"
  defp charge_badge_class("waived"), do: "bg-slate-200 text-slate-700"
  defp charge_badge_class(_), do: "bg-slate-100 text-slate-700"

  defp charge_badge_label("pending_review"), do: "Pending doctor review"
  defp charge_badge_label("approved"), do: "Approved for payment"
  defp charge_badge_label("paid"), do: "Paid"
  defp charge_badge_label("waived"), do: "Waived"
  defp charge_badge_label(_), do: "Unbilled"

  defp consumption_total(consumable, allocation) do
    consumable.consumed_quantity * Nursing.unit_price_for_allocation(allocation)
  end

  defp format_date(nil), do: "—"
  defp format_date(%Date{} = date), do: Calendar.strftime(date, "%b %d, %Y")
  defp format_date(value), do: to_string(value)

  defp format_currency(nil), do: "0"

  defp format_currency(amount) when is_integer(amount),
    do: Number.Delimit.number_to_delimited(amount)

  defp format_currency(amount), do: to_string(amount)
end
