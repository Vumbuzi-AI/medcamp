defmodule Medcamp.DoctorProceduresTest do
  use Medcamp.DataCase

  alias Medcamp.DoctorProcedures

  describe "doctor_procedures" do
    alias Medcamp.DoctorProcedures.DoctorProcedure

    import Medcamp.DoctorProceduresFixtures
    import Medcamp.ProceduresFixtures
    import Medcamp.AccountsFixtures
    import Medcamp.PatientsFixtures

    @invalid_attrs %{payment_type: nil, has_paid: nil, total_amount_paid: nil}

    test "list_doctor_procedures/0 returns all doctor_procedures" do
      doctor_procedure = doctor_procedure_fixture()
      assert DoctorProcedures.list_doctor_procedures() == [doctor_procedure]
    end

    test "get_doctor_procedure!/1 returns the doctor_procedure with given id" do
      doctor_procedure = doctor_procedure_fixture()

      assert DoctorProcedures.get_doctor_procedure!(doctor_procedure.id) ==
               Medcamp.Repo.preload(doctor_procedure, [
                 :procedure,
                 :subsidized_procedure,
                 :doctor,
                 :patient
               ])
    end

    test "create_doctor_procedure/1 with valid data creates a doctor_procedure" do
      procedure = procedure_fixture()

      valid_attrs = %{
        payment_type: "some payment_type",
        has_paid: true,
        total_amount_paid: 42,
        procedure_id: procedure.id
      }

      assert {:ok, %DoctorProcedure{} = doctor_procedure} =
               DoctorProcedures.create_doctor_procedure(valid_attrs)

      assert doctor_procedure.payment_type == "some payment_type"
      assert doctor_procedure.has_paid == true
      assert doctor_procedure.total_amount_paid == 42
    end

    test "create_doctor_procedure/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               DoctorProcedures.create_doctor_procedure(@invalid_attrs)
    end

    test "update_doctor_procedure/2 with valid data updates the doctor_procedure" do
      doctor_procedure = doctor_procedure_fixture()
      procedure = procedure_fixture()

      update_attrs = %{
        payment_type: "some updated payment_type",
        has_paid: false,
        total_amount_paid: 43,
        procedure_id: procedure.id
      }

      assert {:ok, %DoctorProcedure{} = doctor_procedure} =
               DoctorProcedures.update_doctor_procedure(doctor_procedure, update_attrs)

      assert doctor_procedure.payment_type == "some updated payment_type"
      assert doctor_procedure.has_paid == false
      assert doctor_procedure.total_amount_paid == 43
    end

    test "update_doctor_procedure/2 with invalid data returns error changeset" do
      doctor_procedure = doctor_procedure_fixture()

      assert {:error, %Ecto.Changeset{}} =
               DoctorProcedures.update_doctor_procedure(doctor_procedure, @invalid_attrs)

      assert Medcamp.Repo.preload(doctor_procedure, [
               :procedure,
               :subsidized_procedure,
               :doctor,
               :patient
             ]) ==
               DoctorProcedures.get_doctor_procedure!(doctor_procedure.id)
    end

    test "delete_doctor_procedure/1 deletes the doctor_procedure" do
      doctor_procedure = doctor_procedure_fixture()

      assert {:ok, %DoctorProcedure{}} =
               DoctorProcedures.delete_doctor_procedure(doctor_procedure)

      assert_raise Ecto.NoResultsError, fn ->
        DoctorProcedures.get_doctor_procedure!(doctor_procedure.id)
      end
    end

    test "change_doctor_procedure/1 returns a doctor_procedure changeset" do
      doctor_procedure = doctor_procedure_fixture()
      assert %Ecto.Changeset{} = DoctorProcedures.change_doctor_procedure(doctor_procedure)
    end

    test "filters a doctor's performed procedures by patient or procedure name and price" do
      doctor = user_fixture()
      other_doctor = user_fixture()
      patient = patient_fixture(%{"first_name" => "Amina", "last_name" => "Kamau"})
      affordable = procedure_fixture(%{name: "Wound dressing", price: 800})
      expensive = procedure_fixture(%{name: "Minor surgery", price: 4_500})

      matching =
        doctor_procedure_fixture(%{
          doctor: doctor,
          patient: patient,
          procedure: affordable
        })

      doctor_procedure_fixture(%{doctor: doctor, procedure: expensive})
      doctor_procedure_fixture(%{doctor: other_doctor, patient: patient, procedure: affordable})

      assert [result] =
               DoctorProcedures.list_doctor_procedures_for_doctor_paginated(
                 doctor.id,
                 %{search: "Amina", max_price: "1000"}
               )

      assert result.id == matching.id

      assert [result] =
               DoctorProcedures.list_doctor_procedures_for_doctor_paginated(
                 doctor.id,
                 %{search: "surgery", min_price: "4000"}
               )

      assert result.procedure_id == expensive.id
    end

    test "lists procedure types with doctor-scoped frequencies and returns type statistics" do
      doctor = user_fixture()
      other_doctor = user_fixture()
      first_patient = patient_fixture(%{"first_name" => "First"})
      second_patient = patient_fixture(%{"first_name" => "Second"})
      procedure = procedure_fixture(%{name: "Joint injection", price: 2_000})

      doctor_procedure_fixture(%{
        doctor: doctor,
        patient: first_patient,
        procedure: procedure,
        total_amount_paid: 2_000
      })

      doctor_procedure_fixture(%{
        doctor: doctor,
        patient: second_patient,
        procedure: procedure,
        total_amount_paid: 1_500
      })

      doctor_procedure_fixture(%{
        doctor: other_doctor,
        patient: first_patient,
        procedure: procedure,
        total_amount_paid: 2_000
      })

      [type] =
        DoctorProcedures.list_procedure_types_for_doctor_paginated(
          doctor.id,
          %{search: "Joint", min_price: "1500", max_price: "2500"}
        )

      assert type.id == procedure.id
      assert type.performed_count == 2
      assert type.patient_count == 2

      stats = DoctorProcedures.get_procedure_type_stats_for_doctor!(doctor.id, procedure.id)
      assert stats.performed_count == 2
      assert stats.patient_count == 2
      assert stats.paid_count == 2
      assert stats.total_collected == 3_500
    end

    test "filters performed procedures and type frequencies by an inclusive date range" do
      doctor = user_fixture()
      patient = patient_fixture()
      procedure = procedure_fixture(%{name: "Date-scoped procedure"})

      july =
        doctor_procedure_fixture(%{
          doctor: doctor,
          patient: patient,
          procedure: procedure
        })

      august =
        doctor_procedure_fixture(%{
          doctor: doctor,
          patient: patient,
          procedure: procedure
        })

      Medcamp.Repo.update_all(
        from(dp in DoctorProcedure, where: dp.id == ^july.id),
        set: [inserted_at: ~U[2026-07-31 10:00:00Z]]
      )

      Medcamp.Repo.update_all(
        from(dp in DoctorProcedure, where: dp.id == ^august.id),
        set: [inserted_at: ~U[2026-08-01 10:00:00Z]]
      )

      filters = %{date_from: "2026-08-01", date_to: "2026-08-31"}

      assert [record] =
               DoctorProcedures.list_doctor_procedures_for_doctor_paginated(
                 doctor.id,
                 filters
               )

      assert record.id == august.id
      assert DoctorProcedures.count_doctor_procedures_for_doctor(doctor.id, filters) == 1

      assert [type] =
               DoctorProcedures.list_procedure_types_for_doctor_paginated(
                 doctor.id,
                 Map.put(filters, :search, "Date-scoped")
               )

      assert type.performed_count == 1
      assert type.patient_count == 1
      assert type.last_performed_at == ~U[2026-08-01 10:00:00Z]
    end
  end
end
