defmodule Medcamp.AuditTest do
  use Medcamp.DataCase

  alias Medcamp.{Accounts, Audit, AuditLog}

  import Medcamp.AccountsFixtures

  describe "list_audit_users/0" do
    test "returns only active users for the audit-log filter", %{organisation: organisation} do
      active_user = user_fixture(%{name: "Active Auditor"})
      inactive_user = user_fixture(%{name: "Inactive Auditor"})

      {:ok, inactive_user} = Accounts.update_user(inactive_user, %{is_active: false})

      Repo.insert!(%AuditLog{
        action: "update",
        table_name: "patients",
        record_id: 1,
        organisation_id: organisation.id,
        user_id: active_user.id
      })

      Repo.insert!(%AuditLog{
        action: "update",
        table_name: "patients",
        record_id: 2,
        organisation_id: organisation.id,
        user_id: inactive_user.id
      })

      users = Audit.list_audit_users()

      assert Enum.any?(users, &(&1.id == active_user.id))
      refute Enum.any?(users, &(&1.id == inactive_user.id))
    end
  end

  describe "paginated audit log search" do
    test "counts and retrieves database-backed search pages", %{organisation: organisation} do
      for record_id <- 1..12 do
        Repo.insert!(%AuditLog{
          action: "update",
          table_name: "pagination_patients",
          record_id: record_id,
          organisation_id: organisation.id
        })
      end

      Repo.insert!(%AuditLog{
        action: "update",
        table_name: "unrelated_table",
        record_id: 99,
        organisation_id: organisation.id
      })

      filters = [search: "pagination_patients"]

      assert Audit.count_audit_logs(filters) == 12
      assert length(Audit.list_audit_logs(filters: filters, page: 1, page_size: 10)) == 10
      assert length(Audit.list_audit_logs(filters: filters, page: 2, page_size: 10)) == 2
    end

    test "combines search with the other audit filters", %{organisation: organisation} do
      Repo.insert!(%AuditLog{
        action: "insert",
        table_name: "pagination_patients",
        record_id: 1,
        organisation_id: organisation.id
      })

      Repo.insert!(%AuditLog{
        action: "delete",
        table_name: "pagination_patients",
        record_id: 2,
        organisation_id: organisation.id
      })

      assert Audit.count_audit_logs(search: "pagination", action: "delete") == 1
    end
  end
end
