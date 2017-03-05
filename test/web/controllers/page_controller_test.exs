defmodule Platform.Web.PageControllerTest do
  use Platform.Web.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 200) =~ "Players"
  end
end
