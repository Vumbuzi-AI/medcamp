defmodule MedcampWeb.AdminStockTakeLive.Show do
  use MedcampWeb, :admin_live_view

  alias Medcamp.StockTakes
  alias Medcamp.StockTakes.StockTakeEntry

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    stock_take = StockTakes.get_stock_take!(id)
    entries = reload_entries(id)
    summary = StockTakes.stock_take_summary(stock_take)

    {:ok,
     socket
     |> assign(:active_tab, :stock_takes)
     |> assign(:stock_take, stock_take)
     |> assign(:entries, entries)
     |> assign(:summary, summary)
     |> assign(:search_query, "")
     |> assign(:search_results, [])
     |> assign(:search_type, "drug_batch")
     |> assign(:show_search, false)
     |> assign(:editing_entry_id, nil)
     |> assign(:confirm_apply, false)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  # ── Search ────────────────────────────────────────────────────────────────

  @impl true
  def handle_event("toggle_search", _, socket) do
    {:noreply,
     socket
     |> assign(:show_search, !socket.assigns.show_search)
     |> assign(:search_query, "")
     |> assign(:search_results, [])}
  end

  @impl true
  def handle_event("set_search_type", %{"type" => type}, socket) do
    {:noreply,
     socket
     |> assign(:search_type, type)
     |> assign(:search_query, "")
     |> assign(:search_results, [])}
  end

  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    results =
      case socket.assigns.search_type do
        "drug_batch" -> StockTakes.search_drug_batches(query)
        "lab_allocation" -> StockTakes.search_lab_allocations(query)
        "nursing_allocation" -> StockTakes.search_nursing_allocations(query)
        "inventory_received" -> StockTakes.search_inventory_received(query)
        _ -> []
      end

    {:noreply,
     socket
     |> assign(:search_query, query)
     |> assign(:search_results, results)}
  end

  # ── Add Entry ─────────────────────────────────────────────────────────────

  @impl true
  def handle_event("add_drug_batch", %{"id" => id}, socket) do
    stock_take = socket.assigns.stock_take
    drug_batch = Enum.find(socket.assigns.search_results, &(to_string(&1.id) == id))

    if drug_batch &&
         not StockTakes.entry_already_in_stock_take?(
           stock_take.id,
           "drug_batch",
           String.to_integer(id)
         ) do
      attrs = %{
        stock_take_id: stock_take.id,
        entity_type: "drug_batch",
        entity_id: drug_batch.id,
        entity_name: StockTakes.drug_batch_display_name(drug_batch),
        category: drug_batch.drug.inventory_received.category,
        previous_quantity: drug_batch.remaining_quantity,
        uom: drug_batch.batch && drug_batch.batch.uom
      }

      case StockTakes.create_entry(attrs) do
        {:ok, _entry} ->
          {:noreply,
           socket
           |> assign(:entries, reload_entries(stock_take.id))
           |> assign(:summary, StockTakes.stock_take_summary(stock_take))
           |> assign(:search_results, [])
           |> assign(:search_query, "")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to add item.")}
      end
    else
      {:noreply, put_flash(socket, :info, "Item already added to this stock take.")}
    end
  end

  @impl true
  def handle_event("add_lab_allocation", %{"id" => id}, socket) do
    stock_take = socket.assigns.stock_take
    lab_alloc = Enum.find(socket.assigns.search_results, &(to_string(&1.id) == id))

    if lab_alloc &&
         not StockTakes.entry_already_in_stock_take?(
           stock_take.id,
           "lab_allocation",
           String.to_integer(id)
         ) do
      attrs = %{
        stock_take_id: stock_take.id,
        entity_type: "lab_allocation",
        entity_id: lab_alloc.id,
        entity_name: StockTakes.lab_allocation_display_name(lab_alloc),
        category: "Lab",
        previous_quantity: lab_alloc.remaining_quantity || 0,
        uom: lab_alloc.uom
      }

      case StockTakes.create_entry(attrs) do
        {:ok, _entry} ->
          {:noreply,
           socket
           |> assign(:entries, reload_entries(stock_take.id))
           |> assign(:summary, StockTakes.stock_take_summary(stock_take))
           |> assign(:search_results, [])
           |> assign(:search_query, "")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to add item.")}
      end
    else
      {:noreply, put_flash(socket, :info, "Item already added to this stock take.")}
    end
  end

  @impl true
  def handle_event("add_nursing_allocation", %{"id" => id}, socket) do
    stock_take = socket.assigns.stock_take
    alloc = Enum.find(socket.assigns.search_results, &(to_string(&1.id) == id))

    if alloc &&
         not StockTakes.entry_already_in_stock_take?(
           stock_take.id,
           "nursing_allocation",
           String.to_integer(id)
         ) do
      attrs = %{
        stock_take_id: stock_take.id,
        entity_type: "nursing_allocation",
        entity_id: alloc.id,
        entity_name: StockTakes.nursing_allocation_display_name(alloc),
        category: "Nursing",
        previous_quantity: alloc.remaining_quantity || 0,
        uom: alloc.uom
      }

      case StockTakes.create_entry(attrs) do
        {:ok, _entry} ->
          {:noreply,
           socket
           |> assign(:entries, reload_entries(stock_take.id))
           |> assign(:summary, StockTakes.stock_take_summary(stock_take))
           |> assign(:search_results, [])
           |> assign(:search_query, "")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to add item.")}
      end
    else
      {:noreply, put_flash(socket, :info, "Item already added to this stock take.")}
    end
  end

  @impl true
  def handle_event("add_inventory_received", %{"id" => id}, socket) do
    stock_take = socket.assigns.stock_take
    batch = Enum.find(socket.assigns.search_results, &(to_string(&1.id) == id))

    if batch &&
         not StockTakes.entry_already_in_stock_take?(
           stock_take.id,
           "inventory_received",
           String.to_integer(id)
         ) do
      ir = batch.inventory_received
      category = ir && ir.category

      attrs = %{
        stock_take_id: stock_take.id,
        entity_type: "inventory_received",
        entity_id: batch.id,
        entity_name: StockTakes.inventory_received_display_name(batch),
        category: category || "Inventory",
        previous_quantity: batch.remaining_quantity || 0,
        uom: batch.uom
      }

      case StockTakes.create_entry(attrs) do
        {:ok, _entry} ->
          {:noreply,
           socket
           |> assign(:entries, reload_entries(stock_take.id))
           |> assign(:summary, StockTakes.stock_take_summary(stock_take))
           |> assign(:search_results, [])
           |> assign(:search_query, "")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to add item.")}
      end
    else
      {:noreply, put_flash(socket, :info, "Item already added to this stock take.")}
    end
  end

  # ── Edit Entry Count ──────────────────────────────────────────────────────

  @impl true
  def handle_event("edit_entry", %{"id" => id}, socket) do
    {:noreply, assign(socket, :editing_entry_id, String.to_integer(id))}
  end

  @impl true
  def handle_event("cancel_edit", _, socket) do
    {:noreply, assign(socket, :editing_entry_id, nil)}
  end

  @impl true
  def handle_event(
        "save_count",
        %{"entry_id" => entry_id, "counted_quantity" => qty_str} = params,
        socket
      ) do
    entry = StockTakes.get_entry!(String.to_integer(entry_id))
    notes = Map.get(params, "notes", "")
    uom = params |> Map.get("uom", "") |> String.trim()
    allocated_str = params |> Map.get("counted_allocated_quantity", "") |> String.trim()

    with {:ok, qty} <- parse_quantity(qty_str),
         {:ok, allocated_qty} <- parse_optional_quantity(allocated_str) do
      difference = qty - entry.previous_quantity

      attrs = %{
        counted_quantity: qty,
        counted_allocated_quantity: allocated_qty,
        difference: difference,
        notes: notes,
        uom: uom
      }

      case StockTakes.update_entry(entry, attrs) do
        {:ok, _} ->
          stock_take = socket.assigns.stock_take

          {:noreply,
           socket
           |> assign(:editing_entry_id, nil)
           |> assign(:entries, reload_entries(stock_take.id))
           |> assign(:summary, StockTakes.stock_take_summary(stock_take))}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to save count.")}
      end
    else
      :error -> {:noreply, put_flash(socket, :error, "Please enter a valid number.")}
    end
  end

  # ── Delete Entry ──────────────────────────────────────────────────────────

  @impl true
  def handle_event("delete_entry", %{"id" => id}, socket) do
    entry = StockTakes.get_entry!(String.to_integer(id))
    StockTakes.delete_entry(entry)
    stock_take = socket.assigns.stock_take

    {:noreply,
     socket
     |> assign(:entries, reload_entries(stock_take.id))
     |> assign(:summary, StockTakes.stock_take_summary(stock_take))}
  end

  # ── Apply Stock Take ──────────────────────────────────────────────────────

  @impl true
  def handle_event("confirm_apply", _, socket) do
    {:noreply, assign(socket, :confirm_apply, true)}
  end

  @impl true
  def handle_event("cancel_apply", _, socket) do
    {:noreply, assign(socket, :confirm_apply, false)}
  end

  @impl true
  def handle_event("apply_stock_take", _, socket) do
    stock_take = socket.assigns.stock_take
    admin_id = socket.assigns.current_user.id

    case StockTakes.apply_stock_take(stock_take, admin_id) do
      {:ok, _updated} ->
        updated_stock_take = StockTakes.get_stock_take!(stock_take.id)

        {:noreply,
         socket
         |> assign(:stock_take, updated_stock_take)
         |> assign(:entries, reload_entries(stock_take.id))
         |> assign(:summary, StockTakes.stock_take_summary(updated_stock_take))
         |> assign(:confirm_apply, false)
         |> put_flash(
           :info,
           "Stock take applied successfully. All quantities updated and audit trail recorded."
         )}

      {:error, reason} ->
        {:noreply,
         socket
         |> assign(:confirm_apply, false)
         |> put_flash(:error, "Failed to apply stock take: #{inspect(reason)}")}
    end
  end

  # ── Approve / reject requester-raised stock takes ──────────────────────────

  @impl true
  def handle_event("approve_stock_take", _, socket) do
    stock_take = socket.assigns.stock_take

    case StockTakes.approve_stock_take(stock_take, socket.assigns.current_user.id) do
      {:ok, _} ->
        updated = StockTakes.get_stock_take!(stock_take.id)

        {:noreply,
         socket
         |> assign(:stock_take, updated)
         |> assign(:entries, reload_entries(stock_take.id))
         |> assign(:summary, StockTakes.stock_take_summary(updated))
         |> put_flash(:info, "Stock take approved. Quantities updated and audit trail recorded.")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Could not approve: #{inspect(reason)}")}
    end
  end

  @impl true
  def handle_event("reject_stock_take", _, socket) do
    stock_take = socket.assigns.stock_take

    case StockTakes.reject_stock_take(stock_take, socket.assigns.current_user.id) do
      {:ok, _} ->
        updated = StockTakes.get_stock_take!(stock_take.id)

        {:noreply,
         socket |> assign(:stock_take, updated) |> put_flash(:info, "Stock take rejected.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Only pending stock takes can be rejected.")}
    end
  end

  @impl true
  def handle_event("delete_stock_take", _, socket) do
    stock_take = socket.assigns.stock_take

    case StockTakes.delete_requester_stock_take(stock_take) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Stock take deleted.")
         |> push_navigate(to: "/admin/stock_takes")}

      {:error, _} ->
        {:noreply,
         put_flash(socket, :error, "Completed or approved stock takes cannot be deleted.")}
    end
  end

  # Never crash the process on an unmatched event.
  @impl true
  def handle_event(_event, _params, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <%!-- Back + Header --%>
      <div class="flex items-center justify-between">
        <.link
          navigate="/admin/stock_takes"
          class="inline-flex items-center gap-1.5 text-sm text-gray-500 hover:text-gray-700"
        >
          <Heroicons.icon name="arrow-left" type="outline" class="h-4 w-4" /> Back to Stock Takes
        </.link>
        <%= if @stock_take.status in ["draft", "pending", "rejected"] do %>
          <button
            type="button"
            phx-click="delete_stock_take"
            data-confirm="Are you sure you want to delete this stock take?"
            class="inline-flex items-center gap-1.5 rounded-lg border border-red-200 bg-red-50 px-3 py-1.5 text-sm font-medium text-red-700 hover:bg-red-100 transition-colors"
          >
            <Heroicons.icon name="trash" type="outline" class="h-4 w-4" /> Delete Stock Take
          </button>
        <% end %>
      </div>

      <%!-- Stock Take Info Card --%>
      <div class="bg-white rounded-xl shadow-sm border border-slate-200/80 px-6 py-5">
        <div class="flex items-start gap-4">
          <div class="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-emerald-100">
            <Heroicons.icon
              name="clipboard-document-check"
              type="outline"
              class="h-6 w-6 text-emerald-600"
            />
          </div>
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-3">
              <h1 class="text-xl font-semibold text-slate-900">
                Stock Take — {format_date(@stock_take.date)}
              </h1>
              {status_badge(assigns, @stock_take.status)}
            </div>
            <div class="mt-1 flex flex-wrap gap-x-4 gap-y-1 text-sm text-slate-500">
              <%= if @stock_take.department do %>
                <span>
                  Department:
                  <span class="font-medium text-slate-700">{@stock_take.department.name}</span>
                </span>
              <% end %>
              <%= if @stock_take.requested_by do %>
                <span>
                  Requested by:
                  <span class="font-medium text-slate-700">{@stock_take.requested_by.name}</span>
                </span>
              <% end %>
              <%= if @stock_take.admin do %>
                <span>
                  Conducted by:
                  <span class="font-medium text-slate-700">{@stock_take.admin.name}</span>
                </span>
              <% end %>
              <%= if @stock_take.notes do %>
                <span>
                  Notes: <span class="font-medium text-slate-700">{@stock_take.notes}</span>
                </span>
              <% end %>
            </div>
          </div>
        </div>

        <%!-- Summary Stats --%>
        <div class="mt-5 grid grid-cols-2 md:grid-cols-4 gap-4 pt-4 border-t border-slate-100">
          <div class="text-center">
            <p class="text-2xl font-bold text-slate-900">{@summary.total_entries}</p>
            <p class="text-xs text-slate-500 mt-0.5">Total Items</p>
          </div>
          <div class="text-center">
            <p class="text-2xl font-bold text-blue-700">{@summary.counted}</p>
            <p class="text-xs text-slate-500 mt-0.5">Counted</p>
          </div>
          <div class="text-center">
            <p class={"text-2xl font-bold #{if @summary.discrepancies > 0, do: "text-red-600", else: "text-emerald-600"}"}>
              {@summary.discrepancies}
            </p>
            <p class="text-xs text-slate-500 mt-0.5">Discrepancies</p>
          </div>
          <div class="text-center">
            <p class={"text-2xl font-bold #{if @summary.total_difference < 0, do: "text-red-600", else: "text-emerald-600"}"}>
              {if @summary.total_difference >= 0, do: "+", else: ""}{@summary.total_difference}
            </p>
            <p class="text-xs text-slate-500 mt-0.5">Net Difference</p>
          </div>
        </div>
      </div>

      <%!-- Approval actions (requester-raised, awaiting review) --%>
      <%= if @stock_take.status == "pending" do %>
        <div class="rounded-xl border border-blue-200 bg-blue-50 px-6 py-4">
          <div class="flex flex-wrap items-center justify-between gap-3">
            <p class="text-sm text-blue-800">
              This stock take was raised for approval. Approving applies all
              <strong>{@summary.counted}</strong>
              counted quantities and records an audit trail.
            </p>
            <div class="flex gap-3">
              <button
                phx-click="reject_stock_take"
                data-confirm="Reject this stock take? No stock will change."
                class="rounded-lg border border-red-200 bg-white px-4 py-2 text-sm font-semibold text-red-700 hover:bg-red-50"
              >
                Reject
              </button>
              <button
                phx-click="approve_stock_take"
                data-confirm="Approve and apply all counted quantities to inventory?"
                phx-disable-with="Approving..."
                class="rounded-lg bg-emerald-600 px-4 py-2 text-sm font-semibold text-white hover:bg-emerald-700"
              >
                Approve & apply
              </button>
            </div>
          </div>
        </div>
      <% end %>

      <%!-- Action buttons (only for draft) --%>
      <%= if @stock_take.status == "draft" do %>
        <div class="flex items-center justify-between gap-3">
          <button
            phx-click="toggle_search"
            class="inline-flex items-center gap-2 rounded-lg border border-emerald-300 bg-emerald-50 px-4 py-2 text-sm font-medium text-emerald-700 hover:bg-emerald-100 transition-colors"
          >
            <Heroicons.icon name="plus-circle" type="outline" class="h-4 w-4" />
            {if @show_search, do: "Hide Search", else: "Add Items to Count"}
          </button>

          <%= if @summary.counted > 0 do %>
            <button
              phx-click="confirm_apply"
              class="inline-flex items-center gap-2 rounded-lg bg-emerald-600 px-4 py-2 text-sm font-semibold text-white hover:bg-emerald-700 transition-colors"
            >
              <Heroicons.icon name="check-circle" type="outline" class="h-4 w-4" />
              Apply Stock Take ({@summary.counted} items)
            </button>
          <% end %>
        </div>

        <%!-- Search Panel --%>
        <%= if @show_search do %>
          <div class="bg-white rounded-xl shadow-sm border border-emerald-200 px-6 py-5">
            <h3 class="font-semibold text-slate-900 mb-4">Add Items to Count</h3>

            <%!-- Type selector --%>
            <div class="flex flex-wrap gap-2 mb-4">
              <button
                phx-click="set_search_type"
                phx-value-type="drug_batch"
                class={[
                  "rounded-lg px-4 py-2 text-sm font-medium transition-colors",
                  if(@search_type == "drug_batch",
                    do: "bg-emerald-600 text-white",
                    else: "border border-gray-300 text-gray-700 hover:bg-gray-50"
                  )
                ]}
              >
                Drug Batches
              </button>
              <button
                phx-click="set_search_type"
                phx-value-type="lab_allocation"
                class={[
                  "rounded-lg px-4 py-2 text-sm font-medium transition-colors",
                  if(@search_type == "lab_allocation",
                    do: "bg-emerald-600 text-white",
                    else: "border border-gray-300 text-gray-700 hover:bg-gray-50"
                  )
                ]}
              >
                Lab Allocations
              </button>
              <button
                phx-click="set_search_type"
                phx-value-type="nursing_allocation"
                class={[
                  "rounded-lg px-4 py-2 text-sm font-medium transition-colors",
                  if(@search_type == "nursing_allocation",
                    do: "bg-emerald-600 text-white",
                    else: "border border-gray-300 text-gray-700 hover:bg-gray-50"
                  )
                ]}
              >
                Nurse Allocations
              </button>
              <button
                phx-click="set_search_type"
                phx-value-type="inventory_received"
                class={[
                  "rounded-lg px-4 py-2 text-sm font-medium transition-colors",
                  if(@search_type == "inventory_received",
                    do: "bg-emerald-600 text-white",
                    else: "border border-gray-300 text-gray-700 hover:bg-gray-50"
                  )
                ]}
              >
                Inventory Received
              </button>
            </div>

            <%!-- Search input --%>
            <form phx-change="search" phx-submit="search">
              <div class="relative">
                <div class="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3">
                  <Heroicons.icon
                    name="magnifying-glass"
                    type="outline"
                    class="h-4 w-4 text-gray-400"
                  />
                </div>
                <input
                  type="text"
                  name="q"
                  value={@search_query}
                  placeholder={
                    case @search_type do
                      "drug_batch" -> "Search by drug name, generic name or batch number..."
                      _ -> "Search by brand name, generic name or GTIN..."
                    end
                  }
                  class="block w-full rounded-lg border border-gray-300 py-2 pl-10 pr-4 text-sm focus:border-emerald-500 focus:ring-emerald-500"
                  phx-debounce="250"
                />
              </div>
            </form>

            <%!-- Results --%>
            <%= if length(@search_results) > 0 do %>
              <div class="mt-3 rounded-lg border border-gray-200 divide-y divide-gray-100 max-h-64 overflow-y-auto">
                <%= case @search_type do %>
                  <% "drug_batch" -> %>
                    <%= for batch <- @search_results do %>
                      <% ir = batch.drug.inventory_received %>
                      <div class="flex items-center justify-between px-4 py-3 hover:bg-gray-50">
                        <div>
                          <p class="text-sm font-medium text-gray-900">
                            {ir.brand_name || "—"}
                            <%= if ir.generic_name do %>
                              <span class="font-normal text-gray-500">({ir.generic_name})</span>
                            <% end %>
                            <%= if ir.strength do %>
                              <span class="ml-1 text-xs text-gray-400">{ir.strength}</span>
                            <% end %>
                          </p>
                          <p class="text-xs text-gray-500">
                            Batch: {batch.batch.batch} | Category: {ir.category || "—"} | In system:
                            <span class="font-semibold">{batch.remaining_quantity}</span>
                          </p>
                        </div>
                        <button
                          phx-click="add_drug_batch"
                          phx-value-id={batch.id}
                          class="ml-4 shrink-0 rounded-md bg-emerald-50 px-3 py-1 text-xs font-semibold text-emerald-700 hover:bg-emerald-100"
                        >
                          Add
                        </button>
                      </div>
                    <% end %>
                  <% "lab_allocation" -> %>
                    <%= for alloc <- @search_results do %>
                      <% ir = alloc.inventory_issued && alloc.inventory_issued.inventory_received %>
                      <% batch = alloc.inventory_issued && alloc.inventory_issued.batch %>
                      <% batch_no = batch && (batch.batch || batch.serial) %>
                      <div class="flex items-center justify-between px-4 py-3 hover:bg-gray-50">
                        <div>
                          <p class="text-sm font-medium text-gray-900">
                            {ir && ir.brand_name} {if ir && ir.generic_name,
                              do: "(#{ir.generic_name})",
                              else: ""}
                          </p>
                          <p class="text-xs text-gray-500">
                            <%= if batch_no do %>
                              Batch: <span class="font-mono">{batch_no}</span> |
                            <% end %>
                            GTIN: {(ir && ir.gtin) || "—"} | Remaining:
                            <span class="font-semibold">{alloc.remaining_quantity || 0}</span>
                            {if alloc.allocated_to_user,
                              do: " | To: #{alloc.allocated_to_user.name}",
                              else: ""}
                          </p>
                        </div>
                        <button
                          phx-click="add_lab_allocation"
                          phx-value-id={alloc.id}
                          class="ml-4 shrink-0 rounded-md bg-emerald-50 px-3 py-1 text-xs font-semibold text-emerald-700 hover:bg-emerald-100"
                        >
                          Add
                        </button>
                      </div>
                    <% end %>
                  <% "nursing_allocation" -> %>
                    <%= for alloc <- @search_results do %>
                      <% ir = alloc.inventory_issued && alloc.inventory_issued.inventory_received %>
                      <% batch = alloc.inventory_issued && alloc.inventory_issued.batch %>
                      <% batch_no = batch && (batch.batch || batch.serial) %>
                      <div class="flex items-center justify-between px-4 py-3 hover:bg-gray-50">
                        <div>
                          <p class="text-sm font-medium text-gray-900">
                            {ir && ir.brand_name} {if ir && ir.generic_name,
                              do: "(#{ir.generic_name})",
                              else: ""}
                          </p>
                          <p class="text-xs text-gray-500">
                            <%= if batch_no do %>
                              Batch: <span class="font-mono">{batch_no}</span> |
                            <% end %>
                            GTIN: {(ir && ir.gtin) || "—"} | Remaining:
                            <span class="font-semibold">{alloc.remaining_quantity || 0}</span>
                            {if alloc.allocated_to_user,
                              do: " | To: #{alloc.allocated_to_user.name}",
                              else: ""}
                          </p>
                        </div>
                        <button
                          phx-click="add_nursing_allocation"
                          phx-value-id={alloc.id}
                          class="ml-4 shrink-0 rounded-md bg-emerald-50 px-3 py-1 text-xs font-semibold text-emerald-700 hover:bg-emerald-100"
                        >
                          Add
                        </button>
                      </div>
                    <% end %>
                  <% "inventory_received" -> %>
                    <%= for batch <- @search_results do %>
                      <% ir = batch.inventory_received %>
                      <div class="flex items-center justify-between px-4 py-3 hover:bg-gray-50">
                        <div>
                          <p class="text-sm font-medium text-gray-900">
                            {ir && ir.brand_name} {if ir && ir.generic_name,
                              do: "(#{ir.generic_name})",
                              else: ""}
                          </p>
                          <p class="text-xs text-gray-500">
                            Batch: {batch.batch || "—"} | GTIN: {(ir && ir.gtin) || batch.gtin || "—"} | In system:
                            <span class="font-semibold">{batch.remaining_quantity || 0}</span>
                          </p>
                        </div>
                        <button
                          phx-click="add_inventory_received"
                          phx-value-id={batch.id}
                          class="ml-4 shrink-0 rounded-md bg-emerald-50 px-3 py-1 text-xs font-semibold text-emerald-700 hover:bg-emerald-100"
                        >
                          Add
                        </button>
                      </div>
                    <% end %>
                  <% _ -> %>
                <% end %>
              </div>
            <% end %>
          </div>
        <% end %>

        <%!-- Confirm Apply Modal --%>
        <%= if @confirm_apply do %>
          <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
            <div class="bg-white rounded-2xl shadow-xl p-8 max-w-md w-full mx-4">
              <div class="flex items-center gap-3 mb-4">
                <div class="flex h-12 w-12 items-center justify-center rounded-full bg-amber-100">
                  <Heroicons.icon
                    name="exclamation-triangle"
                    type="outline"
                    class="h-6 w-6 text-amber-600"
                  />
                </div>
                <div>
                  <h3 class="text-lg font-semibold text-gray-900">Apply Stock Take?</h3>
                  <p class="text-sm text-gray-500">This cannot be undone.</p>
                </div>
              </div>
              <div class="mb-6 rounded-lg bg-amber-50 border border-amber-200 p-4 text-sm text-amber-800">
                <p class="font-medium mb-1">This will:</p>
                <ul class="list-disc list-inside space-y-1">
                  <li>
                    Update <strong>{@summary.counted}</strong> item quantities to your counted values
                  </li>
                  <li>
                    Create <strong>{@summary.counted}</strong> audit log entries (one per change)
                  </li>
                  <li>
                    Mark this stock take session as <strong>Completed</strong> (no further edits)
                  </li>
                </ul>
              </div>
              <div class="flex gap-3">
                <button
                  phx-click="apply_stock_take"
                  phx-disable-with="Applying..."
                  class="flex-1 rounded-lg bg-emerald-600 px-4 py-2.5 text-sm font-semibold text-white hover:bg-emerald-700"
                >
                  Yes, Apply Stock Take
                </button>
                <button
                  phx-click="cancel_apply"
                  class="flex-1 rounded-lg border border-gray-300 px-4 py-2.5 text-sm font-medium text-gray-700 hover:bg-gray-50"
                >
                  Cancel
                </button>
              </div>
            </div>
          </div>
        <% end %>
      <% end %>

      <%!-- Entries Table --%>
      <div class="bg-white rounded-xl shadow-sm border border-slate-200/80 overflow-hidden">
        <div class="px-6 py-4 border-b border-slate-100">
          <h2 class="font-semibold text-slate-900">
            Items
            <span class="ml-2 text-sm font-normal text-slate-500">({length(@entries)} total)</span>
          </h2>
        </div>

        <%= if Enum.empty?(@entries) do %>
          <div class="flex flex-col items-center justify-center py-16 text-center">
            <Heroicons.icon name="inbox" type="outline" class="h-10 w-10 text-gray-300 mb-3" />
            <p class="text-sm text-gray-500">
              No items added yet. Use "Add Items to Count" to begin.
            </p>
          </div>
        <% else %>
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-500 w-2/5">
                  Item
                </th>
                <th class="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-500">
                  Category
                </th>
                <th class="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-500">
                  UOM
                </th>
                <th class="px-6 py-3 text-right text-xs font-semibold uppercase tracking-wider text-gray-500">
                  System Qty
                </th>
                <th class="px-6 py-3 text-right text-xs font-semibold uppercase tracking-wider text-gray-500">
                  Counted Qty
                </th>
                <th class="px-6 py-3 text-right text-xs font-semibold uppercase tracking-wider text-gray-500">
                  Allocated Qty
                </th>
                <th class="px-6 py-3 text-right text-xs font-semibold uppercase tracking-wider text-gray-500">
                  Difference
                </th>
                <th class="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-500">
                  Notes
                </th>
                <%= if @stock_take.status == "draft" do %>
                  <th class="px-6 py-3 text-right text-xs font-semibold uppercase tracking-wider text-gray-500">
                  </th>
                <% end %>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100 bg-white">
              <%= for entry <- @entries do %>
                <tr class={[
                  "hover:bg-gray-50/50",
                  entry.difference && entry.difference != 0 && "bg-red-50/30"
                ]}>
                  <td class="px-6 py-4">
                    <div>
                      <%= if entry.brand_name do %>
                        <p class="text-sm font-semibold text-gray-900">{entry.brand_name}</p>
                      <% end %>
                      <%= if entry.generic_name do %>
                        <p class="text-xs text-gray-500 italic">{entry.generic_name}</p>
                      <% end %>
                      <%= if entry.batch_number do %>
                        <p class="text-xs text-gray-400 font-mono">Batch: {entry.batch_number}</p>
                      <% end %>
                      <%= if is_nil(entry.brand_name) and is_nil(entry.generic_name) do %>
                        <p class="text-sm font-medium text-gray-900">{entry.entity_name}</p>
                      <% end %>
                      <div class="mt-1 flex flex-wrap gap-1 items-center">
                        <span class={"inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium #{entity_type_badge(entry.entity_type)}"}>
                          {entity_type_label(entry.entity_type)}
                        </span>
                        <%= if entry.has_been_applied do %>
                          <span class="inline-flex items-center rounded-full bg-emerald-50 px-2 py-0.5 text-xs font-medium text-emerald-700">
                            Applied
                          </span>
                        <% end %>
                      </div>
                    </div>
                  </td>
                  <td class="px-6 py-4 text-sm text-gray-500">{entry.category || "—"}</td>
                  <td class="px-6 py-4 text-sm text-gray-500">{entry.uom || "—"}</td>

                  <td class="px-6 py-4 text-right">
                    <span class="font-mono text-sm font-semibold text-gray-800">
                      {entry.previous_quantity}
                    </span>
                  </td>

                  <td class="px-6 py-4 text-right">
                    <%= if @editing_entry_id == entry.id and @stock_take.status == "draft" do %>
                      <form
                        id={"save_count_#{entry.id}"}
                        phx-submit="save_count"
                        class="flex items-center justify-end gap-2"
                      >
                        <input type="hidden" name="entry_id" value={entry.id} />
                        <input
                          type="number"
                          name="counted_quantity"
                          value={entry.counted_quantity}
                          min="0"
                          autofocus
                          class="w-24 rounded-md border border-emerald-400 px-2 py-1 text-right text-sm font-mono focus:border-emerald-500 focus:ring-emerald-500"
                        />
                        <input
                          type="text"
                          name="uom"
                          value={entry.uom || ""}
                          placeholder="UOM"
                          class="w-24 rounded-md border border-emerald-400 px-2 py-1 text-sm focus:border-emerald-500 focus:ring-emerald-500"
                        />
                        <input type="hidden" name="notes" value={entry.notes || ""} />
                        <%= if entry.entity_type != "lab_allocation" do %>
                          <input type="hidden" name="counted_allocated_quantity" value="" />
                        <% end %>
                      </form>
                    <% else %>
                      <div class="flex flex-col items-end">
                        <span class={[
                          "font-mono text-sm font-semibold",
                          if(is_nil(entry.counted_quantity),
                            do: "text-gray-400",
                            else: "text-blue-700"
                          )
                        ]}>
                          {entry.counted_quantity || "—"}
                        </span>
                        <span :if={entry.uom} class="text-xs text-gray-400">{entry.uom}</span>
                      </div>
                    <% end %>
                  </td>

                  <td class="px-6 py-4 text-right">
                    <%= if @editing_entry_id == entry.id and @stock_take.status == "draft" and entry.entity_type == "lab_allocation" do %>
                      <input
                        type="number"
                        name="counted_allocated_quantity"
                        form={"save_count_#{entry.id}"}
                        value={entry.counted_allocated_quantity}
                        min="0"
                        placeholder="Auto"
                        title="Leave blank to auto-adjust only on a surplus count"
                        class="w-24 rounded-md border border-cyan-400 px-2 py-1 text-right text-sm font-mono focus:border-cyan-500 focus:ring-cyan-500"
                      />
                    <% else %>
                      <%= if entry.entity_type == "lab_allocation" do %>
                        <span class={[
                          "font-mono text-sm",
                          if(entry.counted_allocated_quantity,
                            do: "text-cyan-700 font-semibold",
                            else: "text-gray-400"
                          )
                        ]}>
                          {entry.counted_allocated_quantity || "Auto"}
                        </span>
                      <% else %>
                        <span class="text-gray-300 text-sm">—</span>
                      <% end %>
                    <% end %>
                  </td>

                  <td class="px-6 py-4 text-right">
                    <%= if entry.difference != nil do %>
                      <span class={[
                        "inline-flex items-center rounded-full px-2.5 py-0.5 text-sm font-bold",
                        cond do
                          entry.difference > 0 -> "bg-emerald-50 text-emerald-700"
                          entry.difference < 0 -> "bg-red-50 text-red-700"
                          true -> "bg-gray-100 text-gray-600"
                        end
                      ]}>
                        {if entry.difference > 0, do: "+", else: ""}{entry.difference}
                      </span>
                    <% else %>
                      <span class="text-gray-400 text-sm">—</span>
                    <% end %>
                  </td>

                  <td class="px-6 py-4 text-sm text-gray-500 max-w-xs truncate">
                    {entry.notes || "—"}
                  </td>

                  <%= if @stock_take.status == "draft" do %>
                    <td class="px-6 py-4 text-right">
                      <%= if @editing_entry_id == entry.id do %>
                        <div class="flex items-center justify-end gap-2">
                          <button
                            type="submit"
                            form={"save_count_#{entry.id}"}
                            class="rounded bg-emerald-600 px-2 py-1 text-xs text-white hover:bg-emerald-700"
                          >
                            Save
                          </button>
                          <button
                            type="button"
                            phx-click="cancel_edit"
                            class="rounded border px-2 py-1 text-xs text-gray-600 hover:bg-gray-100"
                          >
                            ✕
                          </button>
                        </div>
                      <% else %>
                        <div class="flex items-center justify-end gap-1">
                          <button
                            phx-click="edit_entry"
                            phx-value-id={entry.id}
                            class="rounded-md p-1.5 text-gray-400 hover:bg-blue-50 hover:text-blue-600 transition-colors"
                            title="Enter count"
                          >
                            <Heroicons.icon name="pencil-square" type="outline" class="h-4 w-4" />
                          </button>
                          <button
                            phx-click="delete_entry"
                            phx-value-id={entry.id}
                            data-confirm="Remove this item from the stock take?"
                            class="rounded-md p-1.5 text-gray-400 hover:bg-red-50 hover:text-red-600 transition-colors"
                            title="Remove"
                          >
                            <Heroicons.icon name="trash" type="outline" class="h-4 w-4" />
                          </button>
                        </div>
                      <% end %>
                    </td>
                  <% end %>
                </tr>
              <% end %>
            </tbody>
          </table>
        <% end %>
      </div>
    </div>
    """
  end

  # ── Helpers ────────────────────────────────────────────────────────────────

  defp parse_quantity(str) do
    case Integer.parse(str) do
      {qty, _} -> {:ok, qty}
      :error -> :error
    end
  end

  defp parse_optional_quantity(""), do: {:ok, nil}

  defp parse_optional_quantity(str) do
    case Integer.parse(str) do
      {qty, _} -> {:ok, qty}
      :error -> :error
    end
  end

  defp reload_entries(stock_take_id) do
    import Ecto.Query

    entries =
      Medcamp.Repo.all(
        from e in StockTakeEntry,
          where: e.stock_take_id == ^stock_take_id,
          order_by: [asc: e.entity_type, asc: e.entity_name]
      )

    Enum.map(entries, fn entry ->
      {brand, generic, batch_no} = StockTakes.lookup_entry_names(entry)

      Map.merge(Map.from_struct(entry), %{
        brand_name: brand,
        generic_name: generic,
        batch_number: batch_no,
        uom: entry.uom || StockTakes.lookup_entry_uom(entry)
      })
    end)
  end

  defp status_badge(assigns, "draft") do
    ~H"""
    <span class="inline-flex items-center gap-1 rounded-full bg-amber-50 px-2.5 py-1 text-xs font-semibold text-amber-700 ring-1 ring-inset ring-amber-600/20">
      <span class="h-1.5 w-1.5 rounded-full bg-amber-500"></span>Draft
    </span>
    """
  end

  defp status_badge(assigns, "completed") do
    ~H"""
    <span class="inline-flex items-center gap-1 rounded-full bg-emerald-50 px-2.5 py-1 text-xs font-semibold text-emerald-700 ring-1 ring-inset ring-emerald-600/20">
      <span class="h-1.5 w-1.5 rounded-full bg-emerald-500"></span>Completed
    </span>
    """
  end

  defp status_badge(assigns, "pending") do
    ~H"""
    <span class="inline-flex items-center gap-1 rounded-full bg-blue-50 px-2.5 py-1 text-xs font-semibold text-blue-700 ring-1 ring-inset ring-blue-600/20">
      <span class="h-1.5 w-1.5 rounded-full bg-blue-500"></span>Pending approval
    </span>
    """
  end

  defp status_badge(assigns, "rejected") do
    ~H"""
    <span class="inline-flex items-center gap-1 rounded-full bg-red-50 px-2.5 py-1 text-xs font-semibold text-red-700 ring-1 ring-inset ring-red-600/20">
      <span class="h-1.5 w-1.5 rounded-full bg-red-500"></span>Rejected
    </span>
    """
  end

  defp status_badge(assigns, _), do: ~H""

  defp entity_type_label("drug_batch"), do: "Drug Batch"
  defp entity_type_label("lab_allocation"), do: "Lab Allocation"
  defp entity_type_label("nursing_allocation"), do: "Nurse Allocation"
  defp entity_type_label("inventory_received"), do: "Inv. Received Batch"
  defp entity_type_label(other), do: other

  defp entity_type_badge("drug_batch"), do: "bg-slate-50 text-purple-700"
  defp entity_type_badge("lab_allocation"), do: "bg-cyan-50 text-cyan-700"
  defp entity_type_badge("nursing_allocation"), do: "bg-pink-50 text-pink-700"
  defp entity_type_badge("inventory_received"), do: "bg-orange-50 text-orange-700"
  defp entity_type_badge(_), do: "bg-gray-100 text-gray-600"

  defp format_date(date) do
    Calendar.strftime(date, "%B %-d, %Y")
  end
end
