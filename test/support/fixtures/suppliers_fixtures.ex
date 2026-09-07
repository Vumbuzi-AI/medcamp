defmodule Medcamp.SuppliersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Medcamp.Suppliers` context.
  """

  @doc """
  Generate a supplier.
  """
  def supplier_fixture(attrs \\ %{}) do
    {:ok, supplier} =
      attrs
      |> Enum.into(%{
        contact: "some contact",
        description: "some description",
        email: "some email",
        location: "some location",
        name: "some name"
      })
      |> Medcamp.Suppliers.create_supplier()

    supplier
  end
end
