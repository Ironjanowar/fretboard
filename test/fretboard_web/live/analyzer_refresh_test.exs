defmodule FretboardWeb.AnalyzerRefreshTest do
  @moduledoc """
  Reproduces the bug where the analyzer results do NOT refresh when notes
  are toggled via `phx-click="toggle_note"` in the LiveView.

  Expected flow:
    click note → handle_event("toggle_note", ...) → push_analyzer_patch
    → push_patch(socket, to: path) → handle_params/3 reassigns `analysis`
    → render/1 re-renders `<.analyzer_results analysis={@analysis} ... />`

  The bug: after `push_patch`, the `@analysis` assign (and therefore the
  rendered analysis cards) does NOT reflect the newly-marked notes.
  Refreshing the page (which goes through mount + handle_params fresh)
  works correctly, so the failure is specific to the patch path.

  Note on tuning indices (standard guitar, low→high in the list):
    index 0 = "E" (high E), 1 = "B", 2 = "G", 3 = "D", 4 = "A", 5 = "E" (low E)
  Wait — the list is ["E","A","D","G","B","E"], so:
    0 → E, 1 → A, 2 → D, 3 → G, 4 → B, 5 → E

  G major triad = G, B, D. Voicing used here:
    string 5 fret 3 → E + 3 = G   (low E)
    string 4 fret 0 → B          (open B)
    string 3 fret 0 → G... no. string 3 = G, open G = G. We need D.
    Let's recompute: index 3 = "G", so fret 0 → G, not D. For D on string 3:
    G + 7 = D. So fret 7. Or use string 2 (D) fret 0 → D.

  Final voicing:
    string 5 fret 3 → G   (low E + 3)
    string 4 fret 0 → B   (open B)
    string 2 fret 0 → D   (open D)

  The analyzer renders the G major label as "Gmaj" (Chord.label(:major) = "maj").
  """
  use FretboardWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "analyzer refresh on toggle_note (the bug)" do
    test "empty state is shown initially on the analyzer tab", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/?tab=analyzer")

      assert html =~ "Pulsa notas en el diapasón para identificar un acorde"
      refute html =~ "analysis-card"
    end

    test "clicking toggle_note to mark 3 notes updates the analysis results", %{conn: conn} do
      {:ok, view, html} = live(conn, "/?tab=analyzer")

      # Sanity: empty state before any clicks.
      assert html =~ "Pulsa notas en el diapasón para identificar un acorde"
      refute html =~ "analysis-card"

      # Click 1: mark string 5 fret 3 (G). With a single note we expect the
      # "Nota:" single-note state, NOT the empty state.
      html =
        view
        |> element("[phx-click='toggle_note'][phx-value-string='5'][phx-value-fret='3']")
        |> render_click()

      assert html =~ "Nota:"
      refute html =~ "Pulsa notas en el diapasón para identificar un acorde"

      # Click 2: mark string 4 fret 0 (B, open). Two notes → interval state.
      html =
        view
        |> element("[phx-click='toggle_note'][phx-value-string='4'][phx-value-fret='0']")
        |> render_click()

      assert html =~ "Intervalo:"
      refute html =~ "Nota:"
      refute html =~ "Pulsa notas en el diapasón para identificar un acorde"

      # Click 3: mark string 2 fret 0 (D, open). Three notes G-B-D → G major.
      html =
        view
        |> element("[phx-click='toggle_note'][phx-value-string='2'][phx-value-fret='0']")
        |> render_click()

      # The chord interpretation cards must now appear, and the G major
      # label ("Gmaj") must be rendered. This is the assertion that FAILS
      # due to the bug: the analysis results do not refresh after the patch.
      assert html =~ "analysis-card"
      assert html =~ "Gmaj"
      refute html =~ "Pulsa notas en el diapasón para identificar un acorde"
      refute html =~ "Intervalo:"
    end

    test "clicking toggle_note to remove a note reverts the analysis results", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?tab=analyzer")

      # Mark the G major triad: G (5/3), B (4/0), D (2/0).
      view
      |> element("[phx-click='toggle_note'][phx-value-string='5'][phx-value-fret='3']")
      |> render_click()

      view
      |> element("[phx-click='toggle_note'][phx-value-string='4'][phx-value-fret='0']")
      |> render_click()

      html =
        view
        |> element("[phx-click='toggle_note'][phx-value-string='2'][phx-value-fret='0']")
        |> render_click()

      # Precondition: the chord cards are shown.
      assert html =~ "analysis-card"
      assert html =~ "Gmaj"

      # Now toggle the D off (same string/fret → toggle off).
      html =
        view
        |> element("[phx-click='toggle_note'][phx-value-string='2'][phx-value-fret='0']")
        |> render_click()

      # After removing one note we should be back to a two-note (interval)
      # state, and the chord cards must disappear.
      refute html =~ "analysis-card"
      refute html =~ "Gmaj"
      assert html =~ "Intervalo:"
    end

    test "handle_params is invoked after push_patch (URL carries marked notes)", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?tab=analyzer")

      # Mark one note.
      view
      |> element("[phx-click='toggle_note'][phx-value-string='5'][phx-value-fret='3']")
      |> render_click()

      # assert_patch confirms the LiveView patched its URL — which means
      # handle_params was (or will be) invoked with the new params. The
      # expected path (guitar, standard tuning, no chords, analyzer tab):
      #   /?marked=5-3&tab=analyzer
      assert_patch(view, "/?marked=5-3&tab=analyzer")

      # And the rendered page must reflect the note we just marked via the
      # patch path — not just the URL.
      html = render(view)
      assert html =~ "Nota:"
      assert html =~ "G"
    end
  end

  describe "page refresh (control: this path works)" do
    test "mounting with marked notes in the URL shows the chord analysis", %{conn: conn} do
      # This is the control: refreshing the page (which goes through mount +
      # handle_params fresh) correctly shows the analysis. The bug is only
      # in the live patch path.
      {:ok, _view, html} = live(conn, "/?tab=analyzer&marked=5-3,4-0,2-0")

      assert html =~ "analysis-card"
      assert html =~ "Gmaj"
    end
  end
end
