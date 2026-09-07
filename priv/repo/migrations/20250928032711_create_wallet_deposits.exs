defmodule Medcamp.Repo.Migrations.CreateWalletDeposits do
  use Ecto.Migration

  def change do
    create table(:wallet_deposits) do
      add :phone_number, :string
      add :amount, :integer
      add :reason, :text
      add :patient_id, references(:patients, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:wallet_deposits, [:patient_id])
  end
end
