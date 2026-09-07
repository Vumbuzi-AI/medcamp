defmodule Medcamp.Procurement.ProformaInvoices do
  @moduledoc """
  Proforma invoice lifecycle: create_from_quote → submit → accept/reject.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo
  alias Ecto.Multi

  alias Medcamp.Procurement.{
    ProformaInvoice,
    ProformaInvoiceItem,
    Quote,
    References
  }

  @pubsub Medcamp.PubSub

  def list_proforma_invoices(opts \\ []) do
    ProformaInvoice
    |> maybe_filter(:supplier_id, Keyword.get(opts, :supplier_id))
    |> maybe_filter(:status, Keyword.get(opts, :status))
    |> order_by([p], desc: p.inserted_at)
    |> Repo.all()
  end

  def get_proforma_invoice!(id) do
    ProformaInvoice
    |> Repo.get!(id)
    |> Repo.preload([:quote, :supplier, items: :rfq_item])
  end

  def get_proforma_invoice(id) do
    case Repo.get(ProformaInvoice, id) do
      nil -> nil
      pi -> Repo.preload(pi, [:quote, :supplier, items: :rfq_item])
    end
  end

  defp maybe_filter(query, _field, nil), do: query
  defp maybe_filter(query, field, value), do: where(query, [q], field(q, ^field) == ^value)

  @doc """
  Pre-populates a proforma invoice from an accepted quote. Items mirror quote items.
  """
  def create_from_quote(%Quote{} = quote, attrs \\ %{}) do
    quote = Repo.preload(quote, [:supplier, items: :rfq_item])

    base_attrs =
      %{
        reference: References.next_proforma_invoice_reference(),
        quote_id: quote.id,
        supplier_id: quote.supplier_id,
        pi_date: Date.utc_today(),
        currency: "KES",
        status: "draft",
        subtotal: quote.subtotal,
        vat_amount: quote.vat_amount,
        total: quote.total
      }
      |> Map.merge(Map.new(attrs))

    items =
      Enum.map(quote.items, fn qi ->
        %{
          rfq_item_id: qi.rfq_item_id,
          inventory_received_id:
            qi.inventory_received_id || (qi.rfq_item && qi.rfq_item.inventory_received_id),
          position: qi.position,
          description: qi.rfq_item && qi.rfq_item.description,
          unit: qi.unit,
          quantity: qi.quantity_available,
          unit_price: qi.unit_price,
          total: qi.total
        }
      end)

    Multi.new()
    |> Multi.insert(:pi, ProformaInvoice.changeset(%ProformaInvoice{}, base_attrs))
    |> Multi.run(:items, fn _repo, %{pi: pi} -> insert_items(pi.id, items) end)
    |> Repo.transaction()
    |> case do
      {:ok, %{pi: pi}} -> {:ok, Repo.preload(pi, items: :rfq_item)}
      {:error, _op, reason, _} -> {:error, reason}
    end
  end

  @doc """
  Updates a proforma invoice (typically with line-item discounts) and recomputes totals.
  """
  def update(%ProformaInvoice{} = pi, attrs) do
    {items, attrs} = pop_items(attrs)

    Multi.new()
    |> Multi.update(:pi, ProformaInvoice.changeset(pi, attrs))
    |> Multi.run(:items, fn _repo, %{pi: pi} ->
      if is_nil(items) do
        {:ok, []}
      else
        Repo.delete_all(from i in ProformaInvoiceItem, where: i.proforma_invoice_id == ^pi.id)
        insert_items(pi.id, items)
      end
    end)
    |> Multi.run(:totals, fn _repo, %{pi: pi} -> recalculate_totals(pi) end)
    |> Repo.transaction()
    |> case do
      {:ok, %{totals: pi}} -> {:ok, Repo.preload(pi, items: :rfq_item, force: true)}
      {:error, _op, reason, _} -> {:error, reason}
    end
  end

  defp pop_items(attrs) do
    attrs = Map.new(attrs)
    items = Map.get(attrs, :items) || Map.get(attrs, "items")
    {items, Map.drop(attrs, [:items, "items"])}
  end

  defp insert_items(_pi_id, nil), do: {:ok, []}

  defp insert_items(pi_id, items) do
    Enum.reduce_while(Enum.with_index(items, 1), {:ok, []}, fn {item, idx}, {:ok, acc} ->
      attrs =
        item
        |> Map.new()
        |> Map.put(:proforma_invoice_id, pi_id)
        |> Map.put_new(:position, idx)
        |> compute_line_total()

      %ProformaInvoiceItem{}
      |> ProformaInvoiceItem.changeset(attrs)
      |> Repo.insert()
      |> case do
        {:ok, rec} -> {:cont, {:ok, [rec | acc]}}
        {:error, cs} -> {:halt, {:error, cs}}
      end
    end)
  end

  defp compute_line_total(attrs) do
    qty = decimal(Map.get(attrs, :quantity) || Map.get(attrs, "quantity"))
    price = decimal(Map.get(attrs, :unit_price) || Map.get(attrs, "unit_price"))
    gross = Decimal.mult(qty, price)

    discount_pct =
      decimal(Map.get(attrs, :discount_percent) || Map.get(attrs, "discount_percent"))

    discount_fixed =
      decimal(Map.get(attrs, :discount_amount) || Map.get(attrs, "discount_amount"))

    discount_from_pct = Decimal.mult(gross, Decimal.div(discount_pct, Decimal.new(100)))
    discount = Decimal.add(discount_from_pct, discount_fixed)

    net = Decimal.sub(gross, discount)
    Map.put(attrs, :total, net)
  end

  defp recalculate_totals(%ProformaInvoice{} = pi) do
    items = Repo.all(from i in ProformaInvoiceItem, where: i.proforma_invoice_id == ^pi.id)

    subtotal =
      Enum.reduce(items, Decimal.new(0), fn i, acc ->
        Decimal.add(acc, i.total || Decimal.new(0))
      end)

    discount_total =
      Enum.reduce(items, Decimal.new(0), fn i, acc ->
        Decimal.add(acc, i.discount_amount || Decimal.new(0))
      end)

    vat_amount = Decimal.mult(subtotal, Decimal.new("0.16"))
    total = Decimal.add(subtotal, vat_amount)

    pi
    |> ProformaInvoice.changeset(%{
      subtotal: subtotal,
      discount_amount: discount_total,
      vat_amount: vat_amount,
      total: total
    })
    |> Repo.update()
  end

  def submit(%ProformaInvoice{} = pi) do
    pi
    |> ProformaInvoice.changeset(%{status: "submitted"})
    |> Repo.update()
    |> case do
      {:ok, updated} ->
        broadcast_all({:proforma_submitted, updated})
        {:ok, updated}

      error ->
        error
    end
  end

  def accept(%ProformaInvoice{} = pi, _user) do
    pi
    |> ProformaInvoice.changeset(%{status: "accepted"})
    |> Repo.update()
    |> case do
      {:ok, updated} ->
        broadcast_all({:proforma_accepted, updated})
        broadcast_supplier(updated.supplier_id, {:proforma_accepted, updated})
        {:ok, updated}

      error ->
        error
    end
  end

  def reject(%ProformaInvoice{} = pi, _user) do
    pi
    |> ProformaInvoice.changeset(%{status: "rejected"})
    |> Repo.update()
    |> case do
      {:ok, updated} ->
        broadcast_all({:proforma_rejected, updated})
        broadcast_supplier(updated.supplier_id, {:proforma_rejected, updated})
        {:ok, updated}

      error ->
        error
    end
  end

  defp decimal(nil), do: Decimal.new(0)
  defp decimal(%Decimal{} = d), do: d
  defp decimal(n) when is_integer(n), do: Decimal.new(n)
  defp decimal(n) when is_float(n), do: Decimal.from_float(n)

  defp decimal(s) when is_binary(s) do
    case Decimal.parse(s) do
      {d, _} -> d
      :error -> Decimal.new(0)
    end
  end

  defp broadcast_all(msg), do: Phoenix.PubSub.broadcast(@pubsub, "procurement:all", msg)

  defp broadcast_supplier(supplier_id, msg),
    do: Phoenix.PubSub.broadcast(@pubsub, "supplier:#{supplier_id}", msg)
end
