defmodule Medcamp.TenancyTest do
  @moduledoc """
  The isolation guarantee, tested directly: two organisations, and neither can
  see the other's patients through the ordinary context functions.
  """

  use Medcamp.DataCase, async: true

  import Medcamp.OrganisationsFixtures

  alias Medcamp.Patients
  alias Medcamp.Tenancy

  defp create_patient(name) do
    {:ok, patient} =
      Patients.create_patient(%{
        "first_name" => name,
        "last_name" => "Test",
        "gender" => "female",
        "date_of_birth" => "1990-01-01"
      })

    patient
  end

  describe "query scoping" do
    test "a listing only returns the current organisation's rows", %{organisation: org_a} do
      org_b = organisation_fixture()

      mine = create_patient("Ada")
      theirs = Tenancy.with_org(org_b.id, fn -> create_patient("Grace") end)

      assert mine.organisation_id == org_a.id
      assert theirs.organisation_id == org_b.id

      ids = Enum.map(Patients.list_patients(), & &1.id)
      assert mine.id in ids
      refute theirs.id in ids

      other_ids =
        Tenancy.with_org(org_b.id, fn -> Enum.map(Patients.list_patients(), & &1.id) end)

      assert theirs.id in other_ids
      refute mine.id in other_ids
    end

    test "fetching another organisation's record by id finds nothing", %{organisation: org_a} do
      org_b = organisation_fixture()
      theirs = Tenancy.with_org(org_b.id, fn -> create_patient("Grace") end)

      assert Tenancy.current_org_id() == org_a.id

      assert_raise Ecto.NoResultsError, fn -> Patients.get_patient!(theirs.id) end
    end

    test "a tenant query raises rather than leaking when no organisation is set" do
      Tenancy.clear_org_id()

      assert_raise RuntimeError, ~r/no organisation set/i, fn ->
        Patients.list_patients()
      end
    end

    test "writes are stamped with the current organisation", %{organisation: org} do
      assert create_patient("Ada").organisation_id == org.id
    end

    test "with_org/2 restores the previous organisation", %{organisation: org_a} do
      org_b = organisation_fixture()

      Tenancy.with_org(org_b.id, fn -> assert Tenancy.current_org_id() == org_b.id end)

      assert Tenancy.current_org_id() == org_a.id
    end
  end

  describe "globally unique identifiers" do
    test "a GSRN taken by another organisation is not reissued", %{organisation: _org_a} do
      org_b = organisation_fixture()

      theirs = Tenancy.with_org(org_b.id, fn -> create_patient("Grace") end)

      # Allocated from the same global sequence, so it cannot collide with a
      # GSRN another organisation already holds.
      refute Patients.get_available_gsrn() == theirs.gsrn
    end
  end
end
