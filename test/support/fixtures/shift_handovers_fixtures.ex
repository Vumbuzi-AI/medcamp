defmodule Medcamp.ShiftHandoversFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Medcamp.ShiftHandovers` context.
  """

  @doc """
  Generate a shift_handover.
  """
  def shift_handover_fixture(attrs \\ %{}) do
    submitted_by =
      Map.get(attrs, :submitted_by) || Map.get(attrs, "submitted_by") ||
        Medcamp.AccountsFixtures.user_fixture()

    {:ok, shift_handover} =
      attrs
      |> Map.drop([:submitted_by, "submitted_by"])
      |> Enum.into(%{
        acknowledged_at: ~U[2025-11-01 07:35:00Z],
        admissions: 42,
        department: "some department",
        discharges: 42,
        equipment_issues: "some equipment_issues",
        handover_from: "some handover_from",
        handover_to: "some handover_to",
        incidents: "some incidents",
        notes: "some notes",
        patient_count: 42,
        patient_updates: "some patient_updates",
        pending_tasks: "some pending_tasks",
        shift_date: ~D[2025-11-01],
        shift_start: ~D[2025-11-01],
        shift_type: "morning",
        status: "pending",
        submitted_at: ~U[2025-11-01 07:35:00Z],
        submitted_by_id: submitted_by.id
      })
      |> Medcamp.ShiftHandovers.create_shift_handover()

    shift_handover
  end
end
