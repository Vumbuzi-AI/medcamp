defmodule Medcamp.LabTestsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Medcamp.LabTests` context.
  """

  @doc """
  Generate a lab_test.
  """
  def lab_test_fixture(attrs \\ %{}) do
    {:ok, lab_test} =
      attrs
      |> Enum.into(%{
        desription: "some desription",
        name: "some name",
        price: 42
      })
      |> Medcamp.LabTests.create_lab_test()

    lab_test
  end
end
