defmodule FretboardWeb.URLBoundaryLiveTest do
  use FretboardWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  # Send actual bracket-encoded query strings through Plug, not fabricated
  # socket assigns or URI.encode_query/1 (which does not encode nested maps).
  for field <- ~w(tuning chords marked instrument highlight tab pitches reference),
      suffix <- ["%5B%5D", "%5Bnested%5D%5B%5D"] do
    test "GET and connected mount tolerate #{field}#{suffix}", %{conn: conn} do
      field = unquote(field)
      query = unquote(field <> suffix <> "=invalid")
      path = "/?" <> query
      conn = get(conn, path)
      assert html_response(conn, 200) =~ "Fretboard"
      assert is_list(conn.query_params[field]) or is_map(conn.query_params[field])

      {:ok, view, _html} = live(conn)
      render_click(view, "open_tuning_modal")
      assert has_element?(view, "#string-select-0 option[value='E'][selected]")
      render_click(view, "close_tuning_modal")
      render_click(view, "toggle_tab", %{"tab" => "analyzer"})
      assert render(view) =~ "Pulsa notas en el diapasón para identificar un acorde"
      render_click(view, "toggle_note", %{"string" => "0", "fret" => "0"})
      assert render(view) =~ "Nota:"
    end
  end

  test "valid legacy URL remains a working endpoint and connected analyzer", %{conn: conn} do
    conn =
      get(conn, "/?instrument=ukelele&tuning=G,C,E,A&chords=Cmaj,Amin&tab=analyzer&marked=1-0")

    assert html_response(conn, 200) =~ "Nota:"
    {:ok, view, _} = live(conn)
    render_click(view, "toggle_note", %{"string" => "2", "fret" => "0"})
    assert render(view) =~ "Major 3rd"
  end
end
