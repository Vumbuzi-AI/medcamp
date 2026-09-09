defmodule MedcampWeb.LabSurveillanceLiveTest do
  use MedcampWeb.ConnCase

  import Medcamp.AccountsFixtures
  import Phoenix.LiveViewTest

  test "lab technicians can open and filter the surveillance summary", %{conn: conn} do
    user = user_fixture(%{role: "labtechnician"})

    {:ok, view, html} = conn |> log_in_user(user) |> live("/lab/surveillance")

    assert html =~ "Search lab test"
    assert html =~ "Filters"
    assert html =~ "Laboratory Surveillance Summary"
    assert has_element?(view, "#lab-surveillance-table")

    view
    |> form("#lab-surveillance-filters-form", %{
      "date_from" => "2026-08-01",
      "date_to" => "2026-08-31",
      "age_group" => "under_five"
    })
    |> render_submit()

    assert has_element?(view, "#surveillance-age-group option[selected][value='under_five']")
  end

  test "admins can open the same surveillance summary", %{conn: conn} do
    user = user_fixture(%{role: "admin"})

    {:ok, view, html} = conn |> log_in_user(user) |> live("/admin/lab_surveillance")

    assert html =~ "Laboratory Surveillance Summary"
    assert has_element?(view, "#lab-surveillance-table")
  end
end
