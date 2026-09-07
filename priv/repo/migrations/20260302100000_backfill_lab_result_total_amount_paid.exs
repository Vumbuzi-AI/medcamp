defmodule Medcamp.Repo.Migrations.BackfillLabResultTotalAmountPaid do
  use Ecto.Migration

  def up do
    # Backfill total_amount_paid for insurance lab results that have a tests JSONB
    # array but no total recorded. Each element in `tests` has a `price` integer field.
    execute("""
    UPDATE lab_results
    SET total_amount_paid = (
      SELECT COALESCE(SUM((elem->>'price')::integer), 0)
      FROM jsonb_array_elements(tests) AS elem
      WHERE (elem->>'price') IS NOT NULL
    )
    WHERE payment_type = 'Insurance'
      AND (total_amount_paid IS NULL OR total_amount_paid = 0)
      AND tests IS NOT NULL
      AND tests != '[]'::jsonb
    """)
  end

  def down do
    # Irreversible — we do not want to wipe amounts that were just restored
    :ok
  end
end
