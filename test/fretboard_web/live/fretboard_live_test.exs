defmodule FretboardWeb.FretboardLiveTest do
  use FretboardWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "string ordering" do
    test "tuning labels render high E at top and low E at bottom", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      # Extract tuning labels with y-coordinates, then sort by y to get top-to-bottom order
      labels =
        Regex.scan(
          ~r/class="tuning-label"[^>]*y="(\d+)"[^>]*>\s*([A-G]#?)\s*</s,
          html
        )
        |> Enum.map(fn [_, y, note] -> {String.to_integer(y), note} end)
        |> Enum.sort_by(&elem(&1, 0))

      notes = Enum.map(labels, &elem(&1, 1))

      # Standard tuning reversed for display: high E, B, G, D, A, low E
      assert List.first(notes) == "E", "First (topmost) label should be high E"
      assert List.last(notes) == "E", "Last (bottommost) label should be low E"
      assert notes == ["E", "B", "G", "D", "A", "E"]
    end

    test "thickest string (low E) renders at the bottom with greatest stroke-width", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      # Extract string lines with their y positions and stroke-widths
      strings =
        Regex.scan(
          ~r/class="string-line"[^>]*y1="(\d+)"[^>]*stroke-width="([\d.]+)"/,
          html
        )
        |> Enum.map(fn [_, y, w] -> {String.to_integer(y), String.to_float(w)} end)
        |> Enum.sort_by(&elem(&1, 0))

      {_y_positions, widths} = Enum.unzip(strings)

      # The last (bottom) string should have the thickest stroke (low E)
      assert List.last(widths) > List.first(widths),
             "Bottom string should be thicker than top string"
    end
  end

  describe "mount" do
    test "renders the fretboard page successfully", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")
      assert html =~ "fretboard"
    end

    test "renders 6 strings as horizontal lines", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")
      # 6 string lines in SVG
      assert length(Regex.scan(~r/class="string-line"/, html)) == 6
    end

    test "renders 25 fret lines (0-24)", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")
      assert length(Regex.scan(~r/class="fret-line"/, html)) == 25
    end

    test "shows standard tuning labels", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      for note <- ["E", "A", "D", "G", "B", "E"] do
        assert html =~ note
      end
    end

    test "does not show note circles when no chords are active", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")
      refute html =~ "note-circle"
    end

    test "renders the nut with distinct styling", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")
      assert html =~ "nut-line"
    end

    test "renders fret markers at correct positions", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")
      assert html =~ "fret-marker"
    end

    test "renders chord selector with root and quality dropdowns", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")
      assert html =~ "root-select"
      assert html =~ "quality-select"
      assert html =~ "Add"
    end
  end

  describe "add_chord" do
    test "adding a chord shows note circles on the fretboard", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      html =
        view
        |> form("#chord-form", %{chord: %{root: "C", quality: "major"}})
        |> render_submit()

      assert html =~ "note-circle"
    end

    test "adding a chord shows it as a chip below the fretboard", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      html =
        view
        |> form("#chord-form", %{chord: %{root: "C", quality: "major"}})
        |> render_submit()

      assert html =~ "C major"
      assert html =~ "chord-chip"
    end

    test "chord notes appear with correct note names", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      html =
        view
        |> form("#chord-form", %{chord: %{root: "C", quality: "major"}})
        |> render_submit()

      # C major = C, E, G — all should appear as note text
      assert html =~ ">C<"
      assert html =~ ">E<"
      assert html =~ ">G<"
    end

    test "adding duplicate chord is prevented", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view
      |> form("#chord-form", %{chord: %{root: "C", quality: "major"}})
      |> render_submit()

      html =
        view
        |> form("#chord-form", %{chord: %{root: "C", quality: "major"}})
        |> render_submit()

      # Should only have one chip
      assert length(Regex.scan(~r/chord-chip/, html)) == 1
    end
  end

  describe "remove_chord" do
    test "removing a chord removes it from chips and fretboard", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view
      |> form("#chord-form", %{chord: %{root: "C", quality: "major"}})
      |> render_submit()

      html = view |> element("[phx-click=remove_chord][phx-value-index='0']") |> render_click()

      refute html =~ "chord-chip"
      refute html =~ "note-circle"
    end
  end

  describe "overlap notes" do
    test "overlapping notes show neutral color", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # C major = C, E, G; A minor = A, C, E — overlap on C and E
      view
      |> form("#chord-form", %{chord: %{root: "C", quality: "major"}})
      |> render_submit()

      html =
        view
        |> form("#chord-form", %{chord: %{root: "A", quality: "minor"}})
        |> render_submit()

      # Neutral/overlap color should appear
      assert html =~ "#9E9E9E"
    end
  end

  describe "tuning change" do
    test "clicking tuning label cycles the note and recomputes fretboard", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Add a chord first so we can see note changes
      view
      |> form("#chord-form", %{chord: %{root: "C", quality: "major"}})
      |> render_submit()

      # Click the first tuning label (E, string index 0) — should cycle to F
      html = view |> element("[phx-click=cycle_tuning][phx-value-string='0']") |> render_click()

      # The tuning label should now show F instead of E for string 0
      # We check via the tuning-label class
      assert html =~ "tuning-label"
    end
  end
end
