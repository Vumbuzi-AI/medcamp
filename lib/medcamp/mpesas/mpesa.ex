defmodule Medcamp.Mpesas.Mpesa do
  use Ecto.Schema
  import Ecto.Changeset

  schema "mpesas" do
    field :reason, :string
    field :description, :string
    field :account_number, :string
    field :amount, :integer
    field :phone, :string
    field :receipt, :string
    field :transactiondate, :string
    field :payment_pending, :boolean, default: true
    field :checkout_request_id, :string
    field :merchant_request_id, :string
    field :is_successful, :boolean, default: false
    field :result_code, :integer
    field :formatted_phone_number, :string, virtual: true
    field :actionable_id, :integer
    field :actionable_type, :string
    belongs_to :patient, Medcamp.Patients.Patient
    belongs_to :prompter, Medcamp.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(mpesa, attrs) do
    mpesa
    |> cast(attrs, [
      :account_number,
      :amount,
      :is_successful,
      :description,
      :payment_pending,
      :phone,
      :receipt,
      :transactiondate,
      :actionable_id,
      :actionable_type,
      :reason,
      :patient_id,
      :prompter_id,
      :checkout_request_id,
      :merchant_request_id,
      :result_code
    ])
    |> validate_required([
      :amount,
      :phone,
      :checkout_request_id,
      :merchant_request_id,
      :patient_id,
      :actionable_id,
      :actionable_type,
      :prompter_id
    ])
  end

  def trigger_changeset(mpesa, attrs) do
    mpesa
    |> cast(attrs, [
      :amount,
      :formatted_phone_number
    ])
    |> validate_required([:amount, :formatted_phone_number])
    |> validate_format(
      :formatted_phone_number,
      ~r/^[17]\d{8}$/,
      message: "Number has to start with 7 or 1 and have 9 digits"
    )
  end
end
