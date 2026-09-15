defmodule MedcampWeb.PageControllerTest do
  use MedcampWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Tibasasa Medical Camp Management System"
  end
end
