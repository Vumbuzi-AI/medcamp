defmodule Medcamp.BatchesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Medcamp.Batches` context.
  """

  @doc """
  Generate a batch.
  """
  def batch_fixture(attrs \\ %{}) do
    {:ok, batch} =
      attrs
      |> Enum.into(%{
        batch: "some batch",
        expiry: "some expiry",
        gtin: "some gtin",
        manufacturer: "some manufacturer",
        quantity: 42,
        remaining_quantity: 42,
        serial: "some serial"
      })
      |> Medcamp.Batches.create_batch()

    Medcamp.Repo.preload(batch, [:inventory_received, :supplier])
  end
end
