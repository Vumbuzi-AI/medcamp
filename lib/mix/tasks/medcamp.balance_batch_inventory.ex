defmodule Mix.Tasks.Medcamp.BalanceBatchInventory do
  @shortdoc "Reconciles batch remaining_quantity with (quantity - sum of inventories_issued)"
  @moduledoc """
  Balances batch remaining quantities against what was received and what was issued.

  For each batch:
    - quantity       = initial received quantity
    - remaining_quantity = what the system thinks is left
    - sum(inventory_issued.quantity) = total issued from this batch

  Correct balance: quantity == remaining_quantity + sum_issued

  Usage:
    mix medcamp.balance_batch_inventory           # Report only (dry run)
    mix medcamp.balance_batch_inventory --fix    # Update batch.remaining_quantity where wrong
  """

  use Mix.Task
  import Ecto.Query
  alias Medcamp.Repo
  alias Medcamp.Batches.Batch
  alias Medcamp.InventoriesIssues.InventoryIssued

  @requirements ["app.config"]

  @impl Mix.Task
  def run(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [fix: :boolean])
    fix? = Keyword.get(opts, :fix, false)

    Mix.Task.run("app.start")

    issued_sums =
      from(ii in InventoryIssued,
        group_by: ii.batch_id,
        select: {ii.batch_id, sum(ii.quantity)}
      )
      |> Repo.all()
      |> Map.new(fn {batch_id, sum_qty} -> {batch_id, sum_qty || 0} end)

    batches = Repo.all(from(b in Batch, order_by: [asc: b.id]))

    discrepancies =
      for batch <- batches do
        initial = batch.quantity || 0
        remaining = batch.remaining_quantity || 0
        sum_issued = Map.get(issued_sums, batch.id, 0)
        expected_remaining = max(0, initial - sum_issued)

        if remaining != expected_remaining do
          %{
            batch_id: batch.id,
            batch: batch.batch,
            gtin: batch.gtin,
            initial: initial,
            sum_issued: sum_issued,
            expected_remaining: expected_remaining,
            current_remaining: remaining,
            diff: remaining - expected_remaining
          }
        end
      end
      |> Enum.reject(&is_nil/1)

    if discrepancies == [] do
      Mix.shell().info("All batches are balanced. No discrepancies found.")
    else
      Mix.shell().info("Found #{length(discrepancies)} batch(es) with quantity discrepancies:\n")
      print_table(discrepancies)

      if fix? do
        Mix.shell().info("\nApplying fixes...")

        for d <- discrepancies do
          batch = Repo.get!(Batch, d.batch_id)

          case Medcamp.Batches.update_batch(batch, %{remaining_quantity: d.expected_remaining}) do
            {:ok, _} ->
              Mix.shell().info(
                "  Batch ID #{d.batch_id} (#{d.batch || d.gtin}): remaining_quantity set to #{d.expected_remaining}"
              )

            {:error, changeset} ->
              Mix.shell().error(
                "  Batch ID #{d.batch_id}: update failed - #{inspect(changeset.errors)}"
              )
          end
        end

        Mix.shell().info("Done.")
      else
        Mix.shell().info(
          "\nRun with --fix to update batch remaining_quantity to the computed values."
        )
      end
    end
  end

  defp print_table(rows) do
    pad = fn str, w -> String.pad_trailing(to_string(str) |> String.slice(0, w), w) end

    [h1, h2, h3, h4, h5, h6, h7] = [
      "Batch ID",
      "Batch/GTIN",
      "Initial",
      "Sum issued",
      "Exp. remain",
      "Cur. remain",
      "Diff"
    ]

    IO.puts(
      "#{pad.(h1, 10)}  #{pad.(h2, 20)}  #{pad.(h3, 8)}  #{pad.(h4, 11)}  #{pad.(h5, 18)}  #{pad.(h6, 18)}  #{pad.(h7, 6)}"
    )

    IO.puts(String.duplicate("-", 100))

    for r <- rows do
      IO.puts(
        "#{pad.(r.batch_id, 10)}  #{pad.(r.batch || r.gtin || "", 20)}  #{pad.(r.initial, 8)}  #{pad.(r.sum_issued, 11)}  #{pad.(r.expected_remaining, 18)}  #{pad.(r.current_remaining, 18)}  #{pad.(r.diff, 6)}"
      )
    end
  end
end
