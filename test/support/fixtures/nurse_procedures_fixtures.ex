defmodule Medcamp.NurseProceduresFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Medcamp.NurseProcedures` context.
  """

  @doc """
  Generate a nurse_procedure.
  """
  def nurse_procedure_fixture(attrs \\ %{}) do
    nurse =
      Map.get(attrs, :nurse) || Map.get(attrs, "nurse") || Medcamp.AccountsFixtures.user_fixture()

    patient =
      Map.get(attrs, :patient) || Map.get(attrs, "patient") ||
        Medcamp.PatientsFixtures.patient_fixture()

    procedure =
      Map.get(attrs, :procedure) || Map.get(attrs, "procedure") ||
        Medcamp.ProceduresFixtures.procedure_fixture()

    {:ok, nurse_procedure} =
      attrs
      |> Map.drop([:nurse, "nurse", :patient, "patient", :procedure, "procedure"])
      |> Enum.into(%{
        has_paid: true,
        payment_type: "some payment_type",
        total_amount_paid: 42,
        nurse_id: nurse.id,
        patient_id: patient.id,
        procedure_id: procedure.id
      })
      |> Medcamp.NurseProcedures.create_nurse_procedure()

    Medcamp.Repo.preload(nurse_procedure, [:procedure, :subsidized_procedure, :nurse, :patient])
  end
end
