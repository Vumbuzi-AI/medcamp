defmodule Medcamp.TriagesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Medcamp.Triages` context.
  """

  @doc """
  Generate a triage.
  """
  def triage_fixture(attrs \\ %{}) do
    {:ok, triage} =
      attrs
      |> Enum.into(%{
        blood_pressure: "120/80",
        date: ~D[2025-02-21],
        height: 120.5,
        oxygen_saturation: 120.5,
        pulse_rate: 120.5,
        temperature: 120.5,
        triage_notes: "some triage_notes",
        weight: 120.5
      })
      |> Medcamp.Triages.create_triage()

    triage
  end
end
