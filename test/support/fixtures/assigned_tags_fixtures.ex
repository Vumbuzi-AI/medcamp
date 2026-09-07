defmodule Medcamp.AssignedTagsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Medcamp.AssignedTags` context.
  """

  @doc """
  Generate a assigned_tag.
  """
  def assigned_tag_fixture(attrs \\ %{}) do
    {:ok, assigned_tag} =
      attrs
      |> Enum.into(%{
        date: ~D[2025-08-27],
        number: 42,
        remaining_number: 42
      })
      |> Medcamp.AssignedTags.create_assigned_tag()

    assigned_tag
  end
end
