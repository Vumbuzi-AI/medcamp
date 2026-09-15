defmodule MedcampWeb.MedicalCampPages.GlobalScanTest do
  use MedcampWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "renders the public scanner with Tibasasa branding and no logout action", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/medical-camp/scan")

    assert html =~ "Tibasasa"
    assert html =~ "Patient Scanner"
    assert html =~ "Powered by Tibasasa Medical Camp"
    refute html =~ ~s(<p class="text-center text-sm font-semibold text-slate-500">Tibasasa</p>)
    refute html =~ "HDF Medical Camp"
    refute html =~ "Islamic University of Kenya"
    refute html =~ "Glocal Health Centre of Excellence"
    refute html =~ "Logout"
    refute html =~ "/users/log_out"
  end
end
