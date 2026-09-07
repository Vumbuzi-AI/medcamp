IO.puts("\n=== Recalculating General Inventory Stock From Transactions ===\n")

results = Medcamp.Inventories.recalculate_stock_from_transactions()

{updated, skipped, errors} =
  Enum.reduce(results, {[], [], []}, fn
    {:ok, name, old_qty, new_qty}, {u, s, e} ->
      {[{name, old_qty, new_qty} | u], s, e}

    {:skipped, name, qty}, {u, s, e} ->
      {u, [{name, qty} | s], e}

    {:error, name, reason}, {u, s, e} ->
      {u, s, [{name, reason} | e]}
  end)

IO.puts("✅ Updated (#{length(updated)} items):")

Enum.each(updated, fn {name, old_qty, new_qty} ->
  IO.puts(
    "   #{name}: #{Decimal.to_string(old_qty)} → #{Decimal.to_string(new_qty)}"
  )
end)

IO.puts("\n⏭  Skipped — no transactions (#{length(skipped)} items):")

Enum.each(skipped, fn {name, qty} ->
  IO.puts("   #{name}: #{Decimal.to_string(qty)} (unchanged)")
end)

if errors != [] do
  IO.puts("\n❌ Errors (#{length(errors)} items):")

  Enum.each(errors, fn {name, reason} ->
    IO.puts("   #{name}: #{inspect(reason)}")
  end)
end

IO.puts("\nDone.\n")
