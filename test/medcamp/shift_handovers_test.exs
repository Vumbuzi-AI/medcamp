defmodule Medcamp.ShiftHandoversTest do
  use Medcamp.DataCase

  alias Medcamp.ShiftHandovers

  describe "shift_handovers" do
    alias Medcamp.ShiftHandovers.ShiftHandover

    import Medcamp.ShiftHandoversFixtures

    @invalid_attrs %{
      status: nil,
      shift_date: nil,
      shift_type: nil,
      department: nil,
      handover_from: nil,
      handover_to: nil,
      patient_count: nil,
      admissions: nil,
      discharges: nil,
      patient_updates: nil,
      pending_tasks: nil,
      equipment_issues: nil,
      incidents: nil,
      notes: nil,
      submitted_at: nil,
      acknowledged_at: nil
    }

    test "list_shift_handovers/0 returns all shift_handovers" do
      shift_handover = shift_handover_fixture()

      assert ShiftHandovers.list_shift_handovers() == [
               Medcamp.Repo.preload(shift_handover, [:submitted_by, :acknowledged_by])
             ]
    end

    test "get_shift_handover!/1 returns the shift_handover with given id" do
      shift_handover = shift_handover_fixture()
      assert ShiftHandovers.get_shift_handover!(shift_handover.id) == shift_handover
    end

    test "create_shift_handover/1 with valid data creates a shift_handover" do
      valid_attrs = %{
        status: "acknowledged",
        shift_date: ~D[2025-11-01],
        shift_start: ~D[2025-11-01],
        shift_type: "morning",
        department: "some department",
        handover_from: "some handover_from",
        handover_to: "some handover_to",
        patient_count: 42,
        admissions: 42,
        discharges: 42,
        patient_updates: "some patient_updates",
        pending_tasks: "some pending_tasks",
        equipment_issues: "some equipment_issues",
        incidents: "some incidents",
        notes: "some notes",
        submitted_at: ~U[2025-11-01 07:35:00Z],
        acknowledged_at: ~U[2025-11-01 07:35:00Z]
      }

      assert {:ok, %ShiftHandover{} = shift_handover} =
               ShiftHandovers.create_shift_handover(valid_attrs)

      assert shift_handover.status == "acknowledged"
      assert shift_handover.shift_date == ~D[2025-11-01]
      assert shift_handover.shift_start == ~D[2025-11-01]
      assert shift_handover.shift_type == "morning"
      assert shift_handover.department == "some department"
      assert shift_handover.handover_from == "some handover_from"
      assert shift_handover.handover_to == "some handover_to"
      assert shift_handover.patient_count == 42
      assert shift_handover.admissions == 42
      assert shift_handover.discharges == 42
      assert shift_handover.patient_updates == "some patient_updates"
      assert shift_handover.pending_tasks == "some pending_tasks"
      assert shift_handover.equipment_issues == "some equipment_issues"
      assert shift_handover.incidents == "some incidents"
      assert shift_handover.notes == "some notes"
      assert shift_handover.submitted_at == ~U[2025-11-01 07:35:00Z]
      assert shift_handover.acknowledged_at == ~U[2025-11-01 07:35:00Z]
    end

    test "create_shift_handover/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = ShiftHandovers.create_shift_handover(@invalid_attrs)
    end

    test "update_shift_handover/2 with valid data updates the shift_handover" do
      shift_handover = shift_handover_fixture()

      update_attrs = %{
        status: "completed",
        shift_date: ~D[2025-11-02],
        shift_type: "afternoon",
        department: "some updated department",
        handover_from: "some updated handover_from",
        handover_to: "some updated handover_to",
        patient_count: 43,
        admissions: 43,
        discharges: 43,
        patient_updates: "some updated patient_updates",
        pending_tasks: "some updated pending_tasks",
        equipment_issues: "some updated equipment_issues",
        incidents: "some updated incidents",
        notes: "some updated notes",
        submitted_at: ~U[2025-11-02 07:35:00Z],
        acknowledged_at: ~U[2025-11-02 07:35:00Z]
      }

      assert {:ok, %ShiftHandover{} = shift_handover} =
               ShiftHandovers.update_shift_handover(shift_handover, update_attrs)

      assert shift_handover.status == "completed"
      assert shift_handover.shift_date == ~D[2025-11-02]
      assert shift_handover.shift_type == "afternoon"
      assert shift_handover.department == "some updated department"
      assert shift_handover.handover_from == "some updated handover_from"
      assert shift_handover.handover_to == "some updated handover_to"
      assert shift_handover.patient_count == 43
      assert shift_handover.admissions == 43
      assert shift_handover.discharges == 43
      assert shift_handover.patient_updates == "some updated patient_updates"
      assert shift_handover.pending_tasks == "some updated pending_tasks"
      assert shift_handover.equipment_issues == "some updated equipment_issues"
      assert shift_handover.incidents == "some updated incidents"
      assert shift_handover.notes == "some updated notes"
      assert shift_handover.submitted_at == ~U[2025-11-02 07:35:00Z]
      assert shift_handover.acknowledged_at == ~U[2025-11-02 07:35:00Z]
    end

    test "update_shift_handover/2 with invalid data returns error changeset" do
      shift_handover = shift_handover_fixture()

      assert {:error, %Ecto.Changeset{}} =
               ShiftHandovers.update_shift_handover(shift_handover, @invalid_attrs)

      assert shift_handover == ShiftHandovers.get_shift_handover!(shift_handover.id)
    end

    test "delete_shift_handover/1 deletes the shift_handover" do
      shift_handover = shift_handover_fixture()
      assert {:ok, %ShiftHandover{}} = ShiftHandovers.delete_shift_handover(shift_handover)

      assert_raise Ecto.NoResultsError, fn ->
        ShiftHandovers.get_shift_handover!(shift_handover.id)
      end
    end

    test "change_shift_handover/1 returns a shift_handover changeset" do
      shift_handover = shift_handover_fixture()
      assert %Ecto.Changeset{} = ShiftHandovers.change_shift_handover(shift_handover)
    end
  end
end
