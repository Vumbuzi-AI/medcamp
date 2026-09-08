defmodule Medcamp.DataMatrixParser do
  alias Medcamp.Batches.Batch
  alias Medcamp.Repo
  import Ecto.Query

  @doc """
  Extracts GTIN from datamatrix string (positions 2-15)
  """
  def extract_gtin(datamatrix_string) when is_binary(datamatrix_string) do
    case Regex.run(~r/01(\d{14})/, datamatrix_string) do
      [_, gtin] -> gtin
      _ -> nil
    end
  end

  @doc """
  Tries to find a matching batch by progressively checking substrings
  Starting from position 18 (after "01" + 14-digit GTIN + "10")
  """
  def find_batch_from_datamatrix(datamatrix_string, gtin) do
    marker = "01#{gtin}10"

    case :binary.match(datamatrix_string, marker) do
      {start, marker_length} ->
        batch_start = start + marker_length

        remaining =
          binary_part(datamatrix_string, batch_start, byte_size(datamatrix_string) - batch_start)

        try_batch_combinations(remaining, gtin, 1)

      :nomatch ->
        {:error, "Datamatrix does not contain GS1 GTIN and batch identifiers"}
    end
  end

  defp try_batch_combinations(remaining, gtin, length) do
    max_length = String.length(remaining)

    cond do
      length > max_length ->
        {:error, "No matching batch found"}

      length > 20 ->
        # Safety limit: batch numbers shouldn't be longer than 20 chars
        {:error, "No matching batch found"}

      true ->
        # Try current length
        potential_batch = String.slice(remaining, 0, length)

        case find_batch_in_db(gtin, potential_batch) do
          nil ->
            # Not found, try next length
            try_batch_combinations(remaining, gtin, length + 1)

          batch ->
            # Found it!
            {:ok, batch, potential_batch}
        end
    end
  end

  defp find_batch_in_db(gtin, batch_number) do
    Batch
    |> join(:inner, [b], i in assoc(b, :inventory_received))
    |> where([b, i], i.gtin == ^gtin and b.batch == ^batch_number)
    |> preload([b, i], inventory_received: i)
    |> Repo.one()
  end

  @doc """
  Main function to process datamatrix and find matching inventory + batch
  """
  def process_datamatrix(datamatrix_string) do
    gtin = extract_gtin(datamatrix_string)

    if is_nil(gtin) do
      {:error, "Could not extract GTIN from datamatrix"}
    else
      case find_batch_from_datamatrix(datamatrix_string, gtin) do
        {:ok, batch, batch_number} ->
          {:ok,
           %{
             batch: batch,
             inventory: batch.inventory_received,
             gtin: gtin,
             batch_number: batch_number
           }}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end
end
