defmodule FretboardWeb.PageControllerTest do
  use FretboardWeb.ConnCase

  test "GET / redirects to LiveView", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "fretboard"
  end
end
