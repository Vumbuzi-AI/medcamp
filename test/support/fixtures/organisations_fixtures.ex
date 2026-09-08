defmodule Medcamp.OrganisationsFixtures do
  @moduledoc """
  Test helpers for the `Medcamp.Organisations` context.

  Most tests never call these directly: `Medcamp.DataCase` and
  `MedcampWeb.ConnCase` create an organisation and enter its tenancy in setup,
  so every other fixture writes into it without having to know tenancy exists.
  Reach for `organisation_fixture/1` when a test needs a *second* organisation
  to prove data does not cross between them.
  """

  alias Medcamp.Organisations

  def unique_organisation_slug, do: "org-#{System.unique_integer([:positive])}"

  def organisation_fixture(attrs \\ %{}) do
    {:ok, organisation} =
      attrs
      |> Enum.into(%{
        "name" => "Test Organisation",
        "slug" => unique_organisation_slug()
      })
      |> Organisations.create_organisation()

    organisation
  end
end
