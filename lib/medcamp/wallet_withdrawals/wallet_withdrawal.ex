defmodule Medcamp.WalletWithdrawals.WalletWithdrawal do
  use Ecto.Schema
  import Ecto.Changeset

  schema "wallet_withdrawals" do
    field :reason, :string
    field :date, :date
    field :amount, :integer
    belongs_to :wallet_deposit, Medcamp.WalletDeposits.WalletDeposit
    belongs_to :patient, Medcamp.Patients.Patient

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(wallet_withdrawal, attrs) do
    wallet_withdrawal
    |> cast(attrs, [:reason, :date, :wallet_deposit_id, :patient_id, :amount])
    |> validate_required([:reason, :date, :wallet_deposit_id, :patient_id, :amount])
  end
end
