defmodule Medcamp.Repo.Migrations.BackfillLabResultSubsidizedAmount do
  use Ecto.Migration

  @doc """
  Re-calculates total_amount_paid for insurance lab results using the subsidized price
  from the lab_tests table (joined via the JSONB tests[].name field).

  For each insurance lab result:
  - Each embedded test entry has a name and a price (stored at time of creation).
  - We look up the matching lab_test by name to get its subsidized_price.
  - If subsidized_price exists, we use it; otherwise we fall back to 70% of the
    lab_tests.price, or finally the already-stored price in the JSONB.
  """
  def up do
    execute("""
    UPDATE lab_results lr
    SET total_amount_paid = (
      SELECT COALESCE(SUM(
        COALESCE(
          lt.subsidized_price,
          ROUND(lt.price * 0.7),
          (elem->>'price')::integer
        )
      ), 0)
      FROM jsonb_array_elements(lr.tests) AS elem
      LEFT JOIN lab_tests lt ON lt.name = elem->>'name'
      WHERE (elem->>'price') IS NOT NULL OR lt.id IS NOT NULL
    )
    WHERE lr.payment_type = 'Insurance'
      AND lr.tests IS NOT NULL
      AND lr.tests != '[]'::jsonb
    """)
  end

  def down do
    :ok
  end
end
