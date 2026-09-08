defmodule Medcamp.CampsFixtures do
  @moduledoc """
  Test helpers for the `Medcamp.Camps` context.

  Creates camps inside whatever organisation the test is already in, the same
  way every other fixture does.
  """

  alias Medcamp.Camps

  def camp_fixture(attrs \\ %{}) do
    {:ok, camp} =
      attrs
      |> Enum.into(%{
        "name" => "Camp #{System.unique_integer([:positive])}",
        "location" => "Kajiado"
      })
      |> Camps.create_camp()

    camp
  end

  @doc "A camp that is the organisation's active one."
  def active_camp_fixture(attrs \\ %{}) do
    camp = camp_fixture(attrs)
    {:ok, camp} = Camps.set_active_camp(camp)
    camp
  end
end
