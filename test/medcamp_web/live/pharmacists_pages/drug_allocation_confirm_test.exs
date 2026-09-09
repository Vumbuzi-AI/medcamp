defmodule MedcampWeb.PharmacistsLive.DrugAllocationConfirmTest do
  use MedcampWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Medcamp.AccountsFixtures
  import Medcamp.DrugAllocationsFixtures

  alias Medcamp.DrugAllocations

  setup %{conn: conn} do
    %{conn: log_in_user(conn, user_fixture(%{role: "pharmacist"}))}
  end

  defp mark_all_given(allocation) do
    given =
      Enum.map(allocation.drugs_assigned, fn line ->
        line
        |> Map.from_struct()
        |> Map.new(fn {k, v} -> {to_string(k), v} end)
        |> Map.put("has_been_given", true)
      end)

    {:ok, updated} =
      DrugAllocations.update_drug_allocation_after_dispense(allocation, %{
        "drugs_assigned" => given
      })

    updated
  end

  test "confirm is blocked while any drug line is still ungiven", %{conn: conn} do
    allocation = drug_allocation_fixture()

    {:ok, view, html} =
      live(conn, ~p"/pharmacist/drug_allocations/#{allocation.id}/confirm")

    assert html =~ "of 1 drugs recorded as given"
    assert has_element?(view, "button[phx-click='confirm_dispense'][disabled]")
  end

  test "confirm is enabled once every drug line is recorded as given", %{conn: conn} do
    allocation = drug_allocation_fixture() |> mark_all_given()

    {:ok, view, html} =
      live(conn, ~p"/pharmacist/drug_allocations/#{allocation.id}/confirm")

    assert html =~ "All 1 drugs recorded as given"
    refute has_element?(view, "button[phx-click='confirm_dispense'][disabled]")
  end
end
