defmodule FretboardWeb.AbsolutePitchAnalysisTest do
  @moduledoc """
  Regression tests for the first absolute-pitch vertical tracer (PR A).

  The analyzer must reason about real sounding pitches — open string
  pitch plus fret — instead of trusting string order, so that:

    * the bass of a chord is the lowest sounding pitch,
    * two-note intervals are shown low to high with their simple
      interval name,
    * two notes sharing a pitch class an octave apart are reported as an
      Octave instead of collapsing into a single note, and
    * reentrant tunings such as the standard high-G ukelele place the
      bass on the actual lowest sounding string, not the last string.

  Everything is exercised through the current LiveView interface: URL
  params on mount, `toggle_note` click events and the rendered HTML.
  No internal music API is called directly and no new markup is assumed.

  Tuning lists are indexed by string position, where index 0 is the
  string drawn at the bottom of the fretboard. For standard guitar that
  is the low E string — E(0), A(1), D(2), G(3), B(4), E(5), with the
  open high E on string 5. The standard ukelele list G(0), C(1), E(2),
  A(3) is reentrant: its open G4 sounds above C4.
  """

  use FretboardWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "open C chord (x32010) takes C as the bass, not E" do
    test "marking the open C shape via toggle_note reports Bass: C in root position", %{
      conn: conn
    } do
      {:ok, view, _html} = live(conn, "/?tab=analyzer")

      # Open C shape x32010: string 1 fret 3 (C3), string 2 fret 2 (E3),
      # string 3 fret 0 (G3), string 4 fret 1 (C4), string 5 fret 0 (E4).
      html =
        mark_all(view, [{"1", "3"}, {"2", "2"}, {"3", "0"}, {"4", "1"}, {"5", "0"}])

      # Sanity: with the five notes marked the chord cards are rendered.
      assert html =~ "analysis-card"

      # The lowest sounding pitch of the shape is C3 (string 1 fret 3),
      # not the open E4 on the highest string.
      assert has_element?(view, ".analysis-card-bass", "Bass: C")
      refute has_element?(view, ".analysis-card-bass", "Bass: E")

      # Every interpretation has C as its root, so the bass is the root
      # itself: plain Cmaj in root position and no slash chords.
      assert has_element?(view, ".analysis-card-title", ~r{^Cmaj$})
      assert has_element?(view, ".analysis-card-inversion", "Root position")
    end
  end

  describe "two-note intervals are ordered low to high" do
    test "C3 on string 1 fret 3 and E3 on string 2 fret 2 show C-E Major 3rd", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?tab=analyzer&marked=1-3,2-2")

      # Grave→agudo: the lower note (C3) is shown first, not the note on
      # the higher string, and 4 semitones is a Major 3rd.
      assert has_element?(view, ".analyzer-interval", ~r/Intervalo: C-E \(Major 3rd\)/)
      refute has_element?(view, ".analyzer-interval", ~r/Intervalo: E-C/)
      refute has_element?(view, ".analyzer-interval", ~r/Augmented 5th/)
    end

    test "C3 on string 1 fret 3 and open E4 on string 5 still show the simple Major 3rd",
         %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?tab=analyzer&marked=1-3,5-0")

      # C3→E4 spans 16 semitones (an octave plus a Major 3rd); the
      # simple interval name is still Major 3rd, ordered low to high.
      assert has_element?(view, ".analyzer-interval", ~r/Intervalo: C-E \(Major 3rd\)/)
      refute has_element?(view, ".analyzer-interval", ~r/Intervalo: E-C/)
      refute has_element?(view, ".analyzer-interval", ~r/Augmented 5th/)
    end
  end

  describe "real pitch crossings with high frets" do
    test "E4 on string 0 fret 24 above B3 and G3 makes G the bass, not B", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?tab=analyzer&marked=0-24,2-5,4-0")

      # Real pitches: G3 (string 2 fret 5) < B3 (string 4 open) < E4
      # (string 0 fret 24, two octaves above the open low E). The bass
      # is the lowest sounding pitch: G.
      assert has_element?(view, ".analysis-card-bass", "Bass: G")
      refute has_element?(view, ".analysis-card-bass", "Bass: B")

      # The E minor interpretation keeps its identity, annotated with
      # the real bass instead of the highest string index.
      assert has_element?(view, ".analysis-card-title", ~r{^Emin/G$})
    end
  end

  describe "same pitch class in different octaves" do
    test "C3 and C4 report an Octave instead of collapsing to a single note", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?tab=analyzer&marked=1-3,4-1")

      # String 1 fret 3 is C3 and string 4 fret 1 is C4: same pitch
      # class, one octave apart. Both notes must be reported as an
      # interval, not deduplicated into a single "Nota: C".
      assert has_element?(view, ".analyzer-interval", ~r/Intervalo: C-C \(Octave\)/)
      refute has_element?(view, ".analyzer-single-note", ~r/Nota:/)
    end
  end

  describe "reentrant tuning: standard high-G ukelele" do
    test "enough open strings put the bass on C, not on the last string A", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?instrument=ukelele&tab=analyzer&marked=0-0,1-0,2-0,3-0")

      # Standard ukelele tuning is reentrant high-G: G4 C4 E4 A4, where
      # the open G4 sounds above C4. With the four open strings marked,
      # the lowest sounding pitch is C4 — not string 3's A4.
      assert has_element?(view, ".analysis-card-bass", "Bass: C")
      refute has_element?(view, ".analysis-card-bass", "Bass: A")
    end
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp mark_all(view, positions) do
    Enum.reduce(positions, nil, fn {string, fret}, _html ->
      click_note(view, string, fret)
    end)
  end

  defp click_note(view, string, fret) do
    view
    |> element(
      "[phx-click='toggle_note'][phx-value-string='#{string}'][phx-value-fret='#{fret}']"
    )
    |> render_click()
  end
end
