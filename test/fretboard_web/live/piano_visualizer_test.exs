defmodule FretboardWeb.PianoVisualizerTest do
  # Phase 2 (visualizer) LiveView tests for the piano integration, written
  # RED-first. They describe the keyboard presentation contract that the
  # visualizer must implement, mirroring the conventions of
  # FretboardWeb.FretboardSVG note_circles:
  #
  # Agreed DOM contract:
  #   * `#piano-keyboard` is the keyboard container rendered instead of the
  #     fretboard SVG (`#fretboard` / `#analyzer-fretboard`) when the
  #     instrument is piano.
  #   * One key element per fixed pitch C3..B5 (MIDI 48..83) carrying
  #     `data-pitch="48"` plus the color class `piano-key--white` or
  #     `piano-key--black`.
  #   * Active keys (belonging to at least one active chord) render a
  #     `.piano-key-marker` child whose `fill` is the chord palette color,
  #     the overlap gray `#9E9E9E` for shared notes, or gray for chords
  #     dimmed by highlighting - exactly like `note_fill/4`.
  #   * Active keys also render a `.piano-note-label` child with the bare
  #     note name; inactive keys render no marker and no visible label.
  use FretboardWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  @piano "/?instrument=piano"

  # Palette constants shared with FretboardSVG (@chord_colors, @overlap_color).
  @cmaj_color "#4FC3F7"
  @emaj_color "#FF8A65"
  @overlap_color "#9E9E9E"

  # C major over C3..B5: every C, E and G occurrence.
  @cmaj_pitches [48, 52, 55, 60, 64, 67, 72, 76, 79]
  # C and G occur only in C major when E major is also active.
  @cmaj_unique_pitches [48, 55, 60, 67, 72, 79]
  # E is shared between C major and E major.
  @shared_pitches [52, 64, 76]
  # G# and B occur only in E major when C major is also active.
  @emaj_unique_pitches [56, 59, 68, 71, 80, 83]

  @pending_copy "Piano analyzer is coming in the next update"

  describe "instrument selector offers Piano" do
    test "mounting instrument=piano selects the Piano option", %{conn: conn} do
      {:ok, view, _html} = live(conn, @piano)

      assert has_element?(view, "#instrument-select option[value=piano][selected]", "Piano")

      # Existing fretted instruments remain available with stable values.
      for value <- ~w(guitar bass_4 bass_5 ukelele) do
        assert has_element?(view, "#instrument-select option[value=#{value}]")
      end
    end
  end

  describe "selecting piano from the controls" do
    test "switching via the instrument form patches the URL and hides tuning controls", %{
      conn: conn
    } do
      {:ok, view, _html} = live(conn, "/")
      assert has_element?(view, "button[phx-click=open_tuning_modal]")

      view |> form("#instrument-form", %{instrument: "piano"}) |> render_change()

      assert patch_query(view) == %{"instrument" => "piano"}
      assert has_element?(view, "#piano-keyboard")
      refute has_element?(view, "button[phx-click=open_tuning_modal]")
      refute has_element?(view, "#fretboard")
      refute has_element?(view, ".fretboard-wrapper")
    end

    test "direct tuning events are ignored without crashing or changing state", %{conn: conn} do
      {:ok, view, _html} = live(conn, @piano)
      assert has_element?(view, "#piano-keyboard")

      render_click(view, "open_tuning_modal")
      refute has_element?(view, "#tuning-modal")

      render_click(view, "select_preset", %{"preset" => "Standard"})
      render_click(view, "change_string", %{"string" => "0", "note" => "E"})
      render_click(view, "apply_tuning", %{})

      refute_patch(view)
      assert has_element?(view, "#piano-keyboard")
      refute has_element?(view, "#tuning-modal")
    end
  end

  describe "keyboard rendering for the visualizer" do
    test "direct mount renders the fixed C3-B5 keyboard instead of a fretboard", %{conn: conn} do
      {:ok, view, _html} = live(conn, @piano)

      assert has_element?(view, "#piano-keyboard")
      refute has_element?(view, "#fretboard")
      refute has_element?(view, "#analyzer-fretboard")
      refute has_element?(view, ".fretboard-wrapper")

      html = keyboard_html(view)

      # Exactly one key per pitch in the fixed range.
      assert length(Regex.scan(~r/data-pitch="/, html)) == 36
      assert has_element?(view, "[data-pitch='48']")
      assert has_element?(view, "[data-pitch='83']")
      refute has_element?(view, "[data-pitch='47']")
      refute has_element?(view, "[data-pitch='84']")

      # White and black keys follow the physical keyboard pattern.
      assert count_class(html, "piano-key--white") == 21
      assert count_class(html, "piano-key--black") == 15
      assert has_element?(view, ".piano-key--white[data-pitch='48']")
      assert has_element?(view, ".piano-key--white[data-pitch='83']")
      assert has_element?(view, ".piano-key--black[data-pitch='49']")
      assert has_element?(view, ".piano-key--black[data-pitch='54']")
    end

    test "inactive keys carry no markers or visible note labels", %{conn: conn} do
      {:ok, view, _html} = live(conn, @piano)

      html = keyboard_html(view)

      assert count_class(html, "piano-key-marker") == 0
      assert count_class(html, "piano-note-label") == 0
    end
  end

  describe "chord markers" do
    test "a chord marks every occurrence in all octaves with its palette color", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?instrument=piano&chords=Cmaj")

      for pitch <- @cmaj_pitches do
        assert_marker(view, pitch, @cmaj_color)
      end

      html = keyboard_html(view)
      assert count_class(html, "piano-key-marker") == 9

      # Single chord: nothing is dimmed or overlapped.
      refute has_element?(view, ".piano-key-marker[fill='#{@overlap_color}']")

      # Visible note labels exist only on active keys and carry no octave.
      assert has_element?(view, "[data-pitch='48'] .piano-note-label", ~r/^C$/)
      assert has_element?(view, "[data-pitch='52'] .piano-note-label", ~r/^E$/)
      refute has_element?(view, "[data-pitch='50'] .piano-note-label")
      assert count_class(html, "piano-note-label") == 9
    end

    test "notes shared between chords use the overlap color like fretboard note circles", %{
      conn: conn
    } do
      {:ok, view, _html} = live(conn, "/?instrument=piano&chords=Cmaj,Emaj")

      for pitch <- @cmaj_unique_pitches, do: assert_marker(view, pitch, @cmaj_color)
      for pitch <- @shared_pitches, do: assert_marker(view, pitch, @overlap_color)
      for pitch <- @emaj_unique_pitches, do: assert_marker(view, pitch, @emaj_color)
    end
  end

  describe "highlighting" do
    test "highlighting a chord keeps its notes colored and dims the other chords", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?instrument=piano&chords=Cmaj,Emaj")

      view
      |> element(".chord-chip[phx-click='highlight_chord'][phx-value-index='0']")
      |> render_click()

      assert patch_query(view)["highlight"] == "Cmaj"

      # Highlighted chord notes - including the shared E - stay in its color.
      for pitch <- @cmaj_pitches, do: assert_marker(view, pitch, @cmaj_color)

      # The other chord's unique notes are dimmed to the neutral gray.
      for pitch <- @emaj_unique_pitches, do: assert_marker(view, pitch, @overlap_color)

      assert has_element?(view, ".chord-chip--highlighted", "Cmaj")
      refute has_element?(view, ".chord-chip--highlighted", "Emaj")
    end
  end

  describe "chord chips and suggestions in the piano visualizer" do
    test "adding a chord from the form marks keys and keeps a shareable piano URL", %{
      conn: conn
    } do
      {:ok, view, _html} = live(conn, @piano)

      view
      |> form("#chord-form", %{chord: %{root: "C", quality: "major"}})
      |> render_submit()

      assert patch_query(view) == %{"instrument" => "piano", "chords" => "Cmaj"}
      assert has_element?(view, ".chord-chip", "Cmaj")

      for pitch <- @cmaj_pitches, do: assert_marker(view, pitch, @cmaj_color)
    end

    test "removing the chord chip clears its keyboard markers", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?instrument=piano&chords=Cmaj")

      view |> element(".chord-chip-remove[phx-value-index='0']") |> render_click()

      assert patch_query(view) == %{"instrument" => "piano"}
      refute has_element?(view, ".chord-chip")
      assert count_class(keyboard_html(view), "piano-key-marker") == 0
    end

    test "clearing all chords removes every marker", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?instrument=piano&chords=Cmaj,Amin")

      view |> element("button[phx-click=clear_all_chords]") |> render_click()

      assert patch_query(view) == %{"instrument" => "piano"}
      assert count_class(keyboard_html(view), "piano-key-marker") == 0
    end

    test "key suggestion cards render and apply diatonic chords to the keyboard", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?instrument=piano&chords=Cmaj,Amin")
      render_async(view)

      assert has_element?(view, "#key-suggestions", "Compatible keys")
      assert has_element?(view, "#key-suggestions .key-card")

      render_click(view, "apply_suggested_key", %{"tonic" => "C", "scale_type" => "major"})

      assert patch_query(view) == %{
               "instrument" => "piano",
               "chords" => "Cmaj,Dmin,Emin,Fmaj,Gmaj,Amin,Bdim"
             }

      assert has_element?(view, "[data-pitch='48'] .piano-key-marker")
    end
  end

  describe "switching instruments" do
    test "guitar to piano keeps chords, resets highlight and emits no tuning params", %{
      conn: conn
    } do
      {:ok, view, _html} = live(conn, "/?chords=Cmaj,Amin&highlight=Cmaj")
      assert has_element?(view, ".chord-chip--highlighted", "Cmaj")

      view |> form("#instrument-form", %{instrument: "piano"}) |> render_change()

      assert patch_query(view) == %{"instrument" => "piano", "chords" => "Cmaj,Amin"}
      refute has_element?(view, ".chord-chip--highlighted")
      assert has_element?(view, "#piano-keyboard")
      assert has_element?(view, ".chord-chip", "Amin")

      # Chord markers keep the palette conventions on the keyboard.
      assert_marker(view, 55, @cmaj_color)
      assert_marker(view, 57, @emaj_color)
    end

    test "piano to guitar restores the standard fretboard and tuning", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?instrument=piano&chords=Cmaj")

      view |> form("#instrument-form", %{instrument: "guitar"}) |> render_change()

      assert patch_query(view) == %{"chords" => "Cmaj"}
      refute has_element?(view, "#piano-keyboard")
      assert has_element?(view, "#fretboard")
      assert has_element?(view, ".chord-chip", "Cmaj")

      render_click(view, "open_tuning_modal")
      assert has_element?(view, "option[value='Standard'][selected]")
      assert has_element?(view, "#string-select-0 option[value='E'][selected]")
    end
  end

  describe "analyzer tab pending state" do
    test "piano analyzer tab shows an explicit English pending state instead of a fretboard", %{
      conn: conn
    } do
      {:ok, view, html} = live(conn, "/?instrument=piano&tab=analyzer")

      assert html =~ @pending_copy
      refute has_element?(view, "#piano-keyboard")
      refute has_element?(view, ".fretboard-wrapper")
      refute render(view) =~ "Click notes on the fretboard to identify a chord"
    end

    test "string instruments keep the full analyzer", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/?tab=analyzer")

      assert html =~ "Click notes on the fretboard to identify a chord"
      assert html =~ "analyzer-fretboard"
      refute html =~ @pending_copy
    end
  end

  describe "share and reload roundtrip" do
    test "chords, highlight and the empty selection survive a reload", %{conn: conn} do
      {:ok, view, _html} = live(conn, @piano)

      view
      |> form("#chord-form", %{chord: %{root: "C", quality: "major"}})
      |> render_submit()

      assert_patch(view)

      view
      |> element(".chord-chip[phx-click='highlight_chord'][phx-value-index='0']")
      |> render_click()

      path = assert_patch(view)

      assert URI.decode_query(URI.parse(path).query) == %{
               "instrument" => "piano",
               "chords" => "Cmaj",
               "highlight" => "Cmaj"
             }

      {:ok, reloaded, _html} = live(build_conn(), path)

      assert has_element?(reloaded, "#instrument-select option[value=piano][selected]")
      assert has_element?(reloaded, "#piano-keyboard")
      assert has_element?(reloaded, ".chord-chip--highlighted", "Cmaj")

      for pitch <- @cmaj_pitches, do: assert_marker(reloaded, pitch, @cmaj_color)
    end

    test "legacy string URL parameters are ignored on a piano page", %{conn: conn} do
      {:ok, view, _html} =
        live(
          conn,
          "/?instrument=piano&tuning=D,A,D,G,B,E&pitches=38,45,50,55,59,64&reference=Drop+D&marked=0-0&chords=Cmaj"
        )

      assert has_element?(view, "#piano-keyboard")
      refute has_element?(view, "button[phx-click=open_tuning_modal]")
      assert has_element?(view, ".chord-chip", "Cmaj")

      for pitch <- @cmaj_pitches, do: assert_marker(view, pitch, @cmaj_color)
    end
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp patch_query(view) do
    view |> assert_patch() |> URI.parse() |> Map.get(:query) |> decode_query()
  end

  defp decode_query(nil), do: %{}
  defp decode_query(query), do: URI.decode_query(query)

  # No URL patch may be pending for the view (Phoenix.LiveViewTest 1.1 has no
  # public refute_patch/1, so assert the inverse through assert_patch/2).
  defp refute_patch(view) do
    assert_raise ArgumentError, ~r/but got none/, fn -> assert_patch(view, 0) end
  end

  defp assert_marker(view, pitch, fill) do
    assert has_element?(view, "[data-pitch='#{pitch}'] .piano-key-marker[fill='#{fill}']"),
           "expected a marker with fill #{fill} on pitch #{pitch}"
  end

  defp keyboard_html(view) do
    assert has_element?(view, "#piano-keyboard")
    view |> element("#piano-keyboard") |> render()
  end

  defp count_class(html, class_name) do
    html
    |> then(&Regex.scan(~r/class="([^"]*)"/, &1, capture: :all_but_first))
    |> Enum.count(fn [classes] -> class_name in String.split(classes) end)
  end
end
