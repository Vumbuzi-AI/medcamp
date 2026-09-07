defmodule Medcamp.ProceduresFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Medcamp.Procedures` context.
  """

  @doc """
  Generate a procedure.
  """
  def procedure_fixture(attrs \\ %{}) do
    {:ok, procedure} =
      attrs
      |> Enum.into(%{
        description: "some description",
        name: "some name",
        price: 42
      })
      |> Medcamp.Procedures.create_procedure()

    procedure
  end
end
