defmodule MedcampWeb.AllBatchesLive.IndexTest do
  use MedcampWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Medcamp.AccountsFixtures

  alias Medcamp.Batches.Batch
  alias Medcamp.InventoriesReceived.InventoryReceived
  alias Medcamp.Repo

  test "the batch number and 'View details' link both navigate to that batch's show page", %{
    conn: conn
  } do
    inventory_manager = user_fixture(%{role: "inventory_manager"})

    inventory =
      Repo.insert!(%InventoryReceived{
        gtin: "GTIN-#{System.unique_integer([:positive])}",
        brand_name: "Panadol Extra 500mg",
        generic_name: "Paracetamol",
        category: "Pharmaceuticals"
      })

    batch =
      Repo.insert!(%Batch{
        gtin: inventory.gtin,
        batch: "BATCH-LIST-TEST",
        quantity: 100,
        remaining_quantity: 80,
        uom: "tablets",
        cost_per_unit: 15,
        expiry: "2028-12-31",
        inventory_received_id: inventory.id
      })

    conn = log_in_user(conn, inventory_manager)

    {:ok, view, _html} = live(conn, ~p"/inventory_manager/batches")

    assert has_element?(
             view,
             ~s(a[href="/inventory_manager/batches/#{batch.id}"]),
             "BATCH-LIST-TEST"
           )

    assert has_element?(
             view,
             ~s(a[href="/inventory_manager/batches/#{batch.id}"]),
             "View details"
           )
  end
end
