defmodule Medcamp.ExpiryFilter do
  @moduledoc """
  The one expiry filter shared by every listing that shows inventory items
  (drugs, batches, in-store items, inventories received, lab/nursing
  allocations), so "filter by expiry" means the same thing and offers the same
  options everywhere: a preset status plus an optional custom from/to range.

  A status is a plain string (`""` means "no preset"), which is what a
  `<select>` submits and what a URL param carries, so it needs no atom
  conversion at the boundary. `bounds/3` folds a status and a custom range into
  a single inclusive `{from, to}` pair of ISO date strings — the shape the
  contexts' existing `expiry_from`/`expiry_to` filters already take — so a
  context supports both by translating them into that one range rather than
  growing a second set of date predicates. Status and custom range intersect
  (both narrow the result) rather than one overriding the other.
  `matches?/4` is the equivalent for lists already loaded in memory.

  Rows with a missing or unparseable expiry match no filter other than the
  empty one: an unknown expiry is not evidence that stock is safe to use.
  """

  @soon_days 30
  @horizon_days 90

  @options [
    {"", "All"},
    {"expired", "Expired"},
    {"expiring_30", "Expiring in #{@soon_days} days"},
    {"expiring_90", "Expiring in #{@horizon_days} days"},
    {"not_expired", "Not expired"}
  ]

  @statuses Enum.map(@options, fn {value, _label} -> value end)

  @doc """
  `{value, label}` pairs for the expiry `<select>`, including the blank "All"
  entry.
  """
  def options, do: @options

  @doc "All valid status values, including `\"\"`."
  def statuses, do: @statuses

  @doc """
  Coerces anything arriving from a form, URL param or socket assign into a
  valid status, falling back to `""` (no preset) for unknown values.
  """
  def normalize(nil), do: ""
  def normalize(value) when value in @statuses, do: value
  def normalize(value) when is_atom(value), do: normalize(Atom.to_string(value))
  def normalize(_), do: ""

  @doc """
  Human-readable label for a status, for filter chips and blank states.
  """
  def label(status) do
    case Enum.find(@options, fn {value, _label} -> value == normalize(status) end) do
      {_value, label} -> label
      nil -> ""
    end
  end

  @doc """
  Translates a preset status into an inclusive `{from, to}` range of ISO date
  strings, either side being `nil` when that end is unbounded. `{nil, nil}`
  means the status does not restrict anything (`""` / unknown).

      iex> Medcamp.ExpiryFilter.to_range("expired", ~D[2026-07-28])
      {nil, "2026-07-27"}

      iex> Medcamp.ExpiryFilter.to_range("expiring_30", ~D[2026-07-28])
      {"2026-07-28", "2026-08-27"}
  """
  def to_range(status, today \\ Date.utc_today()) do
    case normalize(status) do
      "expired" -> {nil, iso(Date.add(today, -1))}
      "expiring_30" -> {iso(today), iso(Date.add(today, @soon_days - 1))}
      "expiring_90" -> {iso(today), iso(Date.add(today, @horizon_days - 1))}
      "not_expired" -> {iso(today), nil}
      _ -> {nil, nil}
    end
  end

  @doc """
  Folds a preset status and a user-typed `from`/`to` range into the single
  inclusive `{from, to}` range of ISO date strings that both imply — the
  narrower of the two on each end, so a custom date can only tighten a preset,
  never widen it. Blank and unparseable dates are ignored.

      iex> Medcamp.ExpiryFilter.bounds("not_expired", "", "2026-12-31", ~D[2026-07-28])
      {"2026-07-28", "2026-12-31"}

      iex> Medcamp.ExpiryFilter.bounds("", "2026-01-01", "", ~D[2026-07-28])
      {"2026-01-01", nil}
  """
  def bounds(status, from, to, today \\ Date.utc_today()) do
    {status_from, status_to} = to_range(status, today)

    {
      later_of(status_from, iso_or_nil(from)),
      earlier_of(status_to, iso_or_nil(to))
    }
  end

  @doc """
  Whether a single expiry value satisfies the status and custom range, for
  lists filtered in memory. Accepts a `Date`, an ISO (or `D/M/YYYY`) string, or
  `nil` as the expiry.
  """
  def matches?(expiry, status, from \\ nil, to \\ nil) do
    case bounds(status, from, to) do
      {nil, nil} ->
        true

      range ->
        case parse(expiry) do
          {:ok, date} -> within?(date, range)
          {:error, _reason} -> false
        end
    end
  end

  @doc """
  Parses an expiry value into `{:ok, %Date{}}`, tolerating the non-ISO formats
  that have made it into `batches.expiry` (a string column).
  """
  def parse(%Date{} = date), do: {:ok, date}
  def parse(nil), do: {:error, :no_expiry_date}
  def parse(""), do: {:error, :no_expiry_date}

  def parse(value) when is_binary(value) do
    with {:error, _} <- Date.from_iso8601(value),
         {:error, _} <- parse_with(value, "{D}/{M}/{YYYY}"),
         {:error, _} <- parse_with(value, "{M}/{D}/{YYYY}") do
      {:error, :invalid_date_format}
    end
  end

  def parse(_), do: {:error, :invalid_date_format}

  defp parse_with(value, format) do
    case Timex.parse(value, format) do
      {:ok, datetime} -> {:ok, Timex.to_date(datetime)}
      {:error, reason} -> {:error, reason}
    end
  end

  # Only ISO strings are accepted from user input, since that is what the date
  # inputs submit and what the string `batches.expiry` column can be compared
  # against in SQL.
  defp iso_or_nil(%Date{} = date), do: iso(date)

  defp iso_or_nil(value) when is_binary(value) do
    case Date.from_iso8601(value) do
      {:ok, _date} -> value
      {:error, _reason} -> nil
    end
  end

  defp iso_or_nil(_), do: nil

  defp later_of(nil, other), do: other
  defp later_of(one, nil), do: one
  defp later_of(one, other), do: if(one >= other, do: one, else: other)

  defp earlier_of(nil, other), do: other
  defp earlier_of(one, nil), do: one
  defp earlier_of(one, other), do: if(one <= other, do: one, else: other)

  defp within?(date, {from, to}) do
    (is_nil(from) or Date.compare(date, Date.from_iso8601!(from)) != :lt) and
      (is_nil(to) or Date.compare(date, Date.from_iso8601!(to)) != :gt)
  end

  defp iso(%Date{} = date), do: Date.to_iso8601(date)
end
