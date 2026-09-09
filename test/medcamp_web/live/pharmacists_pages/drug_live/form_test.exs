defmodule MedcampWeb.PharmacistsLive.DrugFormTest do
  use MedcampWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Medcamp.AccountsFixtures

  alias Medcamp.Drugs

  setup %{conn: conn} do
    user = user_fixture(%{role: "pharmacist"})
    %{conn: log_in_user(conn, user), user: user}
  end

  test "New Drug form: GTIN hint, optional brand, strength label, unit-of-measure select", %{
    conn: conn
  } do
    {:ok, view, _html} = live(conn, ~p"/pharmacist/drugs/new")

    assert has_element?(view, "#drug-form input[name='drug[gtin]']")
    assert has_element?(view, "#drug-form label", "GTIN (barcode number)")
    assert has_element?(view, "#drug-form label", "Brand name (optional)")
    assert has_element?(view, "#drug-form label", "Strength (per unit)")
    assert has_element?(view, "#drug-form select[name='drug[uom]'] option", "Tablet")
    assert has_element?(view, "#drug-form select[name='drug[uom]'] option", "mL")
    refute has_element?(view, "#drug-form input[name='drug[uom]']")
  end

  test "an invalid GTIN is rejected with a friendly message", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/pharmacist/drugs/new")

    html =
      view
      |> form("#drug-form",
        drug: %{gtin: "12345", generic_name: "Amoxicillin", uom: "Tablet"}
      )
      |> render_change()

    assert html =~ "not a valid barcode number"
  end

  test "a valid drug is added to the catalogue with a canonical unit", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/pharmacist/drugs/new")

    view
    |> form("#drug-form",
      drug: %{
        gtin: "6291041500213",
        generic_name: "Amoxicillin",
        brand_name: "Amoxil",
        strength: "500 mg",
        uom: "Capsule"
      }
    )
    |> render_submit()

    assert [drug] = Drugs.list_drugs() |> Medcamp.Repo.preload(:inventory_received)
    assert drug.generic_name == "Amoxicillin"
    assert drug.inventory_received.gtin == "6291041500213"
    assert drug.inventory_received.uom == "Capsule"
    assert drug.inventory_received.strength == "500 mg"
  end

  test "brand name is optional when a generic name is given", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/pharmacist/drugs/new")

    view
    |> form("#drug-form",
      drug: %{gtin: "6291041500213", generic_name: "Paracetamol", uom: "Tablet"}
    )
    |> render_submit()

    assert [drug] = Drugs.list_drugs()
    assert drug.generic_name == "Paracetamol"
  end

  test "a scanned GS1 barcode fills the GTIN field", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/pharmacist/drugs/new")

    render_hook(view, "qr_scanned", %{"value" => "(01)06291041500213(17)261231(10)AB12"})

    assert has_element?(
             view,
             "#drug-form input[name='drug[gtin]'][value='06291041500213']"
           )
  end

  test "scanning a barcode for an already-catalogued product prefills its details", %{
    conn: conn,
    user: user
  } do
    Medcamp.Tenancy.with_org(user.organisation_id, fn ->
      {:ok, _drug} =
        Drugs.create_camp_drug(
          %{
            "gtin" => "6291041500213",
            "generic_name" => "Amoxicillin",
            "brand_name" => "Amoxil",
            "strength" => "500 mg",
            "uom" => "Capsule"
          },
          user
        )
    end)

    {:ok, view, _html} = live(conn, ~p"/pharmacist/drugs/new")

    render_hook(view, "qr_scanned", %{"value" => "6291041500213"})

    assert has_element?(
             view,
             "#drug-form input[name='drug[generic_name]'][value='Amoxicillin']"
           )

    assert has_element?(view, "#drug-form input[name='drug[strength]'][value='500 mg']")
  end

  test "an unreadable scan asks the pharmacist to type the GTIN", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/pharmacist/drugs/new")

    render_hook(view, "qr_scanned", %{"value" => "not-a-barcode"})

    assert render(view) =~ "Enter it manually"
  end
end
