defmodule Medcamp.Repo.Migrations.AddPettyCash do
  use Ecto.Migration

  def change do
    alter table(:shift_handovers) do
      add :petty_cash_balance, :integer
    end
  end
end
