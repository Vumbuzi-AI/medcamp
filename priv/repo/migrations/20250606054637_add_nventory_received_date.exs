defmodule Medcamp.Repo.Migrations.AddNventoryReceivedDate do
  use Ecto.Migration

  def change do
    alter table(:batches) do
      add :received_date, :date
    end
  end
end
