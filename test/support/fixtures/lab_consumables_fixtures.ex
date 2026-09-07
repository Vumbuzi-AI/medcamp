defmodule Medcamp.LabConsumablesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Medcamp.LabConsumables` context.
  """

  @doc """
  Generate a lab_consumable.
  """
  def lab_consumable_fixture(attrs \\ %{}) do
    {:ok, lab_consumable} =
      attrs
      |> Enum.into(%{
        consumed_quantity: "some consumed_quantity",
        date: "some date",
        purpose: "some purpose"
      })
      |> Medcamp.LabConsumables.create_lab_consumable()

    lab_consumable
  end
end
