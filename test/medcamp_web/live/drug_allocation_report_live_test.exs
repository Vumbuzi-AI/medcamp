defmodule MedcampWeb.DrugAllocationReportLiveTest do
  use MedcampWeb.ConnCase, async: true

  import Medcamp.AccountsFixtures
  import Medcamp.DrugsFixtures
  import Medcamp.DrugsGivenFixtures
  import Medcamp.InventoriesReceivedFixtures
  import Phoenix.LiveViewTest

  test "admin can view and filter issued quantities by inventory category", %{conn: conn} do
    admin = user_fixture(%{role: "admin"})
    create_issued_drug("Amoxil", "Antibiotics", 12)
    create_issued_drug("Panadol", "Analgesics", 5)

    {:ok, view, html} = live(log_in_user(conn, admin), ~p"/admin/drug_allocations")

    assert html =~ "Drug Allocations"
    assert html =~ "Antibiotics"
    assert html =~ "Amoxil"
    assert has_element?(view, "#drug-allocation-category-summary", "12")

    view
    |> form("#drug-allocation-report-filters", %{category: "Analgesics"})
    |> render_change()

    assert has_element?(view, "#issued-drug-details", "Panadol")
    refute has_element?(view, "#issued-drug-details", "Amoxil")
  end

  test "pharmacist can access the same allocation report", %{conn: conn} do
    pharmacist = user_fixture(%{role: "pharmacist"})
    create_issued_drug("Cefix", "Antibiotics", 7)

    {:ok, view, html} =
      live(log_in_user(conn, pharmacist), ~p"/pharmacist/drug_allocations/report")

    assert html =~ "Drug Allocations"
    assert has_element?(view, "#issued-drug-details", "Cefix")
    assert has_element?(view, "#drug-allocation-category-summary", "Antibiotics")
  end

  defp create_issued_drug(brand_name, category, quantity) do
    inventory =
      inventory_received_fixture(%{
        brand_name: brand_name,
        generic_name: "#{brand_name} generic",
        category: category,
        type: "Medicine"
      })

    drug_given_fixture(%{
      drug: drug_fixture(%{inventory_received: inventory}),
      quantity: quantity
    })
  end
end
