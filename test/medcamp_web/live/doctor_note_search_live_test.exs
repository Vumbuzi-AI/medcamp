defmodule MedcampWeb.DoctorNoteSearchLiveTest do
  use MedcampWeb.ConnCase

  import Medcamp.AccountsFixtures
  import Medcamp.DoctorNotesFixtures
  import Phoenix.LiveViewTest

  test "admin can search doctor notes and see auditable occurrence details", %{conn: conn} do
    admin = user_fixture(%{role: "admin"})
    doctor_note_fixture(%{date: ~D[2026-08-03], diagnosis: "Typhoid typhoid"})

    {:ok, view, html} = conn |> log_in_user(admin) |> live("/admin/doctor-note-search")

    assert html =~ "Doctor Note Master Search"
    assert html =~ "Filters"
    assert html =~ "doctor-note-search-filters"

    view
    |> form("#doctor-note-search-form", %{
      "filters" => %{
        "query" => "typhoid",
        "date_from" => "2026-08-01",
        "date_to" => "2026-08-31",
        "age_from" => "",
        "age_to" => "",
        "sex" => ""
      }
    })
    |> render_submit()

    assert has_element?(view, "#doctor-note-search-results")
    assert render(view) =~ "2 occurrences"
    assert render(view) =~ "2 found"
  end
end
