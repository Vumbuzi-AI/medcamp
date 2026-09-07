defmodule Medcamp.RadiologyTestsTest do
  use Medcamp.DataCase

  alias Medcamp.RadiologyTests

  describe "radiology_tests" do
    alias Medcamp.RadiologyTests.RadiologyTest

    import Medcamp.RadiologyTestsFixtures
    import Medcamp.AccountsFixtures

    @invalid_attrs %{name: nil, description: nil, price: nil}

    test "list_radiology_tests/0 returns all radiology_tests" do
      radiology_test = radiology_test_fixture()
      assert RadiologyTests.list_radiology_tests() == [radiology_test]
    end

    test "get_radiology_test!/1 returns the radiology_test with given id" do
      radiology_test = radiology_test_fixture()
      assert RadiologyTests.get_radiology_test!(radiology_test.id) == radiology_test
    end

    test "create_radiology_test/1 with valid data creates a radiology_test" do
      creator = user_fixture()

      valid_attrs = %{
        name: "some name",
        description: "some description",
        price: 42,
        creator_id: creator.id
      }

      assert {:ok, %RadiologyTest{} = radiology_test} =
               RadiologyTests.create_radiology_test(valid_attrs)

      assert radiology_test.name == "some name"
      assert radiology_test.description == "some description"
      assert radiology_test.price == 42
      assert radiology_test.creator_id == creator.id
    end

    test "create_radiology_test/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = RadiologyTests.create_radiology_test(@invalid_attrs)
    end

    test "update_radiology_test/2 with valid data updates the radiology_test" do
      radiology_test = radiology_test_fixture()

      update_attrs = %{
        name: "some updated name",
        description: "some updated description",
        price: 43
      }

      assert {:ok, %RadiologyTest{} = radiology_test} =
               RadiologyTests.update_radiology_test(radiology_test, update_attrs)

      assert radiology_test.name == "some updated name"
      assert radiology_test.description == "some updated description"
      assert radiology_test.price == 43
    end

    test "update_radiology_test/2 with invalid data returns error changeset" do
      radiology_test = radiology_test_fixture()

      assert {:error, %Ecto.Changeset{}} =
               RadiologyTests.update_radiology_test(radiology_test, @invalid_attrs)

      assert radiology_test == RadiologyTests.get_radiology_test!(radiology_test.id)
    end

    test "delete_radiology_test/1 deletes the radiology_test" do
      radiology_test = radiology_test_fixture()
      assert {:ok, %RadiologyTest{}} = RadiologyTests.delete_radiology_test(radiology_test)

      assert_raise Ecto.NoResultsError, fn ->
        RadiologyTests.get_radiology_test!(radiology_test.id)
      end
    end

    test "change_radiology_test/1 returns a radiology_test changeset" do
      radiology_test = radiology_test_fixture()
      assert %Ecto.Changeset{} = RadiologyTests.change_radiology_test(radiology_test)
    end
  end
end
