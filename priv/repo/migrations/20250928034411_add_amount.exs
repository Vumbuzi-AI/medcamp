defmodule Medcamp.Repo.Migrations.AddAmount do
  use Ecto.Migration

  def change do
    alter table(:wallet_withdrawals) do
      add :amount, :integer, null: false, default: 0
    end
  end
end
