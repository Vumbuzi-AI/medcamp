defmodule Medcamp.ProceduresTest do
  use Medcamp.DataCase

  alias Medcamp.Procedures

  describe "procedure" do
    alias Medcamp.Procedures.Procedure

    import Medcamp.ProceduresFixtures

    @invalid_attrs %{name: nil, description: nil, price: nil}

    test "list_procedure/0 returns all procedure" do
      procedure = procedure_fixture()
      assert Procedures.list_procedure() == [procedure]
    end

    test "get_procedure!/1 returns the procedure with given id" do
      procedure = procedure_fixture()
      assert Procedures.get_procedure!(procedure.id) == procedure
    end

    test "create_procedure/1 with valid data creates a procedure" do
      valid_attrs = %{name: "some name", description: "some description", price: 42}

      assert {:ok, %Procedure{} = procedure} = Procedures.create_procedure(valid_attrs)
      assert procedure.name == "some name"
      assert procedure.description == "some description"
      assert procedure.price == 42
    end

    test "create_procedure/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Procedures.create_procedure(@invalid_attrs)
    end

    test "update_procedure/2 with valid data updates the procedure" do
      procedure = procedure_fixture()

      update_attrs = %{
        name: "some updated name",
        description: "some updated description",
        price: 43
      }

      assert {:ok, %Procedure{} = procedure} =
               Procedures.update_procedure(procedure, update_attrs)

      assert procedure.name == "some updated name"
      assert procedure.description == "some updated description"
      assert procedure.price == 43
    end

    test "update_procedure/2 with invalid data returns error changeset" do
      procedure = procedure_fixture()
      assert {:error, %Ecto.Changeset{}} = Procedures.update_procedure(procedure, @invalid_attrs)
      assert procedure == Procedures.get_procedure!(procedure.id)
    end

    test "delete_procedure/1 deletes the procedure" do
      procedure = procedure_fixture()
      assert {:ok, %Procedure{}} = Procedures.delete_procedure(procedure)
      assert_raise Ecto.NoResultsError, fn -> Procedures.get_procedure!(procedure.id) end
    end

    test "change_procedure/1 returns a procedure changeset" do
      procedure = procedure_fixture()
      assert %Ecto.Changeset{} = Procedures.change_procedure(procedure)
    end
  end

  describe "service_name/2" do
    test "returns the regular procedure name" do
      record = %{procedure: %{name: "Incision And Drainage"}, subsidized_procedure: nil}

      assert Procedures.service_name(record, "Doctor Procedure") ==
               "Incision And Drainage"
    end

    test "returns the subsidized procedure name when there is no regular procedure" do
      record = %{procedure: nil, subsidized_procedure: %{name: "Subsidized Dressing"}}

      assert Procedures.service_name(record, "Doctor Procedure") ==
               "Subsidized Dressing"
    end

    test "returns the supplied fallback when neither procedure has a name" do
      assert Procedures.service_name(
               %{procedure: nil, subsidized_procedure: nil},
               "Doctor Procedure"
             ) == "Doctor Procedure"
    end
  end
end
