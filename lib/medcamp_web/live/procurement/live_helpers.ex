defmodule MedcampWeb.Procurement.LiveHelpers do
  @moduledoc false

  import Phoenix.Component, only: [assign: 3]

  import Ecto.Query, warn: false

  alias Medcamp.Repo
  alias Medcamp.InventoriesReceived.InventoryReceived
  alias Medcamp.Suppliers.Supplier

  @pipeline_steps [
    :registration,
    :rfq,
    :quote,
    :proforma,
    :purchase_order,
    :invoice,
    :shipment,
    :grn
  ]

  def pipeline_steps, do: @pipeline_steps

  def maybe_assign_current_user(socket, user), do: assign(socket, :current_user, user)

  def decimal(nil), do: Decimal.new(0)
  def decimal(%Decimal{} = value), do: value
  def decimal(value) when is_integer(value), do: Decimal.new(value)
  def decimal(value) when is_float(value), do: Decimal.from_float(value)

  def decimal(value) when is_binary(value) do
    case Decimal.parse(String.trim(value)) do
      {parsed, _rest} -> parsed
      :error -> Decimal.new(0)
    end
  end

  def decimal(_), do: Decimal.new(0)

  def decimal_to_string(value, places \\ 2) do
    value
    |> decimal()
    |> Decimal.round(places)
    |> Decimal.to_string(:normal)
  end

  def money(value), do: "KES #{decimal_to_string(value)}"

  def format_date(nil), do: "TBD"
  def format_date(%Date{} = value), do: Calendar.strftime(value, "%d %b %Y")
  def format_date(value), do: to_string(value)

  def format_datetime(nil), do: "Just now"
  def format_datetime(%NaiveDateTime{} = value), do: Calendar.strftime(value, "%d %b %Y %H:%M")
  def format_datetime(%DateTime{} = value), do: value |> DateTime.to_naive() |> format_datetime()
  def format_datetime(value), do: to_string(value)

  def blank?(nil), do: true
  def blank?(""), do: true
  def blank?(value) when is_binary(value), do: String.trim(value) == ""
  def blank?(value) when is_list(value), do: Enum.empty?(value)
  def blank?(_), do: false

  def present?(value), do: not blank?(value)

  def maybe_join_list(nil), do: ""
  def maybe_join_list(values) when is_list(values), do: Enum.join(values, ", ")
  def maybe_join_list(value), do: to_string(value)

  def prune_blank_values(attrs) do
    Enum.reduce(attrs, %{}, fn
      {_key, value}, acc when value in [nil, ""] -> acc
      {key, value}, acc -> Map.put(acc, key, value)
    end)
  end

  def listify_indexed_params(nil), do: []
  def listify_indexed_params(list) when is_list(list), do: Enum.map(list, &Map.new/1)

  def listify_indexed_params(map) when is_map(map) do
    map
    |> Enum.sort_by(fn {key, _value} -> parse_index(key) end)
    |> Enum.map(fn {_key, value} -> Map.new(value) end)
  end

  def listify_indexed_params(_), do: []

  def search_suppliers(term \\ nil, opts \\ []) do
    status = Keyword.get(opts, :status)
    exclude_ids = MapSet.new(Keyword.get(opts, :exclude_ids, []))

    Supplier
    |> maybe_supplier_status(status)
    |> maybe_supplier_search(term)
    |> order_by([s], asc: s.legal_name, asc: s.name)
    |> limit(20)
    |> Repo.all()
    |> Enum.reject(&MapSet.member?(exclude_ids, &1.id))
  end

  def search_inventory_received(term \\ nil, opts \\ []) do
    exclude_ids = MapSet.new(Keyword.get(opts, :exclude_ids, []))

    InventoryReceived
    |> maybe_inventory_received_search(term)
    |> order_by([ir], desc: ir.inserted_at)
    |> limit(10)
    |> Repo.all()
    |> Repo.preload(:room)
    |> Enum.reject(&MapSet.member?(exclude_ids, &1.id))
  end

  def get_inventory_received(nil), do: nil

  def get_inventory_received(id) do
    case Repo.get(InventoryReceived, id) do
      nil -> nil
      inventory_received -> Repo.preload(inventory_received, :room)
    end
  end

  def resource_path(:supplier, id), do: "/procurement/suppliers/#{id}"
  def resource_path(:invoice, id), do: "/procurement/invoices/#{id}"
  def resource_path(:grn, id), do: "/procurement/grn/#{id}"
  def resource_path(:rfq, id), do: "/procurement/rfqs/#{id}"
  def resource_path(:purchase_order, id), do: "/procurement/purchase-orders/#{id}"
  def resource_path(_, _id), do: "/procurement/dashboard"

  def resource_path(:quote, id, rfq_id), do: "/procurement/quotes/#{rfq_id}?quote_id=#{id}"

  def action_queue_path(%{kind: :supplier, resource_id: id}), do: "/procurement/onboarding/#{id}"
  def action_queue_path(%{kind: :quote, resource_id: id}), do: "/procurement/quotes/#{id}"
  def action_queue_path(%{kind: :invoice, resource_id: id}), do: "/procurement/invoices/#{id}"
  def action_queue_path(%{kind: :grn, resource_id: id}), do: "/procurement/grn/#{id}"
  def action_queue_path(_), do: "/procurement/dashboard"

  def invoice_due_tone(nil), do: "text-slate-500"

  def invoice_due_tone(%Date{} = due_date) do
    days = Date.diff(due_date, Date.utc_today())

    cond do
      days < 0 -> "text-rose-600"
      days <= 7 -> "text-amber-600"
      true -> "text-slate-500"
    end
  end

  def sort_quotes(quotes, "price"),
    do: Enum.sort_by(quotes, fn quote -> Decimal.to_float(decimal(quote.total)) end)

  def sort_quotes(quotes, "lead_time"),
    do: Enum.sort_by(quotes, &(&1.lead_time_days || 9_999))

  def sort_quotes(quotes, _sort_by),
    do: Enum.sort_by(quotes, &(-1 * (&1.score || 0)))

  def grn_item_from_shipment_item(shipment_item) do
    %{
      purchase_order_item_id: shipment_item.purchase_order_item_id,
      inventory_received_id: shipment_item.inventory_received_id,
      position: shipment_item.position,
      description: shipment_item.description,
      po_quantity:
        (shipment_item.purchase_order_item && shipment_item.purchase_order_item.quantity) ||
          Decimal.new(0),
      quantity_received: shipment_item.quantity_shipped || Decimal.new(0),
      variance:
        Decimal.sub(
          (shipment_item.purchase_order_item && shipment_item.purchase_order_item.quantity) ||
            Decimal.new(0),
          shipment_item.quantity_shipped || Decimal.new(0)
        ),
      batch_number: shipment_item.batch_number,
      expiry_date: shipment_item.expiry_date,
      condition: "accepted"
    }
  end

  def normalize_grn_item(item) do
    po_quantity = decimal(Map.get(item, "po_quantity") || Map.get(item, :po_quantity))
    received = decimal(Map.get(item, "quantity_received") || Map.get(item, :quantity_received))

    item
    |> Map.new()
    |> Map.put("po_quantity", po_quantity)
    |> Map.put("quantity_received", received)
    |> Map.put("variance", Decimal.sub(po_quantity, received))
    |> Map.put("condition", Map.get(item, "condition") || Map.get(item, :condition) || "accepted")
  end

  def grn_summary(items) do
    normalized = Enum.map(items, &normalize_grn_item/1)

    accepted = Enum.count(normalized, &(Map.get(&1, "condition") == "accepted"))
    partial = Enum.count(normalized, &(Map.get(&1, "condition") == "partial"))

    quantity =
      Enum.reduce(normalized, Decimal.new(0), fn item, acc ->
        Decimal.add(acc, Map.get(item, "quantity_received"))
      end)

    value =
      Enum.reduce(normalized, Decimal.new(0), fn item, acc ->
        unit_price = decimal(Map.get(item, "unit_price") || Map.get(item, :unit_price))
        Decimal.add(acc, Decimal.mult(Map.get(item, "quantity_received"), unit_price))
      end)

    %{
      accepted: accepted,
      partial: partial,
      quantity: decimal_to_string(quantity),
      value: money(value)
    }
  end

  def has_grn_variances?(items) do
    Enum.any?(items, fn item ->
      normalized = normalize_grn_item(item)
      not Decimal.equal?(Map.get(normalized, "variance"), Decimal.new(0))
    end)
  end

  defp parse_index(key) do
    key
    |> to_string()
    |> Integer.parse()
    |> case do
      {value, _rest} -> value
      :error -> 0
    end
  end

  defp maybe_supplier_status(query, nil), do: query
  defp maybe_supplier_status(query, ""), do: query
  defp maybe_supplier_status(query, status), do: where(query, [s], s.status == ^status)

  defp maybe_supplier_search(query, nil), do: query
  defp maybe_supplier_search(query, ""), do: query

  defp maybe_supplier_search(query, term) do
    search = "%#{String.trim(term)}%"

    where(
      query,
      [s],
      ilike(s.legal_name, ^search) or ilike(s.name, ^search) or ilike(s.reference, ^search) or
        ilike(s.contact_email, ^search)
    )
  end

  defp maybe_inventory_received_search(query, nil), do: query
  defp maybe_inventory_received_search(query, ""), do: query

  defp maybe_inventory_received_search(query, term) do
    trimmed = String.trim(term)

    if trimmed == "" do
      query
    else
      search = "%#{trimmed}%"

      where(
        query,
        [ir],
        ilike(ir.brand_name, ^search) or
          ilike(ir.generic_name, ^search) or
          ilike(ir.description, ^search) or
          ilike(ir.gtin, ^search) or
          ilike(ir.supplier, ^search) or
          ilike(ir.category, ^search)
      )
    end
  end
end
