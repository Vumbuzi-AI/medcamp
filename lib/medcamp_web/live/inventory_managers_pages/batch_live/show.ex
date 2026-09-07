defmodule MedcampWeb.BatchLive.Show do
  use MedcampWeb, :inventory_manager_live_view

  alias Medcamp.Batches
  alias Medcamp.DrugAllocations

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    batch = Batches.get_batch!(id)
    allocations = DrugAllocations.list_drug_allocations_for_batch(batch.batch)

    {:ok,
     socket
     |> assign(:page_title, "Batch #{batch.batch}")
     |> assign(:active_tab, :all_batches)
     |> assign(:batch, batch)
     |> assign(:allocations, allocations)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <%!-- Navigation / Header --%>
      <div>
        <.link
          navigate={~p"/inventory_manager/batches"}
          class="inline-flex items-center gap-1.5 text-sm text-slate-500 hover:text-slate-800 transition-colors mb-3"
        >
          <Heroicons.icon name="arrow-left" type="outline" class="h-4 w-4" /> Back to All Batches
        </.link>

        <div class="flex flex-wrap items-center justify-between gap-4 bg-white rounded-xl shadow-sm border border-slate-200/80 px-6 py-5">
          <div class="flex items-center gap-4">
            <div class="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-[#F0F0FF] text-[#373896]">
              <Heroicons.icon name="archive-box" type="outline" class="h-6 w-6" />
            </div>
            <div>
              <div class="flex items-center gap-3">
                <h1 class="text-xl font-bold text-slate-900">
                  Batch: {@batch.batch}
                </h1>
                {status_badge(assigns, @batch)}
              </div>
              <p class="mt-0.5 text-sm text-slate-500">
                GTIN: <span class="font-mono text-slate-700">{@batch.gtin || "—"}</span>
              </p>
            </div>
          </div>

          <div class="flex items-center gap-3">
            <.link
              :if={@batch.inventory_received_id}
              navigate={
                ~p"/inventory_manager/inventories_received/#{@batch.inventory_received_id}/batches"
              }
              class="inline-flex items-center gap-1.5 rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-50 transition-colors shadow-2xs"
            >
              <Heroicons.icon name="arrow-top-right-on-square" type="outline" class="h-4 w-4" />
              View Received Source
            </.link>
          </div>
        </div>
      </div>

      <%!-- Core Details Cards --%>
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <%!-- Drug / Product Card --%>
        <div class="bg-white rounded-xl shadow-sm border border-slate-200/80 p-5">
          <div class="flex items-center gap-2 text-xs font-semibold uppercase tracking-wider text-slate-400">
            <Heroicons.icon name="beaker" type="outline" class="h-4 w-4 text-[#6667AB]" />
            Product Info
          </div>
          <div class="mt-3">
            <p class="text-base font-semibold text-slate-900">
              {if @batch.inventory_received, do: @batch.inventory_received.brand_name, else: "—"}
            </p>
            <p class="mt-0.5 text-xs text-slate-500">
              {if @batch.inventory_received && @batch.inventory_received.generic_name,
                do: "(#{@batch.inventory_received.generic_name})",
                else: "Generic name —"}
            </p>
            <p class="mt-2 text-xs font-medium text-slate-600 bg-slate-100 inline-block px-2 py-0.5 rounded">
              Category: {if @batch.inventory_received,
                do: @batch.inventory_received.category || "General",
                else: "—"}
            </p>
          </div>
        </div>

        <%!-- Quantities Card --%>
        <div class="bg-white rounded-xl shadow-sm border border-slate-200/80 p-5">
          <div class="flex items-center gap-2 text-xs font-semibold uppercase tracking-wider text-slate-400">
            <Heroicons.icon name="rectangle-stack" type="outline" class="h-4 w-4 text-emerald-600" />
            Quantity Metrics
          </div>
          <div class="mt-3 grid grid-cols-2 gap-2">
            <div>
              <p class="text-xs text-slate-500">Remaining</p>
              <p class="text-lg font-bold text-slate-900">
                {@batch.remaining_quantity || 0}
                <span class="text-xs font-normal text-slate-500">{@batch.uom || "units"}</span>
              </p>
            </div>
            <div>
              <p class="text-xs text-slate-500">Initial Total</p>
              <p class="text-lg font-bold text-slate-700">
                {@batch.quantity || 0}
                <span class="text-xs font-normal text-slate-500">{@batch.uom || "units"}</span>
              </p>
            </div>
          </div>
        </div>

        <%!-- Financials Card --%>
        <div class="bg-white rounded-xl shadow-sm border border-slate-200/80 p-5">
          <div class="flex items-center gap-2 text-xs font-semibold uppercase tracking-wider text-slate-400">
            <Heroicons.icon name="banknotes" type="outline" class="h-4 w-4 text-blue-600" />
            Pricing & Cost
          </div>
          <div class="mt-3">
            <p class="text-xs text-slate-500">Cost / Unit Price</p>
            <p class="text-lg font-bold text-slate-900">
              {format_money(@batch.cost_per_unit || @batch.price_per_unit)}
              <span class="text-xs font-normal text-slate-500">/ {@batch.uom || "unit"}</span>
            </p>
            <p class="mt-1 text-xs text-slate-500">
              Supplier:
              <span class="font-medium text-slate-700">
                {if @batch.supplier, do: @batch.supplier.name, else: "—"}
              </span>
            </p>
          </div>
        </div>

        <%!-- Expiry & Dates Card --%>
        <div class="bg-white rounded-xl shadow-sm border border-slate-200/80 p-5">
          <div class="flex items-center gap-2 text-xs font-semibold uppercase tracking-wider text-slate-400">
            <Heroicons.icon name="calendar" type="outline" class="h-4 w-4 text-amber-600" />
            Expiry Status
          </div>
          <div class="mt-3">
            <p class="text-xs text-slate-500">Expiration Date</p>
            <p class={"text-lg font-bold #{expiry_text_class(@batch.expiry)}"}>
              {@batch.expiry || "—"}
            </p>
            <p class="mt-1 text-xs text-slate-500">
              Received:
              <span class="font-medium text-slate-700">{format_date(@batch.inserted_at)}</span>
            </p>
          </div>
        </div>
      </div>

      <%!-- Allocations Section --%>
      <div class="bg-white rounded-xl shadow-sm border border-slate-200/80 overflow-hidden">
        <div class="border-b border-slate-200 px-6 py-4 flex items-center justify-between">
          <div>
            <h2 class="text-base font-semibold text-slate-900">
              Drug Allocations Drawn From This Batch
            </h2>
            <p class="text-xs text-slate-500 mt-0.5">
              Historical record of all patient prescriptions and dispenses drawn from Batch <span class="font-mono">{@batch.batch}</span>.
            </p>
          </div>
          <span class="rounded-full bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-700">
            {length(@allocations)} allocation{if length(@allocations) != 1, do: "s", else: ""}
          </span>
        </div>

        <%= if @allocations == [] do %>
          <div class="px-6 py-12 text-center">
            <div class="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-slate-100 text-slate-400 mb-3">
              <Heroicons.icon name="document-text" type="outline" class="h-6 w-6" />
            </div>
            <h3 class="text-sm font-semibold text-slate-900">No drug allocations found</h3>
            <p class="mt-1 text-xs text-slate-500 max-w-sm mx-auto">
              No patient drug allocations have been dispensed from this specific batch yet.
            </p>
          </div>
        <% else %>
          <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-slate-200 text-sm">
              <thead class="bg-slate-50 text-left text-xs font-semibold uppercase tracking-wider text-slate-500">
                <tr>
                  <th class="px-6 py-3">Patient Name</th>
                  <th class="px-6 py-3">Dispensed Date</th>
                  <th class="px-6 py-3">Prescribed Product</th>
                  <th class="px-6 py-3">Pharmacist / Dispenser</th>
                  <th class="px-6 py-3 text-right">Quantity Allocated</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-100 bg-white">
                <%= for allocation <- @allocations do %>
                  <tr class="hover:bg-slate-50/70 transition-colors">
                    <td class="px-6 py-4 font-medium text-slate-900">
                      {patient_display_name(allocation.patient)}
                    </td>
                    <td class="px-6 py-4 text-slate-600">
                      {format_datetime(allocation.inserted_at)}
                    </td>
                    <td class="px-6 py-4 text-slate-700">
                      {drug_name_for_allocation(allocation, @batch.id)}
                    </td>
                    <td class="px-6 py-4 text-slate-600">
                      <div class="flex items-center gap-2">
                        <div class="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-slate-100 text-slate-700 text-xs font-medium">
                          {String.first((allocation.pharmacist && allocation.pharmacist.name) || "?")}
                        </div>
                        <span>
                          {if allocation.pharmacist, do: allocation.pharmacist.name, else: "—"}
                        </span>
                      </div>
                    </td>
                    <td class="px-6 py-4 text-right">
                      <span class="font-bold text-slate-900">
                        {allocated_quantity_for_batch(allocation, @batch.id)}
                      </span>
                      <span class="text-xs text-slate-500">{@batch.uom || "units"}</span>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp status_badge(assigns, batch) do
    cond do
      expired?(batch.expiry) ->
        ~H"""
        <span class="inline-flex items-center rounded-full bg-red-50 px-2.5 py-0.5 text-xs font-medium text-red-700 ring-1 ring-red-600/20 ring-inset">
          Expired
        </span>
        """

      (batch.remaining_quantity || 0) <= 0 ->
        ~H"""
        <span class="inline-flex items-center rounded-full bg-slate-100 px-2.5 py-0.5 text-xs font-medium text-slate-700 ring-1 ring-slate-500/20 ring-inset">
          Depleted
        </span>
        """

      (batch.remaining_quantity || 0) <= 10 ->
        ~H"""
        <span class="inline-flex items-center rounded-full bg-amber-50 px-2.5 py-0.5 text-xs font-medium text-amber-700 ring-1 ring-amber-600/20 ring-inset">
          Low Stock
        </span>
        """

      true ->
        ~H"""
        <span class="inline-flex items-center rounded-full bg-emerald-50 px-2.5 py-0.5 text-xs font-medium text-emerald-700 ring-1 ring-emerald-600/20 ring-inset">
          Active
        </span>
        """
    end
  end

  defp expired?(nil), do: false
  defp expired?(""), do: false

  defp expired?(expiry_str) when is_binary(expiry_str) do
    case Date.from_iso8601(expiry_str) do
      {:ok, date} -> Date.compare(date, Date.utc_today()) == :lt
      _ -> false
    end
  end

  defp expiry_text_class(nil), do: "text-slate-900"
  defp expiry_text_class(""), do: "text-slate-900"

  defp expiry_text_class(expiry_str) when is_binary(expiry_str) do
    case Date.from_iso8601(expiry_str) do
      {:ok, date} ->
        cond do
          Date.compare(date, Date.utc_today()) == :lt -> "text-red-600"
          Date.diff(date, Date.utc_today()) <= 90 -> "text-amber-600"
          true -> "text-slate-900"
        end

      _ ->
        "text-slate-900"
    end
  end

  defp patient_display_name(%Medcamp.Patients.Patient{first_name: fname, last_name: lname}) do
    case Enum.reject([fname, lname], &(&1 in [nil, ""])) do
      [] -> "Walk-in Patient"
      parts -> Enum.join(parts, " ")
    end
  end

  defp patient_display_name(_), do: "Walk-in Patient"

  defp format_money(amount) when is_number(amount),
    do: "KES #{:erlang.float_to_binary(amount * 1.0, decimals: 2)}"

  defp format_money(_), do: "KES 0.00"

  defp format_date(nil), do: "—"
  defp format_date(%NaiveDateTime{} = dt), do: Calendar.strftime(dt, "%b %d, %Y")
  defp format_date(%DateTime{} = dt), do: Calendar.strftime(dt, "%b %d, %Y")
  defp format_date(_), do: "—"

  defp format_datetime(nil), do: "—"
  defp format_datetime(%NaiveDateTime{} = dt), do: Calendar.strftime(dt, "%b %d, %Y %H:%M")
  defp format_datetime(%DateTime{} = dt), do: Calendar.strftime(dt, "%b %d, %Y %H:%M")
  defp format_datetime(_), do: "—"

  defp drugs_given_for_batch(allocation, batch_id) do
    (allocation.drugs_given || [])
    |> Enum.filter(fn dg ->
      (dg.batch_allocations || [])
      |> Enum.any?(fn ba ->
        bid = Map.get(ba, "batch_id") || Map.get(ba, :batch_id)
        to_string(bid) == to_string(batch_id)
      end)
    end)
    |> case do
      [] -> allocation.drugs_given || []
      matched -> matched
    end
  end

  defp drug_name_for_allocation(allocation, batch_id) do
    case drugs_given_for_batch(allocation, batch_id) do
      [first | _] ->
        if first.drug, do: first.drug.brand_name || first.drug.generic_name, else: "—"

      _ ->
        "—"
    end
  end

  defp allocated_quantity_for_batch(allocation, batch_id) do
    drugs_given_for_batch(allocation, batch_id)
    |> Enum.reduce(0, fn dg, acc ->
      batch_qty =
        (dg.batch_allocations || [])
        |> Enum.filter(fn ba ->
          bid = Map.get(ba, "batch_id") || Map.get(ba, :batch_id)
          to_string(bid) == to_string(batch_id)
        end)
        |> Enum.reduce(0, fn ba, sum ->
          q = Map.get(ba, "quantity") || Map.get(ba, :quantity) || 0
          sum + if is_integer(q), do: q, else: String.to_integer(to_string(q))
        end)

      acc + if(batch_qty > 0, do: batch_qty, else: dg.quantity || 0)
    end)
  end
end
