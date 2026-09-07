defmodule MedcampWeb.PageControllerTest do
  use MedcampWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Glocal Healthcare"
  end
end
