defmodule MedcampWeb.RequisitionLive.Show do
  use MedcampWeb, :shared_live_view

  alias Phoenix.LiveView.JS
  alias MedcampWeb.RoleRouteHelpers
  alias Medcamp.Requisitions
  alias Medcamp.Batches
  alias Medcamp.DrugBatches
  alias Medcamp.InventoriesIssues
  alias Medcamp.Nursing
  alias Medcamp.Departments

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :requisitions)
     |> assign(:show_reject_modal, false)
     |> assign(:reject_error, nil)}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    requisition = Requisitions.get_requisition!(id)

    is_pharmacy_requisition =
      requisition.to_department && requisition.to_department.name == "Pharmacy"

    batches =
      if is_pharmacy_requisition, do: [], else: available_batches_for_requisition(requisition)

    drug_batches =
      if is_pharmacy_requisition,
        do: available_drug_batches_for_requisition(requisition),
        else: []

    issued_history = InventoriesIssues.list_inventories_issued_for_requisition(requisition.id)

    quantity_in_stock =
      case requisition.inventory_received_id &&
             Batches.get_inventory_by_received_id(requisition.inventory_received_id) do
        %{quantity_in_stock: qty} -> qty
        _ -> nil
      end

    {:noreply,
     socket
     |> assign(:page_title, "Requisition Details")
     |> assign(:requisition, requisition)
     |> assign(:is_pharmacy_requisition, is_pharmacy_requisition)
     |> assign(:available_batches, batches)
     |> assign(:drug_batches, drug_batches)
     |> assign(:issued_history, issued_history)
     |> assign(:quantity_in_stock, quantity_in_stock)}
  end

  @impl true
  def handle_event("approve", %{"id" => id}, socket) do
    requisition = Requisitions.get_requisition!(id)

    current_user = socket.assigns.current_user

    if can_respond?(current_user, requisition) do
      case Requisitions.update_requisition(requisition, %{
             status: "approved"
           }) do
        {:ok, updated_requisition} ->
          batches = available_batches_for_requisition(updated_requisition)

          issued_history =
            InventoriesIssues.list_inventories_issued_for_requisition(updated_requisition.id)

          {:noreply,
           socket
           |> assign(:requisition, updated_requisition)
           |> assign(:available_batches, batches)
           |> assign(:issued_history, issued_history)
           |> put_flash(:info, "Requisition approved successfully")}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Failed to approve requisition")}
      end
    else
      {:noreply, put_flash(socket, :error, "You are not authorized to approve this requisition")}
    end
  end

  @impl true
  def handle_event("open_reject_modal", _params, socket) do
    {:noreply, socket |> assign(:show_reject_modal, true) |> assign(:reject_error, nil)}
  end

  @impl true
  def handle_event("close_reject_modal", _params, socket) do
    {:noreply, socket |> assign(:show_reject_modal, false) |> assign(:reject_error, nil)}
  end

  @impl true
  def handle_event("reject", %{"_id" => id, "rejection_reason" => reason}, socket) do
    requisition = Requisitions.get_requisition!(id)

    current_user = socket.assigns.current_user

    if can_respond?(current_user, requisition) do
      case Requisitions.update_requisition(requisition, %{
             "status" => "rejected",
             "rejection_reason" => reason
           }) do
        {:ok, updated_requisition} ->
          batches = available_batches_for_requisition(updated_requisition)

          issued_history =
            InventoriesIssues.list_inventories_issued_for_requisition(updated_requisition.id)

          {:noreply,
           socket
           |> assign(:requisition, updated_requisition)
           |> assign(:available_batches, batches)
           |> assign(:issued_history, issued_history)
           |> assign(:show_reject_modal, false)
           |> assign(:reject_error, nil)
           |> put_flash(:info, "Requisition rejected successfully")}

        {:error, changeset} ->
          {:noreply, assign(socket, :reject_error, changeset_error(changeset))}
      end
    else
      {:noreply,
       socket
       |> assign(:show_reject_modal, false)
       |> put_flash(:error, "You are not authorized to reject this requisition")}
    end
  end

  @impl true
  def handle_event("push_to_admin", %{"id" => id}, socket) do
    requisition = Requisitions.get_requisition!(id)
    admin_dept = Departments.get_department_by_name("admin")

    if requisition.requested_by_id == socket.assigns.current_user.id do
      case Requisitions.update_requisition(requisition, %{
             to_department_id: admin_dept && admin_dept.id,
             needs_reorder: true,
             status: "pending"
           }) do
        {:ok, updated} ->
          {:noreply,
           socket
           |> assign(:requisition, updated)
           |> put_flash(:info, "Requisition pushed to admin for reorder")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to push to admin")}
      end
    else
      {:noreply, put_flash(socket, :error, "Only the requester can push to admin")}
    end
  end

  @impl true
  def handle_event("issue_to_nurse", %{"drug_batch_id" => drug_batch_id}, socket) do
    requisition = socket.assigns.requisition
    current_user = socket.assigns.current_user
    drug_batch = DrugBatches.get_drug_batch!(drug_batch_id)

    quantity =
      min(requisition.quantity || drug_batch.remaining_quantity, drug_batch.remaining_quantity)

    with {:ok, _} <-
           DrugBatches.update_drug_batch(drug_batch, %{
             remaining_quantity: drug_batch.remaining_quantity - quantity
           }),
         {:ok, _} <-
           Nursing.add_to_nursing_allocation(
             requisition.requested_by_id,
             requisition.inventory_received_id,
             quantity,
             %{
               uom:
                 (requisition.inventory_received && requisition.inventory_received.uom) || "units",
               expiry_date: drug_batch.batch && drug_batch.batch.expiry,
               batch_id: drug_batch.batch_id,
               allocated_by: current_user.id
             }
           ),
         {:ok, updated_requisition} <-
           Requisitions.update_requisition(requisition, %{status: "fulfilled"}) do
      drug_batches = available_drug_batches_for_requisition(updated_requisition)

      {:noreply,
       socket
       |> assign(:requisition, updated_requisition)
       |> assign(:drug_batches, drug_batches)
       |> put_flash(:info, "#{quantity} units issued to nursing and added to allocations")}
    else
      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to issue inventory. Please try again.")}
    end
  end

  defp status_badge(status) do
    case status do
      "pending" -> {"Pending", "bg-yellow-100 text-yellow-800"}
      "approved" -> {"Approved", "bg-green-100 text-green-800"}
      "rejected" -> {"Rejected", "bg-red-100 text-red-800"}
      "fulfilled" -> {"Fulfilled", "bg-blue-100 text-blue-800"}
      _ -> {status, "bg-gray-100 text-gray-800"}
    end
  end

  defp requisitions_path(current_user, suffix \\ "") do
    if current_user.role in ["procurement_officer", "stores_officer", "finance_officer"] do
      "/procurement/requisitions" <> suffix
    else
      RoleRouteHelpers.role_path(current_user, "/requisitions" <> suffix)
    end
  end

  defp can_respond?(%{role: "admin"}, %{status: "pending"}), do: true

  defp can_respond?(current_user, requisition) do
    requisition.status == "pending" and
      (requisition.to_department_id == current_user.department_id or
         requisition.requested_from_id == current_user.id)
  end

  defp requested_at_for_display(requisition) do
    requisition.requested_at || requisition.inserted_at
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-4">
      <.header class="text-[#373896] border-b border-gray-100 pb-4 mb-4">
        Requisition Details
        <:actions>
          <.link navigate={requisitions_path(@current_user)}>
            <.button class="bg-gray-200 hover:bg-gray-300 text-gray-700">
              Back to Requisitions
            </.button>
          </.link>
        </:actions>
      </.header>

      <div class="space-y-6">
        <!-- Status Badge -->
        <div class="flex items-center justify-between">
          <div>
            <%= case status_badge(@requisition.status) do %>
              <% {label, classes} -> %>
                <span class={"px-4 py-2 text-sm font-medium rounded-full #{classes}"}>
                  {label}
                </span>
            <% end %>
          </div>
          <div class="flex gap-2">
            <%= if can_respond?(@current_user, @requisition) do %>
              <button
                phx-click="approve"
                phx-value-id={@requisition.id}
                class="px-4 py-2 bg-green-600 hover:bg-green-700 text-white rounded-md text-sm font-medium"
              >
                Approve
              </button>
              <button
                type="button"
                phx-click="open_reject_modal"
                class="px-4 py-2 bg-red-600 hover:bg-red-700 text-white rounded-md text-sm font-medium"
              >
                Reject
              </button>
            <% end %>
            <%= if @requisition.requested_by_id == @current_user.id &&
                     @requisition.status == "pending" &&
                     @requisition.quantity && @quantity_in_stock &&
                     @requisition.quantity > @quantity_in_stock do %>
              <button
                phx-click="push_to_admin"
                phx-value-id={@requisition.id}
                data-confirm="Stock is insufficient — push this requisition to admin for reorder?"
                class="px-4 py-2 bg-orange-500 hover:bg-orange-600 text-white rounded-md text-sm font-medium"
              >
                Push to Admin (Stock Reorder)
              </button>
            <% end %>
          </div>
        </div>
        
    <!-- Requisition Details -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Title</label>
            <p class="text-gray-900">{@requisition.title}</p>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Status</label>
            <%= case status_badge(@requisition.status) do %>
              <% {label, classes} -> %>
                <span class={"px-3 py-1 text-xs font-medium rounded-full #{classes}"}>
                  {label}
                </span>
            <% end %>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Requested By</label>
            <p class="text-gray-900">{@requisition.requested_by.name}</p>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">To department</label>
            <p class="text-gray-900">
              <%= if @requisition.to_department do %>
                {@requisition.to_department.name}
              <% else %>
                <%= if @requisition.requested_from do %>
                  {@requisition.requested_from.name} (user)
                <% else %>
                  —
                <% end %>
              <% end %>
            </p>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Quantity</label>
            <%= if @requisition.quantity do %>
              <span class="px-3 py-1 text-sm font-medium rounded-full bg-blue-100 text-blue-800">
                {@requisition.quantity} units
              </span>
            <% else %>
              <p class="text-gray-400">—</p>
            <% end %>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Linked Inventory</label>
            <%= if @requisition.inventory_received do %>
              <div class="rounded-lg border border-blue-200 bg-blue-50 px-3 py-2">
                <p class="font-medium text-gray-900">
                  {@requisition.inventory_received.brand_name ||
                    @requisition.inventory_received.generic_name || "Inventory item"}
                </p>
                <p class="text-sm text-gray-600">
                  {@requisition.inventory_received.generic_name || "—"} • GTIN: {@requisition.inventory_received.gtin ||
                    "—"}
                </p>
              </div>
            <% else %>
              <%= if @requisition.general_inventory_item do %>
                <div class="rounded-lg border border-purple-200 bg-slate-50 px-3 py-2">
                  <p class="font-medium text-gray-900">
                    {@requisition.general_inventory_item.name}
                  </p>
                  <p class="text-sm text-gray-600">
                    {@requisition.general_inventory_item.category} • {@requisition.general_inventory_item.unit_of_measure}
                  </p>
                </div>
              <% else %>
                <p class="text-gray-400">—</p>
              <% end %>
            <% end %>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Requested At</label>
            <%= if requested_at = requested_at_for_display(@requisition) do %>
              <p class="text-gray-900">
                {format_datetime_kenya(requested_at)}
              </p>
            <% else %>
              <p class="text-gray-400">-</p>
            <% end %>
          </div>

          <%= if @requisition.responded_at do %>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Responded At</label>
              <p class="text-gray-900">
                {format_datetime_kenya(@requisition.responded_at)}
              </p>
            </div>
          <% end %>

          <%= if @requisition.status == "rejected" do %>
            <div class="md:col-span-2">
              <label class="block text-sm font-medium text-gray-700 mb-1">Rejection Reason</label>
              <p class="text-gray-900 whitespace-pre-wrap">{@requisition.rejection_reason || "—"}</p>
            </div>
          <% end %>
        </div>
        
    <!-- Description -->
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Description</label>
          <p class="text-gray-900 whitespace-pre-wrap">{@requisition.description}</p>
        </div>
        
    <!-- Notes -->
        <%= if @requisition.notes && @requisition.notes != "" do %>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Notes</label>
            <p class="text-gray-900 whitespace-pre-wrap">{@requisition.notes}</p>
          </div>
        <% end %>

        <%= if @requisition.inventory_received do %>
          <div class="border-t border-gray-100 pt-6">
            <div class="flex items-center justify-between mb-4 gap-3">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">
                  {if @is_pharmacy_requisition,
                    do: "Available Drug Stock (Pharmacy)",
                    else: "Available Batches"}
                </label>
                <p class="text-sm text-gray-500">
                  <%= if @is_pharmacy_requisition do %>
                    Confirmed drug batches in pharmacy available to issue to nursing.
                  <% else %>
                    Batches currently available for the linked inventory received item.
                  <% end %>
                </p>
              </div>

              <%= if @requisition.status == "approved" and can_issue?(@current_user, @requisition) do %>
                <.link
                  navigate={issue_inventory_path(@requisition, nil, nil)}
                  class="inline-flex items-center px-4 py-2 bg-[#6667ab] hover:bg-[#5556a0] text-white rounded-md text-sm font-medium"
                >
                  Issue Inventory
                </.link>
              <% end %>
            </div>

            <%= if @is_pharmacy_requisition do %>
              <%= if Enum.empty?(@drug_batches) do %>
                <div class="rounded-lg border border-dashed border-gray-300 bg-gray-50 px-4 py-6 text-sm text-gray-500">
                  No confirmed drug stock found in pharmacy for this item.
                </div>
              <% else %>
                <div class="overflow-hidden rounded-lg border border-gray-200">
                  <table class="min-w-full divide-y divide-gray-200">
                    <thead class="bg-gray-50">
                      <tr>
                        <th class="px-4 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500">
                          Batch
                        </th>
                        <th class="px-4 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500">
                          Expiry
                        </th>
                        <th class="px-4 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500">
                          In Pharmacy
                        </th>
                        <th class="px-4 py-3 text-right text-xs font-medium uppercase tracking-wide text-gray-500">
                          Action
                        </th>
                      </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-100 bg-white">
                      <%= for db <- @drug_batches do %>
                        <tr>
                          <td class="px-4 py-3 text-sm font-medium text-gray-900">
                            {(db.batch && db.batch.batch) || "—"}
                          </td>
                          <td class="px-4 py-3 text-sm text-gray-600">
                            {(db.batch && db.batch.expiry) || "N/A"}
                          </td>
                          <td class="px-4 py-3 text-sm text-gray-600">
                            {db.remaining_quantity} units
                          </td>
                          <td class="px-4 py-3 text-right">
                            <%= if @requisition.status == "approved" and can_issue?(@current_user, @requisition) do %>
                              <button
                                phx-click="issue_to_nurse"
                                phx-value-drug_batch_id={db.id}
                                data-confirm={"Issue #{@requisition.quantity || db.remaining_quantity} units of #{@requisition.inventory_received && @requisition.inventory_received.brand_name} to #{@requisition.requested_by.name} (Nursing)?"}
                                class="text-sm font-medium text-green-600 hover:text-green-800"
                              >
                                Issue this batch
                              </button>
                            <% else %>
                              <span class="text-xs text-gray-400">
                                {if @requisition.status != "approved",
                                  do: "Approve requisition first",
                                  else: "Not authorized"}
                              </span>
                            <% end %>
                          </td>
                        </tr>
                      <% end %>
                    </tbody>
                  </table>
                </div>
              <% end %>
            <% else %>
              <%= if Enum.empty?(@available_batches) do %>
                <div class="rounded-lg border border-dashed border-gray-300 bg-gray-50 px-4 py-6 text-sm text-gray-500">
                  No available batches found for this inventory item.
                </div>
              <% else %>
                <div class="overflow-hidden rounded-lg border border-gray-200">
                  <table class="min-w-full divide-y divide-gray-200">
                    <thead class="bg-gray-50">
                      <tr>
                        <th class="px-4 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500">
                          Batch
                        </th>
                        <th class="px-4 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500">
                          Expiry
                        </th>
                        <th class="px-4 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500">
                          Remaining
                        </th>
                        <th class="px-4 py-3 text-right text-xs font-medium uppercase tracking-wide text-gray-500">
                          Action
                        </th>
                      </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-100 bg-white">
                      <%= for batch <- @available_batches do %>
                        <tr>
                          <td class="px-4 py-3 text-sm font-medium text-gray-900">{batch.batch}</td>
                          <td class="px-4 py-3 text-sm text-gray-600">{batch.expiry || "N/A"}</td>
                          <td class="px-4 py-3 text-sm text-gray-600">
                            {batch.remaining_quantity} units
                          </td>
                          <td class="px-4 py-3 text-right">
                            <%= if @requisition.status == "approved" and can_issue?(@current_user, @requisition) do %>
                              <.link
                                navigate={issue_inventory_path(@requisition, batch, nil)}
                                class="text-sm font-medium text-green-600 hover:text-green-800"
                              >
                                Issue this batch
                              </.link>
                            <% else %>
                              <span class="text-xs text-gray-400">
                                {if @requisition.status != "approved",
                                  do: "Approve requisition first",
                                  else: "Not authorized"}
                              </span>
                            <% end %>
                          </td>
                        </tr>
                      <% end %>
                    </tbody>
                  </table>
                </div>
              <% end %>
            <% end %>
          </div>
        <% end %>

        <div class="border-t border-gray-100 pt-6">
          <div class="flex items-center justify-between mb-4 gap-3">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Issued History</label>
              <p class="text-sm text-gray-500">
                Inventory already supplied specifically against this requisition.
              </p>
            </div>

            <%= if !Enum.empty?(@issued_history) do %>
              <span class="px-3 py-1 text-xs font-medium rounded-full bg-green-100 text-green-800">
                {issued_total(@issued_history)} units issued
              </span>
            <% end %>
          </div>

          <%= if Enum.empty?(@issued_history) do %>
            <div class="rounded-lg border border-dashed border-gray-300 bg-gray-50 px-4 py-6 text-sm text-gray-500">
              No inventory has been issued against this requisition yet.
            </div>
          <% else %>
            <div class="overflow-hidden rounded-lg border border-gray-200">
              <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                  <tr>
                    <th class="px-4 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500">
                      Issued At
                    </th>
                    <th class="px-4 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500">
                      Batch
                    </th>
                    <th class="px-4 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500">
                      Location
                    </th>
                    <th class="px-4 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500">
                      Assigned To
                    </th>
                    <th class="px-4 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500">
                      Issued By
                    </th>
                    <th class="px-4 py-3 text-right text-xs font-medium uppercase tracking-wide text-gray-500">
                      Quantity
                    </th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-100 bg-white">
                  <%= for issue <- @issued_history do %>
                    <tr>
                      <td class="px-4 py-3 text-sm text-gray-600">
                        {format_datetime_kenya(issue.inserted_at)}
                      </td>
                      <td class="px-4 py-3 text-sm font-medium text-gray-900">
                        {(issue.batch && issue.batch.batch) || "—"}
                      </td>
                      <td class="px-4 py-3 text-sm text-gray-600">{issue.location || "—"}</td>
                      <td class="px-4 py-3 text-sm text-gray-600">
                        {(issue.assigned_to && issue.assigned_to.name) || "—"}
                      </td>
                      <td class="px-4 py-3 text-sm text-gray-600">
                        {(issue.inventory_manager && issue.inventory_manager.name) || "—"}
                      </td>
                      <td class="px-4 py-3 text-right text-sm font-semibold text-gray-900">
                        {issue.quantity || 0}
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          <% end %>
        </div>
      </div>
    </div>

    <.modal :if={@show_reject_modal} id="reject-modal" show on_cancel={JS.push("close_reject_modal")}>
      <h3 class="text-lg font-semibold text-gray-900">Reject Requisition</h3>
      <p class="mt-1 text-sm text-gray-500">
        Provide a reason so the requester knows why this was rejected.
      </p>

      <form phx-submit="reject" class="mt-4 space-y-3">
        <input type="hidden" name="_id" value={@requisition.id} />
        <textarea
          name="rejection_reason"
          required
          rows="3"
          placeholder="e.g. Insufficient stock available for this quantity"
          class="w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-red-500 focus:ring-red-500"
        ></textarea>
        <p :if={@reject_error} class="text-sm text-red-600">{@reject_error}</p>
        <div class="flex justify-end gap-2">
          <button
            type="button"
            phx-click="close_reject_modal"
            class="px-4 py-2 rounded-md text-sm font-medium text-gray-700 hover:bg-gray-100"
          >
            Cancel
          </button>
          <button
            type="submit"
            class="px-4 py-2 bg-red-600 hover:bg-red-700 text-white rounded-md text-sm font-medium"
          >
            Reject Requisition
          </button>
        </div>
      </form>
    </.modal>
    """
  end

  defp available_batches_for_requisition(%{inventory_received_id: nil}), do: []

  defp available_batches_for_requisition(requisition) do
    Batches.list_batches_with_expiry_for_inventory_received(requisition.inventory_received_id)
  end

  defp available_drug_batches_for_requisition(%{inventory_received_id: nil}), do: []

  defp available_drug_batches_for_requisition(requisition) do
    DrugBatches.list_active_drug_batches_for_inventory_received(requisition.inventory_received_id)
  end

  defp issue_inventory_path(requisition, batch, drug_batch) do
    query =
      %{
        "inventory_received_id" => requisition.inventory_received_id,
        "quantity" => requisition.quantity,
        "requisition_id" => requisition.id
      }
      |> maybe_put_batch(batch)
      |> maybe_put_drug_batch(drug_batch)
      |> URI.encode_query()

    "/inventory_manager/inventories_issued/new?" <> query
  end

  defp maybe_put_batch(map, nil), do: map
  defp maybe_put_batch(map, batch), do: Map.put(map, "batch_id", batch.id)

  defp maybe_put_drug_batch(map, nil), do: map
  defp maybe_put_drug_batch(map, drug_batch), do: Map.put(map, "drug_batch_id", drug_batch.id)

  # Inventory managers and admins can always issue.
  # Staff whose department matches the requisition's to_department can also issue
  # (e.g. a pharmacist issuing from their own department to nursing).
  defp can_issue?(user, requisition) do
    user.role in ["inventory_manager", "admin"] or
      (user.department_id != nil and user.department_id == requisition.to_department_id)
  end

  defp issued_total(issues) do
    Enum.reduce(issues, 0, fn issue, total -> total + (issue.quantity || 0) end)
  end

  defp changeset_error(%Ecto.Changeset{} = changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {msg, _} -> msg end)
    |> Enum.map(fn {field, msgs} ->
      "#{Phoenix.Naming.humanize(field)} #{Enum.join(msgs, ", ")}"
    end)
    |> Enum.join("; ")
  end
end
