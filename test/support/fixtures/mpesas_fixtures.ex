defmodule Medcamp.MpesasFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Medcamp.Mpesas` context.
  """

  import Medcamp.PatientsFixtures

  @doc """
  Generate a mpesa payment record.
  """
  def mpesa_fixture(attrs \\ %{}) do
    patient = patient_fixture()

    {:ok, prompter} =
      Medcamp.Accounts.register_user(%{
        "email" => "prompter#{System.unique_integer()}@example.com",
        "password" => "hello world!",
        "name" => "Payment Prompter",
        "role" => "admin"
      })

    base_attrs = %{
      amount: 1200,
      phone: "254700000000",
      checkout_request_id: "checkout-#{System.unique_integer()}",
      merchant_request_id: "merchant-#{System.unique_integer()}",
      patient_id: patient.id,
      actionable_id: 1,
      actionable_type: "create_wallet_deposit",
      prompter_id: prompter.id,
      reason: "some reason",
      description: "some description",
      account_number: "some account_number",
      receipt: "some receipt",
      transactiondate: "some transactiondate",
      payment_pending: false,
      is_successful: true,
      result_code: 0
    }

    {:ok, mpesa} =
      attrs
      |> Enum.into(base_attrs)
      |> Medcamp.Mpesas.create_mpesa()

    mpesa
  end
end
