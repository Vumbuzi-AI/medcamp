defmodule Medcamp.RadiologyTestsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Medcamp.RadiologyTests` context.
  """

  @doc """
  Generate a radiology_test.
  """
  def radiology_test_fixture(attrs \\ %{}) do
    creator =
      Map.get(attrs, :creator) || Map.get(attrs, "creator") ||
        Medcamp.AccountsFixtures.user_fixture()

    {:ok, radiology_test} =
      attrs
      |> Map.drop([:creator, "creator"])
      |> Enum.into(%{
        description: "some description",
        name: "some name",
        price: 42,
        creator_id: creator.id
      })
      |> Medcamp.RadiologyTests.create_radiology_test()

    radiology_test
  end
end
