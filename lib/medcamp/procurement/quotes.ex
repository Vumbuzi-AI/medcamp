defmodule Medcamp.Procurement.Quotes do
  @moduledoc """
  Quote submission, acceptance (cascades rejections within the RFQ), scoring.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo
  alias Ecto.Multi

  alias Medcamp.Procurement.{
    Quote,
    QuoteItem,
    Rfq,
    References,
    Notifications
  }

  alias Medcamp.Suppliers.Supplier
  alias Medcamp.Accounts.User

  @pubsub Medcamp.PubSub

  # Scoring weights per spec
  @weight_price 50
  @weight_lead_time 20
  @weight_compliance 30

  # ---------------------------------------------------------------------------
  # Queries
  # ---------------------------------------------------------------------------

  def list_quotes(opts \\ []) do
    Quote
    |> maybe_filter(:rfq_id, Keyword.get(opts, :rfq_id))
    |> maybe_filter(:supplier_id, Keyword.get(opts, :supplier_id))
    |> maybe_filter(:status, Keyword.get(opts, :status))
    |> order_by([q], desc: q.inserted_at)
    |> Repo.all()
  end

  def get_quote!(id) do
    Quote
    |> Repo.get!(id)
    |> Repo.preload([:rfq, :supplier, items: :rfq_item])
  end

  def get_quote(id) do
    case Repo.get(Quote, id) do
      nil -> nil
      quote -> Repo.preload(quote, [:rfq, :supplier, items: :rfq_item])
    end
  end

  def list_for_rfq(rfq_id) do
    from(q in Quote,
      where: q.rfq_id == ^rfq_id,
      preload: [:supplier, items: :rfq_item]
    )
    |> Repo.all()
  end

  defp maybe_filter(query, _field, nil), do: query
  defp maybe_filter(query, field, value), do: where(query, [q], field(q, ^field) == ^value)

  # ---------------------------------------------------------------------------
  # Submit
  # ---------------------------------------------------------------------------

  @doc """
  Create or update a quote and transition to `submitted`.

  `attrs` may include `items: [%{rfq_item_id, quantity_available, unit_price, ...}, ...]`.
  Totals are computed server-side from items.
  """
  def submit(attrs) do
    {items, attrs} = pop_items(attrs)

    attrs =
      attrs
      |> Map.new()
      |> Map.put_new(:reference, References.next_quote_reference())
      |> Map.put_new(:quote_date, Date.utc_today())
      |> Map.put(:status, "submitted")
      |> put_totals(items)

    Multi.new()
    |> Multi.insert(:quote, Quote.changeset(%Quote{}, attrs))
    |> Multi.run(:items, fn _repo, %{quote: q} -> insert_items(q.id, items) end)
    |> Multi.run(:compliance, fn _repo, %{quote: q} ->
      score = compute_compliance_for_supplier(q.supplier_id)

      q
      |> Quote.changeset(%{compliance_score: score})
      |> Repo.update()
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{compliance: q}} ->
        quote_full = Repo.preload(q, [:rfq, :supplier, items: :rfq_item])
        broadcast_all({:quote_submitted, quote_full})
        notify_procurement_team(quote_full)
        {:ok, quote_full}

      {:error, _op, reason, _} ->
        {:error, reason}
    end
  end

  defp pop_items(attrs) do
    attrs = Map.new(attrs)
    items = Map.get(attrs, :items) || Map.get(attrs, "items")
    {items, Map.drop(attrs, [:items, "items"])}
  end

  defp put_totals(attrs, items) when is_list(items) do
    subtotal =
      Enum.reduce(items, Decimal.new(0), fn item, acc ->
        item = Map.new(item)
        qty = decimal(Map.get(item, :quantity_available) || Map.get(item, "quantity_available"))
        price = decimal(Map.get(item, :unit_price) || Map.get(item, "unit_price"))
        Decimal.add(acc, Decimal.mult(qty, price))
      end)

    vat_rate = decimal(Map.get(attrs, :vat_rate) || Map.get(attrs, "vat_rate") || "0.16")
    vat_amount = Decimal.mult(subtotal, vat_rate)
    total = Decimal.add(subtotal, vat_amount)

    attrs
    |> Map.put(:subtotal, subtotal)
    |> Map.put(:vat_amount, vat_amount)
    |> Map.put(:total, total)
    |> Map.put_new(:vat_rate, vat_rate)
  end

  defp put_totals(attrs, _items), do: attrs

  defp insert_items(_quote_id, nil), do: {:ok, []}

  defp insert_items(quote_id, items) when is_list(items) do
    Enum.reduce_while(Enum.with_index(items, 1), {:ok, []}, fn {item, idx}, {:ok, acc} ->
      attrs =
        item
        |> Map.new()
        |> Map.put(:quote_id, quote_id)
        |> Map.put_new(:position, idx)
        |> compute_item_total()

      %QuoteItem{}
      |> QuoteItem.changeset(attrs)
      |> Repo.insert()
      |> case do
        {:ok, rec} -> {:cont, {:ok, [rec | acc]}}
        {:error, cs} -> {:halt, {:error, cs}}
      end
    end)
  end

  defp compute_item_total(attrs) do
    qty = decimal(Map.get(attrs, :quantity_available) || Map.get(attrs, "quantity_available"))
    price = decimal(Map.get(attrs, :unit_price) || Map.get(attrs, "unit_price"))
    Map.put(attrs, :total, Decimal.mult(qty, price))
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

  # ---------------------------------------------------------------------------
  # Accept / Reject
  # ---------------------------------------------------------------------------

  @doc """
  Accepts the quote, rejects every other quote for the same RFQ, closes the RFQ.
  """
  def accept(%Quote{} = quote, %User{} = _user) do
    Multi.new()
    |> Multi.update(:accepted, Quote.changeset(quote, %{status: "accepted"}))
    |> Multi.run(:reject_others, fn _repo, %{accepted: accepted} ->
      {count, _} =
        from(q in Quote,
          where: q.rfq_id == ^accepted.rfq_id and q.id != ^accepted.id
        )
        |> Repo.update_all(set: [status: "rejected", updated_at: now()])

      {:ok, count}
    end)
    |> Multi.run(:close_rfq, fn _repo, %{accepted: accepted} ->
      Repo.get!(Rfq, accepted.rfq_id)
      |> Rfq.changeset(%{status: "closed"})
      |> Repo.update()
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{accepted: q}} ->
        full = Repo.preload(q, [:rfq, :supplier, items: :rfq_item])
        broadcast_all({:quote_accepted, full})
        broadcast_supplier(full.supplier_id, {:quote_accepted, full})

        notify_supplier_users(full.supplier_id, "quote_received", %{
          title: "Quote accepted",
          body: "Your quote #{full.reference} has been accepted.",
          resource_type: "quote",
          resource_id: full.id
        })

        {:ok, full}

      {:error, _op, reason, _} ->
        {:error, reason}
    end
  end

  def reject(%Quote{} = quote, reason) when is_binary(reason) or is_nil(reason) do
    quote
    |> Quote.changeset(%{status: "rejected"})
    |> Repo.update()
    |> case do
      {:ok, q} ->
        broadcast_all({:quote_rejected, q})
        broadcast_supplier(q.supplier_id, {:quote_rejected, q})
        {:ok, q}

      error ->
        error
    end
  end

  # ---------------------------------------------------------------------------
  # Comparison & scoring
  # ---------------------------------------------------------------------------

  @doc """
  Returns the RFQ's quotes sorted by composite score (desc) with `:score` assigned.
  """
  def compare_for_rfq(rfq_id) do
    quotes = list_for_rfq(rfq_id)

    if quotes == [] do
      []
    else
      prices = Enum.map(quotes, & &1.total) |> Enum.reject(&is_nil/1)
      leads = Enum.map(quotes, & &1.lead_time_days) |> Enum.reject(&is_nil/1)
      best_price = min_or_zero(prices)
      best_lead = min_or_zero_int(leads)

      quotes
      |> Enum.map(fn q -> {q, compute_score(q, best_price, best_lead)} end)
      |> Enum.sort_by(fn {_q, score} -> -score end)
      |> Enum.map(fn {q, score} -> Map.put(q, :score, score) end)
    end
  end

  @doc """
  Score a quote against the RFQ's best price and best lead time.
  Weights: price 50 / lead_time 20 / compliance 30.
  """
  def compute_score(%Quote{} = quote, best_price, best_lead) do
    price_score = ratio_score(best_price, quote.total) * @weight_price
    lead_score = ratio_score_int(best_lead, quote.lead_time_days) * @weight_lead_time
    compliance_score = (quote.compliance_score || 0) / 100 * @weight_compliance
    round(price_score + lead_score + compliance_score)
  end

  @doc """
  Convenience: compute score for a standalone quote using itself as the baseline.
  """
  def compute_score(%Quote{} = quote) do
    compute_score(quote, quote.total, quote.lead_time_days)
  end

  defp ratio_score(nil, _), do: 0.0
  defp ratio_score(_, nil), do: 0.0

  defp ratio_score(%Decimal{} = best, %Decimal{} = actual) do
    if Decimal.equal?(actual, 0), do: 0.0, else: Decimal.to_float(Decimal.div(best, actual))
  end

  defp ratio_score_int(nil, _), do: 0.0
  defp ratio_score_int(_, nil), do: 0.0
  defp ratio_score_int(_, 0), do: 0.0
  defp ratio_score_int(best, actual), do: best / actual

  defp min_or_zero([]), do: nil

  defp min_or_zero(list),
    do: Enum.min_by(list, fn d -> Decimal.to_float(d) end, fn -> nil end)

  defp min_or_zero_int([]), do: nil
  defp min_or_zero_int(list), do: Enum.min(list)

  defp compute_compliance_for_supplier(supplier_id) do
    case Repo.get(Supplier, supplier_id) do
      nil ->
        0

      supplier ->
        supplier.compliance_score ||
          Medcamp.Procurement.Suppliers.compute_compliance_score(supplier)
    end
  end

  # ---------------------------------------------------------------------------
  # PubSub / notifications
  # ---------------------------------------------------------------------------

  defp broadcast_all(msg), do: Phoenix.PubSub.broadcast(@pubsub, "procurement:all", msg)

  defp broadcast_supplier(supplier_id, msg),
    do: Phoenix.PubSub.broadcast(@pubsub, "supplier:#{supplier_id}", msg)

  defp notify_procurement_team(%Quote{} = q) do
    user_ids =
      from(u in User,
        where: u.role in ["procurement_officer", "stores_officer", "finance_officer", "admin"],
        select: u.id
      )
      |> Repo.all()

    Enum.each(user_ids, fn uid ->
      Notifications.notify(uid, "quote_received", %{
        title: "Quote received: #{q.reference}",
        body: "A supplier has submitted a quote.",
        resource_type: "quote",
        resource_id: q.id
      })
    end)
  end

  defp notify_supplier_users(supplier_id, type, attrs) do
    user_ids =
      from(u in User, where: u.supplier_id == ^supplier_id, select: u.id)
      |> Repo.all()

    Enum.each(user_ids, fn uid -> Notifications.notify(uid, type, attrs) end)
  end

  defp now, do: DateTime.utc_now() |> DateTime.truncate(:second)
end
