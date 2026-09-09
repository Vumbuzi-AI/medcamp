defmodule Medcamp.PatientsTest do
  use Medcamp.DataCase

  alias Medcamp.Patients
  alias Medcamp.Patients.Patient

  import Medcamp.PatientsFixtures
  import Medcamp.AccountsFixtures

  describe "patients" do
    @invalid_attrs %{
      first_name: nil,
      phone_number: nil,
      date_of_birth: nil,
      gender: nil,
      home_address: nil
    }

    test "list_patients/0 returns all patients" do
      patient = patient_fixture()

      expected =
        patient
        |> Patient.with_age()
        |> Medcamp.Repo.preload(:documents)

      assert Patients.list_patients() == [expected]
    end

    test "get_patient!/1 returns the patient with given id" do
      patient = patient_fixture()

      expected =
        patient
        |> Patient.with_age()
        |> Medcamp.Repo.preload(:documents)

      assert Patients.get_patient!(patient.id) == expected
    end

    test "create_patient/1 with valid data creates a patient" do
      creator = user_fixture()

      valid_attrs = %{
        first_name: "Some",
        last_name: "Patient",
        email: "some.email@example.com",
        phone_number: "0712345678",
        date_of_birth: ~D[2025-02-21],
        gender: "some gender",
        home_address: "some home_address",
        emergency_contact_relationship: "some emergency_contact_relationship",
        creator_id: creator.id
      }

      assert {:ok, %Patient{} = patient} = Patients.create_patient(valid_attrs)
      assert patient.first_name == "Some"
      assert patient.last_name == "Patient"
      assert patient.email == "some.email@example.com"
      assert patient.phone_number == "0712345678"
      assert patient.date_of_birth == ~D[2025-02-21]
      assert patient.gender == "some gender"
      assert patient.home_address == "some home_address"

      assert patient.emergency_contact_relationship ==
               "some emergency_contact_relationship"
    end

    test "create_patient/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Patients.create_patient(@invalid_attrs)
    end

    test "create_patient/1 stores national ID and birth certificate details" do
      creator = user_fixture()

      valid_attrs = %{
        first_name: "Some",
        phone_number: "0712345678",
        date_of_birth: ~D[2025-02-21],
        gender: "some gender",
        home_address: "some home_address",
        creator_id: creator.id,
        national_id: "12345678",
        national_id_document: "/uploads/national-id-123.pdf",
        birth_certificate_number: "BC-987654",
        birth_certificate_document: "/uploads/birth-cert-987.pdf"
      }

      assert {:ok, %Patient{} = patient} = Patients.create_patient(valid_attrs)
      assert patient.national_id == "12345678"
      assert patient.national_id_document == "/uploads/national-id-123.pdf"
      assert patient.birth_certificate_number == "BC-987654"
      assert patient.birth_certificate_document == "/uploads/birth-cert-987.pdf"
    end

    test "create_patient/1 does not require birth certificate or national ID document" do
      creator = user_fixture()

      valid_attrs = %{
        first_name: "Some",
        phone_number: "0712345678",
        date_of_birth: ~D[2025-02-21],
        gender: "some gender",
        home_address: "some home_address",
        creator_id: creator.id
      }

      assert {:ok, %Patient{} = patient} = Patients.create_patient(valid_attrs)
      assert patient.national_id_document == nil
      assert patient.birth_certificate_number == nil
      assert patient.birth_certificate_document == nil
    end

    test "create_patient/1 rejects a garbage single-character email" do
      creator = user_fixture()

      valid_attrs = %{
        first_name: "Some",
        phone_number: "0712345678",
        date_of_birth: ~D[2025-02-21],
        gender: "some gender",
        home_address: "some home_address",
        creator_id: creator.id,
        email: "l"
      }

      assert {:error, changeset} = Patients.create_patient(valid_attrs)
      assert "must be a valid email address" in errors_on(changeset).email
    end

    test "create_patient/1 accepts a well-formed email" do
      creator = user_fixture()

      valid_attrs = %{
        first_name: "Some",
        phone_number: "0712345678",
        date_of_birth: ~D[2025-02-21],
        gender: "some gender",
        home_address: "some home_address",
        creator_id: creator.id,
        email: "jane.doe@example.com"
      }

      assert {:ok, patient} = Patients.create_patient(valid_attrs)
      assert patient.email == "jane.doe@example.com"
    end

    test "create_patient/1 rejects a garbage single-character phone number" do
      creator = user_fixture()

      valid_attrs = %{
        first_name: "Some",
        phone_number: "l",
        date_of_birth: ~D[2025-02-21],
        gender: "some gender",
        home_address: "some home_address",
        creator_id: creator.id
      }

      assert {:error, changeset} = Patients.create_patient(valid_attrs)
      assert "is not a valid phone number" in errors_on(changeset).phone_number
    end

    test "create_patient/1 rejects a phone number that is too short" do
      creator = user_fixture()

      valid_attrs = %{
        first_name: "Some",
        phone_number: "12345",
        date_of_birth: ~D[2025-02-21],
        gender: "some gender",
        home_address: "some home_address",
        creator_id: creator.id
      }

      assert {:error, changeset} = Patients.create_patient(valid_attrs)
      assert "is not a valid phone number" in errors_on(changeset).phone_number
    end

    test "create_patient/1 accepts an international phone number with separators" do
      creator = user_fixture()

      valid_attrs = %{
        first_name: "Some",
        phone_number: "+254 (712) 345-678",
        date_of_birth: ~D[2025-02-21],
        gender: "some gender",
        home_address: "some home_address",
        creator_id: creator.id
      }

      assert {:ok, patient} = Patients.create_patient(valid_attrs)
      assert patient.phone_number == "+254 (712) 345-678"
    end

    test "create_patient/1 rejects letters in phone numbers" do
      creator = user_fixture()

      valid_attrs = %{
        first_name: "Some",
        phone_number: "+254 712-CALL",
        date_of_birth: ~D[2025-02-21],
        gender: "some gender",
        home_address: "some home_address",
        creator_id: creator.id
      }

      assert {:error, changeset} = Patients.create_patient(valid_attrs)
      assert "is not a valid phone number" in errors_on(changeset).phone_number
    end

    test "create_patient/1 rejects a garbage single-character first name" do
      creator = user_fixture()

      valid_attrs = %{
        first_name: "l",
        phone_number: "0712345678",
        date_of_birth: ~D[2025-02-21],
        gender: "some gender",
        home_address: "some home_address",
        creator_id: creator.id
      }

      assert {:error, changeset} = Patients.create_patient(valid_attrs)
      assert "should be at least 2 character(s)" in errors_on(changeset).first_name
    end

    test "create_patient/1 rejects a garbage single-character home address" do
      creator = user_fixture()

      valid_attrs = %{
        first_name: "Some",
        phone_number: "0712345678",
        date_of_birth: ~D[2025-02-21],
        gender: "some gender",
        home_address: "l",
        creator_id: creator.id
      }

      assert {:error, changeset} = Patients.create_patient(valid_attrs)
      assert "should be at least 3 character(s)" in errors_on(changeset).home_address
    end

    test "create_patient/1 rejects a date of birth in the future" do
      creator = user_fixture()

      valid_attrs = %{
        first_name: "Some",
        phone_number: "0712345678",
        date_of_birth: Date.add(Date.utc_today(), 1),
        gender: "some gender",
        home_address: "some home_address",
        creator_id: creator.id
      }

      assert {:error, changeset} = Patients.create_patient(valid_attrs)
      assert "cannot be in the future" in errors_on(changeset).date_of_birth
    end

    test "create_patient/1 accepts a date of birth of today" do
      creator = user_fixture()

      valid_attrs = %{
        first_name: "Some",
        phone_number: "0712345678",
        date_of_birth: Date.utc_today(),
        gender: "some gender",
        home_address: "some home_address",
        creator_id: creator.id
      }

      assert {:ok, patient} = Patients.create_patient(valid_attrs)
      assert patient.date_of_birth == Date.utc_today()
    end

    test "create_patient/1 rejects a garbage single-character emergency contact name" do
      creator = user_fixture()

      valid_attrs = %{
        first_name: "Some",
        phone_number: "0712345678",
        date_of_birth: ~D[2025-02-21],
        gender: "some gender",
        home_address: "some home_address",
        creator_id: creator.id,
        emergency_contact_name: "l"
      }

      assert {:error, changeset} = Patients.create_patient(valid_attrs)
      assert "should be at least 2 character(s)" in errors_on(changeset).emergency_contact_name
    end

    test "create_patient/1 rejects a garbage emergency contact phone number" do
      creator = user_fixture()

      valid_attrs = %{
        first_name: "Some",
        phone_number: "0712345678",
        date_of_birth: ~D[2025-02-21],
        gender: "some gender",
        home_address: "some home_address",
        creator_id: creator.id,
        emergency_contact_phone_number: "l"
      }

      assert {:error, changeset} = Patients.create_patient(valid_attrs)

      assert "is not a valid phone number" in errors_on(changeset).emergency_contact_phone_number
    end

    test "create_patient/1 does not require an emergency contact phone number" do
      creator = user_fixture()

      valid_attrs = %{
        first_name: "Some",
        phone_number: "0712345678",
        date_of_birth: ~D[2025-02-21],
        gender: "some gender",
        home_address: "some home_address",
        creator_id: creator.id
      }

      assert {:ok, patient} = Patients.create_patient(valid_attrs)
      assert patient.emergency_contact_phone_number == nil
    end

    test "create_patient/1 handles explicit nil emergency_contact_phone_number without error" do
      creator = user_fixture()

      valid_attrs = %{
        first_name: "Some",
        phone_number: "0712345678",
        date_of_birth: ~D[2025-02-21],
        gender: "some gender",
        home_address: "some home_address",
        creator_id: creator.id,
        emergency_contact_phone_number: nil
      }

      assert {:ok, patient} = Patients.create_patient(valid_attrs)
      assert patient.emergency_contact_phone_number == nil
    end

    test "create_patient/1 handles empty string emergency_contact_phone_number without error" do
      creator = user_fixture()

      valid_attrs = %{
        first_name: "Some",
        phone_number: "0712345678",
        date_of_birth: ~D[2025-02-21],
        gender: "some gender",
        home_address: "some home_address",
        creator_id: creator.id,
        emergency_contact_phone_number: ""
      }

      assert {:ok, patient} = Patients.create_patient(valid_attrs)
      assert patient.emergency_contact_phone_number == nil
    end

    test "update_patient/2 with valid data updates the patient" do
      patient = patient_fixture()

      update_attrs = %{
        first_name: "Updated",
        last_name: "Name",
        email: "updated.email@example.com",
        phone_number: "0798765432",
        date_of_birth: ~D[2025-02-22],
        gender: "some updated gender",
        home_address: "some updated home_address",
        emergency_contact_relationship: "some updated emergency_contact_relationship"
      }

      assert {:ok, %Patient{} = patient} = Patients.update_patient(patient, update_attrs)
      assert patient.first_name == "Updated"
      assert patient.last_name == "Name"
      assert patient.email == "updated.email@example.com"
      assert patient.phone_number == "0798765432"
      assert patient.date_of_birth == ~D[2025-02-22]
      assert patient.gender == "some updated gender"
      assert patient.home_address == "some updated home_address"

      assert patient.emergency_contact_relationship ==
               "some updated emergency_contact_relationship"
    end

    test "update_patient/2 with invalid data returns error changeset" do
      patient = patient_fixture()
      assert {:error, %Ecto.Changeset{}} = Patients.update_patient(patient, @invalid_attrs)

      expected =
        patient
        |> Patient.with_age()
        |> Medcamp.Repo.preload(:documents)

      assert expected == Patients.get_patient!(patient.id)
    end

    test "delete_patient/1 deletes the patient" do
      patient = patient_fixture()
      assert {:ok, %Patient{}} = Patients.delete_patient(patient)
      assert_raise Ecto.NoResultsError, fn -> Patients.get_patient!(patient.id) end
    end

    test "change_patient/1 returns a patient changeset" do
      patient = patient_fixture()
      assert %Ecto.Changeset{} = Patients.change_patient(patient)
    end

    test "filter_patients/1 with creator_id only returns patients registered by that user" do
      creator_a = user_fixture()
      creator_b = user_fixture()
      patient_a = patient_fixture(%{creator: creator_a})
      _patient_b = patient_fixture(%{creator: creator_b})

      result = Patients.filter_patients(%{creator_id: creator_a.id})

      assert Enum.map(result, & &1.id) == [patient_a.id]
    end

    test "filter_patients/1 with creator_id as a string filters the same way" do
      creator_a = user_fixture()
      creator_b = user_fixture()
      patient_a = patient_fixture(%{creator: creator_a})
      _patient_b = patient_fixture(%{creator: creator_b})

      result = Patients.filter_patients(%{creator_id: Integer.to_string(creator_a.id)})

      assert Enum.map(result, & &1.id) == [patient_a.id]
    end
  end

  describe "create_patient/1 PIN delivery" do
    test "sends exactly one PIN email on successful creation" do
      creator = user_fixture()

      attrs = %{
        first_name: "Test",
        last_name: "Patient",
        email: "test.patient@example.com",
        phone_number: "0711999999",
        date_of_birth: ~D[1990-01-01],
        gender: "female",
        home_address: "Nairobi",
        creator_id: creator.id
      }

      assert {:ok, _patient} = Patients.create_patient(attrs)

      # allow the Task.start'd process to complete before asserting
      Process.sleep(50)

      assert length(Medcamp.Postal.TestClient.calls()) == 1
    end
  end

  describe "find_or_create_public_booking_patient/1" do
    test "normalizes email before creating the patient" do
      assert {:ok, patient} =
               Patients.find_or_create_public_booking_patient(%{
                 "first_name" => "Ada",
                 "last_name" => "Camper",
                 "email" => "  ADA.CAMPER@EXAMPLE.COM  ",
                 "phone_number" => "0712345678"
               })

      assert patient.email == "ada.camper@example.com"
    end

    test "validates email and phone number" do
      assert {:error, changeset} =
               Patients.find_or_create_public_booking_patient(%{
                 "first_name" => "Ada",
                 "last_name" => "Camper",
                 "email" => "not valid",
                 "phone_number" => "12345"
               })

      assert "must be a valid email address" in errors_on(changeset).email
      assert "is not a valid phone number" in errors_on(changeset).phone_number
    end
  end
end
