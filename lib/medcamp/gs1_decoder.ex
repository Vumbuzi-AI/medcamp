defmodule GS1Decoder do
  # ASCII 29 - Group Separator
  @gs "\x1D"

  @doc """
  Decodes a GS1 datamatrix string into a map of application identifiers (AIs) and their values.

  ## Example
      iex> GS1Decoder.decode("01061611109303671026240178811251002172510022145678")
      %{
        "01" => "06161110930367",  # GTIN
        "10" => "262401788",        # Batch/Lot
        "11" => "251002",           # Production Date
        "17" => "251002",           # Expiration Date
        "21" => "45678"             # Serial Number
      }
  """
  def decode(datamatrix_string) do
    # Replace the GS character (ASCII 29) if present in the string
    normalized = String.replace(datamatrix_string, @gs, "|")

    parse_ais(normalized, %{})
  end

  defp parse_ais("", acc), do: acc

  defp parse_ais(string, acc) do
    cond do
      # AI 01 - GTIN (14 digits, fixed length)
      String.starts_with?(string, "01") ->
        {value, rest} = String.split_at(String.slice(string, 2..-1//1), 14)
        parse_ais(rest, Map.put(acc, "01", value))

      # AI 10 - Batch/Lot (variable length, look ahead for next AI)
      String.starts_with?(string, "10") ->
        rest = String.slice(string, 2..-1//1)
        {value, remainder} = extract_until_next_ai(rest)
        parse_ais(remainder, Map.put(acc, "10", value))

      # AI 11 - Production Date (6 digits, fixed length, YYMMDD)
      String.starts_with?(string, "11") ->
        {value, rest} = String.split_at(String.slice(string, 2..-1//1), 6)
        parse_ais(rest, Map.put(acc, "11", value))

      # AI 17 - Expiration Date (6 digits, fixed length, YYMMDD)
      String.starts_with?(string, "17") ->
        {value, rest} = String.split_at(String.slice(string, 2..-1//1), 6)
        parse_ais(rest, Map.put(acc, "17", value))

      # AI 21 - Serial Number (variable length, goes to end or next AI)
      String.starts_with?(string, "21") ->
        rest = String.slice(string, 2..-1//1)
        {value, remainder} = extract_until_next_ai(rest)
        parse_ais(remainder, Map.put(acc, "21", value))

      # Skip GS separator
      String.starts_with?(string, "|") ->
        parse_ais(String.slice(string, 1..-1//1), acc)

      # Unknown AI - skip 2 characters and continue
      true ->
        parse_ais(String.slice(string, 2..-1//1), acc)
    end
  end

  defp extract_until_next_ai(string) do
    # First check for GS separator
    case String.split(string, "|", parts: 2) do
      [value, rest] ->
        {value, rest}

      [_value] ->
        # No GS found, look for next known AI (11, 17, 21, etc.)
        find_next_ai(string)
    end
  end

  defp find_next_ai(string) do
    # Look for the position of the next AI
    known_ais = ["11", "17", "21", "10"]

    positions =
      known_ais
      |> Enum.map(fn ai ->
        case :binary.match(string, ai) do
          {pos, _} -> pos
          :nomatch -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    case Enum.min(positions, fn -> nil end) do
      nil -> {string, ""}
      pos -> String.split_at(string, pos)
    end
  end

  @doc """
  Decodes and formats the result in a more readable way.
  """
  def decode_pretty(datamatrix_string) do
    datamatrix_string
    |> decode()
    |> Enum.map(fn {ai, value} ->
      label =
        case ai do
          "01" -> "GTIN"
          "10" -> "Batch/Lot"
          "11" -> "Production Date"
          "17" -> "Expiration Date"
          "21" -> "Serial Number"
          _ -> "AI #{ai}"
        end

      {label, value}
    end)
    |> Enum.into(%{})
  end

  @doc """
  Formats the decoded GS1 data for display like a barcode scanner app.
  Returns a formatted string ready to display.
  """
  def format_for_display(datamatrix_string) do
    decoded = decode(datamatrix_string)

    pc = Map.get(decoded, "01", "")
    sn = Map.get(decoded, "21", "")
    lot = Map.get(decoded, "10", "")
    prod_date = format_date(Map.get(decoded, "11", ""))
    exp_date = format_date(Map.get(decoded, "17", ""))

    """
    Product
    PC: #{pc}
    SN: #{sn}
    LOT: #{lot}
    PROD: #{prod_date}
    EXP: #{exp_date}
    """
  end

  defp format_date(""), do: ""

  defp format_date(date) when byte_size(date) == 6 do
    # Convert YYMMDD to DD/MM/20YY
    <<yy::binary-size(2), mm::binary-size(2), dd::binary-size(2)>> = date
    "#{dd}/#{mm}/20#{yy}"
  end

  defp format_date(date), do: date
end
