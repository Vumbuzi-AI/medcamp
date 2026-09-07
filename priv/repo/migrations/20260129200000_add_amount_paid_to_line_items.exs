defmodule Medcamp.Repo.Migrations.AddAmountPaidToLineItems do
  use Ecto.Migration

  def change do
    alter table(:admission_request_line_items) do
      add :amount_paid, :integer, default: 0, null: false
    end
  end
end
