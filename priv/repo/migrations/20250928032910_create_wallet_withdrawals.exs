defmodule Medcamp.Repo.Migrations.CreateWalletWithdrawals do
  use Ecto.Migration

  def change do
    create table(:wallet_withdrawals) do
      add :reason, :text
      add :date, :date
      add :wallet_deposit_id, references(:wallet_deposits, on_delete: :nothing)
      add :patient_id, references(:patients, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:wallet_withdrawals, [:wallet_deposit_id])
    create index(:wallet_withdrawals, [:patient_id])
  end
end
