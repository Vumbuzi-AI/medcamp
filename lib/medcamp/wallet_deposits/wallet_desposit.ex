defmodule Medcamp.WalletDeposits.WalletDeposit do
  use Ecto.Schema
  import Ecto.Changeset

  schema "wallet_deposits" do
    field :reason, :string
    field :phone_number, :string
    field :amount, :integer
    field :has_been_paid, :boolean, default: false

    belongs_to :patient, Medcamp.Patients.Patient

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(wallet_Deposit, attrs) do
    wallet_Deposit
    |> cast(attrs, [:phone_number, :amount, :reason, :patient_id, :has_been_paid])
    |> validate_required([:phone_number, :amount, :reason, :patient_id, :has_been_paid])
  end
end
