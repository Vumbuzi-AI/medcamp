defmodule MedcampWeb.AdminPaginationFixesTest do
  use MedcampWeb.ConnCase

  import Phoenix.LiveViewTest
  import Medcamp.AccountsFixtures

  describe "AdminMedicalCampLive Pagination" do
    setup %{conn: conn} do
      user = user_fixture(%{role: "admin"})
      %{conn: log_in_user(conn, user)}
    end

    test "handles paginate event with invalid input without crashing", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/admin/medical_camp")

      assert render_hook(view, "paginate", %{"page" => "invalid"})
      assert render_hook(view, "paginate", %{"page" => "-5"})
    end
  end

  describe "AdminAuditLogsLive Pagination" do
    setup %{conn: conn, organisation: organisation} do
      user = user_fixture(%{role: "admin"})

      for record_id <- 1..12 do
        Medcamp.Repo.insert!(%Medcamp.AuditLog{
          action: "update",
          table_name: "pagination_test",
          record_id: record_id,
          organisation_id: organisation.id
        })
      end

      %{conn: log_in_user(conn, user)}
    end

    test "renders ten logs per page and navigates to the second page", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/admin/audit_logs")
      html = render_async(view)

      assert html =~ "Showing 1–10 of 12"
      assert html =~ "Page <span class=\"font-semibold text-slate-900\">1</span>"

      html = view |> element("button", "Next") |> render_click()

      assert html =~ "Showing 11–12 of 12"
      assert html =~ "Page <span class=\"font-semibold text-slate-900\">2</span>"
    end

    test "handles invalid page values without crashing", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/admin/audit_logs")
      render_async(view)

      assert render_hook(view, "paginate", %{"page" => "invalid"}) =~ "Showing 1–10 of 12"
      assert render_hook(view, "paginate", %{"page" => "-5"}) =~ "Showing 1–10 of 12"
    end
  end
end
