defmodule Medcamp.NurseProceduresTest do
  use Medcamp.DataCase

  alias Medcamp.NurseProcedures

  describe "nurse_procedures" do
    alias Medcamp.NurseProcedures.NurseProcedure

    import Medcamp.NurseProceduresFixtures
    import Medcamp.AccountsFixtures
    import Medcamp.PatientsFixtures
    import Medcamp.ProceduresFixtures

    @invalid_attrs %{payment_type: nil, has_paid: nil, total_amount_paid: nil}

    test "list_nurse_procedures/0 returns all nurse_procedures" do
      nurse_procedure = nurse_procedure_fixture()
      assert NurseProcedures.list_nurse_procedures() == [nurse_procedure]
    end

    test "get_nurse_procedure!/1 returns the nurse_procedure with given id" do
      nurse_procedure = nurse_procedure_fixture()
      assert NurseProcedures.get_nurse_procedure!(nurse_procedure.id) == nurse_procedure
    end

    test "create_nurse_procedure/1 with valid data creates a nurse_procedure" do
      nurse = user_fixture()
      patient = patient_fixture()
      procedure = procedure_fixture()

      valid_attrs = %{
        payment_type: "some payment_type",
        has_paid: true,
        total_amount_paid: 42,
        nurse_id: nurse.id,
        patient_id: patient.id,
        procedure_id: procedure.id
      }

      assert {:ok, %NurseProcedure{} = nurse_procedure} =
               NurseProcedures.create_nurse_procedure(valid_attrs)

      assert nurse_procedure.payment_type == "some payment_type"
      assert nurse_procedure.has_paid == true
      assert nurse_procedure.total_amount_paid == 42
      assert nurse_procedure.nurse_id == nurse.id
      assert nurse_procedure.patient_id == patient.id
      assert nurse_procedure.procedure_id == procedure.id
    end

    test "create_nurse_procedure/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = NurseProcedures.create_nurse_procedure(@invalid_attrs)
    end

    test "update_nurse_procedure/2 with valid data updates the nurse_procedure" do
      nurse_procedure = nurse_procedure_fixture()

      update_attrs = %{
        payment_type: "some updated payment_type",
        has_paid: false,
        total_amount_paid: 43
      }

      assert {:ok, %NurseProcedure{} = nurse_procedure} =
               NurseProcedures.update_nurse_procedure(nurse_procedure, update_attrs)

      assert nurse_procedure.payment_type == "some updated payment_type"
      assert nurse_procedure.has_paid == false
      assert nurse_procedure.total_amount_paid == 43
    end

    test "update_nurse_procedure/2 with invalid data returns error changeset" do
      nurse_procedure = nurse_procedure_fixture()

      assert {:error, %Ecto.Changeset{}} =
               NurseProcedures.update_nurse_procedure(nurse_procedure, @invalid_attrs)

      assert nurse_procedure == NurseProcedures.get_nurse_procedure!(nurse_procedure.id)
    end

    test "delete_nurse_procedure/1 deletes the nurse_procedure" do
      nurse_procedure = nurse_procedure_fixture()
      assert {:ok, %NurseProcedure{}} = NurseProcedures.delete_nurse_procedure(nurse_procedure)

      assert_raise Ecto.NoResultsError, fn ->
        NurseProcedures.get_nurse_procedure!(nurse_procedure.id)
      end
    end

    test "change_nurse_procedure/1 returns a nurse_procedure changeset" do
      nurse_procedure = nurse_procedure_fixture()
      assert %Ecto.Changeset{} = NurseProcedures.change_nurse_procedure(nurse_procedure)
    end
  end
end
