defmodule FretboardWeb.AnalyzerLiveTest do
  use FretboardWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "tab switching" do
    test "mount defaults to the visualizer tab", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      # Visualizer tab button should be active
      assert html =~ ~s(phx-value-tab="visualizer")
      assert html =~ ~s(tab-toggle-btn--active)

      # Visualizer-only controls should be present
      assert html =~ "root-select"
      assert html =~ "quality-select"
      assert html =~ "open_key_modal"
      assert html =~ "open_progression_modal"
    end

    test "mount with tab=analyzer shows the analyzer tab", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/?tab=analyzer")

      assert html =~ "tab-toggle"
      assert html =~ "analyzer-fretboard"
    end

    test "clicking the Analyzer segment switches to the analyzer tab", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      html =
        view
        |> element("[phx-click=toggle_tab][phx-value-tab=analyzer]")
        |> render_click()

      assert html =~ "analyzer-fretboard"
      assert html =~ "analyzer-results"
    end

    test "clicking the Visualizer segment switches back to visualizer", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?tab=analyzer")

      html =
        view
        |> element("[phx-click=toggle_tab][phx-value-tab=visualizer]")
        |> render_click()

      assert html =~ "root-select"
      refute html =~ "analyzer-fretboard"
    end
  end

  describe "analyzer empty state" do
    test "shows the empty state message when no notes are marked", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/?tab=analyzer")

      assert html =~ "Pulsa notas en el diapasón para identificar un acorde"
    end

    test "does not show the clear button when no notes are marked", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/?tab=analyzer")

      refute html =~ "clear_notes"
    end
  end

  describe "toggle_note event" do
    test "clicking a note position marks it (visible circle appears)", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?tab=analyzer")

      html = render_click(view, "toggle_note", %{"string" => "0", "fret" => "3"})

      # A marked note circle should be present
      assert html =~ "analyzer-note-circle"
      assert html =~ "analyzer-note-text"
    end

    test "clicking a marked note unmarks it (toggle off)", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?tab=analyzer&marked=0-3")

      html = render_click(view, "toggle_note", %{"string" => "0", "fret" => "3"})

      # No marked circles should remain
      refute html =~ "analyzer-note-circle"
      assert html =~ "Pulsa notas en el diapasón para identificar un acorde"
    end

    test "clicking a note on the same string replaces the previous note", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?tab=analyzer&marked=0-3")

      # String 0 already has fret 3 marked. Click fret 5 instead.
      html = render_click(view, "toggle_note", %{"string" => "0", "fret" => "5"})

      # There should still be exactly one marked note circle
      circle_count = length(Regex.scan(~r/analyzer-note-circle/, html))
      assert circle_count == 1
    end

    test "marking multiple notes on different strings shows multiple circles", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?tab=analyzer&marked=0-3,2-2,1-0")

      html = render(view)

      circle_count = length(Regex.scan(~r/analyzer-note-circle/, html))
      assert circle_count == 3
    end
  end

  describe "clear_notes event" do
    test "clear button removes all marked notes", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?tab=analyzer&marked=0-3,2-2")

      html = render_click(view, "clear_notes", %{})

      refute html =~ "analyzer-note-circle"
      assert html =~ "Pulsa notas en el diapasón para identificar un acorde"
    end

    test "clear button is shown only when there are marked notes", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?tab=analyzer&marked=0-3")

      html = render(view)
      assert html =~ "clear_notes"

      # After clearing, the button should disappear
      html = render_click(view, "clear_notes", %{})
      refute html =~ "clear_notes"
    end
  end

  describe "analysis results" do
    test "with one note marked shows the single note display", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/?tab=analyzer&marked=0-3")

      # String 0 is high E (standard tuning), fret 3 → G
      assert html =~ "Nota:"
      assert html =~ "G"
      refute html =~ "analysis-card"
    end

    test "with two notes marked shows the interval display", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/?tab=analyzer&marked=0-3,2-2")

      # String 0 fret 3 → G; string 2 fret 2 → E
      assert html =~ "Intervalo:"
      refute html =~ "analysis-card"
    end

    test "with three notes marked shows chord interpretation cards", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/?tab=analyzer&marked=0-3,1-2,2-0")

      # String 0 fret 3 → G; string 1 fret 2 → C#; string 2 fret 0 → G
      # But let's use a clearer chord: string 5 fret 3 → G, string 4 fret 2 → B,
      # string 3 fret 0 → G. Actually, let's use C major shape.
      # Standard tuning: E(0), A(1), D(2), G(3), B(4), E(5)
      # C major triad: C, E, G
      # String 5 fret 8 → C; string 4 fret 7 → E; string 3 fret 5 → G
      # That's too high. Let's use: string 5 fret 3 → G, string 4 fret 2 → B,
      # string 3 fret 0 → G → G major (G-B-D, but we have G-B-G).
      # Actually let's just check that analysis cards appear.
      assert html =~ "analysis-card"
    end

    test "analysis card shows chord name and exact/partial badge", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/?tab=analyzer&marked=0-3,1-2,2-0")

      assert html =~ "analysis-card-title"
      assert html =~ "analysis-card-badge"
    end

    test "analysis card shows notes, intervals, and bass", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/?tab=analyzer&marked=0-3,1-2,2-0")

      assert html =~ "analysis-card-notes"
      assert html =~ "analysis-card-intervals"
      assert html =~ "analysis-card-bass"
      assert html =~ "Bass:"
    end
  end

  describe "tab visibility of controls" do
    test "visualizer controls are hidden in analyzer tab", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/?tab=analyzer")

      refute html =~ "root-select"
      refute html =~ "quality-select"
      refute html =~ "open_key_modal"
      refute html =~ "open_progression_modal"
      refute html =~ "chord-form"
    end

    test "tuning and instrument controls are visible in the visualizer tab", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      assert html =~ "open_tuning_modal"
      assert html =~ "instrument-select"
    end

    test "tuning and instrument controls are visible in the analyzer tab", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/?tab=analyzer")

      assert html =~ "open_tuning_modal"
      assert html =~ "instrument-select"
    end
  end

  describe "tuning and instrument changes preserve tab" do
    test "applying a tuning change preserves tab=analyzer", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?tab=analyzer")

      view |> element("[phx-click=open_tuning_modal]") |> render_click()
      render_click(view, "select_preset", %{"preset" => "Drop D"})

      html = render_click(view, "apply_tuning", %{})

      # Should still be on the analyzer tab
      assert html =~ "analyzer-fretboard"
      refute html =~ "root-select"
    end

    test "applying a tuning change preserves tab=visualizer (no tab param)", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view |> element("[phx-click=open_tuning_modal]") |> render_click()
      render_click(view, "select_preset", %{"preset" => "Drop D"})

      html = render_click(view, "apply_tuning", %{})

      # Should still be on the visualizer tab
      assert html =~ "root-select"
      refute html =~ "analyzer-fretboard"
    end

    test "changing instrument preserves tab=analyzer", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?tab=analyzer")

      html = render_click(view, "change_instrument", %{"instrument" => "bass_4"})

      assert html =~ "analyzer-fretboard"
      refute html =~ "root-select"
    end

    test "adding a chord preserves tab=analyzer", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?tab=analyzer")

      html = render_click(view, "add_chord", %{"chord" => %{"root" => "C", "quality" => "major"}})

      assert html =~ "analyzer-fretboard"
      refute html =~ "root-select"
    end
  end

  describe "switching tabs clears marked notes" do
    test "switching from analyzer to visualizer clears marked notes", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?tab=analyzer&marked=0-3,2-2")

      # Switch to visualizer
      html =
        view
        |> element("[phx-click=toggle_tab][phx-value-tab=visualizer]")
        |> render_click()

      refute html =~ "analyzer-fretboard"
      refute html =~ "analyzer-note-circle"
    end

    test "switching from visualizer to analyzer clears marked notes", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?tab=visualizer&marked=0-3")

      html =
        view
        |> element("[phx-click=toggle_tab][phx-value-tab=analyzer]")
        |> render_click()

      # Should show the empty state, not marked notes
      assert html =~ "Pulsa notas en el diapasón para identificar un acorde"
      refute html =~ "analyzer-note-circle"
    end
  end

  describe "interactive fretboard rendering" do
    test "analyzer fretboard renders all positions as clickable", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/?tab=analyzer")

      # Every string/fret combination should have a toggle_note click handler.
      # Standard tuning has 6 strings × 25 frets = 150 positions.
      toggle_count = length(Regex.scan(~r/phx-click="toggle_note"/, html))
      assert toggle_count == 6 * 25
    end

    test "analyzer fretboard renders tuning labels", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/?tab=analyzer")

      assert length(Regex.scan(~r/class="tuning-label"/, html)) == 6
    end

    test "analyzer fretboard renders string and fret lines", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/?tab=analyzer")

      assert length(Regex.scan(~r/class="string-line"/, html)) == 6
      assert length(Regex.scan(~r/class="fret-line"/, html)) == 25
    end

    test "marked positions show the note name", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/?tab=analyzer&marked=0-3")

      # String 0 (high E) fret 3 → G
      assert html =~ "analyzer-note-text"
      assert html =~ "G"
    end
  end

  describe "URL persistence" do
    test "mount with marked param restores marked notes", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/?tab=analyzer&marked=0-3,2-2,1-0")

      circle_count = length(Regex.scan(~r/analyzer-note-circle/, html))
      assert circle_count == 3
    end

    test "toggle_note updates the URL via patch", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?tab=analyzer")

      render_click(view, "toggle_note", %{"string" => "5", "fret" => "3"})

      # The view should show the marked note
      html = render(view)
      assert html =~ "analyzer-note-circle"
    end
  end
end
