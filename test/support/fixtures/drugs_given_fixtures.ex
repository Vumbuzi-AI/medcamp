defmodule Medcamp.DrugsGivenFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Medcamp.DrugsGiven` context.
  """

  @doc """
  Generate a drug_given.
  """
  def drug_given_fixture(attrs \\ %{}) do
    drug = Map.get(attrs, :drug) || Map.get(attrs, "drug") || Medcamp.DrugsFixtures.drug_fixture()

    drug_allocation =
      Map.get(attrs, :drug_allocation) ||
        Map.get(attrs, "drug_allocation") ||
        Medcamp.DrugAllocationsFixtures.drug_allocation_fixture()

    pharmacist =
      Map.get(attrs, :pharmacist) || Map.get(attrs, "pharmacist") ||
        Medcamp.AccountsFixtures.user_fixture()

    {:ok, drug_given} =
      attrs
      |> Map.drop([:drug, "drug", :drug_allocation, "drug_allocation", :pharmacist, "pharmacist"])
      |> Enum.into(%{
        drug_id: drug.id,
        drug_allocation_id: drug_allocation.id,
        pharmacist_id: pharmacist.id,
        price: 42,
        quantity: 42
      })
      |> Medcamp.DrugsGiven.create_drug_given()

    drug_given
  end
end
