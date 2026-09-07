defmodule Medcamp.Repo.Migrations.AddBatchNumberToQuoteItems do
  use Ecto.Migration

  def change do
    alter table(:quote_items) do
      add :batch_number, :string
    end
  end
end
