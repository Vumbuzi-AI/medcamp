defmodule MedcampWeb.SupplierDashboardLive do
  @moduledoc """
  Dashboard for supplier users. Shows total supplied, used, and remaining quantities
  for the supplier linked to the current user.
  """
  use MedcampWeb, :supplier_live_view

  alias Medcamp.Suppliers

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    if is_nil(user.supplier_id) do
      {:ok,
       socket
       |> put_flash(
         :error,
         "Your account is not linked to a supplier. Please contact the administrator."
       )
       |> push_navigate(to: ~p"/users/log_out")}
    else
      supplier = Suppliers.get_supplier!(user.supplier_id)
      total_supplied = Suppliers.total_supplied_quantity_for_supplier(supplier.id)
      total_remaining = Suppliers.total_remaining_quantity_for_supplier(supplier.id)
      total_used = Suppliers.total_used_quantity_for_supplier(supplier.id)
      batches = Suppliers.list_batches_for_supplier(supplier.id)

      {:ok,
       socket
       |> assign(:page_title, "Supplier Dashboard")
       |> assign(:active_tab, :overview)
       |> assign(:supplier, supplier)
       |> assign(:total_supplied, total_supplied)
       |> assign(:total_remaining, total_remaining)
       |> assign(:total_used, total_used)
       |> assign(:batches, batches)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <.header class="text-[#373896] border-b border-gray-100 pb-4">
        <div class="flex items-center gap-2">
          <Heroicons.icon name="chart-bar" type="outline" class="h-6 w-6 text-[#6667ab]" />
          {@supplier.name}
        </div>
        <:subtitle>
          Your supply overview — quantities supplied, consumed, and remaining in stock.
        </:subtitle>
      </.header>

      <%!-- Stat cards --%>
      <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div class="bg-blue-50 rounded-xl border border-blue-100 p-6">
          <div class="flex items-center gap-3 mb-3">
            <div class="h-9 w-9 rounded-lg bg-blue-100 flex items-center justify-center">
              <Heroicons.icon name="arrow-down-tray" type="outline" class="h-5 w-5 text-blue-700" />
            </div>
            <h3 class="text-sm font-semibold text-blue-800 uppercase tracking-wide">
              Total Supplied
            </h3>
          </div>
          <p class="text-3xl font-bold text-blue-900">{@total_supplied}</p>
          <p class="text-sm text-blue-600 mt-1">units received from you across all batches</p>
        </div>

        <div class="bg-amber-50 rounded-xl border border-amber-100 p-6">
          <div class="flex items-center gap-3 mb-3">
            <div class="h-9 w-9 rounded-lg bg-amber-100 flex items-center justify-center">
              <Heroicons.icon name="fire" type="outline" class="h-5 w-5 text-amber-700" />
            </div>
            <h3 class="text-sm font-semibold text-amber-800 uppercase tracking-wide">
              Used / Consumed
            </h3>
          </div>
          <p class="text-3xl font-bold text-amber-900">{@total_used}</p>
          <p class="text-sm text-amber-600 mt-1">units issued or consumed from your batches</p>
        </div>

        <div class="bg-emerald-50 rounded-xl border border-emerald-100 p-6">
          <div class="flex items-center gap-3 mb-3">
            <div class="h-9 w-9 rounded-lg bg-emerald-100 flex items-center justify-center">
              <Heroicons.icon name="archive-box" type="outline" class="h-5 w-5 text-emerald-700" />
            </div>
            <h3 class="text-sm font-semibold text-emerald-800 uppercase tracking-wide">Remaining</h3>
          </div>
          <p class="text-3xl font-bold text-emerald-900">{@total_remaining}</p>
          <p class="text-sm text-emerald-600 mt-1">units still in stock from your batches</p>
        </div>
      </div>

      <%!-- Quick links --%>
      <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-3">
        <%= for {label, icon, path} <- [
          {"Documents", "folder-open", ~p"/supplier/documents"},
          {"Invoices", "banknotes", ~p"/supplier/invoices"},
          {"Quotes", "clipboard-document-list", ~p"/supplier/quotes"},
          {"Delivery Notes", "truck", ~p"/supplier/delivery_notes"},
          {"Ship Notices", "paper-airplane", ~p"/supplier/advance_ship_notices"},
          {"Recalls", "exclamation-triangle", ~p"/supplier/recalls"}
        ] do %>
          <.link
            navigate={path}
            class="flex flex-col items-center justify-center gap-2 p-4 bg-white border border-gray-200 rounded-xl shadow-sm hover:border-[#6667ab] hover:bg-[#f0f0ff] transition-colors group"
          >
            <div class="h-9 w-9 rounded-lg bg-[#e7e7ff] flex items-center justify-center group-hover:bg-[#d2d3ff]">
              <Heroicons.icon name={icon} type="outline" class="h-5 w-5 text-[#373896]" />
            </div>
            <span class="text-xs font-medium text-gray-700 group-hover:text-[#373896] text-center">
              {label}
            </span>
          </.link>
        <% end %>
      </div>

      <%!-- Supplier details --%>
      <div class="bg-white border border-gray-200 rounded-xl p-6 shadow-sm">
        <h3 class="text-base font-semibold text-[#373896] mb-4">Supplier Details</h3>
        <dl class="grid grid-cols-1 md:grid-cols-2 gap-x-8 gap-y-3 text-sm">
          <div class="flex gap-2">
            <Heroicons.icon
              name="envelope"
              type="outline"
              class="h-4 w-4 text-gray-400 mt-0.5 flex-shrink-0"
            />
            <div>
              <dt class="font-medium text-gray-500">Email</dt>
              <dd class="text-gray-900">{@supplier.email}</dd>
            </div>
          </div>
          <div class="flex gap-2">
            <Heroicons.icon
              name="phone"
              type="outline"
              class="h-4 w-4 text-gray-400 mt-0.5 flex-shrink-0"
            />
            <div>
              <dt class="font-medium text-gray-500">Contact</dt>
              <dd class="text-gray-900">{@supplier.contact}</dd>
            </div>
          </div>
          <div :if={@supplier.location} class="flex gap-2">
            <Heroicons.icon
              name="map-pin"
              type="outline"
              class="h-4 w-4 text-gray-400 mt-0.5 flex-shrink-0"
            />
            <div>
              <dt class="font-medium text-gray-500">Location</dt>
              <dd class="text-gray-900">{@supplier.location}</dd>
            </div>
          </div>
          <div :if={@supplier.gln} class="flex gap-2">
            <Heroicons.icon
              name="qr-code"
              type="outline"
              class="h-4 w-4 text-gray-400 mt-0.5 flex-shrink-0"
            />
            <div>
              <dt class="font-medium text-gray-500">GLN</dt>
              <dd class="text-gray-900 font-mono">{@supplier.gln}</dd>
            </div>
          </div>
        </dl>
      </div>

      <%!-- Batches table --%>
      <div class="bg-white border border-gray-200 rounded-xl shadow-sm overflow-hidden">
        <div class="px-6 py-4 border-b border-gray-100 flex items-center justify-between">
          <h3 class="text-base font-semibold text-[#373896]">Batches from Your Supplies</h3>
          <span class="text-sm text-gray-500">{length(@batches)} batch(es)</span>
        </div>

        <%= if Enum.empty?(@batches) do %>
          <div class="flex flex-col items-center justify-center py-16 text-center">
            <Heroicons.icon name="archive-box" type="outline" class="h-12 w-12 text-gray-300 mb-3" />
            <p class="text-gray-500 font-medium">No batches linked yet</p>
            <p class="text-gray-400 text-sm mt-1">
              Batches will appear here once the facility records a delivery from you.
            </p>
          </div>
        <% else %>
          <div class="overflow-x-auto">
            <table class="w-full min-w-[700px]">
              <thead class="border-b border-slate-200 bg-slate-50/80">
                <tr>
                  <th class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500">
                    Item
                  </th>
                  <th class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500">
                    Batch #
                  </th>
                  <th class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-500">
                    Expiry
                  </th>
                  <th class="px-6 py-4 text-right text-xs font-semibold uppercase tracking-wider text-slate-500">
                    Quantity
                  </th>
                  <th class="px-6 py-4 text-right text-xs font-semibold uppercase tracking-wider text-slate-500">
                    Remaining
                  </th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-100 bg-white">
                <tr :for={batch <- @batches} class="group transition-colors hover:bg-slate-50/50">
                  <td class="px-6 py-3 text-sm text-gray-900">
                    {(batch.inventory_received && batch.inventory_received.brand_name) || "—"}
                  </td>
                  <td class="px-6 py-3 text-sm font-mono text-gray-700">{batch.batch}</td>
                  <td class="px-6 py-3 text-sm text-gray-600">{batch.expiry || "—"}</td>
                  <td class="px-6 py-3 text-sm text-gray-900 text-right">{batch.quantity || 0}</td>
                  <td class="px-6 py-3 text-sm font-semibold text-right">
                    <span class={
                      if (batch.remaining_quantity || 0) <= 20,
                        do: "text-rose-600",
                        else: "text-gray-900"
                    }>
                      {batch.remaining_quantity || 0}
                    </span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
