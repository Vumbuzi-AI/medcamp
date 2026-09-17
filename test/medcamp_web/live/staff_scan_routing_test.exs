defmodule MedcampWeb.StaffScanRoutingTest do
  use MedcampWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Medcamp.AccountsFixtures
  import Medcamp.PatientsFixtures
  import Medcamp.TriagesFixtures

  test "nurse search selection opens the new triage", %{conn: conn} do
    nurse = user_fixture(%{role: "nurse"})
    patient = patient_fixture(%{:creator => nurse, "first_name" => "ScanNurse"})
    {:ok, view, _html} = live(log_in_user(conn, nurse), "/nurse/scan")

    view
    |> element("form[phx-change=search_patients]")
    |> render_change(%{"search" => "ScanNurse"})

    view |> element("[phx-click=select_patient][phx-value-id='#{patient.id}']") |> render_click()

    assert_redirect(view, "/8018/#{patient.gsrn}/medical-camp/triages/new")

    {:ok, _triage_view, html} =
      live(log_in_user(conn, nurse), "/8018/#{patient.gsrn}/medical-camp/triages/new")

    assert html =~ "New Triage"
  end

  test "doctor scan opens a note with triage and bio data tab", %{conn: conn} do
    doctor = user_fixture(%{role: "doctor"})
    patient = patient_fixture(%{creator: doctor})
    triage_fixture(%{patient: patient, triage_notes: "Latest scan triage"})
    {:ok, view, _html} = live(log_in_user(conn, doctor), "/doctor/scan")

    view
    |> element("form[phx-submit=check]")
    |> render_submit(%{"value" => %{"qr" => patient.gsrn}})

    path = "/8018/#{patient.gsrn}/medical-camp/doctor_notes/new"
    assert_redirect(view, path)
    {:ok, note_view, html} = live(log_in_user(conn, doctor), path)
    assert html =~ "Triage &amp; Bio Data" or html =~ "Triage & Bio Data"

    details =
      note_view |> element("[phx-click=switch_panel][phx-value-panel=triage]") |> render_click()

    assert details =~ "Latest scan triage"
    assert details =~ "Bio Data"
  end

  for {role, scan_path, destination} <- [
        {"labtechnician", "/lab/scan", "/lab"},
        {"pharmacist", "/pharmacist/scan", "/pharmacist"}
      ] do
    test "#{role} search selection opens patient requests", %{conn: conn} do
      user = user_fixture(%{role: unquote(role)})
      patient = patient_fixture(%{:creator => user, "first_name" => "ScanRequests"})
      {:ok, view, _html} = live(log_in_user(conn, user), unquote(scan_path))

      view
      |> element("form[phx-change=search_patients]")
      |> render_change(%{"search" => "ScanRequests"})

      view
      |> element("[phx-click=select_patient][phx-value-id='#{patient.id}']")
      |> render_click()

      suffix = if unquote(role) == "labtechnician", do: "lab_results", else: "drug_allocations"
      assert_redirect(view, "#{unquote(destination)}/#{patient.id}/#{suffix}")
    end
  end
end
