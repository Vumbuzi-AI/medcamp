defmodule Medcamp.SuppliersTest do
  use Medcamp.DataCase

  alias Medcamp.Suppliers

  describe "suppliers" do
    alias Medcamp.Suppliers.Supplier

    import Medcamp.SuppliersFixtures

    @invalid_attrs %{name: nil, description: nil, location: nil, email: nil, contact: nil}

    test "list_suppliers/0 returns all suppliers" do
      supplier = supplier_fixture()
      assert Suppliers.list_suppliers() == [supplier]
    end

    test "get_supplier!/1 returns the supplier with given id" do
      supplier = supplier_fixture()

      assert Suppliers.get_supplier!(supplier.id) ==
               Medcamp.Repo.preload(supplier, :supplier_documents)
    end

    test "create_supplier/1 with valid data creates a supplier" do
      valid_attrs = %{
        name: "some name",
        description: "some description",
        location: "some location",
        email: "some email",
        contact: "some contact"
      }

      assert {:ok, %Supplier{} = supplier} = Suppliers.create_supplier(valid_attrs)
      assert supplier.name == "some name"
      assert supplier.description == "some description"
      assert supplier.location == "some location"
      assert supplier.email == "some email"
      assert supplier.contact == "some contact"
    end

    test "create_supplier/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Suppliers.create_supplier(@invalid_attrs)
    end

    test "update_supplier/2 with valid data updates the supplier" do
      supplier = supplier_fixture()

      update_attrs = %{
        name: "some updated name",
        description: "some updated description",
        location: "some updated location",
        email: "some updated email",
        contact: "some updated contact"
      }

      assert {:ok, %Supplier{} = supplier} = Suppliers.update_supplier(supplier, update_attrs)
      assert supplier.name == "some updated name"
      assert supplier.description == "some updated description"
      assert supplier.location == "some updated location"
      assert supplier.email == "some updated email"
      assert supplier.contact == "some updated contact"
    end

    test "update_supplier/2 with invalid data returns error changeset" do
      supplier = supplier_fixture()
      assert {:error, %Ecto.Changeset{}} = Suppliers.update_supplier(supplier, @invalid_attrs)

      assert Medcamp.Repo.preload(supplier, :supplier_documents) ==
               Suppliers.get_supplier!(supplier.id)
    end

    test "delete_supplier/1 deletes the supplier" do
      supplier = supplier_fixture()
      assert {:ok, %Supplier{}} = Suppliers.delete_supplier(supplier)
      assert_raise Ecto.NoResultsError, fn -> Suppliers.get_supplier!(supplier.id) end
    end

    test "change_supplier/1 returns a supplier changeset" do
      supplier = supplier_fixture()
      assert %Ecto.Changeset{} = Suppliers.change_supplier(supplier)
    end
  end
end
