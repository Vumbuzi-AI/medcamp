defmodule Medcamp.ReferralsTest do
  use Medcamp.DataCase

  alias Medcamp.Referrals

  describe "referrals" do
    alias Medcamp.Referrals.Referral

    import Medcamp.ReferralsFixtures
    import Medcamp.DoctorNotesFixtures

    @invalid_attrs %{date: nil, time: nil, referral_note: nil, hospital: nil}

    test "list_referrals/0 returns all referrals" do
      referral = referral_fixture()
      assert Referrals.list_referrals() == [referral]
    end

    test "get_referral!/1 returns the referral with given id" do
      referral = referral_fixture()
      assert Referrals.get_referral!(referral.id) == referral
    end

    test "create_referral/1 with valid data creates a referral" do
      doctor_note = doctor_note_fixture()

      valid_attrs = %{
        date: ~D[2025-04-12],
        time: ~T[14:00:00],
        referral_note: "some referral_note",
        hospital: "some hospital",
        patient_id: doctor_note.patient_id,
        doctor_id: doctor_note.doctor_id,
        doctor_note_id: doctor_note.id
      }

      assert {:ok, %Referral{} = referral} = Referrals.create_referral(valid_attrs)
      assert referral.date == ~D[2025-04-12]
      assert referral.time == ~T[14:00:00]
      assert referral.referral_note == "some referral_note"
      assert referral.hospital == "some hospital"
      assert referral.patient_id == doctor_note.patient_id
      assert referral.doctor_id == doctor_note.doctor_id
      assert referral.doctor_note_id == doctor_note.id
    end

    test "create_referral/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Referrals.create_referral(@invalid_attrs)
    end

    test "update_referral/2 with valid data updates the referral" do
      referral = referral_fixture()

      update_attrs = %{
        date: ~D[2025-04-13],
        time: ~T[15:01:01],
        referral_note: "some updated referral_note",
        hospital: "some updated hospital"
      }

      assert {:ok, %Referral{} = referral} = Referrals.update_referral(referral, update_attrs)
      assert referral.date == ~D[2025-04-13]
      assert referral.time == ~T[15:01:01]
      assert referral.referral_note == "some updated referral_note"
      assert referral.hospital == "some updated hospital"
    end

    test "update_referral/2 with invalid data returns error changeset" do
      referral = referral_fixture()
      assert {:error, %Ecto.Changeset{}} = Referrals.update_referral(referral, @invalid_attrs)
      assert referral == Referrals.get_referral!(referral.id)
    end

    test "delete_referral/1 deletes the referral" do
      referral = referral_fixture()
      assert {:ok, %Referral{}} = Referrals.delete_referral(referral)
      assert_raise Ecto.NoResultsError, fn -> Referrals.get_referral!(referral.id) end
    end

    test "change_referral/1 returns a referral changeset" do
      referral = referral_fixture()
      assert %Ecto.Changeset{} = Referrals.change_referral(referral)
    end
  end
end
