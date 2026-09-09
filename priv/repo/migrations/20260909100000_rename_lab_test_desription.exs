defmodule Medcamp.Repo.Migrations.RenameLabTestDesription do
  use Ecto.Migration

  # `lab_tests.desription` was misspelled in the baseline migration and the typo
  # surfaced in form labels and table headers ("Desription"). Rename preserves
  # the column data.
  def change do
    rename table(:lab_tests), :desription, to: :description
  end
end
