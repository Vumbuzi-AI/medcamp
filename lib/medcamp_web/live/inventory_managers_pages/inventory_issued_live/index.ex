defmodule MedcampWeb.InventoryIssuedLive.Index do
  use MedcampWeb, :inventory_manager_live_view

  alias Medcamp.InventoriesIssues
  alias Medcamp.InventoriesIssues.InventoryIssued
  alias Medcamp.Requisitions
  alias Medcamp.DrugBatches

  @location_options [
    "Pharmacy",
    "Store",
    "Warehouse",
    "Laboratory",
    "Nurse",
    "Clinical Office",
    "Kitchen"
  ]

  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :inventories_issued)
     |> assign(:filters, default_filters())
     |> assign(:location_options, @location_options)
     |> assign(:per_page, @per_page)
     |> assign(:page, 1)
     |> assign(:total_count, 0)
     |> assign(:total_pages, 0)
     |> assign(:inventories_issued, [])}
  end

  defp default_filters do
    %{
      location: "",
      quantity_min: "",
      quantity_max: "",
      item_search: ""
    }
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Inventory issued")
    |> assign(:inventory_issued, InventoriesIssues.get_inventory_issued!(id))
    |> assign(:prefill_requisition, nil)
    |> assign(:drug_batch_id, nil)
  end

  defp apply_action(socket, :new, params) do
    requisition_id = parse_int_param(params["requisition_id"])
    requisition = requisition_id && Requisitions.get_requisition!(requisition_id)
    drug_batch_id = parse_int_param(params["drug_batch_id"])
    inventory_issued = build_prefilled_inventory_issued(params, requisition, drug_batch_id)

    socket
    |> assign(:page_title, "New Inventory issued")
    |> assign(:inventory_issued, inventory_issued)
    |> assign(:prefill_requisition, requisition)
    |> assign(:drug_batch_id, drug_batch_id)
  end

  defp apply_action(socket, :scan, _params) do
    socket
    |> assign(:page_title, "New Inventory issued")
    |> assign(:inventory_issued, %InventoryIssued{})
    |> assign(:prefill_requisition, nil)
    |> assign(:drug_batch_id, nil)
  end

  defp apply_action(socket, :index, params) do
    filters = filters_from_params(params)
    page = parse_page(params["page"])

    filter_params = %{
      "location" => filters.location,
      "quantity_min" => filters.quantity_min,
      "quantity_max" => filters.quantity_max,
      "item_search" => filters.item_search
    }

    total_count = InventoriesIssues.count_inventories_issued(filter_params)
    total_pages = max(1, div(total_count + @per_page - 1, @per_page))
    page = min(max(1, page), total_pages)

    inventories_issued =
      InventoriesIssues.list_inventories_issued_paginated(filter_params, page, @per_page)

    socket
    |> assign(:page_title, "Inventories Issued")
    |> assign(:inventory_issued, nil)
    |> assign(:filters, filters)
    |> assign(:page, page)
    |> assign(:per_page, @per_page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:inventories_issued, inventories_issued)
    |> assign(:prefill_requisition, nil)
    |> assign(:drug_batch_id, nil)
  end

  defp parse_page(nil), do: 1
  defp parse_page(""), do: 1

  defp parse_page(s) when is_binary(s) do
    case Integer.parse(s) do
      {n, _} -> max(1, n)
      _ -> 1
    end
  end

  defp parse_page(n) when is_integer(n), do: max(1, n)
  defp parse_page(_), do: 1

  defp filters_from_params(params) do
    %{
      location: params["location"] || "",
      quantity_min: params["quantity_min"] || "",
      quantity_max: params["quantity_max"] || "",
      item_search: params["item_search"] || ""
    }
  end

  # The search box and the filter drawer submit independently (two separate
  # <form>s), so a submission from either one only carries its own fields.
  # Merging onto a stringified version of the current filters means a key
  # absent from this submission is left unchanged rather than reset — this
  # also keeps the push_patch URL below reflecting the complete filter set.
  defp stringify_filters(filters) do
    Map.new(filters, fn {key, value} -> {Atom.to_string(key), value || ""} end)
  end

  @impl true
  def handle_event("filter", %{"filters" => filters}, socket) do
    filters = Map.merge(stringify_filters(socket.assigns.filters), filters)
    q = filters_to_query(filters) |> Map.put("page", "1")

    {:noreply,
     push_patch(socket, to: "/inventory_manager/inventories_issued?" <> URI.encode_query(q))}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply, push_patch(socket, to: "/inventory_manager/inventories_issued?page=1")}
  end

  @impl true
  def handle_event("clear_chip", %{"field" => field}, socket) do
    handle_event("filter", %{"filters" => %{field => ""}}, socket)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    inventory_issued = InventoriesIssues.get_inventory_issued!(id)
    {:ok, _} = InventoriesIssues.delete_inventory_issued(inventory_issued)

    q =
      filters_to_query(socket.assigns.filters) |> Map.put("page", to_string(socket.assigns.page))

    {:noreply,
     push_patch(socket, to: "/inventory_manager/inventories_issued?" <> URI.encode_query(q))}
  end

  defp filters_to_query(filters) when is_map(filters) do
    %{}
    |> maybe_put("location", filters[:location] || filters["location"])
    |> maybe_put("quantity_min", filters[:quantity_min] || filters["quantity_min"])
    |> maybe_put("quantity_max", filters[:quantity_max] || filters["quantity_max"])
    |> maybe_put("item_search", filters[:item_search] || filters["item_search"])
  end

  defp filters_to_query(_), do: %{}

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, _key, ""), do: map
  defp maybe_put(map, key, val), do: Map.put(map, key, to_string(val))

  def pagination_path(filters, page) do
    filters_to_query(filters)
    |> Map.put("page", to_string(page))
    |> then(&("/inventory_manager/inventories_issued?" <> URI.encode_query(&1)))
  end

  defp count_active_filters(filters) do
    filters
    |> Map.drop([:item_search])
    |> Map.values()
    |> Enum.count(&(&1 not in [nil, ""]))
  end

  defp filter_chips(filters) do
    [
      filter_chip(filters[:location], "location", filters[:location]),
      filter_chip(filters[:quantity_min], "quantity_min", "Min qty #{filters[:quantity_min]}"),
      filter_chip(filters[:quantity_max], "quantity_max", "Max qty #{filters[:quantity_max]}")
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp build_prefilled_inventory_issued(params, requisition, drug_batch_id) do
    inventory_received_id = parse_int_param(params["inventory_received_id"])
    quantity = parse_int_param(params["quantity"])
    requisition_id = parse_int_param(params["requisition_id"])

    # When issuing from a drug batch (pharmacy stock), use that batch's underlying batch_id
    batch_id =
      if drug_batch_id do
        case DrugBatches.get_drug_batch!(drug_batch_id) do
          %{batch_id: bid} -> bid
          _ -> parse_int_param(params["batch_id"])
        end
      else
        parse_int_param(params["batch_id"])
      end

    assigned_to_id = requisition && requisition.requested_by_id

    location =
      case requisition do
        %{requested_by: %{department: %{name: dept_name}}}
        when dept_name in ["Nursing", "nursing"] ->
          "Nurse"

        _ ->
          nil
      end

    attrs =
      %{}
      |> maybe_put_struct(:batch_id, batch_id)
      |> maybe_put_struct(:inventory_received_id, inventory_received_id)
      |> maybe_put_struct(:quantity, quantity)
      |> maybe_put_struct(:requisition_id, requisition_id)
      |> maybe_put_struct(:assigned_to_id, assigned_to_id)
      |> maybe_put_struct(:location, location)

    struct(InventoryIssued, attrs)
  end

  defp parse_int_param(nil), do: nil
  defp parse_int_param(""), do: nil

  defp parse_int_param(value) when is_binary(value) do
    case Integer.parse(value) do
      {parsed, _} -> parsed
      _ -> nil
    end
  end

  defp parse_int_param(value) when is_integer(value), do: value
  defp parse_int_param(_), do: nil

  defp maybe_put_struct(map, _key, nil), do: map
  defp maybe_put_struct(map, key, value), do: Map.put(map, key, value)
end
