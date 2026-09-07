defmodule MedcampWeb.DoctorsPagePatientLive.AllDoctorProceduresLiveTest do
  use MedcampWeb.ConnCase

  import Phoenix.LiveViewTest
  import Medcamp.AccountsFixtures
  import Medcamp.DoctorProceduresFixtures
  import Medcamp.PatientsFixtures
  import Medcamp.ProceduresFixtures

  setup %{conn: conn} do
    doctor = user_fixture(%{role: "doctor", name: "Dr. Procedure"})
    patient = patient_fixture(%{"first_name" => "Jane", "last_name" => "Wanjiku"})
    procedure = procedure_fixture(%{name: "Skin biopsy", price: 3_000})

    doctor_procedure_fixture(%{
      doctor: doctor,
      patient: patient,
      procedure: procedure,
      total_amount_paid: 3_000
    })

    %{conn: log_in_user(conn, doctor), doctor: doctor, procedure: procedure}
  end

  test "shows performed procedures and filters by procedure name", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/doctor/doctor_procedures")

    assert html =~ "Procedures done"
    assert html =~ "Skin biopsy"
    assert html =~ "Jane Wanjiku"
    assert html =~ "KES 3000"

    html = render_change(view, "search", %{"search" => "Skin"})
    assert html =~ "Skin biopsy"

    html = render_change(view, "search", %{"search" => "missing"})
    assert html =~ "No procedures match these filters"
  end

  test "filters performed procedures by date and shows date filters on the frequency view", %{
    conn: conn
  } do
    {:ok, view, _html} = live(conn, ~p"/doctor/doctor_procedures")

    html =
      render_submit(view, "apply_filters", %{
        "filters" => %{
          "date_from" => "2030-01-01",
          "date_to" => "2030-01-31"
        }
      })

    assert html =~ "No procedures match these filters"
    assert html =~ "From 2030-01-01"
    assert html =~ "To 2030-01-31"

    {:ok, types_view, _html} = live(conn, ~p"/doctor/doctor_procedures/types")
    assert has_element?(types_view, "#doctor-procedures-date-from")
    assert has_element?(types_view, "#doctor-procedures-date-to")
  end

  test "shows type frequencies and the type detail history", %{
    conn: conn,
    procedure: procedure
  } do
    {:ok, _view, html} = live(conn, ~p"/doctor/doctor_procedures/types")

    assert html =~ "Procedure types &amp; frequency"
    assert html =~ "Skin biopsy"
    assert html =~ "Times done"
    assert html =~ "People treated"

    {:ok, _view, html} = live(conn, ~p"/doctor/doctor_procedures/types/#{procedure.id}")

    assert html =~ "Procedure history"
    assert html =~ "Jane Wanjiku"
    assert html =~ "Amount collected"
    assert html =~ "KES 3000"
  end
end
