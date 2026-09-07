defmodule Medcamp.Repo.Migrations.AddSubsidizedPriceToLabTests do
  use Ecto.Migration

  def change do
    alter table(:lab_tests) do
      add :subsidized_price, :integer
    end
  end
end
