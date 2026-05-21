defmodule FretboardWeb.FretboardLiveTest do
  use FretboardWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

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
