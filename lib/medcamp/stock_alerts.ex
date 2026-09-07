defmodule Medcamp.StockAlerts do
  @moduledoc """
  Automated stock alert notifications for:
  - Near expiry (≤ 3 months to expiry)
  - Below minimum reorder level
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo
  alias Medcamp.Batches.Batch
  alias Medcamp.DrugBatches.DrugBatch
  alias Medcamp.Drugs.Drug
  alias Medcamp.Inventories.GeneralInventoryItem

  @near_expiry_days 90
  @default_reorder_threshold 20

  @doc """
  Returns all alerts: near-expiry batches and items below reorder level.
  """
  def list_all_alerts do
    %{
      near_expiry: list_near_expiry_batches(),
      below_reorder: list_below_reorder_items()
    }
  end

  @doc """
  Returns batches (drug and inventory) expiring within the next 3 months (≤ 90 days).
  """
  def list_near_expiry_batches do
    today = Date.utc_today()
    cutoff = Date.add(today, @near_expiry_days)

    # Drug batches with batch expiry
    filtered_drug_batches =
      from(db in DrugBatch,
        join: b in assoc(db, :batch),
        where: db.is_active != false and db.remaining_quantity > 0,
        where: not is_nil(b.expiry) and b.expiry != "",
        preload: [batch: b, drug: :inventory_received]
      )
      |> Repo.all()
      |> Enum.filter(fn db ->
        case parse_expiry_date(db.batch.expiry) do
          {:ok, expiry_date} ->
            Date.compare(expiry_date, today) != :lt and
              (Date.compare(expiry_date, cutoff) == :lt or
                 Date.compare(expiry_date, cutoff) == :eq)

          _ ->
            false
        end
      end)

    drug_batch_ids = Enum.map(filtered_drug_batches, fn db -> db.batch.id end)

    drug_batches =
      Enum.map(filtered_drug_batches, fn db ->
        days = days_to_expiry(db.batch.expiry)

        item_name =
          db.drug.brand_name ||
            (db.drug.inventory_received && db.drug.inventory_received.brand_name) ||
            db.drug.generic_name ||
            "Unknown"

        %{
          type: :drug_batch,
          id: db.id,
          batch_number: db.batch.batch,
          expiry: db.batch.expiry,
          days_to_expiry: days,
          remaining_quantity: db.remaining_quantity,
          item_name: item_name
        }
      end)

    # Inventory batches (Batch not used by DrugBatch - e.g. non-drug inventory)
    inventory_batches =
      from(b in Batch,
        where: b.remaining_quantity > 0,
        where: not is_nil(b.expiry) and b.expiry != "",
        preload: [:inventory_received]
      )
      |> Repo.all()
      |> Enum.filter(fn b ->
        case parse_expiry_date(b.expiry) do
          {:ok, expiry_date} ->
            Date.compare(expiry_date, today) != :lt and
              (Date.compare(expiry_date, cutoff) == :lt or
                 Date.compare(expiry_date, cutoff) == :eq)

          _ ->
            false
        end
      end)
      |> Enum.reject(fn b -> b.id in drug_batch_ids end)
      |> Enum.map(fn b ->
        days = days_to_expiry(b.expiry)

        %{
          type: :inventory_batch,
          id: b.id,
          batch_number: b.batch,
          expiry: b.expiry,
          days_to_expiry: days,
          remaining_quantity: b.remaining_quantity,
          item_name:
            (b.inventory_received &&
               (b.inventory_received.brand_name || b.inventory_received.generic_name)) ||
              "Unknown"
        }
      end)

    drug_batches ++ inventory_batches
  end

  @doc """
  Returns items below minimum reorder level:
  - Drugs: total stock (sum of drug_batches) < 20
  - General inventory items: current_quantity < reorder_level
  """
  def list_below_reorder_items do
    drug_alerts = list_drugs_below_reorder()
    general_inventory_alerts = list_general_inventory_below_reorder()

    drug_alerts ++ general_inventory_alerts
  end

  defp list_drugs_below_reorder do
    from(d in Drug,
      left_join: ir in assoc(d, :inventory_received),
      preload: [:inventory_received, drug_batches: :batch]
    )
    |> Repo.all()
    |> Enum.filter(fn drug ->
      total = Enum.sum(Enum.map(drug.drug_batches || [], fn db -> db.remaining_quantity || 0 end))
      total > 0 and total < @default_reorder_threshold
    end)
    |> Enum.map(fn drug ->
      total = Enum.sum(Enum.map(drug.drug_batches || [], fn db -> db.remaining_quantity || 0 end))

      %{
        type: :drug,
        id: drug.id,
        item_name:
          drug.brand_name || drug.inventory_received.brand_name || drug.generic_name || "Unknown",
        current_quantity: total,
        reorder_level: @default_reorder_threshold
      }
    end)
  end

  defp list_general_inventory_below_reorder do
    from(i in GeneralInventoryItem,
      where: not is_nil(i.reorder_level)
    )
    |> Repo.all()
    |> Enum.filter(fn item ->
      current =
        (item.current_quantity && Decimal.to_integer(Decimal.round(item.current_quantity))) || 0

      reorder = (item.reorder_level && Decimal.to_integer(Decimal.round(item.reorder_level))) || 0
      current < reorder
    end)
    |> Enum.map(fn item ->
      current =
        (item.current_quantity && Decimal.to_integer(Decimal.round(item.current_quantity))) || 0

      reorder = (item.reorder_level && Decimal.to_integer(Decimal.round(item.reorder_level))) || 0

      %{
        type: :general_inventory,
        id: item.id,
        item_name: item.name || "Unknown",
        current_quantity: current,
        reorder_level: reorder,
        unit: item.unit_of_measure
      }
    end)
  end

  defp parse_expiry_date(nil), do: {:error, nil}
  defp parse_expiry_date(""), do: {:error, :empty}

  defp parse_expiry_date(expiry_string) when is_binary(expiry_string) do
    case Date.from_iso8601(expiry_string) do
      {:ok, date} ->
        {:ok, date}

      {:error, _} ->
        case Timex.parse(expiry_string, "{D}/{M}/{YYYY}") do
          {:ok, dt} ->
            {:ok, Timex.to_date(dt)}

          {:error, _} ->
            case Timex.parse(expiry_string, "{M}/{D}/{YYYY}") do
              {:ok, dt} -> {:ok, Timex.to_date(dt)}
              {:error, _} -> {:error, :invalid_format}
            end
        end
    end
  end

  defp parse_expiry_date(_), do: {:error, :invalid}

  defp days_to_expiry(expiry_string) do
    case parse_expiry_date(expiry_string) do
      {:ok, expiry_date} -> Date.diff(expiry_date, Date.utc_today())
      _ -> nil
    end
  end

  @doc """
  Public helper: days until expiry. Accepts string (e.g. ISO or "D/M/YYYY") or a Date.
  Returns nil if invalid or already expired.
  """
  def days_to_expiry_public(expiry) when is_struct(expiry, Date) do
    if Date.compare(expiry, Date.utc_today()) in [:gt, :eq] do
      Date.diff(expiry, Date.utc_today())
    else
      nil
    end
  end

  def days_to_expiry_public(expiry) when is_binary(expiry) do
    case parse_expiry_date(expiry) do
      {:ok, expiry_date} ->
        if Date.compare(expiry_date, Date.utc_today()) in [:gt, :eq] do
          Date.diff(expiry_date, Date.utc_today())
        else
          nil
        end

      _ ->
        nil
    end
  end

  def days_to_expiry_public(_), do: nil

  @doc "True if expiry (string or Date) is within the next `within_days` days (default 90)."
  def near_expiry?(expiry, within_days \\ @near_expiry_days)
  def near_expiry?(nil, _), do: false

  def near_expiry?(expiry, within_days) when is_struct(expiry, Date) do
    days = days_to_expiry_public(expiry)
    days != nil and days <= within_days
  end

  def near_expiry?(expiry, within_days) when is_binary(expiry) do
    days = days_to_expiry_public(expiry)
    days != nil and days <= within_days
  end

  def near_expiry?(_, _), do: false

  @doc "Total count of all alerts"
  def alert_count do
    alerts = list_all_alerts()
    length(alerts.near_expiry) + length(alerts.below_reorder)
  end
end
