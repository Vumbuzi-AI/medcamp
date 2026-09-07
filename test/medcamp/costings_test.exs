defmodule Medcamp.CostingsTest do
  use Medcamp.DataCase

  alias Medcamp.Costings

  describe "costings" do
    alias Medcamp.Costings.Costing

    import Medcamp.CostingsFixtures
    import Medcamp.AccountsFixtures

    @invalid_attrs %{type: nil, price: nil}

    test "list_costings/0 returns all costings" do
      costing = costing_fixture()
      assert Costings.list_costings() == [costing]
    end

    test "get_costing!/1 returns the costing with given id" do
      costing = costing_fixture()
      assert Costings.get_costing!(costing.id) == costing
    end

    test "create_costing/1 with valid data creates a costing" do
      user = user_fixture()
      valid_attrs = %{type: "some type", price: 42, user_id: user.id}

      assert {:ok, %Costing{} = costing} = Costings.create_costing(valid_attrs)
      assert costing.type == "some type"
      assert costing.price == 42
      assert costing.user_id == user.id
    end

    test "create_costing/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Costings.create_costing(@invalid_attrs)
    end

    test "update_costing/2 with valid data updates the costing" do
      costing = costing_fixture()
      update_attrs = %{type: "some updated type", price: 43}

      assert {:ok, %Costing{} = costing} = Costings.update_costing(costing, update_attrs)
      assert costing.type == "some updated type"
      assert costing.price == 43
    end

    test "update_costing/2 with invalid data returns error changeset" do
      costing = costing_fixture()
      assert {:error, %Ecto.Changeset{}} = Costings.update_costing(costing, @invalid_attrs)
      assert costing == Costings.get_costing!(costing.id)
    end

    test "delete_costing/1 deletes the costing" do
      costing = costing_fixture()
      assert {:ok, %Costing{}} = Costings.delete_costing(costing)
      assert_raise Ecto.NoResultsError, fn -> Costings.get_costing!(costing.id) end
    end

    test "change_costing/1 returns a costing changeset" do
      costing = costing_fixture()
      assert %Ecto.Changeset{} = Costings.change_costing(costing)
    end
  end
end
