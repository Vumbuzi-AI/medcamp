defmodule Medcamp.TriagesTest do
  use Medcamp.DataCase

  alias Medcamp.Triages

  describe "triages" do
    alias Medcamp.Triages.Triage

    import Medcamp.TriagesFixtures

    @invalid_attrs %{
      date: nil,
      temperature: nil,
      blood_pressure: nil,
      pulse_rate: nil,
      oxygen_saturation: nil,
      height: nil,
      weight: nil,
      triage_notes: nil
    }

    test "list_triages/0 returns all triages" do
      triage = triage_fixture()
      assert [%Triage{id: id}] = Triages.list_triages()
      assert id == triage.id
    end

    test "get_triage!/1 returns the triage with given id" do
      triage = triage_fixture()
      assert Triages.get_triage!(triage.id) == triage
    end

    test "create_triage/1 with valid data creates a triage" do
      patient = Medcamp.PatientsFixtures.patient_fixture()
      creator = Medcamp.AccountsFixtures.user_fixture(%{role: "nurse"})

      valid_attrs = %{
        date: ~D[2025-02-21],
        temperature: 120.5,
        blood_pressure: "120/80",
        pulse_rate: 120.5,
        oxygen_saturation: 120.5,
        height: 120.5,
        weight: 120.5,
        triage_notes: "some triage_notes",
        patient_id: patient.id,
        creator_id: creator.id
      }

      assert {:ok, %Triage{} = triage} = Triages.create_triage(valid_attrs)
      assert triage.date == ~D[2025-02-21]
      assert triage.temperature == 120.5
      assert triage.blood_pressure == "120/80"
      assert triage.bmi == 82.99
      assert triage.pulse_rate == 120.5
      assert triage.oxygen_saturation == 120.5
      assert triage.height == 120.5
      assert triage.weight == 120.5
      assert triage.triage_notes == "some triage_notes"
      assert triage.patient_id == patient.id
      assert triage.creator_id == creator.id
    end

    test "create_triage/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Triages.create_triage(@invalid_attrs)
    end

    test "update_triage/2 with valid data updates the triage" do
      triage = triage_fixture()

      update_attrs = %{
        date: ~D[2025-02-22],
        temperature: 456.7,
        blood_pressure: "130/90",
        pulse_rate: 456.7,
        oxygen_saturation: 456.7,
        height: 456.7,
        weight: 456.7,
        triage_notes: "some updated triage_notes"
      }

      assert {:ok, %Triage{} = triage} = Triages.update_triage(triage, update_attrs)
      assert triage.date == ~D[2025-02-22]
      assert triage.temperature == 456.7
      assert triage.blood_pressure == "130/90"
      assert triage.pulse_rate == 456.7
      assert triage.oxygen_saturation == 456.7
      assert triage.height == 456.7
      assert triage.weight == 456.7
      assert triage.triage_notes == "some updated triage_notes"
    end

    test "update_triage/2 with invalid data returns error changeset" do
      triage = triage_fixture()
      assert {:error, %Ecto.Changeset{}} = Triages.update_triage(triage, @invalid_attrs)
      assert triage == Triages.get_triage!(triage.id)
    end

    test "delete_triage/1 deletes the triage" do
      triage = triage_fixture()
      assert {:ok, %Triage{}} = Triages.delete_triage(triage)
      assert_raise Ecto.NoResultsError, fn -> Triages.get_triage!(triage.id) end
    end

    test "change_triage/1 returns a triage changeset" do
      triage = triage_fixture()
      assert %Ecto.Changeset{} = Triages.change_triage(triage)
    end
  end
end
