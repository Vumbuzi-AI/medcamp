defmodule Medcamp.ConsumptionAnalysis do
  @moduledoc """
  Periodic consumption analysis for pharmaceuticals and non-pharmaceuticals.
  Pharmaceuticals: from drugs_given (dispensed drugs).
  Non-pharmaceuticals: from inventories_issued (items allocated to departments).
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo
  alias Medcamp.DrugsGiven.DrugGiven

  @periods ~w(all_time weekly monthly quarterly yearly custom)
  @categories ~w(pharmaceuticals non_pharmaceuticals both)

  def periods, do: @periods
  def categories, do: @categories

  @doc """
  Returns consumption analysis for the given period and category.
  Results are sorted by total quantity consumed (most to least).

  ## Options
  - :period - "all_time" | "weekly" | "monthly" | "quarterly"
  - :category - "pharmaceuticals" | "non_pharmaceuticals" | "both"
  - :date - Date to anchor the period (default: today); ignored for "all_time"
  - :search - filter by drug brand/generic name or GTIN

  ## Returns
  List of maps with :brand_name, :generic_name, :gtin, :total_quantity,
  :total_sold_amount, :average_unit_price, :category, :rank
  """
  def consumption_analysis(opts \\ []) do
    period = Keyword.get(opts, :period, "monthly")
    category = Keyword.get(opts, :category, "both")
    anchor_date = Keyword.get(opts, :date, Date.utc_today())
    date_from = Keyword.get(opts, :date_from)
    date_to = Keyword.get(opts, :date_to)
    search = Keyword.get(opts, :search, "") |> to_string() |> String.trim()

    date_range =
      cond do
        period == "all_time" ->
          nil

        period == "custom" and not is_nil(date_from) and not is_nil(date_to) ->
          {date_from, date_to}

        period == "custom" ->
          nil

        true ->
          date_range_for_period(period, anchor_date)
      end

    pharmaceuticals =
      if category in ["pharmaceuticals", "both"] do
        pharmaceuticals_consumption(date_range, search)
      else
        []
      end

    non_pharmaceuticals =
      if category in ["non_pharmaceuticals", "both"] do
        non_pharmaceuticals_consumption(date_range, search)
      else
        []
      end

    combined =
      if category == "both" do
        merge_by_item(pharmaceuticals, non_pharmaceuticals)
      else
        pharmaceuticals ++ non_pharmaceuticals
      end

    combined
    |> Enum.sort_by(& &1.total_quantity, :desc)
    |> Enum.with_index(1)
    |> Enum.map(fn {item, rank} -> Map.put(item, :rank, rank) end)
  end

  defp merge_by_item(pharma, non_pharma) do
    all = pharma ++ non_pharma

    all
    |> Enum.group_by(&{&1.brand_name, &1.generic_name, &1.gtin})
    |> Enum.map(fn {{brand, generic, gtin}, items} ->
      total_quantity = items |> Enum.map(& &1.total_quantity) |> Enum.sum()
      sold_amounts = items |> Enum.map(& &1.total_sold_amount) |> Enum.reject(&is_nil/1)
      total_sold_amount = if sold_amounts == [], do: nil, else: Enum.sum(sold_amounts)

      %{
        brand_name: brand,
        generic_name: generic,
        gtin: gtin,
        total_quantity: total_quantity,
        total_sold_amount: total_sold_amount,
        average_unit_price: average_unit_price(total_sold_amount, total_quantity),
        category: :both
      }
    end)
  end

  defp date_range_for_period("weekly", anchor) do
    week_start = Date.beginning_of_week(anchor, :sunday)
    week_end = Date.add(week_start, 6)
    {week_start, week_end}
  end

  defp date_range_for_period("monthly", anchor) do
    month_start = Date.beginning_of_month(anchor)
    month_end = Date.end_of_month(anchor)
    {month_start, month_end}
  end

  defp date_range_for_period("quarterly", anchor) do
    {year, month, _} = Date.to_erl(anchor)
    quarter_month = ((month - 1) |> div(3) |> Kernel.*(3)) + 1
    quarter_start = Date.from_erl!({year, quarter_month, 1})
    quarter_end = Date.end_of_month(Date.add(quarter_start, 2))
    {quarter_start, quarter_end}
  end

  defp date_range_for_period("yearly", anchor) do
    year_start = Date.new!(anchor.year, 1, 1)
    year_end = Date.new!(anchor.year, 12, 31)
    {year_start, year_end}
  end

  defp date_range_for_period(_, anchor), do: date_range_for_period("monthly", anchor)

  # date_range is either {from_date, to_date} or nil (all time)
  defp pharmaceuticals_consumption(date_range, search) do
    base =
      from(dg in DrugGiven,
        join: d in assoc(dg, :drug),
        join: ir in assoc(d, :inventory_received),
        group_by: [ir.id, ir.brand_name, ir.generic_name, ir.gtin],
        select: {
          ir.id,
          ir.brand_name,
          ir.generic_name,
          ir.gtin,
          sum(dg.quantity),
          sum(dg.price)
        }
      )

    base =
      case date_range do
        {from_date, to_date} ->
          from_datetime = DateTime.new!(from_date, ~T[00:00:00], "Etc/UTC")
          to_datetime = DateTime.new!(Date.add(to_date, 1), ~T[00:00:00], "Etc/UTC")

          from([dg, _d, _ir] in base,
            where: dg.inserted_at >= ^from_datetime and dg.inserted_at < ^to_datetime
          )

        nil ->
          base
      end

    query =
      if search != "" do
        term = "%#{search}%"

        from([_dg, _d, ir] in base,
          where:
            ilike(ir.brand_name, ^term) or
              ilike(ir.generic_name, ^term) or
              ilike(ir.gtin, ^term)
        )
      else
        base
      end

    query
    |> Repo.all()
    |> Enum.map(fn {_id, brand, generic, gtin, total_quantity, total_sold_amount} ->
      %{
        brand_name: brand,
        generic_name: generic,
        gtin: gtin,
        total_quantity: total_quantity || 0,
        total_sold_amount: total_sold_amount || 0,
        average_unit_price: average_unit_price(total_sold_amount, total_quantity),
        category: :pharmaceuticals
      }
    end)
  end

  defp average_unit_price(nil, _quantity), do: nil
  defp average_unit_price(_amount, nil), do: nil
  defp average_unit_price(_amount, 0), do: nil
  defp average_unit_price(amount, quantity), do: amount / quantity
end
