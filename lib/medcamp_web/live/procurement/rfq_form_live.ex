defmodule MedcampWeb.Procurement.RfqFormLive do
  use MedcampWeb, :procurement_live_view

  import MedcampWeb.ProcurementComponents,
    only: [supplier_chip: 1, confirmation_modal: 1, portal_form_shell: 1]

  alias Ecto.Changeset
  alias Phoenix.LiveView.JS

  alias Medcamp.Procurement.{Rfq, RfqItem, Rfqs}
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
  )a

  @impl true
  def mount(params, _session, socket) do
    {rfq_form, rfq_items} = maybe_prefill_from_requisitions(params)

    {:ok,
     socket
     |> assign(:page_title, "Create request for quotation")
     |> assign(:rfq, nil)
     |> assign(:rfq_form, rfq_form)
     |> assign(:rfq_items, rfq_items)
     |> assign(:rfq_errors, %{})
     |> assign(:rfq_item_errors, %{})
     |> assign(:rfq_general_errors, [])
     |> assign(:selected_suppliers, [])
     |> assign(:inventory_search, "")
     |> assign(:inventory_results, [])
     |> assign(:supplier_results, LiveHelpers.search_suppliers(nil, status: "approved"))
     |> assign(:supplier_search, "")}
  end

  @impl true
  def handle_event("change", %{"rfq" => params}, socket) do
    form = rfq_form_from_params(params, socket.assigns.rfq_form)
    items = rfq_items_from_params(params, socket.assigns.rfq_items)

    {:noreply,
     socket
     |> assign(:rfq_form, form)
     |> assign(:rfq_items, items)
     |> assign(
       :inventory_results,
       inventory_results(socket.assigns.inventory_search, items)
     )
     |> assign(:rfq_errors, %{})
     |> assign(:rfq_item_errors, %{})
     |> assign(:rfq_general_errors, [])}
  end

  def handle_event("inventory_search", %{"inventory_search" => %{"query" => term}}, socket) do
    {:noreply,
     socket
     |> assign(:inventory_search, term)
     |> assign(:inventory_results, inventory_results(term, socket.assigns.rfq_items))}
  end

  def handle_event("supplier_search", %{"supplier_search" => %{"query" => term}}, socket) do
    {:noreply,
     socket
     |> assign(:supplier_search, term)
     |> assign(
       :supplier_results,
       LiveHelpers.search_suppliers(term,
         status: "approved",
         exclude_ids: Enum.map(socket.assigns.selected_suppliers, & &1.id)
       )
     )}
  end

  def handle_event("add_supplier", %{"id" => id}, socket) do
    case LiveHelpers.search_suppliers(nil, status: "approved")
         |> Enum.find(&("#{&1.id}" == id)) do
      nil ->
        {:noreply, socket}

      supplier ->
        selected_suppliers =
          [supplier | socket.assigns.selected_suppliers]
          |> Enum.uniq_by(& &1.id)

        {:noreply,
         socket
         |> assign(:selected_suppliers, selected_suppliers)
         |> assign(
           :supplier_results,
           LiveHelpers.search_suppliers(socket.assigns.supplier_search,
             status: "approved",
             exclude_ids: Enum.map(selected_suppliers, & &1.id)
           )
         )}
    end
  end

  def handle_event("remove_supplier", %{"id" => id}, socket) do
    selected_suppliers = Enum.reject(socket.assigns.selected_suppliers, &("#{&1.id}" == id))

    {:noreply,
     socket
     |> assign(:selected_suppliers, selected_suppliers)
     |> assign(
       :supplier_results,
       LiveHelpers.search_suppliers(socket.assigns.supplier_search,
         status: "approved",
         exclude_ids: Enum.map(selected_suppliers, & &1.id)
       )
     )}
  end

  def handle_event("add_item", _params, socket) do
    next_position = length(socket.assigns.rfq_items) + 1

    {:noreply,
     assign(socket, :rfq_items, socket.assigns.rfq_items ++ [blank_rfq_item(next_position)])}
  end

  def handle_event("add_inventory_item", %{"id" => id}, socket) do
    inventory_received =
      id
      |> parse_integer()
      |> LiveHelpers.get_inventory_received()

    cond do
      is_nil(inventory_received) ->
        {:noreply, socket}

      inventory_received.id in selected_inventory_received_ids(socket.assigns.rfq_items) ->
        {:noreply, socket}

      true ->
        next_position = length(socket.assigns.rfq_items) + 1

        items =
          socket.assigns.rfq_items ++
            [rfq_item_from_inventory_received(inventory_received, next_position)]

        {:noreply,
         socket
         |> assign(:rfq_items, items)
         |> assign(:inventory_results, inventory_results(socket.assigns.inventory_search, items))}
    end
  end

  def handle_event("remove_item", %{"index" => index}, socket) do
    idx = String.to_integer(index)

    items =
      socket.assigns.rfq_items
      |> Enum.with_index()
      |> Enum.reject(fn {_item, item_index} -> item_index == idx end)
      |> Enum.map(fn {item, item_index} -> Map.put(item, "position", item_index + 1) end)

    items = if(items == [], do: [blank_rfq_item(1)], else: items)

    {:noreply,
     socket
     |> assign(:rfq_items, items)
     |> assign(:inventory_results, inventory_results(socket.assigns.inventory_search, items))}
  end

  def handle_event("save_draft", _params, socket) do
    case persist_rfq(socket, :draft) do
      {:ok, rfq} ->
        {:noreply,
         socket
         |> assign(:rfq, rfq)
         |> put_flash(:info, "Request for quotation draft saved.")
         |> push_navigate(to: ~p"/procurement/rfqs/#{rfq.id}")}

      {:error, reason} ->
        {:noreply, handle_persist_error(socket, reason)}
    end
  end

  def handle_event("confirm_send", _params, socket) do
    case persist_rfq(socket, :send) do
      {:ok, rfq} ->
        {:noreply,
         socket
         |> put_flash(:info, "Request for quotation sent successfully.")
         |> push_navigate(to: ~p"/procurement/rfqs/#{rfq.id}")}

      {:error, reason} ->
        {:noreply, handle_persist_error(socket, reason)}
    end
  end

  defp persist_rfq(socket, intent) do
    supplier_ids = Enum.map(socket.assigns.selected_suppliers, & &1.id)

    cond do
      intent == :send and supplier_ids == [] ->
        {:error, "Select at least one supplier before sending the request for quotation."}

      Enum.all?(socket.assigns.rfq_items, &LiveHelpers.blank?(Map.get(&1, "description"))) ->
        {:error, "Add at least one request for quotation line item before saving."}

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

  defp default_form do
    %{
      "title" => "",
      "department" => "",
      "priority" => "normal",
      "issue_date" => Date.utc_today() |> Date.to_iso8601(),
      "quote_deadline" => "",
      "delivery_by" => "",
      "currency" => "KES",
      "delivery_terms" => "",
      "payment_terms" => "",
      "special_instructions" => ""
    }
  end

  defp maybe_prefill_from_requisitions(params) do
    requisition_ids = parse_requisition_ids(Map.get(params, "requisition_ids"))

    if requisition_ids == [] do
      {default_form(), [blank_rfq_item(1)]}
    else
      requisitions = Requisitions.list_requisitions_by_ids(requisition_ids)
      rfq_items = requisitions_to_rfq_items(requisitions)
      rfq_items = if(rfq_items == [], do: [blank_rfq_item(1)], else: rfq_items)

      base_form =
        default_form()
        |> Map.put("title", default_prefill_title(requisitions))
        |> Map.put("department", default_prefill_department(requisitions))
        |> Map.put("priority", "normal")

      form =
        base_form
        |> maybe_put_param("title", Map.get(params, "title"))
        |> maybe_put_param("quote_deadline", Map.get(params, "quote_deadline"))
        |> maybe_put_param("priority", Map.get(params, "priority"))

      {form, rfq_items}
    end
  end

  defp parse_requisition_ids(nil), do: []
  defp parse_requisition_ids(""), do: []

  defp parse_requisition_ids(ids) when is_binary(ids) do
    ids
    |> String.split([",", " "], trim: true)
    |> Enum.map(fn part ->
      case Integer.parse(part) do
        {int, ""} -> int
        _ -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp parse_requisition_ids(ids) when is_list(ids),
    do: parse_requisition_ids(Enum.join(ids, ","))

  defp parse_requisition_ids(_), do: []

  defp maybe_put_param(form, _key, value) when value in [nil, ""], do: form

  defp maybe_put_param(form, key, value) do
    Map.put(form, key, value)
  end

  defp default_prefill_title([]), do: "Requisition RFQ"
  defp default_prefill_title(requisitions), do: "Requisition RFQ (#{length(requisitions)})"

  defp default_prefill_department(requisitions) do
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

    general_groups =
      requisitions
      |> Enum.filter(& &1.general_inventory_item_id)
      |> Enum.group_by(& &1.general_inventory_item_id)

    manual_groups =
      requisitions
      |> Enum.reject(&(&1.inventory_received_id || &1.general_inventory_item_id))
      |> Enum.group_by(&(&1.title || "Requisition"))

    {items, _pos} =
      {[], 1}
      |> add_inventory_groups(inventory_groups)
      |> add_general_groups(general_groups)
      |> add_manual_groups(manual_groups)

    Enum.reverse(items)
  end

  defp add_inventory_groups({acc, pos}, groups) do
    Enum.reduce(groups, {acc, pos}, fn {_id, group}, {acc, pos} ->
      inv = List.first(group).inventory_received
      qty = Enum.map(group, &(&1.quantity || 0)) |> Enum.sum()

      item =
        inv
        |> rfq_item_from_inventory_received(pos)
        |> Map.put("quantity_required", Integer.to_string(qty))

      {[item | acc], pos + 1}
    end)
  end

  defp add_general_groups({acc, pos}, groups) do
    Enum.reduce(groups, {acc, pos}, fn {_id, group}, {acc, pos} ->
      gen = List.first(group).general_inventory_item
      qty = Enum.map(group, &(&1.quantity || 0)) |> Enum.sum()

      item =
        gen
        |> rfq_item_from_general_inventory_item(pos)
        |> Map.put("quantity_required", Integer.to_string(qty))

      {[item | acc], pos + 1}
    end)
  end

  defp add_manual_groups({acc, pos}, groups) do
    Enum.reduce(groups, {acc, pos}, fn {_key, group}, {acc, pos} ->
      req = List.first(group)
      qty = Enum.map(group, &(&1.quantity || 0)) |> Enum.sum()

      item =
        rfq_item_from_manual_requisition(req, pos)
        |> Map.put("quantity_required", Integer.to_string(qty))

      {[item | acc], pos + 1}
    end)
  end

  defp rfq_item_from_general_inventory_item(nil, position), do: blank_rfq_item(position)

  defp rfq_item_from_general_inventory_item(item, position) do
    %{
      "position" => position,
      "description" => item.name || "",
      "category" => item.category || "",
      "unit" => item.unit_of_measure || "",
      "quantity_required" => "",
      "estimated_unit_price" =>
        (item.unit_cost && LiveHelpers.decimal_to_string(item.unit_cost)) || "",
      "inventory_received_id" => "",
      "inventory_label" => item.name || "",
      "inventory_supplier" => item.supplier || "",
      "inventory_gtin" => item.gtin || ""
    }
  end

  defp rfq_item_from_manual_requisition(req, position) do
    label =
      [req.title, req.description]
      |> Enum.reject(&LiveHelpers.blank?/1)
      |> Enum.join(" — ")

    %{
      "position" => position,
      "description" => label,
      "category" => "",
      "unit" => "",
      "quantity_required" => "",
      "estimated_unit_price" => "",
      "inventory_received_id" => "",
      "inventory_label" => "",
      "inventory_supplier" => "",
      "inventory_gtin" => ""
    }
  end

  defp rfq_form_from_params(params, current),
    do:
      Map.merge(
        current,
        Map.take(
          params,
          ~w(title department priority issue_date quote_deadline delivery_by currency delivery_terms payment_terms special_instructions)
        )
      )

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

  defp blank_rfq_item(position) do
    %{
      "position" => position,
      "description" => "",
      "category" => "",
      "unit" => "",
      "quantity_required" => "",
      "estimated_unit_price" => "",
      "inventory_received_id" => "",
      "inventory_label" => "",
      "inventory_supplier" => "",
      "inventory_gtin" => ""
    }
  end

  defp rfq_item_from_inventory_received(inventory_received, position) do
    %{
      "position" => position,
      "description" => inventory_received_description(inventory_received),
      "category" => inventory_received.category || inventory_received.type || "",
      "unit" => inventory_received.uom || "",
      "quantity_required" => "",
      "estimated_unit_price" => "",
      "inventory_received_id" => inventory_received.id,
      "inventory_label" => inventory_received_label(inventory_received),
      "inventory_supplier" => inventory_received.supplier || "",
      "inventory_gtin" => inventory_received.gtin || ""
    }
  end

  defp inventory_results(term, items) do
    if LiveHelpers.blank?(term) do
      []
    else
      LiveHelpers.search_inventory_received(term,
        exclude_ids: selected_inventory_received_ids(items)
      )
    end
  end

  defp selected_inventory_received_ids(items) do
    items
    |> Enum.map(&parse_integer(Map.get(&1, "inventory_received_id")))
    |> Enum.reject(&is_nil/1)
  end

  defp inventory_received_label(inventory_received) do
    [
      inventory_received.brand_name,
      inventory_received.generic_name,
      inventory_received.description,
      inventory_received.strength
    ]
    |> Enum.reject(&LiveHelpers.blank?/1)
    |> Enum.uniq()
    |> Enum.join(" • ")
  end

  defp inventory_received_description(inventory_received) do
    inventory_received_label(inventory_received)
    |> case do
      "" -> "Imported inventory item ##{inventory_received.id}"
      label -> label
    end
  end

  defp blank_rfq_item_row?(item) do
    Enum.all?(
      ~w(description category unit quantity_required estimated_unit_price inventory_received_id),
      &LiveHelpers.blank?(Map.get(item, &1))
    )
  end

  defp parse_integer(nil), do: nil
  defp parse_integer(value) when is_integer(value), do: value

  defp parse_integer(value) do
    value
    |> to_string()
    |> Integer.parse()
    |> case do
      {parsed, _rest} -> parsed
      :error -> nil
    end
  end

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value

  defp handle_persist_error(socket, %Changeset{data: %Rfq{}} = changeset) do
    errors = changeset_errors(changeset)

    socket
    |> clear_form_errors()
    |> assign(:rfq_errors, Map.take(errors, @rfq_fields))
    |> assign(:rfq_general_errors, general_errors(errors, @rfq_fields))
  end

  defp handle_persist_error(socket, %Changeset{data: %RfqItem{}} = changeset) do
    errors = changeset_errors(changeset)
    position = Changeset.get_field(changeset, :position)

    socket
    |> clear_form_errors()
    |> assign(
      :rfq_item_errors,
      if(is_integer(position), do: %{position => errors}, else: %{})
    )
  end

  defp handle_persist_error(socket, message) when is_binary(message) do
    socket
    |> clear_form_errors()
    |> put_flash(:error, message)
  end

  defp handle_persist_error(socket, reason) when is_list(reason) do
    socket
    |> clear_form_errors()
    |> put_flash(
      :error,
      "Request for quotation was saved, but we couldn't send it to suppliers. Please try again."
    )
  end

  defp handle_persist_error(socket, _reason) do
    socket
    |> clear_form_errors()
    |> put_flash(
      :error,
      "We couldn't save the request for quotation right now. Please try again."
    )
  end

  defp clear_form_errors(socket) do
    socket
    |> assign(:rfq_errors, %{})
    |> assign(:rfq_item_errors, %{})
    |> assign(:rfq_general_errors, [])
  end

  defp changeset_errors(%Changeset{} = changeset) do
    Changeset.traverse_errors(changeset, &translate_error/1)
  end

  defp general_errors(errors, inline_fields) do
    errors
    |> Map.drop(inline_fields)
    |> Enum.flat_map(fn {field, messages} ->
      Enum.map(messages, fn message -> "#{Phoenix.Naming.humanize(field)} #{message}" end)
    end)
  end

  defp field_errors(errors, field), do: Map.get(errors, field, [])

  defp item_field_errors(item_errors, position, field) do
    item_errors
    |> Map.get(position, %{})
    |> Map.get(field, [])
  end

  defp input_classes(errors, field) do
    [
      "mt-2 w-full rounded-xl px-4 py-2.5",
      if(field_errors(errors, field) == [],
        do: "border border-slate-200",
        else: "border border-rose-400"
      )
    ]
  end

  defp item_input_classes(item_errors, position, field) do
    [
      "mt-2 w-full rounded-xl px-4 py-2.5",
      if(item_field_errors(item_errors, position, field) == [],
        do: "border border-slate-200",
        else: "border border-rose-400"
      )
    ]
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.portal_form_shell
      eyebrow="Request for quotation form"
      title="Create and send request for quotation"
      subtitle="Select approved suppliers, build the line items, save a draft, then confirm before sending."
      cancel_path={~p"/procurement/dashboard"}
      max_width="max-w-[96rem]"
    >
      <div class="space-y-6">
        <div
          :if={@rfq_errors != %{} or @rfq_item_errors != %{} or @rfq_general_errors != []}
          class="rounded-[2rem] border border-rose-200 bg-rose-50 p-5 text-sm text-rose-700"
        >
          <p class="font-semibold">Please fix the highlighted fields and try again.</p>
          <ul :if={@rfq_general_errors != []} class="mt-3 list-disc space-y-1 pl-5">
            <li :for={message <- @rfq_general_errors}>{message}</li>
          </ul>
        </div>

        <form
          phx-change="change"
          class="overflow-hidden rounded-[2rem] border border-slate-200 bg-white shadow-sm"
        >
          <div class="border-b border-slate-200 bg-gradient-to-r from-slate-50 via-white to-[#f5f4ff] px-6 py-5">
            <div class="flex flex-col gap-3 xl:flex-row xl:items-start xl:justify-between">
              <div class="space-y-2">
                <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
                  Request for quotation setup
                </p>
                <h2 class="text-2xl font-semibold tracking-tight text-slate-900">
                  Details and suppliers
                </h2>
                <p class="max-w-3xl text-sm leading-6 text-slate-500">
                  Set the commercial dates and terms, then choose the approved suppliers who should receive this request for quotation.
                </p>
              </div>

              <div class="flex flex-wrap gap-3">
                <button
                  type="button"
                  phx-click="save_draft"
                  class="rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-semibold text-slate-700 transition hover:bg-slate-50"
                >
                  Save draft
                </button>
                <button
                  type="button"
                  phx-click={show_modal("rfq-send-confirm")}
                  class="rounded-xl bg-[#373896] px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-[#2d2d7a]"
                >
                  Send request for quotation
                </button>
              </div>
            </div>
          </div>

          <div class="grid gap-6 px-6 py-6 xl:grid-cols-[minmax(0,1.45fr)_minmax(21rem,0.95fr)]">
            <div>
              <div class="grid gap-4 md:grid-cols-2">
                <label class="block text-sm font-medium text-slate-700">
                  Title
                  <input
                    name="rfq[title]"
                    value={@rfq_form["title"]}
                    class={input_classes(@rfq_errors, :title)}
                  />
                  <.error :for={msg <- field_errors(@rfq_errors, :title)}>{msg}</.error>
                </label>
                <label class="block text-sm font-medium text-slate-700">
                  Department
                  <input
                    name="rfq[department]"
                    value={@rfq_form["department"]}
                    class={input_classes(@rfq_errors, :department)}
                  />
                  <.error :for={msg <- field_errors(@rfq_errors, :department)}>{msg}</.error>
                </label>
                <label class="block text-sm font-medium text-slate-700">
                  Priority
                  <select name="rfq[priority]" class={input_classes(@rfq_errors, :priority)}>
                    <option value="normal" selected={@rfq_form["priority"] == "normal"}>
                      Normal
                    </option>
                    <option value="high" selected={@rfq_form["priority"] == "high"}>High</option>
                    <option value="urgent" selected={@rfq_form["priority"] == "urgent"}>
                      Urgent
                    </option>
                  </select>
                  <.error :for={msg <- field_errors(@rfq_errors, :priority)}>{msg}</.error>
                </label>
                <label class="block text-sm font-medium text-slate-700">
                  Currency
                  <input
                    name="rfq[currency]"
                    value={@rfq_form["currency"]}
                    class={input_classes(@rfq_errors, :currency)}
                  />
                  <.error :for={msg <- field_errors(@rfq_errors, :currency)}>{msg}</.error>
                </label>
                <label class="block text-sm font-medium text-slate-700">
                  Issue date
                  <input
                    type="date"
                    name="rfq[issue_date]"
                    value={@rfq_form["issue_date"]}
                    class={input_classes(@rfq_errors, :issue_date)}
                  />
                  <.error :for={msg <- field_errors(@rfq_errors, :issue_date)}>{msg}</.error>
                </label>
                <label class="block text-sm font-medium text-slate-700">
                  Quote deadline
                  <input
                    type="date"
                    name="rfq[quote_deadline]"
                    value={@rfq_form["quote_deadline"]}
                    class={input_classes(@rfq_errors, :quote_deadline)}
                  />
                  <.error :for={msg <- field_errors(@rfq_errors, :quote_deadline)}>{msg}</.error>
                </label>
                <label class="block text-sm font-medium text-slate-700">
                  Delivery by
                  <input
                    type="date"
                    name="rfq[delivery_by]"
                    value={@rfq_form["delivery_by"]}
                    class={input_classes(@rfq_errors, :delivery_by)}
                  />
                  <.error :for={msg <- field_errors(@rfq_errors, :delivery_by)}>{msg}</.error>
                </label>
                <label class="block text-sm font-medium text-slate-700">
                  Payment terms
                  <input
                    name="rfq[payment_terms]"
                    value={@rfq_form["payment_terms"]}
                    class={input_classes(@rfq_errors, :payment_terms)}
                  />
                  <.error :for={msg <- field_errors(@rfq_errors, :payment_terms)}>{msg}</.error>
                </label>
              </div>

              <div class="mt-4 grid gap-4 lg:grid-cols-2">
                <label class="block text-sm font-medium text-slate-700">
                  Delivery terms <textarea
                    name="rfq[delivery_terms]"
                    rows="5"
                    class={input_classes(@rfq_errors, :delivery_terms)}
                  >{@rfq_form["delivery_terms"]}</textarea>
                  <.error :for={msg <- field_errors(@rfq_errors, :delivery_terms)}>{msg}</.error>
                </label>

                <label class="block text-sm font-medium text-slate-700">
                  Special instructions <textarea
                    name="rfq[special_instructions]"
                    rows="5"
                    class={input_classes(@rfq_errors, :special_instructions)}
                  >{@rfq_form["special_instructions"]}</textarea>
                  <.error :for={msg <- field_errors(@rfq_errors, :special_instructions)}>
                    {msg}
                  </.error>
                </label>
              </div>
            </div>

            <div class="rounded-[1.75rem] border border-slate-200 bg-slate-50/80 p-5">
              <div class="flex items-start justify-between gap-3">
                <div>
                  <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
                    Suppliers
                  </p>
                  <h3 class="mt-2 text-lg font-semibold text-slate-900">
                    Who should receive this request for quotation?
                  </h3>
                </div>
                <span class="rounded-full bg-white px-3 py-1 text-xs font-semibold text-[#373896] shadow-sm">
                  {length(@selected_suppliers)} selected
                </span>
              </div>

              <form phx-change="supplier_search" class="mt-4">
                <input
                  type="text"
                  name="supplier_search[query]"
                  value={@supplier_search}
                  placeholder="Search approved suppliers"
                  phx-debounce="250"
                  class="w-full rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm text-slate-700"
                />
              </form>

              <div :if={@selected_suppliers != []} class="mt-4 flex flex-wrap gap-2">
                <.supplier_chip
                  :for={supplier <- @selected_suppliers}
                  supplier={supplier}
                  on_remove="remove_supplier"
                />
              </div>

              <div class="mt-4 space-y-3">
                <div
                  :for={supplier <- Enum.take(@supplier_results, 6)}
                  class="flex items-center justify-between rounded-2xl border border-slate-200 bg-white px-4 py-3 shadow-sm"
                >
                  <div>
                    <p class="text-sm font-semibold text-slate-800">
                      {supplier.legal_name || supplier.name}
                    </p>
                    <p class="mt-1 text-xs text-slate-500">
                      {supplier.reference || "Pending reference"}
                    </p>
                  </div>
                  <button
                    type="button"
                    phx-click="add_supplier"
                    phx-value-id={supplier.id}
                    class="rounded-xl border border-slate-200 px-4 py-2 text-sm font-semibold text-slate-700 transition hover:bg-slate-50"
                  >
                    Add
                  </button>
                </div>
              </div>
            </div>
          </div>
        </form>

        <div class="overflow-hidden rounded-[2rem] border border-slate-200 bg-white shadow-sm">
          <div class="border-b border-slate-200 bg-gradient-to-r from-slate-50 via-white to-[#f5f4ff] px-6 py-5">
            <div class="flex flex-col gap-4 xl:flex-row xl:items-center xl:justify-between">
              <div>
                <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
                  Line items
                </p>
                <h2 class="mt-2 text-2xl font-semibold tracking-tight text-slate-900">
                  Request for quotation requirements
                </h2>
                <p class="mt-2 max-w-3xl text-sm leading-6 text-slate-500">
                  Add items manually, or search inventory received and import only the exact items you want to trace through the procurement flow.
                </p>
              </div>
              <button
                type="button"
                phx-click="add_item"
                class="rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-semibold text-slate-700 transition hover:bg-slate-50"
              >
                Add blank item
              </button>
            </div>
          </div>

          <div class="space-y-6 px-6 py-6">
            <div class="rounded-[1.75rem] border border-slate-200 bg-slate-50/80 p-5">
              <div class="flex flex-col gap-4 xl:flex-row xl:items-end xl:justify-between">
                <div class="max-w-2xl">
                  <p class="text-xs font-semibold uppercase tracking-[0.22em] text-slate-400">
                    Import from inventory received
                  </p>
                  <p class="mt-2 text-sm leading-6 text-slate-600">
                    Search first, then import. We only show matched inventory-received items so this area stays focused and easier to use.
                  </p>
                </div>

                <form phx-change="inventory_search" class="w-full xl:max-w-lg">
                  <input
                    type="text"
                    name="inventory_search[query]"
                    value={@inventory_search}
                    placeholder="Search by brand, generic, GTIN, supplier, or category"
                    phx-debounce="300"
                    class="w-full rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm text-slate-700"
                  />
                </form>
              </div>

              <div
                :if={LiveHelpers.blank?(@inventory_search)}
                class="mt-4 rounded-2xl border border-dashed border-slate-300 bg-white px-5 py-6 text-sm text-slate-500"
              >
                Start typing to search inventory received. We won’t show the full inventory list here.
              </div>

              <div
                :if={!LiveHelpers.blank?(@inventory_search) and @inventory_results != []}
                class="mt-4 grid gap-3 md:grid-cols-2 xl:grid-cols-3"
              >
                <div
                  :for={inventory <- @inventory_results}
                  class="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm"
                >
                  <div class="flex items-start justify-between gap-3">
                    <div class="space-y-1">
                      <p class="text-sm font-semibold leading-6 text-slate-900">
                        {inventory_received_description(inventory)}
                      </p>
                      <p class="text-xs text-slate-500">
                        Inventory received ##{inventory.id}
                        <span :if={!LiveHelpers.blank?(inventory.supplier)}>
                          • {inventory.supplier}
                        </span>
                      </p>
                    </div>
                    <button
                      type="button"
                      phx-click="add_inventory_item"
                      phx-value-id={inventory.id}
                      class="rounded-xl bg-[#373896] px-3 py-2 text-xs font-semibold text-white transition hover:bg-[#2d2d7a]"
                    >
                      Import
                    </button>
                  </div>

                  <div class="mt-3 flex flex-wrap gap-2 text-xs text-slate-500">
                    <span
                      :if={!LiveHelpers.blank?(inventory.category)}
                      class="rounded-full bg-slate-100 px-3 py-1"
                    >
                      {inventory.category}
                    </span>
                    <span
                      :if={!LiveHelpers.blank?(inventory.uom)}
                      class="rounded-full bg-slate-100 px-3 py-1"
                    >
                      Unit: {inventory.uom}
                    </span>
                    <span
                      :if={!LiveHelpers.blank?(inventory.gtin)}
                      class="rounded-full bg-slate-100 px-3 py-1"
                    >
                      GTIN: {inventory.gtin}
                    </span>
                  </div>
                </div>
              </div>

              <p
                :if={!LiveHelpers.blank?(@inventory_search) and @inventory_results == []}
                class="mt-4 text-sm text-slate-500"
              >
                No inventory received items match this search. You can still add the request for quotation line manually.
              </p>
            </div>

            <form phx-change="change" class="space-y-4">
              <div
                :for={{item, index} <- Enum.with_index(@rfq_items)}
                class="rounded-[1.75rem] border border-slate-200 bg-slate-50/70 p-5"
              >
                <div class="mb-4 flex flex-col gap-3 lg:flex-row lg:items-start lg:justify-between">
                  <div>
                    <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-400">
                      Line {item["position"]}
                    </p>
                    <h3 class="mt-2 text-lg font-semibold text-slate-900">Requirement details</h3>
                  </div>
                  <button
                    type="button"
                    phx-click="remove_item"
                    phx-value-index={index}
                    class="text-sm font-semibold text-rose-600"
                  >
                    Remove item
                  </button>
                </div>

                <div
                  :if={!LiveHelpers.blank?(item["inventory_received_id"])}
                  class="mb-4 rounded-2xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-xs leading-5 text-emerald-900"
                >
                  <p class="font-semibold uppercase tracking-[0.18em] text-emerald-700">
                    Imported from inventory received
                  </p>
                  <p class="mt-1">
                    ID #{item["inventory_received_id"]} • {if LiveHelpers.blank?(
                                                                item["inventory_label"]
                                                              ),
                                                              do: item["description"],
                                                              else: item["inventory_label"]}
                  </p>
                  <p
                    :if={
                      !LiveHelpers.blank?(item["inventory_supplier"]) or
                        !LiveHelpers.blank?(item["inventory_gtin"])
                    }
                    class="mt-1 text-emerald-800/80"
                  >
                    <span :if={!LiveHelpers.blank?(item["inventory_supplier"])}>
                      Supplier {item["inventory_supplier"]}
                    </span>
                    <span :if={
                      !LiveHelpers.blank?(item["inventory_supplier"]) and
                        !LiveHelpers.blank?(item["inventory_gtin"])
                    }>
                      •
                    </span>
                    <span :if={!LiveHelpers.blank?(item["inventory_gtin"])}>
                      GTIN {item["inventory_gtin"]}
                    </span>
                  </p>
                </div>

                <div class="grid gap-4 lg:grid-cols-2 xl:grid-cols-5">
                  <label class="block text-sm font-medium text-slate-700 xl:col-span-2">
                    Description
                    <input
                      name={"rfq[items][#{index}][description]"}
                      value={item["description"]}
                      class={item_input_classes(@rfq_item_errors, item["position"], :description)}
                    />
                    <.error :for={
                      msg <- item_field_errors(@rfq_item_errors, item["position"], :description)
                    }>
                      {msg}
                    </.error>
                  </label>
                  <label class="block text-sm font-medium text-slate-700">
                    Category
                    <input
                      name={"rfq[items][#{index}][category]"}
                      value={item["category"]}
                      class={item_input_classes(@rfq_item_errors, item["position"], :category)}
                    />
                    <.error :for={
                      msg <- item_field_errors(@rfq_item_errors, item["position"], :category)
                    }>
                      {msg}
                    </.error>
                  </label>
                  <label class="block text-sm font-medium text-slate-700">
                    Unit
                    <input
                      name={"rfq[items][#{index}][unit]"}
                      value={item["unit"]}
                      class={item_input_classes(@rfq_item_errors, item["position"], :unit)}
                    />
                    <.error :for={msg <- item_field_errors(@rfq_item_errors, item["position"], :unit)}>
                      {msg}
                    </.error>
                  </label>
                  <label class="block text-sm font-medium text-slate-700">
                    Quantity required
                    <input
                      name={"rfq[items][#{index}][quantity_required]"}
                      value={item["quantity_required"]}
                      class={
                        item_input_classes(@rfq_item_errors, item["position"], :quantity_required)
                      }
                    />
                    <.error :for={
                      msg <-
                        item_field_errors(
                          @rfq_item_errors,
                          item["position"],
                          :quantity_required
                        )
                    }>
                      {msg}
                    </.error>
                  </label>
                  <label class="block text-sm font-medium text-slate-700 xl:col-span-2">
                    Estimated unit price
                    <input
                      name={"rfq[items][#{index}][estimated_unit_price]"}
                      value={item["estimated_unit_price"]}
                      class={
                        item_input_classes(@rfq_item_errors, item["position"], :estimated_unit_price)
                      }
                    />
                    <.error :for={
                      msg <-
                        item_field_errors(
                          @rfq_item_errors,
                          item["position"],
                          :estimated_unit_price
                        )
                    }>
                      {msg}
                    </.error>
                  </label>
                </div>
                <input
                  type="hidden"
                  name={"rfq[items][#{index}][inventory_received_id]"}
                  value={item["inventory_received_id"]}
                />
                <input
                  type="hidden"
                  name={"rfq[items][#{index}][inventory_label]"}
                  value={item["inventory_label"]}
                />
                <input
                  type="hidden"
                  name={"rfq[items][#{index}][inventory_supplier]"}
                  value={item["inventory_supplier"]}
                />
                <input
                  type="hidden"
                  name={"rfq[items][#{index}][inventory_gtin]"}
                  value={item["inventory_gtin"]}
                />
              </div>
            </form>
          </div>
        </div>
      </div>
    </.portal_form_shell>

    <.confirmation_modal
      id="rfq-send-confirm"
      title="Send request for quotation to selected suppliers?"
      body="This will transition the request for quotation from draft to sent and notify every selected supplier."
      confirm_label="Send request for quotation"
      on_confirm={JS.push("confirm_send")}
    />
    """
  end
end
