defmodule FretboardWeb.PageControllerTest do
  use FretboardWeb.ConnCase

  test "GET /fretboard renders the LiveView", %{conn: conn} do
    conn = get(conn, ~p"/fretboard")
    assert html_response(conn, 200) =~ "fretboard"
  end
end
