defmodule MedcampWeb.AdminInventoryDisposalLive.Show do
  use MedcampWeb, :admin_live_view

  alias Medcamp.InventoryDisposals

  @source_types [
    {"Received batches", "inventory_received"},
    {"Pharmacy batches", "drug_batch"},
    {"Lab allocations", "lab_allocation"},
    {"Nurse allocations", "nursing_allocation"}
  ]

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :inventory_disposals)
     |> assign(:disposal, InventoryDisposals.get_disposal!(id))
     |> assign(:source_types, @source_types)
     |> assign(:source_type, "inventory_received")
     |> assign(:search_query, "")
     |> assign(:search_results, [])}
  end

  # Keeps the picker on the same result set after an item is added, so several
  # items can be added in a row; the one just added drops out because it is now
  # on the request.
  defp refresh_search(socket) do
    query = socket.assigns.search_query

    results =
      if String.trim(query) != "" do
        socket.assigns.source_type
        |> InventoryDisposals.search_sources(query)
        |> reject_already_added(socket.assigns.disposal)
      else
        []
      end

    assign(socket, :search_results, results)
  end

  defp reject_already_added(results, disposal) do
    added = MapSet.new(disposal.items, & &1.entity_id)
    Enum.reject(results, &MapSet.member?(added, &1.id))
  end

  @impl true
  def handle_event("select_source_type", %{"type" => type}, socket) do
    {:noreply,
     socket
     |> assign(:source_type, type)
     |> assign(:search_query, "")
     |> assign(:search_results, [])}
  end

  def handle_event("search", %{"q" => query}, socket) do
    {:noreply, socket |> assign(:search_query, query) |> refresh_search()}
  end

  def handle_event("add_source", params, socket) do
    type = socket.assigns.source_type

    source =
      Enum.find(socket.assigns.search_results, &(to_string(&1.id) == params["source_id"]))

    with false <- socket.assigns.disposal.status != "draft",
         source when not is_nil(source) <- source,
         {quantity, ""} when quantity > 0 <- Integer.parse(params["quantity"] || ""),
         attrs <-
           type
           |> InventoryDisposals.source_attributes(source)
           |> Map.merge(%{
             inventory_disposal_id: socket.assigns.disposal.id,
             quantity: quantity,
             notes: params["notes"]
           }),
         {:ok, _item} <- InventoryDisposals.create_item(attrs) do
      {:noreply,
       socket
       |> reload_disposal()
       |> refresh_search()
       |> put_flash(:info, "Item added to the request.")}
    else
      true ->
        {:noreply, put_flash(socket, :error, "Only draft requests can be changed.")}

      nil ->
        {:noreply, put_flash(socket, :error, "That inventory source is no longer available.")}

      :error ->
        {:noreply, put_flash(socket, :error, "Enter a valid quantity greater than zero.")}

      {:error, %Ecto.Changeset{} = changeset} ->
        message =
          changeset.errors
          |> Enum.map(fn {field, {text, _}} -> "#{Phoenix.Naming.humanize(field)} #{text}" end)
          |> Enum.join(", ")

        {:noreply, put_flash(socket, :error, message)}

      {_quantity, _rest} ->
        {:noreply, put_flash(socket, :error, "Enter a whole-number quantity greater than zero.")}
    end
  end

  def handle_event("delete_item", %{"id" => id}, socket) do
    if socket.assigns.disposal.status == "draft" do
      item = id |> String.to_integer() |> InventoryDisposals.get_item!()

      if item.inventory_disposal_id == socket.assigns.disposal.id do
        InventoryDisposals.delete_item(item)

        {:noreply,
         socket |> reload_disposal() |> refresh_search() |> put_flash(:info, "Item removed.")}
      else
        {:noreply, put_flash(socket, :error, "That item does not belong to this request.")}
      end
    else
      {:noreply, put_flash(socket, :error, "Only draft requests can be changed.")}
    end
  end

  def handle_event("submit", _, socket) do
    case InventoryDisposals.submit(socket.assigns.disposal) do
      {:ok, _} ->
        {:noreply,
         socket
         |> reload_disposal()
         |> put_flash(:info, "Request submitted for approval.")}

      {:error, :no_items} ->
        {:noreply, put_flash(socket, :error, "Add at least one item before submitting.")}

      {:error, {:insufficient_stock, name, available}} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "#{name} now has only #{available} left. Remove that item and add it again with a smaller quantity."
         )}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "This request cannot be submitted.")}
    end
  end

  def handle_event("approve", _, socket) do
    case InventoryDisposals.approve(socket.assigns.disposal, socket.assigns.current_user.id) do
      {:ok, _} ->
        {:noreply,
         socket
         |> reload_disposal()
         |> put_flash(:info, "Request approved. Inventory quantities have been deducted.")}

      {:error, {:insufficient_stock, name, available}} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "#{name} now has only #{available} available. Update the request before approval."
         )}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Could not approve request: #{error_label(reason)}")}
    end
  end

  def handle_event("reject", _, socket) do
    case InventoryDisposals.reject(socket.assigns.disposal, socket.assigns.current_user.id) do
      {:ok, _} ->
        {:noreply, socket |> reload_disposal() |> put_flash(:info, "Request rejected.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Only pending requests can be rejected.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6 print:hidden">
      <.link
        navigate="/admin/inventory_disposals"
        class="inline-flex items-center gap-1 text-sm text-slate-500 hover:text-slate-800"
      >
        <Heroicons.icon name="arrow-left" type="outline" class="h-4 w-4" /> Back to Donations & Expiry
      </.link>

      <div class="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
        <div class="flex flex-wrap items-start gap-4">
          <div class={[
            "flex h-12 w-12 items-center justify-center rounded-xl",
            @disposal.kind == "donation" && "bg-indigo-100 text-indigo-700",
            @disposal.kind == "expiry" && "bg-amber-100 text-amber-700"
          ]}>
            <Heroicons.icon
              name={if @disposal.kind == "donation", do: "gift", else: "clock"}
              type="outline"
              class="h-6 w-6"
            />
          </div>
          <div class="min-w-0 flex-1">
            <div class="flex flex-wrap items-center gap-3">
              <h1 class="text-xl font-semibold text-slate-900">
                {kind_label(@disposal.kind)} request #{@disposal.id}
              </h1>
              {status_badge(assigns, @disposal.status)}
            </div>
            <p class="mt-1 text-sm text-slate-500">
              Requested by {@disposal.requested_by.name} on {format_date(@disposal.date)}
            </p>
            <%= if @disposal.reason not in [nil, ""] do %>
              <p class="mt-2 text-sm text-slate-700">{@disposal.reason}</p>
            <% end %>
            <%= if @disposal.supporting_document_path do %>
              <p class="mt-2 flex items-center gap-1.5 text-sm text-slate-500">
                <Heroicons.icon name="paper-clip" type="outline" class="h-4 w-4 shrink-0" />
                Authorization document:
                <a
                  href={@disposal.supporting_document_path}
                  target="_blank"
                  class="font-medium text-indigo-700 underline hover:text-indigo-900"
                >
                  View PDF
                </a>
              </p>
            <% end %>
          </div>
          <%= if @disposal.items != [] do %>
            <button
              type="button"
              phx-click={show_modal("print-modal")}
              class="inline-flex shrink-0 items-center gap-2 rounded-lg border border-slate-200 px-3 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-50"
            >
              <Heroicons.icon name="printer" type="outline" class="h-4 w-4" /> Print
            </button>
          <% end %>
        </div>

        <%= if @disposal.status == "draft" do %>
          <div class="mt-5 flex justify-end border-t border-slate-100 pt-4">
            <button
              phx-click="submit"
              data-confirm="Submit this request for approval? You will no longer be able to edit it."
              class="rounded-lg bg-[#373896] px-4 py-2 text-sm font-semibold text-white"
            >
              Submit for approval
            </button>
          </div>
        <% end %>

        <%= if @disposal.status == "pending" do %>
          <div class="mt-5 flex justify-end gap-3 border-t border-slate-100 pt-4">
            <button
              phx-click="reject"
              data-confirm="Reject this request?"
              class="rounded-lg border border-red-200 px-4 py-2 text-sm font-semibold text-red-700"
            >
              Reject
            </button>
            <button
              phx-click="approve"
              data-confirm="Approve and deduct all listed quantities from inventory?"
              class="rounded-lg bg-emerald-600 px-4 py-2 text-sm font-semibold text-white"
            >
              Approve & deduct stock
            </button>
          </div>
        <% end %>
      </div>

      <%= if @disposal.status == "draft" do %>
        <div class="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
          <h2 class="font-semibold text-slate-900">Add inventory</h2>
          <p class="mt-1 text-sm text-slate-500">
            Choose the table holding the stock, search for an item, then specify the quantity.
          </p>

          <div class="mt-4 flex flex-wrap gap-2">
            <%= for {label, type} <- @source_types do %>
              <button
                phx-click="select_source_type"
                phx-value-type={type}
                class={[
                  "rounded-full border px-3 py-1.5 text-sm font-medium",
                  @source_type == type && "border-[#373896] bg-indigo-50 text-[#373896]",
                  @source_type != type && "border-slate-200 text-slate-600 hover:bg-slate-50"
                ]}
              >
                {label}
              </button>
            <% end %>
          </div>

          <form phx-change="search" class="mt-4">
            <input
              type="search"
              name="q"
              value={@search_query}
              phx-debounce="300"
              placeholder="Search by item, generic name, GTIN, or batch..."
              class="w-full rounded-lg border border-slate-300 px-4 py-2.5 text-sm focus:border-[#373896] focus:ring-[#373896]"
            />
          </form>

          <%= if @search_results != [] do %>
            <div class="mt-4 overflow-x-auto rounded-lg border border-slate-200">
              <table class="min-w-full divide-y divide-slate-200 text-sm">
                <thead class="bg-slate-50 text-left text-xs uppercase text-slate-500">
                  <tr>
                    <th class="px-4 py-3">Item</th>
                    <th class="px-4 py-3">Batch</th>
                    <th class="px-4 py-3">Available</th>
                    <th class="px-4 py-3">Quantity to remove</th>
                    <th class="px-4 py-3">Notes</th>
                    <th class="px-4 py-3"></th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-slate-100">
                  <%= for result <- @search_results do %>
                    <% attrs = InventoryDisposals.source_attributes(@source_type, result) %>
                    <tr>
                      <td class="px-4 py-3 font-medium text-slate-800">{attrs.entity_name}</td>
                      <td class="whitespace-nowrap px-4 py-3 font-medium text-slate-700">
                        {InventoryDisposals.source_batch(@source_type, result)}
                      </td>
                      <td class="whitespace-nowrap px-4 py-3">
                        {attrs.available_quantity} {attrs.uom}
                      </td>
                      <td class="px-4 py-3" colspan="3">
                        <form phx-submit="add_source" class="flex min-w-[430px] items-center gap-2">
                          <input type="hidden" name="source_id" value={result.id} />
                          <input
                            type="number"
                            name="quantity"
                            min="1"
                            max={attrs.available_quantity}
                            required
                            class="w-28 rounded-lg border border-slate-300 px-3 py-2"
                          />
                          <input
                            type="text"
                            name="notes"
                            placeholder="Optional notes"
                            class="min-w-36 flex-1 rounded-lg border border-slate-300 px-3 py-2"
                          />
                          <button class="rounded-lg bg-[#373896] px-3 py-2 font-semibold text-white">
                            Add
                          </button>
                        </form>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          <% end %>
        </div>
      <% end %>

      <div class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
        <div class="border-b border-slate-200 px-5 py-4">
          <h2 class="font-semibold text-slate-900">Items for {kind_label(@disposal.kind)}</h2>
        </div>
        <div class="overflow-x-auto">
          <table class="min-w-full divide-y divide-slate-200 text-sm">
            <thead class="bg-slate-50 text-left text-xs uppercase text-slate-500">
              <tr>
                <th class="px-5 py-3">Source table</th>
                <th class="px-5 py-3">Item</th>
                <th class="px-5 py-3">Available when added</th>
                <th class="px-5 py-3">Quantity</th>
                <th class="px-5 py-3">Notes</th>
                <th class="px-5 py-3">Applied</th>
                <th class="px-5 py-3"></th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
              <%= for item <- @disposal.items do %>
                <tr>
                  <td class="whitespace-nowrap px-5 py-4">{source_label(item.entity_type)}</td>
                  <td class="px-5 py-4 font-medium text-slate-800">{item.entity_name}</td>
                  <td class="whitespace-nowrap px-5 py-4">
                    {item.available_quantity} {item.uom}
                  </td>
                  <td class="whitespace-nowrap px-5 py-4 font-semibold">
                    {item.quantity} {item.uom}
                  </td>
                  <td class="px-5 py-4 text-slate-600">{item.notes || "—"}</td>
                  <td class="px-5 py-4">
                    <%= if item.has_been_applied do %>
                      <span class="font-semibold text-emerald-700">Yes</span>
                    <% else %>
                      <span class="text-slate-400">No</span>
                    <% end %>
                  </td>
                  <td class="px-5 py-4 text-right">
                    <%= if @disposal.status == "draft" do %>
                      <button
                        phx-click="delete_item"
                        phx-value-id={item.id}
                        data-confirm="Remove this item?"
                        class="font-semibold text-red-600 hover:underline"
                      >
                        Remove
                      </button>
                    <% end %>
                  </td>
                </tr>
              <% end %>
              <%= if @disposal.items == [] do %>
                <tr>
                  <td colspan="7" class="px-5 py-12 text-center text-slate-500">
                    No inventory items have been added.
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <.modal :if={@disposal.items != []} id="print-modal">
      <div class="mb-4 flex justify-end print:hidden">
        <button
          type="button"
          onclick="window.print()"
          class="inline-flex items-center gap-2 rounded-lg bg-[#373896] px-4 py-2 text-sm font-semibold text-white hover:bg-[#2d2d7a]"
        >
          <Heroicons.icon name="printer" type="outline" class="h-4 w-4" /> Print
        </button>
      </div>
      {MedcampWeb.StockRequests.Print.voucher(assigns)}
    </.modal>
    """
  end

  defp reload_disposal(socket),
    do: assign(socket, :disposal, InventoryDisposals.get_disposal!(socket.assigns.disposal.id))

  defp kind_label("donation"), do: "Donation"
  defp kind_label("expiry"), do: "Expiry"

  defp source_label("inventory_received"), do: "Received batch"
  defp source_label("drug_batch"), do: "Pharmacy batch"
  defp source_label("lab_allocation"), do: "Lab allocation"
  defp source_label("nursing_allocation"), do: "Nurse allocation"

  defp format_date(date), do: Calendar.strftime(date, "%d %b %Y")
  defp error_label(reason), do: inspect(reason)

  defp status_badge(assigns, status) do
    assigns = assign(assigns, :status, status)

    ~H"""
    <span class={[
      "inline-flex rounded-full px-2.5 py-1 text-xs font-semibold capitalize",
      @status == "draft" && "bg-slate-100 text-slate-700",
      @status == "pending" && "bg-amber-100 text-amber-800",
      @status == "approved" && "bg-emerald-100 text-emerald-800",
      @status == "rejected" && "bg-red-100 text-red-800"
    ]}>
      {@status}
    </span>
    """
  end
end
