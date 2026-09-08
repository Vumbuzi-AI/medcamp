defmodule Medcamp.CampsTest do
  use Medcamp.DataCase

  alias Medcamp.Camps
  alias Medcamp.Camps.Camp
  alias Medcamp.Camps.Scope
  alias Medcamp.PatientVisits

  import Medcamp.CampsFixtures
  import Medcamp.PatientVisitsFixtures

  describe "camps" do
    test "create_camp/1 makes the organisation's first camp active" do
      assert {:ok, %Camp{} = camp} = Camps.create_camp(%{"name" => "Kajiado Weekend"})
      assert camp.is_active
      assert Camps.get_active_camp().id == camp.id
    end

    test "create_camp/1 leaves later camps inactive" do
      camp_fixture()
      assert {:ok, %Camp{is_active: false}} = Camps.create_camp(%{"name" => "Turkana"})
    end

    test "create_camp/1 requires a name" do
      assert {:error, changeset} = Camps.create_camp(%{"name" => ""})
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "create_camp/1 rejects an end date before the start date" do
      assert {:error, changeset} =
               Camps.create_camp(%{
                 "name" => "Backwards",
                 "start_date" => ~D[2026-03-10],
                 "end_date" => ~D[2026-03-01]
               })

      assert %{end_date: ["must be on or after the start date"]} = errors_on(changeset)
    end

    test "set_active_camp/1 deactivates whichever camp was active" do
      first = active_camp_fixture()
      second = camp_fixture()

      assert {:ok, _} = Camps.set_active_camp(second)
      refute Camps.get_camp!(first.id).is_active
      assert Camps.get_active_camp().id == second.id
    end

    test "clear_active_camp/0 leaves the organisation with no active camp" do
      active_camp_fixture()
      assert :ok = Camps.clear_active_camp()
      assert Camps.get_active_camp() == nil
    end

    test "delete_camp/1 refuses a camp that already has records" do
      camp = active_camp_fixture()
      Scope.put_active_camp_id(camp.id)
      patient_visit_fixture()

      assert {:error, :camp_has_records} = Camps.delete_camp(camp)
      assert Camps.get_camp(camp.id)
    end

    test "delete_camp/1 removes an unused camp" do
      camp = camp_fixture()
      assert {:ok, _} = Camps.delete_camp(camp)
      assert Camps.get_camp(camp.id) == nil
    end

    test "camps do not cross between organisations" do
      camp_fixture(%{"name" => "Ours"})
      other = Medcamp.OrganisationsFixtures.organisation_fixture()

      Medcamp.Tenancy.with_org(other.id, fn ->
        assert Camps.list_camps() == []
      end)
    end
  end

  describe "stamping records with the active camp" do
    test "a record created while a camp is active belongs to it" do
      camp = active_camp_fixture()
      Scope.put_active_camp_id(camp.id)

      visit = patient_visit_fixture()

      assert PatientVisits.get_patient_visit!(visit.id).camp_id == camp.id
    end

    test "a record created with no active camp belongs to none" do
      Scope.put_active_camp_id(nil)

      visit = patient_visit_fixture()

      assert PatientVisits.get_patient_visit!(visit.id).camp_id == nil
    end

    test "a record keeps the camp it happened at when edited later" do
      first = active_camp_fixture()
      Scope.put_active_camp_id(first.id)
      visit = patient_visit_fixture()

      second = camp_fixture()
      Scope.put_active_camp_id(second.id)

      {:ok, visit} = PatientVisits.update_patient_visit(visit, %{reason: "amended"})

      assert visit.camp_id == first.id
    end
  end

  describe "the camp filter" do
    setup do
      kajiado = camp_fixture(%{"name" => "Kajiado"})
      turkana = camp_fixture(%{"name" => "Turkana"})

      Scope.put_active_camp_id(kajiado.id)
      kajiado_visit = patient_visit_fixture()

      Scope.put_active_camp_id(turkana.id)
      turkana_visit = patient_visit_fixture()

      Scope.put_active_camp_id(nil)

      %{
        kajiado: kajiado,
        turkana: turkana,
        kajiado_visit: kajiado_visit,
        turkana_visit: turkana_visit
      }
    end

    test "unset, it shows every camp", ctx do
      ids = PatientVisits.list_patient_visits() |> Enum.map(& &1.id) |> Enum.sort()
      assert ids == Enum.sort([ctx.kajiado_visit.id, ctx.turkana_visit.id])
    end

    test "set, it shows only that camp's records", ctx do
      Scope.with_camp_filter(ctx.kajiado.id, fn ->
        assert Enum.map(PatientVisits.list_patient_visits(), & &1.id) == [ctx.kajiado_visit.id]
      end)
    end

    test "it is restored after with_camp_filter/2", ctx do
      Scope.with_camp_filter(ctx.turkana.id, fn -> :ok end)
      assert Scope.camp_filter_id() == nil
    end

    test "across_camps/1 looks past a filter in effect", ctx do
      Scope.with_camp_filter(ctx.kajiado.id, fn ->
        assert Scope.across_camps(fn -> length(PatientVisits.list_patient_visits()) end) == 2
      end)
    end

    test "it does not reach tables that are not camp-scoped", ctx do
      patient_count = length(Medcamp.Patients.list_patients())

      Scope.with_camp_filter(ctx.kajiado.id, fn ->
        assert length(Medcamp.Patients.list_patients()) == patient_count
      end)
    end
  end
end
