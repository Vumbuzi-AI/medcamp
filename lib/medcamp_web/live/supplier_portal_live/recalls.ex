defmodule MedcampWeb.SupplierPortalLive.Recalls do
  @moduledoc """
  Supplier portal: initiate and manage product recalls.
  """
  use MedcampWeb, :supplier_live_view

  alias Medcamp.Suppliers
  alias Medcamp.Suppliers.SupplierRecall

  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    if is_nil(user.supplier_id) do
      {:ok,
       socket
       |> put_flash(:error, "Your account is not linked to a supplier.")
       |> push_navigate(to: ~p"/users/log_out")}
    else
      supplier = Suppliers.get_supplier!(user.supplier_id)

      {:ok,
       socket
       |> assign(:page_title, "Recalls")
       |> assign(:active_tab, :recalls)
       |> assign(:supplier, supplier)
       |> assign(:page, 1)
       |> assign(:per_page, @per_page)
       |> load_recalls()
       |> assign(:form, nil)
       |> assign(:editing, nil)}
    end
  end

  defp load_recalls(socket) do
    all = Suppliers.list_supplier_recalls(socket.assigns.supplier.id)
    total_count = length(all)
    total_pages = Medcamp.Pagination.total_pages(total_count, socket.assigns.per_page)
    page = min(max(1, socket.assigns.page || 1), total_pages)
    recalls = Enum.slice(all, (page - 1) * socket.assigns.per_page, socket.assigns.per_page)

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:all_recalls, all)
    |> assign(:recalls, recalls)
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:form, to_form(Suppliers.change_supplier_recall(%SupplierRecall{})))
    |> assign(:editing, nil)
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    recall = Suppliers.get_supplier_recall!(id)

    socket
    |> assign(:form, to_form(Suppliers.change_supplier_recall(recall)))
    |> assign(:editing, recall)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:form, nil)
    |> assign(:editing, nil)
  end

  @impl true
  def handle_event("validate", %{"supplier_recall" => params}, socket) do
    changeset =
      case socket.assigns.editing do
        nil -> Suppliers.change_supplier_recall(%SupplierRecall{}, params)
        r -> Suppliers.change_supplier_recall(r, params)
      end

    {:noreply, assign(socket, :form, to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"supplier_recall" => params}, socket) do
    supplier_id = socket.assigns.supplier.id
    full_params = Map.put(params, "supplier_id", supplier_id)

    result =
      case socket.assigns.editing do
        nil -> Suppliers.create_supplier_recall(full_params)
        r -> Suppliers.update_supplier_recall(r, full_params)
      end

    case result do
      {:ok, _} ->
        action = if socket.assigns.editing, do: "updated", else: "initiated"

        {:noreply,
         socket
         |> put_flash(:info, "Recall #{action} successfully.")
         |> load_recalls()
         |> assign(:form, nil)
         |> assign(:editing, nil)
         |> push_patch(to: ~p"/supplier/recalls")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    Suppliers.delete_supplier_recall(Suppliers.get_supplier_recall!(id))

    {:noreply,
     socket
     |> put_flash(:info, "Recall deleted.")
     |> load_recalls()}
  end

  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, max(1, String.to_integer(page)))
     |> load_recalls()}
  end

  def handle_event("close-form", _params, socket) do
    {:noreply,
     socket
     |> assign(:form, nil)
     |> assign(:editing, nil)
     |> push_patch(to: ~p"/supplier/recalls")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <.header class="text-[#373896] border-b border-gray-100 pb-4">
        <div class="flex items-center gap-2">
          <Heroicons.icon name="exclamation-triangle" type="outline" class="h-6 w-6 text-rose-500" />
          Product Recalls
        </div>
        <:subtitle>
          Initiate a product recall to notify the facility of affected items that must be withdrawn from use.
        </:subtitle>
        <:actions>
          <.link patch={~p"/supplier/recalls/new"}>
            <.button class="bg-rose-600 hover:bg-rose-700">
              <Heroicons.icon name="plus" type="outline" class="h-4 w-4 mr-1" /> Initiate Recall
            </.button>
          </.link>
        </:actions>
      </.header>

      <%!-- Critical recall banner if any active recalls --%>
      <%= if Enum.any?(@all_recalls, &(&1.status in ["initiated", "in_progress"] and &1.severity in ["high", "critical"])) do %>
        <div class="bg-rose-50 border border-rose-200 rounded-xl p-4 flex items-start gap-3">
          <Heroicons.icon
            name="exclamation-triangle"
            type="solid"
            class="h-5 w-5 text-rose-500 mt-0.5 flex-shrink-0"
          />
          <div>
            <p class="text-sm font-semibold text-rose-800">
              Active high-severity recall(s) in progress
            </p>
            <p class="text-sm text-rose-600 mt-0.5">
              You have ongoing recalls that require immediate attention. Please ensure the facility has been contacted directly.
            </p>
          </div>
        </div>
      <% end %>

      <%= if @form do %>
        <.modal id="recall-modal" show on_cancel={JS.push("close-form")}>
          <h2 class="flex items-center gap-2 text-lg font-semibold text-rose-700 mb-6">
            <Heroicons.icon name="exclamation-triangle" type="outline" class="h-5 w-5" />
            {if @editing, do: "Edit Recall", else: "Initiate Product Recall"}
          </h2>
          <.simple_form for={@form} phx-submit="save" phx-change="validate">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <.input
                field={@form[:recall_number]}
                label="Recall Reference Number"
                placeholder="RCL-001"
              />
              <.input field={@form[:recall_date]} label="Recall Date" type="date" />
              <.input
                field={@form[:severity]}
                label="Severity"
                type="select"
                options={
                  Enum.map(SupplierRecall.severities(), &{SupplierRecall.severity_label(&1), &1})
                }
              />
              <.input
                field={@form[:status]}
                label="Status"
                type="select"
                options={Enum.map(SupplierRecall.statuses(), &{SupplierRecall.status_label(&1), &1})}
              />
            </div>
            <.input
              field={@form[:reason]}
              label="Reason for Recall"
              placeholder="e.g. Contamination, mislabelling, failed quality test"
            />
            <.input
              field={@form[:affected_products]}
              label="Affected Products / Batch Numbers"
              type="textarea"
              rows="3"
              placeholder="List all affected product names and batch numbers..."
            />
            <.input
              field={@form[:description]}
              label="Full Description"
              type="textarea"
              rows="4"
              placeholder="Detailed description of the issue, potential risks, and recommended actions..."
            />
            <.input
              field={@form[:notes]}
              label="Additional Notes"
              type="textarea"
              rows="2"
              placeholder="Contact person, disposal instructions, etc."
            />
            <:actions>
              <.button type="submit" class="bg-rose-600 hover:bg-rose-700">
                {if @editing, do: "Update Recall", else: "Submit Recall Notice"}
              </.button>
              <button
                type="button"
                phx-click="close-form"
                class="px-4 py-2 text-sm text-gray-600 hover:text-gray-800"
              >
                Cancel
              </button>
            </:actions>
          </.simple_form>
        </.modal>
      <% end %>

      <div class="bg-white border border-gray-200 rounded-xl shadow-sm overflow-hidden">
        <div class="px-6 py-4 border-b border-gray-100 flex items-center justify-between">
          <h3 class="text-base font-semibold text-[#373896]">All Recalls</h3>
          <span class="text-sm text-gray-500">{@total_count} recall(s)</span>
        </div>

        <%= if Enum.empty?(@recalls) do %>
          <div class="flex flex-col items-center justify-center py-16 text-center">
            <Heroicons.icon
              name="shield-check"
              type="outline"
              class="h-12 w-12 text-emerald-300 mb-3"
            />
            <p class="text-gray-500 font-medium">No recalls on record</p>
            <p class="text-gray-400 text-sm mt-1">
              Use the "Initiate Recall" button if you need to recall a product.
            </p>
          </div>
        <% else %>
          <div class="overflow-x-auto">
            <table class="w-full min-w-[1000px]">
              <thead class="border-b border-slate-200 bg-slate-50/80">
                <tr>
                  <th class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500">
                    Recall #
                  </th>
                  <th class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500">
                    Date
                  </th>
                  <th class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500">
                    Reason
                  </th>
                  <th class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500">
                    Affected Products
                  </th>
                  <th class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500">
                    Severity
                  </th>
                  <th class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500">
                    Status
                  </th>
                  <th class="px-6 py-4 text-right text-xs font-semibold uppercase tracking-wider text-slate-500">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-100 bg-white">
                <tr
                  :for={r <- @recalls}
                  class={[
                    "group transition-colors",
                    if(
                      r.severity in ["high", "critical"] and r.status in ["initiated", "in_progress"],
                      do: "bg-rose-50/30",
                      else: "hover:bg-slate-50/50"
                    )
                  ]}
                >
                  <td class="px-6 py-3 text-sm font-medium text-gray-900">{r.recall_number}</td>
                  <td class="px-6 py-3 text-sm text-gray-600">{r.recall_date || "—"}</td>
                  <td class="px-6 py-3 text-sm text-gray-700 max-w-[180px] truncate">{r.reason}</td>
                  <td class="px-6 py-3 text-sm text-gray-600 max-w-[200px] truncate">
                    {r.affected_products}
                  </td>
                  <td class="px-6 py-3 text-sm">
                    <span class={"inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium #{SupplierRecall.severity_color(r.severity)}"}>
                      {SupplierRecall.severity_label(r.severity)}
                    </span>
                  </td>
                  <td class="px-6 py-3 text-sm">
                    <span class={"inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium #{SupplierRecall.status_color(r.status)}"}>
                      {SupplierRecall.status_label(r.status)}
                    </span>
                  </td>
                  <td class="px-6 py-3 text-sm text-right">
                    <div class="flex items-center justify-end gap-3">
                      <.link
                        patch={~p"/supplier/recalls/#{r.id}/edit"}
                        class="text-[#6667ab] hover:text-[#373896] font-medium"
                      >
                        Edit
                      </.link>
                      <button
                        phx-click="delete"
                        phx-value-id={r.id}
                        data-confirm="Delete this recall record?"
                        class="text-rose-500 hover:text-rose-700 font-medium"
                      >
                        Delete
                      </button>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
            <.pagination
              page={@page}
              total_pages={@total_pages}
              total_count={@total_count}
              per_page={@per_page}
              class="px-6 pb-4"
            />
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
