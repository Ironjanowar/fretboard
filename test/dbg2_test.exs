defmodule Dbg2 do
  use FretboardWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  test "inspect analyzer-results IDs after clicks", %{conn: conn} do
    {:ok, view, html0} = live(conn, "/?tab=analyzer")
    IO.puts("=== INITIAL ===")
    for m <- Regex.scan(~r"<div class=\"analyzer-results\"[^>]*>", html0), do: IO.puts(hd(m))
    IO.puts("  inner-divs")

    for m <-
          Regex.scan(~r"<div class=\"analyzer-(?:empty|single-note|interval)\">.*?</div>", html0,
            capture: :first
          ) do
      IO.puts("  " <> hd(m))
    end

    html1 =
      view
      |> element("[phx-click='toggle_note'][phx-value-string='5'][phx-value-fret='3']")
      |> render_click()

    IO.puts("=== AFTER CLICK 1 (G) ===")
    for m <- Regex.scan(~r"<div class=\"analyzer-results\"[^>]*>", html1), do: IO.puts(hd(m))
    IO.puts("  inner-divs")

    for m <-
          Regex.scan(~r"<div class=\"analyzer-(?:empty|single-note|interval)\">.*?</div>", html1,
            capture: :first
          ) do
      IO.puts("  " <> hd(m))
    end

    html2 =
      view
      |> element("[phx-click='toggle_note'][phx-value-string='4'][phx-value-fret='0']")
      |> render_click()

    IO.puts("=== AFTER CLICK 2 (B) ===")
    for m <- Regex.scan(~r"<div class=\"analyzer-results\"[^>]*>", html2), do: IO.puts(hd(m))
    IO.puts("  inner-divs")

    for m <-
          Regex.scan(~r"<div class=\"analyzer-(?:empty|single-note|interval)\">.*?</div>", html2,
            capture: :first
          ) do
      IO.puts("  " <> hd(m))
    end

    html3 =
      view
      |> element("[phx-click='toggle_note'][phx-value-string='2'][phx-value-fret='0']")
      |> render_click()

    IO.puts("=== AFTER CLICK 3 (D) ===")
    for m <- Regex.scan(~r"<div class=\"analyzer-results\"[^>]*>", html3), do: IO.puts(hd(m))
    IO.puts("  card-titles")

    for m <-
          Regex.scan(~r"<span class=\"analysis-card-title\">.*?</span>", html3, capture: :first) do
      IO.puts("  " <> hd(m))
    end
  end
end
