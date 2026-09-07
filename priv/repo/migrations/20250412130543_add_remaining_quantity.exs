defmodule Medcamp.Repo.Migrations.AddRemainingQuantity do
  use Ecto.Migration

  def change do
    alter table(:batches) do
      add :remaining_quantity, :integer
    end
  end
end
