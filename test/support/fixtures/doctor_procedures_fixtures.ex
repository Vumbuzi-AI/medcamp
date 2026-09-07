defmodule Medcamp.DoctorProceduresFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Medcamp.DoctorProcedures` context.
  """

  @doc """
  Generate a doctor_procedure.
  """
  def doctor_procedure_fixture(attrs \\ %{}) do
    doctor =
      Map.get(attrs, :doctor) || Map.get(attrs, "doctor") || Medcamp.AccountsFixtures.user_fixture()

    patient =
      Map.get(attrs, :patient) || Map.get(attrs, "patient") ||
        Medcamp.PatientsFixtures.patient_fixture()

    procedure =
      Map.get(attrs, :procedure) || Map.get(attrs, "procedure") ||
        Medcamp.ProceduresFixtures.procedure_fixture()

    {:ok, doctor_procedure} =
      attrs
      |> Map.drop([:doctor, "doctor", :patient, "patient", :procedure, "procedure"])
      |> Enum.into(%{
        has_paid: true,
        payment_type: "some payment_type",
        total_amount_paid: 42,
        doctor_id: doctor.id,
        patient_id: patient.id,
        procedure_id: procedure.id
      })
      |> Medcamp.DoctorProcedures.create_doctor_procedure()

    doctor_procedure
  end
end
