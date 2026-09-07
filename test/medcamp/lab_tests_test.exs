defmodule Medcamp.LabTestsTest do
  use Medcamp.DataCase

  alias Medcamp.LabTests

  describe "lab_tests" do
    alias Medcamp.LabTests.LabTest

    import Medcamp.LabTestsFixtures

    @invalid_attrs %{name: nil, desription: nil, price: nil}

    test "list_lab_tests/0 returns all lab_tests" do
      lab_test = lab_test_fixture()
      assert lab_test in LabTests.list_lab_tests()
    end

    test "get_lab_test!/1 returns the lab_test with given id" do
      lab_test = lab_test_fixture()
      assert LabTests.get_lab_test!(lab_test.id) == lab_test
    end

    test "create_lab_test/1 with valid data creates a lab_test" do
      valid_attrs = %{name: "some name", desription: "some desription", price: 42}

      assert {:ok, %LabTest{} = lab_test} = LabTests.create_lab_test(valid_attrs)
      assert lab_test.name == "some name"
      assert lab_test.desription == "some desription"
      assert lab_test.price == 42
    end

    test "create_lab_test/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = LabTests.create_lab_test(@invalid_attrs)
    end

    test "update_lab_test/2 with valid data updates the lab_test" do
      lab_test = lab_test_fixture()

      update_attrs = %{
        name: "some updated name",
        desription: "some updated desription",
        price: 43
      }

      assert {:ok, %LabTest{} = lab_test} = LabTests.update_lab_test(lab_test, update_attrs)
      assert lab_test.name == "some updated name"
      assert lab_test.desription == "some updated desription"
      assert lab_test.price == 43
    end

    test "update_lab_test/2 with invalid data returns error changeset" do
      lab_test = lab_test_fixture()
      assert {:error, %Ecto.Changeset{}} = LabTests.update_lab_test(lab_test, @invalid_attrs)
      assert lab_test == LabTests.get_lab_test!(lab_test.id)
    end

    test "delete_lab_test/1 deletes the lab_test" do
      lab_test = lab_test_fixture()
      assert {:ok, %LabTest{}} = LabTests.delete_lab_test(lab_test)
      assert_raise Ecto.NoResultsError, fn -> LabTests.get_lab_test!(lab_test.id) end
    end

    test "change_lab_test/1 returns a lab_test changeset" do
      lab_test = lab_test_fixture()
      assert %Ecto.Changeset{} = LabTests.change_lab_test(lab_test)
    end
  end
end
