defmodule Medcamp.LabAllocationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Medcamp.LabAllocations` context.
  """

  @doc """
  Generate a lab_allocation.
  """
  def lab_allocation_fixture(attrs \\ %{}) do
    {:ok, lab_allocation} =
      attrs
      |> Enum.into(%{
        allocated_quantity: 42,
        expiry_date: ~D[2025-09-17],
        remaining_quantity: 42,
        uom: "some uom"
      })
      |> Medcamp.LabAllocations.create_lab_allocation()

    Medcamp.Repo.preload(lab_allocation, [
      :allocated_by_user,
      :allocated_to_user,
      inventory_issued: [:inventory_received, batch: :supplier]
    ])
  end
end
