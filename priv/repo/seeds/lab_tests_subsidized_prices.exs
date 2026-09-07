# Script to set subsidized_price (30% off) for all lab tests.
# Run with: mix run priv/repo/seeds/lab_tests_subsidized_prices.exs

alias Medcamp.Repo
alias Medcamp.LabTests.LabTest

import Ecto.Query

lab_tests = Repo.all(LabTest)

Enum.each(lab_tests, fn lt ->
  subsidized_price = if lt.price, do: round(lt.price * 0.7), else: nil
  lt
  |> Ecto.Changeset.change(%{subsidized_price: subsidized_price})
  |> Repo.update!()
end)

IO.puts("Updated subsidized_price (30% off) for #{length(lab_tests)} lab test(s).")
