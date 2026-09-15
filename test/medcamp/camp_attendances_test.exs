defmodule Medcamp.CampAttendancesTest do
  use Medcamp.DataCase, async: true

  import Medcamp.AccountsFixtures

  alias Medcamp.CampAttendances
  alias Medcamp.Camps
  alias Medcamp.Patients

  defp a_patient(name) do
    {:ok, patient} =
      Patients.create_patient(%{
        "first_name" => name,
        "last_name" => "Test",
        "phone_number" => "0700#{:rand.uniform(999_999)}",
        "date_of_birth" => "1990-01-01",
        "gender" => "Female",
        "home_address" => "Nairobi",
        "creator_id" => user_fixture(%{role: "receptionist"}).id
      })

    patient
  end

  test "record/2 is idempotent per (patient, camp)" do
    {:ok, camp} = Camps.create_camp(%{name: "March"})
    p = a_patient("Ann")

    assert {:ok, %Medcamp.Camps.CampAttendance{}} = CampAttendances.record(p.id, camp.id)
    assert {:ok, _} = CampAttendances.record(p.id, camp.id)

    assert CampAttendances.camp_count(p.id) == 1
    assert CampAttendances.attended?(p.id, camp.id)
  end

  test "camp_count/1 counts distinct camps for the patient" do
    {:ok, c1} = Camps.create_camp(%{name: "March"})
    {:ok, c2} = Camps.create_camp(%{name: "September"})
    p = a_patient("Bea")

    CampAttendances.record(p.id, c1.id)
    CampAttendances.record(p.id, c2.id)

    assert CampAttendances.camp_count(p.id) == 2
  end

  test "patient_count_for_camp/1 counts distinct patients at a camp" do
    {:ok, camp} = Camps.create_camp(%{name: "March"})
    p1 = a_patient("Cara")
    p2 = a_patient("Dee")

    CampAttendances.record(p1.id, camp.id)
    CampAttendances.record(p2.id, camp.id)
    CampAttendances.record(p1.id, camp.id)

    assert CampAttendances.patient_count_for_camp(camp.id) == 2
  end
end
