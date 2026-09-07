defmodule MedcampWeb.MpesaControllerTest do
  use MedcampWeb.ConnCase, async: true

  import Medcamp.DrugAllocationsFixtures
  import Medcamp.DrugsGivenFixtures

  alias Medcamp.DrugAllocations
  alias MedcampWeb.MpesaController

  test "drug allocation payment marks the allocation paid when drugs have been given" do
    drug_allocation = drug_allocation_fixture()
    drug_given_fixture(%{drug_allocation: drug_allocation})

    assert {:ok, updated_allocation} =
             MpesaController.handle_after_action(
               "create_drug_allocation",
               drug_allocation.id,
               %{amount: 600}
             )

    assert updated_allocation.has_been_assigned
    assert updated_allocation.has_paid
    assert updated_allocation.total_amount_paid == 600

    persisted_allocation = DrugAllocations.get_drug_allocation!(drug_allocation.id)
    assert persisted_allocation.has_been_assigned
    assert persisted_allocation.has_paid
    assert persisted_allocation.total_amount_paid == 600
  end
end
