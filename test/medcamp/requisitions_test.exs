defmodule Medcamp.RequisitionsTest do
  use Medcamp.DataCase

  alias Medcamp.Accounts
  alias Medcamp.Departments
  alias Medcamp.Requisitions

  describe "create_requisition/1" do
    test "preserves a provided requested_at value" do
      {:ok, requester} =
        Accounts.register_user(%{
          "email" => "requisition-requester#{System.unique_integer()}@example.com",
          "password" => "hello world!",
          "name" => "Requester",
          "role" => "admin"
        })

      {:ok, department} = Departments.create_department(%{name: "Pharmacy"})

      requested_at = ~U[2026-05-01 09:30:00Z]

      assert {:ok, requisition} =
               Requisitions.create_requisition(%{
                 "title" => "Amoxicillin restock",
                 "description" => "Need additional stock for the ward.",
                 "requested_at" => requested_at,
                 "requested_by_id" => requester.id,
                 "to_department_id" => department.id
               })

      assert requisition.requested_at == requested_at
    end
  end

  describe "rejection_reason validation" do
    setup do
      {:ok, requester} =
        Accounts.register_user(%{
          "email" => "requisition-reject#{System.unique_integer()}@example.com",
          "password" => "hello world!",
          "name" => "Requester",
          "role" => "admin"
        })

      {:ok, department} =
        Departments.create_department(%{name: "Pharmacy #{System.unique_integer()}"})

      {:ok, requisition} =
        Requisitions.create_requisition(%{
          "title" => "Amoxicillin restock",
          "description" => "Need additional stock for the ward.",
          "requested_by_id" => requester.id,
          "to_department_id" => department.id
        })

      %{requisition: requisition}
    end

    test "rejecting without a reason fails validation", %{requisition: requisition} do
      assert {:error, changeset} =
               Requisitions.update_requisition(requisition, %{"status" => "rejected"})

      assert "is required when rejecting a requisition" in errors_on(changeset).rejection_reason
    end

    test "rejecting with a blank/whitespace-only reason fails validation", %{
      requisition: requisition
    } do
      assert {:error, changeset} =
               Requisitions.update_requisition(requisition, %{
                 "status" => "rejected",
                 "rejection_reason" => "   "
               })

      assert "is required when rejecting a requisition" in errors_on(changeset).rejection_reason
    end

    test "rejecting with a reason succeeds", %{requisition: requisition} do
      assert {:ok, updated} =
               Requisitions.update_requisition(requisition, %{
                 "status" => "rejected",
                 "rejection_reason" => "Insufficient stock available"
               })

      assert updated.status == "rejected"
      assert updated.rejection_reason == "Insufficient stock available"
    end

    test "rejection_reason is not required for non-rejected statuses", %{requisition: requisition} do
      assert {:ok, updated} =
               Requisitions.update_requisition(requisition, %{"status" => "approved"})

      assert updated.status == "approved"
      assert is_nil(updated.rejection_reason)
    end
  end
end
