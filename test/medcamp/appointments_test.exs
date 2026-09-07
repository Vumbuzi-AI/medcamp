defmodule Medcamp.AppointmentsTest do
  use Medcamp.DataCase

  alias Medcamp.Appointments
  alias Medcamp.Patients.Patient

  describe "appointments" do
    alias Medcamp.Appointments.Appointment

    import Medcamp.AppointmentsFixtures

    @invalid_attrs %{reason: nil, date: nil, time: nil}

    test "list_appointments/0 returns all appointments" do
      appointment = appointment_fixture()
      assert Appointments.list_appointments() == [appointment]
    end

    test "get_appointment!/1 returns the appointment with given id" do
      appointment = appointment_fixture()
      assert Appointments.get_appointment!(appointment.id) == appointment
    end

    test "create_appointment/1 with valid data creates a appointment" do
      patient = public_booking_patient_fixture()

      valid_attrs = %{
        reason: "some reason",
        date: ~D[2025-04-05],
        time: ~T[14:00:00],
        patient_id: patient.id
      }

      assert {:ok, %Appointment{} = appointment} = Appointments.create_appointment(valid_attrs)
      assert appointment.reason == "some reason"
      assert appointment.date == ~D[2025-04-05]
      assert appointment.time == ~T[14:00:00]
    end

    test "create_appointment/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Appointments.create_appointment(@invalid_attrs)
    end

    test "update_appointment/2 with valid data updates the appointment" do
      appointment = appointment_fixture()
      update_attrs = %{reason: "some updated reason", date: ~D[2025-04-06], time: ~T[15:01:01]}

      assert {:ok, %Appointment{} = appointment} =
               Appointments.update_appointment(appointment, update_attrs)

      assert appointment.reason == "some updated reason"
      assert appointment.date == ~D[2025-04-06]
      assert appointment.time == ~T[15:01:01]
    end

    test "update_appointment/2 with invalid data returns error changeset" do
      appointment = appointment_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Appointments.update_appointment(appointment, @invalid_attrs)

      assert appointment == Appointments.get_appointment!(appointment.id)
    end

    test "delete_appointment/1 deletes the appointment" do
      appointment = appointment_fixture()
      assert {:ok, %Appointment{}} = Appointments.delete_appointment(appointment)
      assert_raise Ecto.NoResultsError, fn -> Appointments.get_appointment!(appointment.id) end
    end

    test "change_appointment/1 returns a appointment changeset" do
      appointment = appointment_fixture()
      assert %Ecto.Changeset{} = Appointments.change_appointment(appointment)
    end

    test "create_public_appointment/1 creates an appointment and broadcasts it to reception" do
      Appointments.subscribe()

      assert {:ok, appointment} =
               Appointments.create_public_appointment(%{
                 "first_name" => "Jane",
                 "last_name" => "Doe",
                 "email" => "jane@example.com",
                 "phone_number" => "+254700000001",
                 "service" => "outpatient",
                 "date" => "2026-06-10",
                 "time" => "09:30",
                 "message" => "Need a follow-up review"
               })

      assert appointment.patient.first_name == "Jane"
      assert appointment.patient.last_name == "Doe"
      assert appointment.reason =~ "Website booking"
      assert appointment.reason =~ "Outpatient"
      assert appointment.reason =~ "Need a follow-up review"

      assert_receive {:appointment_created, broadcast_appointment}
      assert broadcast_appointment.id == appointment.id
      assert broadcast_appointment.patient.id == appointment.patient.id
    end

    test "create_public_appointment/1 reuses an existing patient by email" do
      patient =
        public_booking_patient_fixture(%{
          email: "existing@example.com",
          phone_number: "+254700000099"
        })

      assert {:ok, appointment} =
               Appointments.create_public_appointment(%{
                 "first_name" => "Existing",
                 "last_name" => "Patient",
                 "email" => "existing@example.com",
                 "phone_number" => "+254700000123",
                 "service" => "diagnostics",
                 "date" => "2026-06-10",
                 "message" => "Need an imaging appointment"
               })

      assert appointment.patient.id == patient.id
      assert Repo.aggregate(Patient, :count, :id) == 1
    end
  end

  defp public_booking_patient_fixture(attrs \\ %{}) do
    unique_integer = System.unique_integer([:positive])

    params =
      %{
        first_name: "Existing",
        last_name: "Patient",
        email: "existing#{unique_integer}@example.com",
        phone_number: "+2547#{String.pad_leading(Integer.to_string(unique_integer), 8, "0")}"
      }
      |> Map.merge(attrs)

    {:ok, patient} =
      %Patient{}
      |> Patient.public_booking_changeset(params)
      |> Repo.insert()

    patient
  end
end
