defmodule Medcamp.Repo.Migrations.SetAllDrugsNonOtc do
  use Ecto.Migration

  def up do
    execute "UPDATE drugs SET is_otc = false"
  end

  def down do
    # No reversible action - we don't know which drugs were previously OTC
  end
end
