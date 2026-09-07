defmodule MedcampWeb.RequisitionLive.RfqModalComponent do
  use MedcampWeb, :live_component

  import MedcampWeb.ProcurementComponents, only: [supplier_chip: 1]

  alias Phoenix.LiveView.JS

  alias Medcamp.Procurement.Rfqs
  alias Medcamp.Requisitions
  alias MedcampWeb.Procurement.LiveHelpers

  @rfq_fields ~w(
    title
    department
    priority
    issue_date
    quote_deadline
    delivery_by
    currency
    delivery_terms
    payment_terms
    special_instructions
  )

  @impl true
  def update(%{requisition_ids: requisition_ids} = assigns, socket) do
    socket = assign(socket, assigns)

    if socket.assigns[:loaded_for_ids] != requisition_ids do
      requisitions = Requisitions.list_requisitions_by_ids(requisition_ids)
      {rfq_form, rfq_items} = default_rfq_state(requisitions)

      {:ok,
       socket
       |> assign(:loaded_for_ids, requisition_ids)
       |> assign(:requisitions, requisitions)
       |> assign(:rfq, nil)
       |> assign(:rfq_form, rfq_form)
       |> assign(:rfq_items, rfq_items)
       |> assign(:rfq_general_errors, [])
       |> assign(:selected_suppliers, [])
       |> assign(:supplier_search, "")
       |> assign(:supplier_results, LiveHelpers.search_suppliers(nil, status: "approved"))}
    else
      {:ok, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
        <div class="space-y-1">
          <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
            Request for quotation
          </p>
          <h2 class="text-xl font-semibold text-slate-900">Create and send</h2>
          <p class="text-sm text-slate-600">
            {length(@requisitions)} requisition(s) • {length(@rfq_items)} line item(s) • {length(
              @selected_suppliers
            )} supplier(s)
          </p>
        </div>
      </div>

      <div
        :if={@rfq_general_errors != []}
        class="rounded-2xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-800"
      >
        <p class="font-semibold">Please fix the following:</p>
        <ul class="mt-2 list-disc space-y-1 pl-5">
          <li :for={msg <- @rfq_general_errors}>{msg}</li>
        </ul>
      </div>

      <.simple_form
        for={to_form(%{}, as: "rfq")}
        id="admin-rfq-form"
        phx-change="change"
        phx-submit="send"
        phx-target={@myself}
        class="space-y-6"
      >
        <div class="grid gap-6 lg:grid-cols-2">
          <div class="rounded-[2rem] border border-slate-200 bg-white p-5 shadow-sm">
            <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">Details</p>
            <div class="mt-4 grid gap-4 sm:grid-cols-2">
              <label class="block text-sm font-medium text-slate-700 sm:col-span-2">
                Title
                <input
                  name="rfq[title]"
                  value={@rfq_form["title"]}
                  class="mt-1 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm focus:border-[#373896] focus:ring-[#373896]"
                />
              </label>

              <label class="block text-sm font-medium text-slate-700">
                Priority
                <select
                  name="rfq[priority]"
                  class="mt-1 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm focus:border-[#373896] focus:ring-[#373896]"
                >
                  <%= for p <- Medcamp.Procurement.Rfq.priorities() do %>
                    <option value={p} selected={@rfq_form["priority"] == p}>
                      {String.capitalize(p)}
                    </option>
                  <% end %>
                </select>
              </label>

              <label class="block text-sm font-medium text-slate-700">
                Currency
                <input
                  name="rfq[currency]"
                  value={@rfq_form["currency"]}
                  class="mt-1 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm focus:border-[#373896] focus:ring-[#373896]"
                />
              </label>

              <label class="block text-sm font-medium text-slate-700 sm:col-span-2">
                Department
                <input
                  name="rfq[department]"
                  value={@rfq_form["department"]}
                  class="mt-1 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm focus:border-[#373896] focus:ring-[#373896]"
                />
              </label>

              <label class="block text-sm font-medium text-slate-700">
                Issue date
                <input
                  type="date"
                  name="rfq[issue_date]"
                  value={@rfq_form["issue_date"]}
                  class="mt-1 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm focus:border-[#373896] focus:ring-[#373896]"
                />
              </label>

              <label class="block text-sm font-medium text-slate-700">
                Quote deadline
                <input
                  type="date"
                  name="rfq[quote_deadline]"
                  value={@rfq_form["quote_deadline"]}
                  class="mt-1 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm focus:border-[#373896] focus:ring-[#373896]"
                />
              </label>

              <label class="block text-sm font-medium text-slate-700 sm:col-span-2">
                Delivery by
                <input
                  type="date"
                  name="rfq[delivery_by]"
                  value={@rfq_form["delivery_by"]}
                  class="mt-1 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm focus:border-[#373896] focus:ring-[#373896]"
                />
              </label>

              <label class="block text-sm font-medium text-slate-700 sm:col-span-2">
                Delivery terms
                <input
                  name="rfq[delivery_terms]"
                  value={@rfq_form["delivery_terms"]}
                  class="mt-1 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm focus:border-[#373896] focus:ring-[#373896]"
                />
              </label>

              <label class="block text-sm font-medium text-slate-700 sm:col-span-2">
                Payment terms
                <input
                  name="rfq[payment_terms]"
                  value={@rfq_form["payment_terms"]}
                  class="mt-1 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm focus:border-[#373896] focus:ring-[#373896]"
                />
              </label>

              <label class="block text-sm font-medium text-slate-700 sm:col-span-2">
                Special instructions <textarea
                  name="rfq[special_instructions]"
                  class="mt-1 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm focus:border-[#373896] focus:ring-[#373896]"
                  rows="3"
                ><%= @rfq_form["special_instructions"] %></textarea>
              </label>
            </div>
          </div>

          <div class="rounded-[2rem] border border-slate-200 bg-white p-5 shadow-sm">
            <div class="flex items-start justify-between gap-3">
              <div>
                <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
                  Suppliers
                </p>
                <h3 class="mt-1 text-lg font-semibold text-slate-900">Select suppliers</h3>
                <p class="mt-1 text-sm text-slate-600">
                  Search approved suppliers and add them to the RFQ.
                </p>
              </div>
            </div>

            <div class="mt-4 space-y-3">
              <label class="block text-sm font-medium text-slate-700">
                Search
                <input
                  name="supplier_search[query]"
                  value={@supplier_search}
                  phx-change="supplier_search"
                  phx-target={@myself}
                  phx-debounce="250"
                  class="mt-1 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm focus:border-[#373896] focus:ring-[#373896]"
                  placeholder="Type supplier name…"
                />
              </label>

              <div :if={@selected_suppliers != []} class="flex flex-wrap gap-2">
                <.supplier_chip
                  :for={supplier <- @selected_suppliers}
                  supplier={supplier}
                  on_remove={JS.push("remove_supplier", target: @myself)}
                />
              </div>

              <div class="rounded-2xl border border-slate-100 bg-slate-50 px-4 py-3">
                <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
                  Search results
                </p>
                <div class="mt-3 space-y-2">
                  <button
                    :for={supplier <- @supplier_results}
                    type="button"
                    phx-click="add_supplier"
                    phx-value-id={supplier.id}
                    phx-target={@myself}
                    class="flex w-full items-center justify-between gap-3 rounded-xl border border-slate-100 bg-white px-3 py-2 text-left text-sm transition hover:bg-slate-50"
                  >
                    <span class="font-medium text-slate-800">
                      {supplier.legal_name || supplier.name}
                    </span>
                    <span class="text-xs font-semibold text-[#373896]">Add</span>
                  </button>

                  <div :if={Enum.empty?(@supplier_results)} class="text-sm text-slate-500">
                    No suppliers match the current search.
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="rounded-[2rem] border border-slate-200 bg-white p-5 shadow-sm">
          <div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
                Line items
              </p>
              <h3 class="mt-1 text-lg font-semibold text-slate-900">Requested items</h3>
              <p class="mt-1 text-sm text-slate-600">
                Edit descriptions and quantities before sending.
              </p>
            </div>

            <button
              type="button"
              phx-click="add_line"
              phx-target={@myself}
              class="inline-flex items-center justify-center rounded-xl border border-slate-200 bg-white px-4 py-2 text-sm font-semibold text-slate-700 transition hover:bg-slate-50"
            >
              + Add line
            </button>
          </div>

          <div class="mt-4 overflow-x-auto">
            <table class="w-full min-w-[920px] table-auto text-left text-sm">
              <thead class="border-b border-slate-200 text-slate-500">
                <tr>
                  <th class="w-12 pb-3 pr-4 font-semibold">#</th>
                  <th class="pb-3 pr-4 font-semibold">Description</th>
                  <th class="w-40 pb-3 pr-4 font-semibold">Category</th>
                  <th class="w-32 pb-3 pr-4 font-semibold">Unit</th>
                  <th class="w-36 pb-3 pr-4 text-right font-semibold">Qty</th>
                  <th class="w-44 pb-3 pr-4 text-right font-semibold">Estimate</th>
                  <th class="w-20 pb-3 text-right font-semibold"></th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-100">
                <tr :for={{item, index} <- Enum.with_index(@rfq_items)} class="align-top">
                  <td class="py-3 pr-4 text-slate-600">{item["position"]}</td>
                  <td class="py-3 pr-4">
                    <input
                      name={"rfq[items][#{index}][description]"}
                      value={item["description"]}
                      class="w-full rounded-xl border border-slate-200 px-3 py-2 text-sm focus:border-[#373896] focus:ring-[#373896]"
                    />
                    <input
                      type="hidden"
                      name={"rfq[items][#{index}][position]"}
                      value={item["position"]}
                    />
                    <input
                      type="hidden"
                      name={"rfq[items][#{index}][inventory_received_id]"}
                      value={item["inventory_received_id"]}
                    />
                  </td>
                  <td class="py-3 pr-4">
                    <input
                      name={"rfq[items][#{index}][category]"}
                      value={item["category"]}
                      class="w-full rounded-xl border border-slate-200 px-3 py-2 text-sm focus:border-[#373896] focus:ring-[#373896]"
                    />
                  </td>
                  <td class="py-3 pr-4">
                    <input
                      name={"rfq[items][#{index}][unit]"}
                      value={item["unit"]}
                      class="w-full rounded-xl border border-slate-200 px-3 py-2 text-sm focus:border-[#373896] focus:ring-[#373896]"
                    />
                  </td>
                  <td class="py-3 pr-4 text-right">
                    <input
                      name={"rfq[items][#{index}][quantity_required]"}
                      value={item["quantity_required"]}
                      class="w-full rounded-xl border border-slate-200 px-3 py-2 text-sm text-right tabular-nums focus:border-[#373896] focus:ring-[#373896]"
                    />
                  </td>
                  <td class="py-3 pr-4 text-right">
                    <input
                      name={"rfq[items][#{index}][estimated_unit_price]"}
                      value={item["estimated_unit_price"]}
                      class="w-full rounded-xl border border-slate-200 px-3 py-2 text-sm text-right tabular-nums focus:border-[#373896] focus:ring-[#373896]"
                      placeholder="KES"
                    />
                  </td>
                  <td class="py-3 text-right">
                    <button
                      type="button"
                      phx-click="remove_line"
                      phx-value-index={index}
                      phx-target={@myself}
                      class="rounded-lg px-2 py-1 text-xs font-semibold text-rose-700 transition hover:bg-rose-50"
                      title="Remove line"
                    >
                      Remove
                    </button>
                  </td>
                </tr>

                <tr :if={Enum.empty?(@rfq_items)}>
                  <td colspan="7" class="py-6 text-center text-sm text-slate-500">
                    No line items yet. Add one above.
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <:actions>
          <button
            type="button"
            phx-click={JS.push("close")}
            phx-target={@myself}
            class="rounded-xl border border-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-700 transition hover:bg-slate-50"
          >
            Cancel
          </button>

          <button
            type="button"
            phx-click="save_draft"
            phx-target={@myself}
            class="rounded-xl border border-[#d2d3ff] bg-[#f0f0ff] px-4 py-2.5 text-sm font-semibold text-[#373896] transition hover:bg-[#e7e7ff]"
          >
            Save draft
          </button>

          <button
            type="submit"
            class="rounded-xl bg-[#373896] px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-[#2d2d7a]"
          >
            Send RFQ
          </button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def handle_event("close", _params, socket) do
    send(self(), {__MODULE__, :close})
    {:noreply, socket}
  end

  def handle_event("supplier_search", %{"supplier_search" => %{"query" => term}}, socket) do
    selected_ids = Enum.map(socket.assigns.selected_suppliers, & &1.id)

    {:noreply,
     socket
     |> assign(:supplier_search, term)
     |> assign(
       :supplier_results,
       LiveHelpers.search_suppliers(term, status: "approved", exclude_ids: selected_ids)
     )}
  end

  def handle_event("add_supplier", %{"id" => id}, socket) do
    supplier =
      LiveHelpers.search_suppliers(nil, status: "approved")
      |> Enum.find(&("#{&1.id}" == to_string(id)))

    if is_nil(supplier) do
      {:noreply, socket}
    else
      selected =
        [supplier | socket.assigns.selected_suppliers]
        |> Enum.uniq_by(& &1.id)

      {:noreply,
       socket
       |> assign(:selected_suppliers, selected)
       |> assign(
         :supplier_results,
         LiveHelpers.search_suppliers(socket.assigns.supplier_search,
           status: "approved",
           exclude_ids: Enum.map(selected, & &1.id)
         )
       )}
    end
  end

  def handle_event("remove_supplier", %{"id" => id}, socket) do
    selected = Enum.reject(socket.assigns.selected_suppliers, &("#{&1.id}" == to_string(id)))

    {:noreply,
     socket
     |> assign(:selected_suppliers, selected)
     |> assign(
       :supplier_results,
       LiveHelpers.search_suppliers(socket.assigns.supplier_search,
         status: "approved",
         exclude_ids: Enum.map(selected, & &1.id)
       )
     )}
  end

  def handle_event("add_line", _params, socket) do
    position = length(socket.assigns.rfq_items) + 1
    items = socket.assigns.rfq_items ++ [blank_rfq_item(position)]
    {:noreply, assign(socket, :rfq_items, items)}
  end

  def handle_event("remove_line", %{"index" => idx}, socket) do
    idx =
      case Integer.parse(to_string(idx)) do
        {int, ""} -> int
        _ -> nil
      end

    {:noreply,
     if is_nil(idx) do
       socket
     else
       items =
         socket.assigns.rfq_items
         |> Enum.with_index()
         |> Enum.reject(fn {_item, item_index} -> item_index == idx end)
         |> Enum.map(fn {item, item_index} -> Map.put(item, "position", item_index + 1) end)

       assign(socket, :rfq_items, if(items == [], do: [blank_rfq_item(1)], else: items))
     end}
  end

  def handle_event("change", %{"rfq" => params}, socket) do
    form = rfq_form_from_params(params, socket.assigns.rfq_form)
    items = rfq_items_from_params(params, socket.assigns.rfq_items)

    {:noreply,
     socket
     |> assign(:rfq_form, form)
     |> assign(:rfq_items, items)
     |> assign(:rfq_general_errors, [])}
  end

  def handle_event("save_draft", _params, socket) do
    case persist_rfq(socket, :draft) do
      {:ok, rfq} ->
        send(self(), {__MODULE__, {:saved, rfq, :draft}})
        {:noreply, socket |> assign(:rfq, rfq) |> assign(:rfq_general_errors, [])}

      {:error, reason} ->
        {:noreply, assign(socket, :rfq_general_errors, List.wrap(reason))}
    end
  end

  def handle_event("send", _params, socket) do
    case persist_rfq(socket, :send) do
      {:ok, rfq} ->
        send(self(), {__MODULE__, {:saved, rfq, :sent}})
        {:noreply, socket |> assign(:rfq, rfq) |> assign(:rfq_general_errors, [])}

      {:error, reason} ->
        {:noreply, assign(socket, :rfq_general_errors, List.wrap(reason))}
    end
  end

  defp persist_rfq(socket, intent) do
    supplier_ids = Enum.map(socket.assigns.selected_suppliers, & &1.id)

    cond do
      LiveHelpers.blank?(socket.assigns.rfq_form["title"]) ->
        {:error, "Title is required."}

      LiveHelpers.blank?(socket.assigns.rfq_form["quote_deadline"]) ->
        {:error, "Quote deadline is required."}

      intent == :send and supplier_ids == [] ->
        {:error, "Select at least one supplier before sending the RFQ."}

      Enum.all?(socket.assigns.rfq_items, &LiveHelpers.blank?(Map.get(&1, "description"))) ->
        {:error, "Add at least one line item before saving."}

      true ->
        attrs = build_rfq_attrs(socket)

        result =
          case socket.assigns.rfq do
            nil -> Rfqs.create(attrs, socket.assigns.current_user)
            rfq -> Rfqs.update(rfq, attrs)
          end

        case result do
          {:ok, rfq} when intent == :send ->
            Rfqs.send(rfq, supplier_ids)

          other ->
            other
        end
    end
  end

  defp build_rfq_attrs(socket) do
    %{
      title: socket.assigns.rfq_form["title"],
      department: socket.assigns.rfq_form["department"],
      priority: socket.assigns.rfq_form["priority"],
      issue_date: blank_to_nil(socket.assigns.rfq_form["issue_date"]),
      quote_deadline: blank_to_nil(socket.assigns.rfq_form["quote_deadline"]),
      delivery_by: blank_to_nil(socket.assigns.rfq_form["delivery_by"]),
      currency: socket.assigns.rfq_form["currency"],
      delivery_terms: socket.assigns.rfq_form["delivery_terms"],
      payment_terms: socket.assigns.rfq_form["payment_terms"],
      special_instructions: socket.assigns.rfq_form["special_instructions"],
      items:
        socket.assigns.rfq_items
        |> Enum.reject(&blank_rfq_item_row?/1)
        |> Enum.map(fn item ->
          %{
            position: item["position"],
            description: item["description"],
            category: item["category"],
            unit: item["unit"],
            quantity_required: blank_to_nil(item["quantity_required"]),
            estimated_unit_price: blank_to_nil(item["estimated_unit_price"]),
            inventory_received_id: blank_to_nil(item["inventory_received_id"])
          }
        end)
    }
    |> LiveHelpers.prune_blank_values()
  end

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value

  defp rfq_form_from_params(params, current) do
    Map.merge(current, Map.take(params, @rfq_fields))
  end

  defp rfq_items_from_params(params, current) do
    params
    |> Map.get("items", %{})
    |> LiveHelpers.listify_indexed_params()
    |> case do
      [] ->
        current

      items ->
        Enum.with_index(items, 1)
        |> Enum.map(fn {item, position} -> Map.put(item, "position", position) end)
    end
  end

  defp default_rfq_state(requisitions) do
    form =
      %{
        "title" => default_title(requisitions),
        "department" => default_department(requisitions),
        "priority" => "normal",
        "issue_date" => Date.utc_today() |> Date.to_iso8601(),
        "quote_deadline" => Date.add(Date.utc_today(), 7) |> Date.to_iso8601(),
        "delivery_by" => "",
        "currency" => "KES",
        "delivery_terms" => "",
        "payment_terms" => "",
        "special_instructions" => ""
      }

    items = requisitions_to_rfq_items(requisitions)
    {form, if(items == [], do: [blank_rfq_item(1)], else: items)}
  end

  defp default_title([]), do: "Requisition RFQ"
  defp default_title(requisitions), do: "Requisition RFQ (#{length(requisitions)})"

  defp default_department(requisitions) do
    departments =
      requisitions
      |> Enum.map(&get_in(&1, [Access.key(:to_department), Access.key(:name)]))
      |> Enum.reject(&LiveHelpers.blank?/1)
      |> Enum.uniq()

    cond do
      departments == [] -> ""
      length(departments) <= 3 -> Enum.join(departments, ", ")
      true -> "Multiple departments"
    end
  end

  defp requisitions_to_rfq_items(requisitions) do
    inventory_groups =
      requisitions
      |> Enum.filter(& &1.inventory_received_id)
      |> Enum.group_by(& &1.inventory_received_id)

    manual =
      requisitions
      |> Enum.reject(& &1.inventory_received_id)

    inventory_items =
      inventory_groups
      |> Enum.map(fn {_id, group} ->
        inv = List.first(group).inventory_received
        qty = Enum.map(group, &(&1.quantity || 0)) |> Enum.sum()

        rfq_item_from_inventory_received(inv, qty)
      end)

    manual_items =
      manual
      |> Enum.map(fn req ->
        %{
          "description" =>
            [req.title, req.description] |> Enum.reject(&LiveHelpers.blank?/1) |> Enum.join(" — "),
          "category" => "",
          "unit" => "",
          "quantity_required" => to_string(req.quantity || 0),
          "estimated_unit_price" => "",
          "inventory_received_id" => ""
        }
      end)

    (inventory_items ++ manual_items)
    |> Enum.with_index(1)
    |> Enum.map(fn {item, pos} -> Map.put(item, "position", pos) end)
  end

  defp rfq_item_from_inventory_received(nil, qty) do
    blank_rfq_item(1) |> Map.put("quantity_required", to_string(qty || 0))
  end

  defp rfq_item_from_inventory_received(inv, qty) do
    %{
      "description" => inventory_received_label(inv),
      "category" => inv.category || inv.type || "",
      "unit" => inv.uom || "",
      "quantity_required" => to_string(qty || 0),
      "estimated_unit_price" => "",
      "inventory_received_id" => to_string(inv.id)
    }
  end

  defp inventory_received_label(inv) do
    [
      inv.brand_name,
      inv.generic_name,
      inv.description,
      inv.strength
    ]
    |> Enum.reject(&LiveHelpers.blank?/1)
    |> Enum.uniq()
    |> Enum.join(" • ")
    |> case do
      "" -> "Inventory item ##{inv.id}"
      label -> label
    end
  end

  defp blank_rfq_item(position) do
    %{
      "position" => position,
      "description" => "",
      "category" => "",
      "unit" => "",
      "quantity_required" => "",
      "estimated_unit_price" => "",
      "inventory_received_id" => ""
    }
  end

  defp blank_rfq_item_row?(item) do
    LiveHelpers.blank?(item["description"]) and LiveHelpers.blank?(item["quantity_required"])
  end
end
