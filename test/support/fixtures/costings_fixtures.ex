defmodule Medcamp.CostingsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Medcamp.Costings` context.
  """

  @doc """
  Generate a costing.
  """
  def costing_fixture(attrs \\ %{}) do
    user =
      Map.get(attrs, :user) || Map.get(attrs, "user") || Medcamp.AccountsFixtures.user_fixture()

    {:ok, costing} =
      attrs
      |> Map.drop([:user, "user"])
      |> Enum.into(%{
        price: 42,
        type: "some type",
        user_id: user.id
      })
      |> Medcamp.Costings.create_costing()

    costing
  end
end
