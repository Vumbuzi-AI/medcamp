defmodule MedcampWeb.InStoreLive.Show do
  use MedcampWeb, :inventory_manager_live_view

  alias Medcamp.Batches
  alias Medcamp.InventoriesReceived

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    ir = InventoriesReceived.get_inventory_received!(id)
    batches = Batches.get_batches_for_in_store(id)
    total_remaining = Enum.sum(Enum.map(batches, &(&1.remaining_quantity || 0)))

    {:ok,
     socket
     |> assign(:active_tab, :in_store)
     |> assign(:ir, ir)
     |> assign(:batches, batches)
     |> assign(:total_remaining, total_remaining)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <%!-- Back --%>
      <div>
        <.link
          navigate="/inventory_manager/in_store"
          class="inline-flex items-center gap-1.5 text-sm text-gray-500 hover:text-gray-700"
        >
          <Heroicons.icon name="arrow-left" type="outline" class="h-4 w-4" /> Back to In Store
        </.link>
      </div>

      <%!-- Item info card --%>
      <div class="bg-white rounded-xl shadow-sm border border-slate-200/80 px-6 py-5">
        <div class="flex items-start gap-5">
          <div class="flex h-14 w-14 shrink-0 items-center justify-center rounded-xl bg-emerald-100">
            <Heroicons.icon name="archive-box" type="outline" class="h-7 w-7 text-emerald-600" />
          </div>
          <div class="flex-1 min-w-0">
            <h1 class="text-xl font-semibold text-slate-900">{@ir.brand_name}</h1>
            <div class="mt-1 flex flex-wrap items-center gap-x-4 gap-y-1 text-sm text-slate-500">
              <%= if @ir.generic_name do %>
                <span class="italic">{@ir.generic_name}</span>
              <% end %>
              <%= if @ir.strength do %>
                <span>{@ir.strength}</span>
              <% end %>
              <%= if @ir.gtin do %>
                <span class="font-mono text-xs">GTIN: {@ir.gtin}</span>
              <% end %>
              <%= if @ir.uom do %>
                <span>UOM: {@ir.uom}</span>
              <% end %>
              <%= if @ir.category do %>
                <span class="inline-flex items-center rounded-full bg-slate-100 px-2.5 py-0.5 text-xs font-medium text-slate-700">
                  {@ir.category}
                </span>
              <% end %>
            </div>
          </div>

          <%!-- Summary stats --%>
          <div class="flex shrink-0 gap-6 text-center">
            <div>
              <p class={"text-3xl font-bold tabular-nums #{if @total_remaining <= 0, do: "text-red-600", else: if(@total_remaining < 10, do: "text-amber-600", else: "text-emerald-700")}"}>
                {@total_remaining}
              </p>
              <p class="text-xs text-slate-500 mt-0.5">Total Remaining</p>
            </div>
            <div>
              <p class="text-3xl font-bold text-slate-900">{length(@batches)}</p>
              <p class="text-xs text-slate-500 mt-0.5">Batches</p>
            </div>
          </div>
        </div>
      </div>

      <%!-- Batches table --%>
      <div class="bg-white rounded-xl shadow-sm border border-slate-200/80 overflow-hidden">
        <div class="px-6 py-4 border-b border-slate-200 flex items-center justify-between">
          <h2 class="text-sm font-semibold text-slate-800">Batch Details</h2>
          <span class="text-xs text-slate-500">
            {length(@batches)} batch{if length(@batches) != 1, do: "es", else: ""}
          </span>
        </div>

        <%= if Enum.empty?(@batches) do %>
          <div class="flex flex-col items-center justify-center py-16 text-center">
            <Heroicons.icon name="archive-box-x-mark" type="outline" class="h-10 w-10 text-gray-300" />
            <p class="mt-3 text-sm text-gray-500">No batches found for this item.</p>
          </div>
        <% else %>
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-500">
                  Batch No.
                </th>
                <th class="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-500">
                  GTIN
                </th>
                <th class="px-6 py-3 text-center text-xs font-semibold uppercase tracking-wider text-gray-500">
                  Qty Received
                </th>
                <th class="px-6 py-3 text-center text-xs font-semibold uppercase tracking-wider text-gray-500">
                  Remaining
                </th>
                <th class="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-500">
                  Expiry
                </th>
                <th class="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-500">
                  Received On
                </th>
                <th class="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-500">
                  Status
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100 bg-white">
              <%= for batch <- @batches do %>
                <% remaining = batch.remaining_quantity || 0 %>
                <% total = batch.quantity || 0 %>
                <% used_pct = if total > 0, do: round((total - remaining) / total * 100), else: 0 %>
                <% expired =
                  case safe_parse_date(batch.expiry) do
                    {:ok, d} -> Date.compare(d, Date.utc_today()) == :lt
                    _ -> false
                  end %>
                <tr class={[
                  "hover:bg-gray-50",
                  expired && "bg-red-50/40"
                ]}>
                  <td class="px-6 py-4">
                    <span class="font-mono text-sm font-semibold text-gray-900">
                      {batch.batch || batch.serial || "—"}
                    </span>
                  </td>
                  <td class="px-6 py-4">
                    <span class="font-mono text-xs text-gray-500">{batch.gtin || "—"}</span>
                  </td>
                  <td class="px-6 py-4 text-center">
                    <span class="font-semibold text-gray-700 tabular-nums">{total}</span>
                  </td>
                  <td class="px-6 py-4 text-center">
                    <div class="flex flex-col items-center gap-1">
                      <span class={"text-base font-bold tabular-nums #{cond do remaining <= 0 -> "text-red-600"; remaining < total * 0.2 -> "text-amber-600"; true -> "text-emerald-700" end}"}>
                        {remaining}
                      </span>
                      <%!-- Progress bar --%>
                      <div class="w-20 h-1.5 rounded-full bg-gray-200 overflow-hidden">
                        <div
                          class={"h-full rounded-full #{cond do remaining <= 0 -> "bg-red-500"; remaining < total * 0.2 -> "bg-amber-400"; true -> "bg-emerald-500" end}"}
                          style={"width: #{100 - used_pct}%"}
                        />
                      </div>
                    </div>
                  </td>
                  <td class="px-6 py-4">
                    <%= case safe_parse_date(batch.expiry) do %>
                      <% {:ok, exp_date} -> %>
                        <div>
                          <span class={[
                            "text-sm",
                            if(expired, do: "text-red-600 font-semibold", else: "text-gray-700")
                          ]}>
                            {Calendar.strftime(exp_date, "%d %b %Y")}
                          </span>
                          <%= if expired do %>
                            <span class="ml-1 inline-flex items-center rounded-full bg-red-100 px-2 py-0.5 text-xs font-medium text-red-700">
                              Expired
                            </span>
                          <% end %>
                        </div>
                      <% _ -> %>
                        <span class="text-gray-400 text-sm">{batch.expiry || "—"}</span>
                    <% end %>
                  </td>
                  <td class="px-6 py-4 text-sm text-gray-500">
                    {Calendar.strftime(batch.received_date || batch.inserted_at, "%d %b %Y")}
                  </td>
                  <td class="px-6 py-4">
                    <%= cond do %>
                      <% expired -> %>
                        <span class="inline-flex items-center rounded-full bg-red-100 px-2.5 py-0.5 text-xs font-semibold text-red-700">
                          Expired
                        </span>
                      <% remaining <= 0 -> %>
                        <span class="inline-flex items-center rounded-full bg-gray-100 px-2.5 py-0.5 text-xs font-semibold text-gray-600">
                          Depleted
                        </span>
                      <% remaining < total * 0.2 -> %>
                        <span class="inline-flex items-center rounded-full bg-amber-100 px-2.5 py-0.5 text-xs font-semibold text-amber-700">
                          Low
                        </span>
                      <% true -> %>
                        <span class="inline-flex items-center rounded-full bg-emerald-100 px-2.5 py-0.5 text-xs font-semibold text-emerald-700">
                          Available
                        </span>
                    <% end %>
                  </td>
                </tr>
              <% end %>
            </tbody>
            <tfoot class="bg-gray-50 border-t border-gray-200">
              <tr>
                <td colspan="3" class="px-6 py-3 text-right text-sm font-semibold text-gray-700">
                  Total Remaining
                </td>
                <td class="px-6 py-3 text-center">
                  <span class={"text-base font-bold tabular-nums #{if @total_remaining <= 0, do: "text-red-600", else: "text-emerald-700"}"}>
                    {@total_remaining}
                  </span>
                </td>
                <td colspan="3" />
              </tr>
            </tfoot>
          </table>
        <% end %>
      </div>
    </div>
    """
  end

  defp safe_parse_date(nil), do: :error
  defp safe_parse_date(""), do: :error
  defp safe_parse_date(%Date{} = d), do: {:ok, d}
  defp safe_parse_date(str) when is_binary(str), do: Date.from_iso8601(str)
end
