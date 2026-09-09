defmodule MedcampWeb.Plugs.RequirePanelPermissionTest do
  use MedcampWeb.ConnCase

  import Phoenix.LiveViewTest
  import Medcamp.AccountsFixtures

  alias Medcamp.Authorization

  describe "the doctor.lab_results panel" do
    test "a doctor with the role default can access it", %{conn: conn} do
      doctor = user_fixture(%{role: "doctor"})

      assert {:ok, _view, _html} = live(log_in_user(conn, doctor), ~p"/doctor/lab_results")
    end

    test "a doctor with a per-user deny override is redirected, not shown the page", %{conn: conn} do
      doctor = user_fixture(%{role: "doctor"})
      {:ok, _} = Authorization.deny_user_override(doctor, "doctor.lab_results", nil)

      assert {:error, {:redirect, %{to: "/doctor/scan", flash: flash}}} =
               live(log_in_user(conn, doctor), ~p"/doctor/lab_results")

      assert flash["error"] == "You do not have permission to access that page."
    end

    test "a non-doctor role never reaches the permission check - the role plug redirects first",
         %{
           conn: conn
         } do
      nurse = user_fixture(%{role: "nurse"})

      assert {:error, {:redirect, %{to: "/nurse/scan"}}} =
               live(log_in_user(conn, nurse), ~p"/doctor/lab_results")
    end
  end

  describe "the admin.users panel" do
    test "an admin with the role default can access it", %{conn: conn} do
      admin = user_fixture(%{role: "admin"})

      assert {:ok, _view, _html} = live(log_in_user(conn, admin), ~p"/admin/users")
    end

    test "an admin with a per-user deny override is redirected", %{conn: conn} do
      admin = user_fixture(%{role: "admin"})
      {:ok, _} = Authorization.deny_user_override(admin, "admin.users", nil)

      assert {:error, {:redirect, %{to: "/admin/dashboard", flash: flash}}} =
               live(log_in_user(conn, admin), ~p"/admin/users")

      assert flash["error"] == "You do not have permission to access that page."
    end
  end

  describe "the admin.audit_logs panel" do
    test "an admin with the role default can access it", %{conn: conn} do
      admin = user_fixture(%{role: "admin"})

      assert {:ok, _view, _html} = live(log_in_user(conn, admin), ~p"/admin/audit_logs")
    end

    test "an admin with a per-user deny override is redirected", %{conn: conn} do
      admin = user_fixture(%{role: "admin"})
      {:ok, _} = Authorization.deny_user_override(admin, "admin.audit_logs", nil)

      assert {:error, {:redirect, %{to: "/admin/dashboard", flash: flash}}} =
               live(log_in_user(conn, admin), ~p"/admin/audit_logs")

      assert flash["error"] == "You do not have permission to access that page."
    end
  end

  describe "the pharmacist.drugs panel" do
    test "a pharmacist with the role default can access it", %{conn: conn} do
      pharmacist = user_fixture(%{role: "pharmacist"})

      assert {:ok, _view, _html} = live(log_in_user(conn, pharmacist), ~p"/pharmacist/drugs")
    end

    test "a pharmacist with a per-user deny override is redirected", %{conn: conn} do
      pharmacist = user_fixture(%{role: "pharmacist"})

      {:ok, _} = Authorization.deny_user_override(pharmacist, "pharmacist.drugs", nil)

      assert {:error, {:redirect, %{to: "/pharmacist/scan", flash: flash}}} =
               live(log_in_user(conn, pharmacist), ~p"/pharmacist/drugs")

      assert flash["error"] == "You do not have permission to access that page."
    end
  end

  describe "panels the catalog does not claim" do
    test "a role's landing page is not gated by any panel permission", %{conn: conn} do
      doctor = user_fixture(%{role: "doctor"})

      # /doctor/dashboard has no sidebar tab of its own, so the panel hook
      # leaves it to the role plug rather than failing closed.
      assert {:ok, _view, _html} = live(log_in_user(conn, doctor), ~p"/doctor/dashboard")
    end
  end

  describe "per-patient sub-pages of a panel" do
    test "are blocked when the panel itself is denied", %{conn: conn} do
      doctor = user_fixture(%{role: "doctor"})
      {:ok, _} = Authorization.deny_user_override(doctor, "doctor.patient.doctor_notes", nil)

      assert {:error, {:redirect, %{to: "/doctor/scan"}}} =
               live(log_in_user(conn, doctor), ~p"/doctor/patients/1/notes")
    end
  end

  describe "the sidebar and the routes agree" do
    test "a denied panel disappears from the sidebar", %{conn: conn} do
      doctor = user_fixture(%{role: "doctor"})

      {:ok, _view, html} = live(log_in_user(conn, doctor), ~p"/doctor/scan")
      assert html =~ "Lab Results"

      {:ok, _} = Authorization.deny_user_override(doctor, "doctor.lab_results", nil)

      {:ok, _view, html} = live(log_in_user(conn, doctor), ~p"/doctor/scan")
      refute html =~ "Lab Results"
    end
  end
end
