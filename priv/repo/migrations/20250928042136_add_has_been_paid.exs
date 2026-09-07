defmodule Medcamp.Repo.Migrations.AddHasBeenPaid do
  use Ecto.Migration

  def change do
    alter table(:wallet_deposits) do
      add :has_been_paid, :boolean, default: false, null: false
    end
  end
end
