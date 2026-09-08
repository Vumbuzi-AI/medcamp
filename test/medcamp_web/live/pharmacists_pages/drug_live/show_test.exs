defmodule MedcampWeb.PharmacistsLive.DrugsShowTest do
  use MedcampWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Medcamp.AccountsFixtures
  import Medcamp.PatientsFixtures
  import Medcamp.DrugsFixtures
  import Medcamp.DrugBatchesFixtures
  import Medcamp.DrugAllocationsFixtures
  import Medcamp.InventoriesReceivedFixtures

  setup %{conn: conn} do
    pharmacist = user_fixture(%{role: "pharmacist"})
    %{conn: log_in_user(conn, pharmacist)}
  end

  describe "batch actions" do
    test "adds a batch for the current drug without selecting the drug again", %{conn: conn} do
      drug = drug_fixture() |> Medcamp.Repo.preload(:inventory_received)

      {:ok, view, _html} = live(conn, ~p"/pharmacist/drugs/#{drug.id}/new_batch")

      assert has_element?(view, "#drug-batch-form", Medcamp.Drugs.display_name(drug))
      refute has_element?(view, ~s(select[name="drug_batch[drug_id]"]))

      assert has_element?(
               view,
               ~s(input[name="drug_batch[gtin]"][value="#{drug.inventory_received.gtin}"][readonly])
             )

      view
      |> form("#drug-batch-form",
        drug_batch: %{
          gtin: "06161021090004",
          batch: "ALB-2605",
          manufacture_date: "2026-09-01",
          expiry: "2028-01-31",
          quantity: "100",
          price_per_unit: "25",
          manufacturer: "",
          serial: ""
        }
      )
      |> render_submit()

      assert_redirect(view, ~p"/pharmacist/drugs/#{drug.id}")

      [drug_batch] = Medcamp.DrugBatches.list_drug_batches_for_drug(drug.id)
      assert drug_batch.batch.batch == "ALB-2605"
      assert drug_batch.batch.manufacture_date == ~D[2026-09-01]
      assert drug_batch.batch.price_per_unit == 25
    end

    test "opens a printable GS1 DataMatrix for a batch", %{conn: conn} do
      inventory_received = inventory_received_fixture(%{gtin: "06161021090004"})
      drug = drug_fixture(%{inventory_received: inventory_received})

      batch =
        Medcamp.BatchesFixtures.batch_fixture(%{
          gtin: "06161021090004",
          batch: "ALB-2604",
          manufacture_date: ~D[2026-09-01],
          expiry: "2028-01-31"
        })

      drug_batch =
        drug_batch_fixture(%{
          inventory_received: inventory_received,
          drug: drug,
          batch: batch
        })

      {:ok, view, _html} =
        live(conn, ~p"/pharmacist/drugs/#{drug.id}/batches/#{drug_batch.id}/print")

      assert has_element?(view, "#batch-datamatrix-#{drug_batch.id}")

      assert has_element?(
               view,
               ~s(#batch-datamatrix-#{drug_batch.id}[data-value^="010616102109000410ALB-2604"])
             )

      assert render(view) =~ "(11)"
      assert render(view) =~ "260901"
      assert render(view) =~ "(17)"
      assert render(view) =~ "280131"
      assert has_element?(view, ~s([phx-click="print_batch_label"]), "Print")
    end

    test "edits batch details including production date", %{conn: conn} do
      inventory_received = inventory_received_fixture(%{gtin: "06161021090004"})
      drug = drug_fixture(%{inventory_received: inventory_received})

      batch =
        Medcamp.BatchesFixtures.batch_fixture(%{
          gtin: "06161021090004",
          batch: "OLD-LOT",
          manufacture_date: ~D[2026-01-01],
          expiry: "2027-01-01",
          price_per_unit: 10
        })

      drug_batch =
        drug_batch_fixture(%{
          inventory_received: inventory_received,
          drug: drug,
          batch: batch,
          remaining_quantity: 20
        })

      {:ok, view, _html} =
        live(conn, ~p"/pharmacist/drugs/#{drug.id}/batches/#{drug_batch.id}/edit")

      assert has_element?(
               view,
               ~s(input[name="drug_batch[manufacture_date]"][value="2026-01-01"])
             )

      view
      |> form("#drug-batch-form",
        drug_batch: %{
          gtin: "06161021090004",
          batch: "NEW-LOT",
          manufacture_date: "2026-02-03",
          expiry: "2028-04-05",
          quantity: "30",
          price_per_unit: "15",
          manufacturer: "Updated Manufacturer",
          serial: "SER-2"
        }
      )
      |> render_submit()

      assert_redirect(view, ~p"/pharmacist/drugs/#{drug.id}")

      updated = Medcamp.DrugBatches.get_drug_batch!(drug_batch.id)
      assert updated.remaining_quantity == 30
      assert updated.batch.remaining_quantity == 30
      assert updated.batch.batch == "NEW-LOT"
      assert updated.batch.manufacture_date == ~D[2026-02-03]
      assert updated.batch.expiry == "2028-04-05"
      assert updated.batch.price_per_unit == 15
      assert updated.batch.manufacturer == "Updated Manufacturer"
      assert updated.batch.serial == "SER-2"
    end

    test "does not show OTC or DDA controls", %{conn: conn} do
      drug = drug_fixture()

      {:ok, view, _html} = live(conn, ~p"/pharmacist/drugs/#{drug.id}")

      refute has_element?(view, ~s([phx-click="toggle_otc"]))
      refute has_element?(view, ~s([phx-click="toggle_dangerous_drug"]))
      refute render(view) =~ "Add to DDA"

      {:ok, new_view, _html} = live(conn, ~p"/pharmacist/drugs/new")
      refute has_element?(new_view, ~s(input[name="drug[is_otc]"]))
      refute has_element?(new_view, ~s(input[name="drug[is_dangerous_drug]"]))
    end
  end

  describe "Prescriptions tab" do
    test "shows an empty state when the drug has no prescriptions", %{conn: conn} do
      drug = drug_fixture()

      {:ok, view, _html} = live(conn, ~p"/pharmacist/drugs/#{drug.id}?drug_tab=prescriptions")

      assert has_element?(view, "h3", "No prescriptions found")
    end

    test "lists patient, date, prescribing doctor, and status for each allocation", %{
      conn: conn
    } do
      inventory_received = inventory_received_fixture()
      drug = drug_fixture(%{inventory_received: inventory_received})

      drug_batch_fixture(%{
        inventory_received: inventory_received,
        drug: drug,
        is_confirmed: true,
        remaining_quantity: 10
      })

      doctor = user_fixture(%{role: "doctor", name: "Jane Otieno"})
      patient = patient_fixture(%{"first_name" => "Ada", "last_name" => "Achieng"})

      drug_allocation =
        drug_allocation_fixture(%{
          patient: patient,
          doctor_id: doctor.id,
          drugs_assigned: [
            %{
              "brand_name" => drug.brand_name,
              "generic_name" => drug.generic_name,
              "inventory_received_id" => inventory_received.id,
              "quantity" => 1,
              "frequency" => "OD",
              "duration_in_days" => 1
            }
          ]
        })

      {:ok, view, html} =
        live(conn, ~p"/pharmacist/drugs/#{drug.id}?drug_tab=prescriptions")

      assert html =~ "Ada Achieng"
      assert html =~ "Dr. Jane Otieno"
      assert has_element?(view, "#drug_prescriptions", "Pending")
      refute has_element?(view, "h3", "No prescriptions found")

      assert has_element?(
               view,
               ~s(a[href="/pharmacist/drug_allocations/#{drug_allocation.id}"])
             )
    end

    test "shows a Given badge once the allocation has been dispensed", %{conn: conn} do
      inventory_received = inventory_received_fixture()
      drug = drug_fixture(%{inventory_received: inventory_received})

      drug_batch_fixture(%{
        inventory_received: inventory_received,
        drug: drug,
        is_confirmed: true,
        remaining_quantity: 10
      })

      drug_allocation_fixture(%{
        has_been_assigned: true,
        drugs_assigned: [
          %{
            "brand_name" => drug.brand_name,
            "generic_name" => drug.generic_name,
            "inventory_received_id" => inventory_received.id,
            "quantity" => 1,
            "frequency" => "OD",
            "duration_in_days" => 1
          }
        ]
      })

      {:ok, view, _html} =
        live(conn, ~p"/pharmacist/drugs/#{drug.id}?drug_tab=prescriptions")

      assert has_element?(view, "#drug_prescriptions", "Given")
      refute has_element?(view, "#drug_prescriptions", "Pending")
    end

    test "the Prescriptions tab link points at the drug_tab=prescriptions query param", %{
      conn: conn
    } do
      drug = drug_fixture()

      {:ok, view, _html} = live(conn, ~p"/pharmacist/drugs/#{drug.id}")

      assert has_element?(
               view,
               ~s(a[href="/pharmacist/drugs/#{drug.id}?drug_tab=prescriptions"])
             )
    end

    test "loading the page with drug_tab=prescriptions selects that tab", %{conn: conn} do
      drug = drug_fixture()

      {:ok, view, _html} = live(conn, ~p"/pharmacist/drugs/#{drug.id}?drug_tab=prescriptions")

      assert has_element?(view, "div", "Prescriptions across all patients")
    end

    test "still shows prescriptions after switching tabs client-side, not just on a fresh load",
         %{conn: conn} do
      inventory_received = inventory_received_fixture()
      drug = drug_fixture(%{inventory_received: inventory_received})

      drug_batch_fixture(%{
        inventory_received: inventory_received,
        drug: drug,
        is_confirmed: true,
        remaining_quantity: 10
      })

      drug_allocation_fixture(%{
        drugs_assigned: [
          %{
            "brand_name" => drug.brand_name,
            "generic_name" => drug.generic_name,
            "inventory_received_id" => inventory_received.id,
            "quantity" => 1,
            "frequency" => "OD",
            "duration_in_days" => 1
          }
        ]
      })

      {:ok, view, _html} = live(conn, ~p"/pharmacist/drugs/#{drug.id}")

      html =
        view
        |> element(~s(a[href="/pharmacist/drugs/#{drug.id}?drug_tab=prescriptions"]))
        |> render_click()

      refute html =~ "No prescriptions found"
      assert has_element?(view, "#drug_prescriptions")
    end
  end

  describe "Prescriptions tab status filter" do
    defp prescription_drug_setup do
      inventory_received = inventory_received_fixture()
      drug = drug_fixture(%{inventory_received: inventory_received})

      drug_batch_fixture(%{
        inventory_received: inventory_received,
        drug: drug,
        is_confirmed: true,
        remaining_quantity: 10
      })

      {drug, inventory_received}
    end

    defp drug_assigned_for(drug, inventory_received) do
      [
        %{
          "brand_name" => drug.brand_name,
          "generic_name" => drug.generic_name,
          "inventory_received_id" => inventory_received.id,
          "quantity" => 1,
          "frequency" => "OD",
          "duration_in_days" => 1
        }
      ]
    end

    test "filtering by pending hides given allocations, and vice versa", %{conn: conn} do
      {drug, inventory_received} = prescription_drug_setup()

      pending_patient = patient_fixture(%{"first_name" => "Pending", "last_name" => "Patient"})
      given_patient = patient_fixture(%{"first_name" => "Given", "last_name" => "Patient"})

      drug_allocation_fixture(%{
        patient: pending_patient,
        has_been_assigned: false,
        drugs_assigned: drug_assigned_for(drug, inventory_received)
      })

      drug_allocation_fixture(%{
        patient: given_patient,
        has_been_assigned: true,
        drugs_assigned: drug_assigned_for(drug, inventory_received)
      })

      {:ok, view, html} = live(conn, ~p"/pharmacist/drugs/#{drug.id}?drug_tab=prescriptions")
      assert html =~ "Pending Patient"
      assert html =~ "Given Patient"

      html =
        view
        |> element(~s([phx-click="filter_prescriptions_status"][phx-value-status="pending"]))
        |> render_click()

      assert html =~ "Pending Patient"
      refute html =~ "Given Patient"

      assert_patch(
        view,
        ~p"/pharmacist/drugs/#{drug.id}?drug_tab=prescriptions&prescription_status=pending"
      )

      html =
        view
        |> element(~s([phx-click="filter_prescriptions_status"][phx-value-status="given"]))
        |> render_click()

      refute html =~ "Pending Patient"
      assert html =~ "Given Patient"

      html =
        view
        |> element(~s([phx-click="filter_prescriptions_status"][phx-value-status="all"]))
        |> render_click()

      assert html =~ "Pending Patient"
      assert html =~ "Given Patient"
    end

    test "shows a filtered empty state when a filter matches nothing", %{conn: conn} do
      {drug, inventory_received} = prescription_drug_setup()

      drug_allocation_fixture(%{
        has_been_assigned: false,
        drugs_assigned: drug_assigned_for(drug, inventory_received)
      })

      {:ok, _view, html} =
        live(
          conn,
          ~p"/pharmacist/drugs/#{drug.id}?drug_tab=prescriptions&prescription_status=given"
        )

      assert html =~ "No prescriptions match this filter."
    end
  end

  describe "Prescriptions tab pagination" do
    test "paginates once there are more prescriptions than fit on one page", %{conn: conn} do
      {drug, inventory_received} = prescription_drug_setup()

      for n <- 1..11 do
        patient_fixture(%{"first_name" => "Patient#{n}", "last_name" => "Prescribed"})
        |> then(fn patient ->
          drug_allocation_fixture(%{
            patient: patient,
            drugs_assigned: drug_assigned_for(drug, inventory_received)
          })
        end)
      end

      {:ok, view, html} = live(conn, ~p"/pharmacist/drugs/#{drug.id}?drug_tab=prescriptions")

      assert html =~ "Showing 1"
      assert html =~ "Patient11 Prescribed"
      refute html =~ "Patient1 Prescribed"

      html =
        view
        |> element(~s([phx-click="paginate_prescriptions"][phx-value-page="2"]))
        |> render_click()

      assert html =~ "Patient1 Prescribed"
      refute html =~ "Patient11 Prescribed"

      assert_patch(
        view,
        ~p"/pharmacist/drugs/#{drug.id}?drug_tab=prescriptions&prescription_page=2"
      )
    end

    test "does not crash when there are zero prescriptions (page/total_pages stay >= 1)", %{
      conn: conn
    } do
      {drug, _inventory_received} = prescription_drug_setup()

      {:ok, view, _html} = live(conn, ~p"/pharmacist/drugs/#{drug.id}?drug_tab=prescriptions")

      assert has_element?(view, "h3", "No prescriptions found")
      refute has_element?(view, ~s([phx-click="paginate_prescriptions"]))
    end
  end

  describe "Drug Allocations tab" do
    test "shows an empty state when the drug has never been dispensed", %{conn: conn} do
      drug = drug_fixture()

      {:ok, view, _html} = live(conn, ~p"/pharmacist/drugs/#{drug.id}?drug_tab=allocations")

      assert has_element?(view, "h3", "No dispensing activity found")
    end

    test "does not crash when there are zero drugs_given (page/total_pages stay >= 1)", %{
      conn: conn
    } do
      drug = drug_fixture()

      {:ok, view, _html} = live(conn, ~p"/pharmacist/drugs/#{drug.id}?drug_tab=allocations")

      assert has_element?(view, "h3", "No dispensing activity found")
      refute has_element?(view, ~s([phx-click="paginate_drugs_given"]))
    end

    test "lists dispensing activity once the drug has been given out", %{conn: conn} do
      drug = drug_fixture()
      Medcamp.DrugsGivenFixtures.drug_given_fixture(%{drug: drug})

      {:ok, view, _html} = live(conn, ~p"/pharmacist/drugs/#{drug.id}?drug_tab=allocations")

      refute has_element?(view, "h3", "No dispensing activity found")
      assert has_element?(view, "#drugs_given")
    end

    test "still shows dispensing activity after switching tabs client-side, not just on a fresh load",
         %{conn: conn} do
      drug = drug_fixture()
      Medcamp.DrugsGivenFixtures.drug_given_fixture(%{drug: drug})

      # Land on the default (Batches) tab first, exactly like a real user
      # would, then patch over to Drug Allocations without a fresh mount.
      {:ok, view, _html} = live(conn, ~p"/pharmacist/drugs/#{drug.id}")

      html =
        view
        |> element(~s(a[href="/pharmacist/drugs/#{drug.id}?drug_tab=allocations"]))
        |> render_click()

      refute html =~ "No dispensing activity found"
      assert has_element?(view, "#drugs_given")
    end
  end
end
