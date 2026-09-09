defmodule MedcampWeb.AdminMedicalCampLive.CampScopeTest do
  @moduledoc """
  The medical camp dashboard scopes to the organisation's active camp via
  `camp_attendances`, not a fixed calendar window.
  """
  use MedcampWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Medcamp.AccountsFixtures

  alias Medcamp.CampAttendances
  alias Medcamp.Camps
  alias Medcamp.Patients
  alias Medcamp.Tenancy

  setup %{conn: conn} do
    admin = user_fixture(%{role: "admin"})
    %{conn: log_in_user(conn, admin), org_id: admin.organisation_id}
  end

  defp in_org(org_id, fun), do: Tenancy.with_org(org_id, fun)

  defp a_patient(org_id, name) do
    in_org(org_id, fn ->
      {:ok, patient} =
        Patients.create_patient(%{
          "first_name" => name,
          "last_name" => "Test",
          "gender" => "Female",
          "date_of_birth" => "1990-01-01",
          "phone_number" => "0712345678",
          "home_address" => "Nairobi",
          "creator_id" => user_fixture(%{role: "receptionist"}).id
        })

      patient
    end)
  end

  test "Camp.days/1 lists every calendar day in the range" do
    camp = %Camps.Camp{start_date: ~D[2026-05-01], end_date: ~D[2026-05-03]}
    assert Camps.Camp.days(camp) == [~D[2026-05-01], ~D[2026-05-02], ~D[2026-05-03]]

    assert Camps.Camp.days(%Camps.Camp{start_date: ~D[2026-05-01], end_date: nil}) ==
             [~D[2026-05-01]]

    assert Camps.Camp.days(%Camps.Camp{start_date: nil, end_date: nil}) == []
  end

  test "the dashboard counts only patients who attended the active camp", %{
    conn: conn,
    org_id: org_id
  } do
    {:ok, camp} = in_org(org_id, fn -> Camps.create_camp(%{name: "May Camp"}) end)

    attended_a = a_patient(org_id, "Amina")
    attended_b = a_patient(org_id, "Brian")
    _not_attended = a_patient(org_id, "Cleo")

    in_org(org_id, fn ->
      CampAttendances.record(attended_a.id, camp.id)
      CampAttendances.record(attended_b.id, camp.id)
    end)

    {:ok, view, html} = live(conn, ~p"/admin/medical_camp")

    # Header patient count is the camp roster, not every org patient.
    assert html =~ "2 patients"

    roster =
      view
      |> element("button[phx-value-tab='patient_data']")
      |> render_click()

    assert roster =~ "Amina"
    assert roster =~ "Brian"
    refute roster =~ "Cleo"
  end

  test "list_patients_for_camp_on/2 narrows to one camp day", %{org_id: org_id} do
    {:ok, camp} = in_org(org_id, fn -> Camps.create_camp(%{name: "Two Day Camp"}) end)
    patient = a_patient(org_id, "Dalia")

    in_org(org_id, fn -> CampAttendances.record(patient.id, camp.id) end)

    today = Date.utc_today()

    assert in_org(org_id, fn -> Patients.list_patients_for_camp_on(camp.id, today) end)
           |> Enum.map(& &1.id) == [patient.id]

    assert in_org(org_id, fn ->
             Patients.list_patients_for_camp_on(camp.id, Date.add(today, -30))
           end) == []
  end
end
