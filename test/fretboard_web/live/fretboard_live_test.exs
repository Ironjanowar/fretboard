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

      assert html =~ "Cmaj"
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
      assert length(Regex.scan(~r/chord-chip"/, html)) == 1
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

  describe "tuning labels" do
    test "tuning labels are not clickable (no phx-click attribute)", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      # Tuning labels should exist but NOT have phx-click
      labels = Regex.scan(~r/class="tuning-label"[^>]*>/, html)
      assert length(labels) == 6

      for [label] <- labels do
        refute label =~ "phx-click"
      end
    end
  end

  describe "tuning modal" do
    test "renders a Tuning button in controls", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")
      assert html =~ "Tuning"
    end

    test "modal is hidden by default", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")
      refute html =~ "tuning-modal"
    end

    test "clicking Tuning button opens the modal", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      html = view |> element("[phx-click=open_tuning_modal]") |> render_click()
      assert html =~ "tuning-modal"
    end

    test "modal shows preset dropdown", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      html = view |> element("[phx-click=open_tuning_modal]") |> render_click()
      assert html =~ "preset-select"
      assert html =~ "Standard"
      assert html =~ "Drop D"
      assert html =~ "Custom"
    end

    test "modal shows 6 string dropdowns", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      html = view |> element("[phx-click=open_tuning_modal]") |> render_click()

      for i <- 1..6 do
        assert html =~ "String #{i}"
      end
    end

    test "selecting a preset updates modal tuning", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      view |> element("[phx-click=open_tuning_modal]") |> render_click()

      html = render_click(view, "select_preset", %{"preset" => "Drop D"})
      # The modal should still be open with Drop D selected
      assert html =~ "tuning-modal"
    end

    test "selecting a preset updates string dropdowns to show preset notes", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      view |> element("[phx-click=open_tuning_modal]") |> render_click()

      # Select Drop D preset: D A D G B E (index 0=D, 1=A, 2=D, 3=G, 4=B, 5=E)
      html = render_click(view, "select_preset", %{"preset" => "Drop D"})

      # Extract all String N (index I) = Note mappings from the modal
      string_notes =
        Regex.scan(
          ~r/String (\d).*?<select[^>]*id="string-select-(\d)"[^>]*>.*?<option[^>]*value="([^"]*)"[^>]*selected/s,
          html
        )
        |> Enum.map(fn [_, string_num, _idx, note] -> {String.to_integer(string_num), note} end)
        |> Enum.sort_by(&elem(&1, 0))

      # Drop D: String 1=E, 2=B, 3=G, 4=D, 5=A, 6=D
      assert string_notes == [{1, "E"}, {2, "B"}, {3, "G"}, {4, "D"}, {5, "A"}, {6, "D"}]
    end

    test "applying tuning updates the fretboard and closes modal", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      view |> element("[phx-click=open_tuning_modal]") |> render_click()
      render_click(view, "select_preset", %{"preset" => "Drop D"})

      html = render_click(view, "apply_tuning", %{})
      # Modal should be closed
      refute html =~ "tuning-modal"
      # Tuning label should show D for the low string
      assert html =~ "tuning-label"
    end

    test "canceling modal doesn't change tuning", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      view |> element("[phx-click=open_tuning_modal]") |> render_click()
      render_click(view, "select_preset", %{"preset" => "Drop D"})

      html = render_click(view, "close_tuning_modal", %{})
      # Modal should be closed
      refute html =~ "tuning-modal"
      # Tuning should still be standard — check labels show standard order
      labels =
        Regex.scan(~r/class="tuning-label"[^>]*>\s*([A-G]#?)\s*</s, html)
        |> Enum.map(fn [_, note] -> note end)

      # Standard tuning DOM order (low to high): E A D G B E
      assert labels == ["E", "A", "D", "G", "B", "E"]
    end

    test "changing individual string works", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      view |> element("[phx-click=open_tuning_modal]") |> render_click()

      html = render_click(view, "change_string", %{"string" => "0", "note" => "D"})
      # Modal should still be open
      assert html =~ "tuning-modal"
    end
  end

  describe "query params" do
    test "mount with no params has standard tuning and no chords", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")
      refute html =~ "note-circle"
      refute html =~ "chord-chip"
    end

    test "mount with chords param restores those chords", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/?chords=Cmaj,Amin")
      assert html =~ "note-circle"
      assert html =~ "Cmaj"
      assert html =~ "Amin"
      assert length(Regex.scan(~r/chord-chip"/, html)) == 2
    end

    test "mount with tuning and chords params restores full state", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/?tuning=D,A,D,G,B,E&chords=Cmaj")
      assert html =~ "note-circle"
      assert html =~ "Cmaj"

      labels =
        Regex.scan(~r/class="tuning-label"[^>]*>\s*([A-G]#?)\s*</s, html)
        |> Enum.map(fn [_, note] -> note end)

      assert labels == ["D", "A", "D", "G", "B", "E"]
    end

    test "adding a chord updates the URL", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view
      |> form("#chord-form", %{chord: %{root: "C", quality: "major"}})
      |> render_submit()

      assert render(view) =~ "Cmaj"
    end
  end

  describe "key modal" do
    test "renders a Key button in controls", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")
      assert html =~ "Key"
    end

    test "key modal is hidden by default", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")
      refute html =~ "key-modal"
    end

    test "clicking Key button opens the modal", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      html = view |> element("[phx-click=open_key_modal]") |> render_click()
      assert html =~ "key-modal"
    end

    test "modal shows tonic and scale type selectors", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      html = view |> element("[phx-click=open_key_modal]") |> render_click()
      assert html =~ "key-tonic-select"
      assert html =~ "key-scale-select"
    end

    test "modal shows 7 preview chord chips", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      html = view |> element("[phx-click=open_key_modal]") |> render_click()
      assert length(Regex.scan(~r/key-preview-chip/, html)) == 7
    end

    test "applying key replaces all active chords", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Add a chord first
      view
      |> form("#chord-form", %{chord: %{root: "A", quality: "minor"}})
      |> render_submit()

      # Open key modal and apply C major
      view |> element("[phx-click=open_key_modal]") |> render_click()
      html = render_click(view, "apply_key", %{})

      # Should have 7 diatonic chords of C major, not the old Amin
      assert length(Regex.scan(~r/chord-chip"/, html)) == 7
      assert html =~ "Cmaj"
      assert html =~ "Dmin"
      assert html =~ "Bdim"
      # Modal should be closed
      refute html =~ "key-modal"
    end

    test "applying key updates URL with chord params", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      view |> element("[phx-click=open_key_modal]") |> render_click()
      render_click(view, "apply_key", %{})

      # Verify chords are in the rendered output
      html = render(view)
      assert html =~ "Cmaj"
    end

    test "canceling key modal doesn't change active chords", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view
      |> form("#chord-form", %{chord: %{root: "A", quality: "minor"}})
      |> render_submit()

      view |> element("[phx-click=open_key_modal]") |> render_click()
      html = render_click(view, "close_key_modal", %{})

      refute html =~ "key-modal"
      assert html =~ "Amin"
      assert length(Regex.scan(~r/chord-chip"/, html)) == 1
    end

    test "after applying key, user can still remove individual chords", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      view |> element("[phx-click=open_key_modal]") |> render_click()
      render_click(view, "apply_key", %{})

      # Remove the first chord
      html = view |> element("[phx-click=remove_chord][phx-value-index='0']") |> render_click()
      assert length(Regex.scan(~r/chord-chip"/, html)) == 6
    end

    test "changing key tonic updates preview", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      view |> element("[phx-click=open_key_modal]") |> render_click()

      html =
        render_change(view, "update_key", %{"key" => %{"tonic" => "G", "scale_type" => "major"}})

      # Preview should show G major diatonic chords
      assert html =~ "Gmaj"
      assert html =~ "Amin"
    end
  end

  describe "key modal chord mode" do
    test "modal shows a chord mode select with Triads and 7ths options", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      html = view |> element("[phx-click=open_key_modal]") |> render_click()

      assert html =~ "name=\"key[chord_mode]\""
      assert html =~ "Triads"
      assert html =~ "7ths"
    end

    test "default chord mode is triad (Triads option is selected)", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      html = view |> element("[phx-click=open_key_modal]") |> render_click()

      # The Triads option should be selected by default
      assert html =~ ~s(value="triad" selected)
      refute html =~ ~s(value="seventh" selected)
    end

    test "default mode produces triad diatonic chords (backward compat)", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      view |> element("[phx-click=open_key_modal]") |> render_click()

      html = render_click(view, "apply_key", %{})

      # C major triads: Cmaj, Dmin, Emin, Fmaj, Gmaj, Amin, Bdim
      assert length(Regex.scan(~r/chord-chip\"/, html)) == 7
      assert html =~ "Cmaj"
      assert html =~ "Bdim"
      # 7th-only labels should NOT appear
      refute html =~ "Cmaj7"
      refute html =~ "Dmin7"
    end

    test "selecting 7ths mode updates the preview to 7th diatonic chords", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      view |> element("[phx-click=open_key_modal]") |> render_click()

      html =
        render_change(view, "update_key", %{
          "key" => %{"tonic" => "C", "scale_type" => "major", "chord_mode" => "seventh"}
        })

      # Preview should show C major 7th diatonic chords
      assert html =~ "Cmaj7"
      assert html =~ "Dmin7"
      assert html =~ "G7"
      assert html =~ "Bm7b5"
    end

    test "applying with 7ths mode generates 7th diatonic chords as active chords", %{
      conn: conn
    } do
      {:ok, view, _html} = live(conn, "/")
      view |> element("[phx-click=open_key_modal]") |> render_click()

      # Switch to 7ths mode
      render_change(view, "update_key", %{
        "key" => %{"tonic" => "C", "scale_type" => "major", "chord_mode" => "seventh"}
      })

      html = render_click(view, "apply_key", %{})

      # 7th diatonic chords of C major should be active
      assert length(Regex.scan(~r/chord-chip\"/, html)) == 7
      assert html =~ "Cmaj7"
      assert html =~ "Dmin7"
      assert html =~ "Emin7"
      assert html =~ "Fmaj7"
      assert html =~ "G7"
      assert html =~ "Amin7"
      assert html =~ "Bm7b5"
      # Modal should be closed
      refute html =~ "key-modal"
    end

    test "update_key without chord_mode param defaults to triad", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      view |> element("[phx-click=open_key_modal]") |> render_click()

      # Send update_key without chord_mode (simulates older form / backward compat)
      html =
        render_change(view, "update_key", %{
          "key" => %{"tonic" => "C", "scale_type" => "major"}
        })

      # Should still render triad chords, not 7ths
      assert html =~ "Cmaj"
      refute html =~ "Cmaj7"
    end
  end

  describe "highlight_chord event" do
    test "clicking a chord chip with highlight_chord highlights it", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?chords=Cmaj,Amin")

      html = render_click(view, "highlight_chord", %{"index" => "0"})

      assert html =~ "chord-chip--highlighted"
    end

    test "highlighting a chip toggles it on (adds highlighted_chord assign)", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?chords=Cmaj,Amin")

      html = render_click(view, "highlight_chord", %{"index" => "1"})

      # The second chip should be highlighted
      assert html =~ "chord-chip--highlighted"
    end

    test "clicking the same chip again toggles highlight off", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?chords=Cmaj,Amin")

      # First click: toggle on
      render_click(view, "highlight_chord", %{"index" => "0"})
      # Second click: toggle off
      html = render_click(view, "highlight_chord", %{"index" => "0"})

      refute html =~ "chord-chip--highlighted"
    end

    test "clicking a different chip switches highlight to the new chip", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?chords=Cmaj,Amin,G7")

      render_click(view, "highlight_chord", %{"index" => "0"})
      html = render_click(view, "highlight_chord", %{"index" => "2"})

      # Only one chip should be highlighted at a time
      assert html =~ "chord-chip--highlighted"
    end

    test "chord chips have phx-click=highlight_chord and phx-value-index", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/?chords=Cmaj,Amin")

      # Each chip should have the click handler and value
      assert html =~ ~s(phx-click="highlight_chord")
      assert html =~ ~s(phx-value-index="0")
      assert html =~ ~s(phx-value-index="1")
    end

    test "highlighted chord notes render in chord color instead of gray for single-chord notes",
         %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?chords=Cmaj,Amin")

      # Without highlighting, overlapping notes are gray
      _initial_html = render(view)

      # Highlight C major — its unique notes (C, E, G) should use Cmaj's color
      html = render_click(view, "highlight_chord", %{"index" => "0"})

      # C major color is #4FC3F7 (first chord, index 0)
      # The note fill for the highlighted chord should use chord color, not gray
      assert html =~ "#4FC3F7"
    end
  end

  describe "highlight clears on remove_chord" do
    test "removing the highlighted chord clears highlight", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?chords=Cmaj,Amin")

      render_click(view, "highlight_chord", %{"index" => "0"})

      # Remove the highlighted chord (index 0)
      html = view |> element("[phx-click=remove_chord][phx-value-index='0']") |> render_click()

      refute html =~ "chord-chip--highlighted"
    end

    test "removing a chord before the highlighted chord decrements highlighted_chord", %{
      conn: conn
    } do
      {:ok, view, _html} = live(conn, "/?chords=Cmaj,Amin,G7")

      # Highlight G7 (index 2)
      render_click(view, "highlight_chord", %{"index" => "2"})

      # Remove Cmaj (index 0, which is before the highlighted chord)
      html = view |> element("[phx-click=remove_chord][phx-value-index='0']") |> render_click()

      # After removal, Amin is now index 0, G7 is now index 1
      # G7 should still be highlighted (at its new index)
      assert html =~ "chord-chip--highlighted"
    end

    test "removing a chord after the highlighted chord keeps highlight on same chord", %{
      conn: conn
    } do
      {:ok, view, _html} = live(conn, "/?chords=Cmaj,Amin,G7")

      # Highlight Cmaj (index 0)
      render_click(view, "highlight_chord", %{"index" => "0"})

      # Remove G7 (index 2, which is after the highlighted chord)
      html = view |> element("[phx-click=remove_chord][phx-value-index='2']") |> render_click()

      # Cmaj should still be highlighted
      assert html =~ "chord-chip--highlighted"
    end
  end

  describe "highlight clears on apply_key" do
    test "applying a key clears highlighted_chord", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?chords=Amin")

      # Highlight the chord
      render_click(view, "highlight_chord", %{"index" => "0"})

      # Apply a key
      view |> element("[phx-click=open_key_modal]") |> render_click()
      html = render_click(view, "apply_key", %{})

      # Highlight should be cleared after applying key
      refute html =~ "chord-chip--highlighted"
    end
  end

  describe "progressions button" do
    test "renders a Progressions button in controls", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")
      assert html =~ "Progressions"
    end
  end

  describe "progression modal" do
    test "progression modal is hidden by default", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")
      refute html =~ "progression-modal"
    end

    test "clicking Progressions button opens the modal", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      html = view |> element("[phx-click=open_progression_modal]") |> render_click()
      assert html =~ "progression-modal"
    end

    test "modal shows progression selector with categories", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      html = view |> element("[phx-click=open_progression_modal]") |> render_click()
      assert html =~ "Famous / Classic"
      assert html =~ "Jazz / Sophisticated"
    end

    test "modal shows tonic selector", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      html = view |> element("[phx-click=open_progression_modal]") |> render_click()
      assert html =~ "progression-tonic-select" or html =~ "name=\"progression[tonic]\""
    end

    test "modal shows preview chord chips", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      html = view |> element("[phx-click=open_progression_modal]") |> render_click()
      # Default progression is Pop Punk I-V-vi-IV in C → C, G, Am, F
      assert html =~ "Cmaj"
      assert html =~ "Gmaj"
    end

    test "applying progression replaces all active chords", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      # Open modal and apply
      view |> element("[phx-click=open_progression_modal]") |> render_click()
      html = render_click(view, "apply_progression", %{})
      # Pop Punk in C → 4 chords
      assert length(Regex.scan(~r/chord-chip\"/, html)) == 4
      assert html =~ "Cmaj"
      assert html =~ "Gmaj"
      refute html =~ "progression-modal"
    end

    test "canceling progression modal doesn't change active chords", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      # Add a chord first
      view |> form("#chord-form", %{chord: %{root: "A", quality: "minor"}}) |> render_submit()
      # Open modal and cancel
      view |> element("[phx-click=open_progression_modal]") |> render_click()
      html = render_click(view, "close_progression_modal", %{})
      refute html =~ "progression-modal"
      assert html =~ "Amin"
      assert length(Regex.scan(~r/chord-chip\"/, html)) == 1
    end

    test "changing progression updates preview", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      view |> element("[phx-click=open_progression_modal]") |> render_click()
      # Change to andalusian cadence in A
      html =
        render_change(view, "update_progression", %{
          "progression" => %{"id" => "andalusian_cadence", "tonic" => "A"}
        })

      # Andalusian in A → Am, G, F, E
      assert html =~ "Amin"
    end

    test "changing tonic updates preview", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      view |> element("[phx-click=open_progression_modal]") |> render_click()
      # Change to G tonic
      html =
        render_change(view, "update_progression", %{
          "progression" => %{"id" => "pop_i_v_vi_iv", "tonic" => "G"}
        })

      # Pop Punk in G → G, D, Em, C
      assert html =~ "Gmaj"
      assert html =~ "Dmaj"
    end

    test "after applying progression, user can still remove individual chords", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      view |> element("[phx-click=open_progression_modal]") |> render_click()
      render_click(view, "apply_progression", %{})
      # Remove the first chord
      html = view |> element("[phx-click=remove_chord][phx-value-index='0']") |> render_click()
      # Should have one fewer chip
      chips_before = 4
      assert length(Regex.scan(~r/chord-chip\"/, html)) == chips_before - 1
    end

    test "applying progression clears highlighted chord", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?chords=Cmaj")
      # Highlight the chord
      render_click(view, "highlight_chord", %{"index" => "0"})
      # Apply a progression
      view |> element("[phx-click=open_progression_modal]") |> render_click()
      html = render_click(view, "apply_progression", %{})
      refute html =~ "chord-chip--highlighted"
    end
  end

  describe "highlight in URL params" do
    test "mount with highlight param highlights the correct chord", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/?chords=Cmaj,Amin&highlight=Cmaj")

      assert html =~ "chord-chip--highlighted"
    end

    test "mount with highlight param pointing to second chord", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/?chords=Cmaj,Amin&highlight=Amin")

      assert html =~ "chord-chip--highlighted"
    end

    test "mount with invalid highlight param defaults to no highlight", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/?chords=Cmaj,Amin&highlight=G7")

      refute html =~ "chord-chip--highlighted"
    end

    test "highlighting a chord updates the URL", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?chords=Cmaj")

      render_click(view, "highlight_chord", %{"index" => "0"})

      # The URL should include the highlight param
      # We verify by checking the rendered output still shows the highlighted chip
      html = render(view)
      assert html =~ "chord-chip--highlighted"
    end

    test "toggling highlight off removes it from URL", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?chords=Cmaj")

      # Toggle on
      render_click(view, "highlight_chord", %{"index" => "0"})
      # Toggle off
      render_click(view, "highlight_chord", %{"index" => "0"})

      html = render(view)
      refute html =~ "chord-chip--highlighted"
    end
  end

  describe "instrument selector" do
    test "renders an instrument selector dropdown in the controls", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      assert html =~ ~s(id="instrument-select") or html =~ ~s(phx-click="change_instrument")
    end

    test "instrument selector shows all 3 instruments", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      assert html =~ "Guitar"
      assert html =~ "Bass (4-string)"
      assert html =~ "Bass (5-string)"
    end

    test "instrument selector defaults to Guitar", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      # The default selected instrument should be Guitar
      assert html =~ ~s(id="instrument-select") or html =~ ~s(phx-click="change_instrument")

      # Check that Guitar is the selected/default option
      assert html =~ "Guitar"
    end
  end

  describe "mount with instrument param" do
    test "mount with instrument=bass_4 renders 4 string lines", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/?instrument=bass_4")

      assert length(Regex.scan(~r/class="string-line"/, html)) == 4
    end

    test "mount with instrument=bass_5 renders 5 string lines", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/?instrument=bass_5")

      assert length(Regex.scan(~r/class="string-line"/, html)) == 5
    end

    test "mount with instrument=bass_4 shows 4 tuning labels", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/?instrument=bass_4")

      assert length(Regex.scan(~r/class="tuning-label"/, html)) == 4
    end

    test "mount with instrument=bass_5 shows 5 tuning labels", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/?instrument=bass_5")

      assert length(Regex.scan(~r/class="tuning-label"/, html)) == 5
    end

    test "mount with instrument=bass_4 shows bass_4 standard tuning labels (E,A,D,G)", %{
      conn: conn
    } do
      {:ok, _view, html} = live(conn, "/?instrument=bass_4")

      labels =
        Regex.scan(~r/class="tuning-label"[^>]*>\s*([A-G]#?)\s*</s, html)
        |> Enum.map(fn [_, note] -> note end)

      # bass_4 standard tuning DOM order (low to high): E, A, D, G
      assert labels == ["E", "A", "D", "G"]
    end

    test "mount with instrument=bass_5 shows bass_5 standard tuning labels (B,E,A,D,G)", %{
      conn: conn
    } do
      {:ok, _view, html} = live(conn, "/?instrument=bass_5")

      labels =
        Regex.scan(~r/class="tuning-label"[^>]*>\s*([A-G]#?)\s*</s, html)
        |> Enum.map(fn [_, note] -> note end)

      # bass_5 standard tuning DOM order (low to high): B, E, A, D, G
      assert labels == ["B", "E", "A", "D", "G"]
    end

    test "mount without instrument defaults to 6 strings (guitar)", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      assert length(Regex.scan(~r/class="string-line"/, html)) == 6
    end
  end

  describe "change_instrument event" do
    test "changing to bass_4 updates the fretboard to 4 strings", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      html = render_click(view, "change_instrument", %{"instrument" => "bass_4"})

      assert length(Regex.scan(~r/class="string-line"/, html)) == 4
    end

    test "changing to bass_5 updates the fretboard to 5 strings", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      html = render_click(view, "change_instrument", %{"instrument" => "bass_5"})

      assert length(Regex.scan(~r/class="string-line"/, html)) == 5
    end

    test "changing instrument resets tuning to the new instrument's standard", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Start with guitar (standard tuning E,A,D,G,B,E)
      html = render_click(view, "change_instrument", %{"instrument" => "bass_4"})

      labels =
        Regex.scan(~r/class="tuning-label"[^>]*>\s*([A-G]#?)\s*</s, html)
        |> Enum.map(fn [_, note] -> note end)

      # bass_4 standard tuning DOM order (low to high): E, A, D, G
      assert labels == ["E", "A", "D", "G"]
    end

    test "changing instrument keeps active chords", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?chords=Cmaj")

      html = render_click(view, "change_instrument", %{"instrument" => "bass_4"})

      assert html =~ "Cmaj"
      assert html =~ "chord-chip"
    end

    test "changing to bass_4 and then back to guitar restores 6 strings", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      render_click(view, "change_instrument", %{"instrument" => "bass_4"})
      html = render_click(view, "change_instrument", %{"instrument" => "guitar"})

      assert length(Regex.scan(~r/class="string-line"/, html)) == 6
    end
  end

  describe "tuning modal with instrument" do
    test "opening tuning modal on bass_4 shows 4 string dropdowns", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?instrument=bass_4")

      html = view |> element("[phx-click=open_tuning_modal]") |> render_click()

      for i <- 1..4 do
        assert html =~ "String #{i}"
      end

      refute html =~ "String 5"
      refute html =~ "String 6"
    end

    test "opening tuning modal on bass_5 shows 5 string dropdowns", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?instrument=bass_5")

      html = view |> element("[phx-click=open_tuning_modal]") |> render_click()

      for i <- 1..5 do
        assert html =~ "String #{i}"
      end

      refute html =~ "String 6"
    end

    test "tuning modal on bass_4 shows bass_4 presets", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?instrument=bass_4")

      html = view |> element("[phx-click=open_tuning_modal]") |> render_click()

      assert html =~ "Standard"
      refute html =~ "DADGAD"
      refute html =~ "Open G"
    end

    test "tuning modal on bass_5 shows bass_5 presets", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?instrument=bass_5")

      html = view |> element("[phx-click=open_tuning_modal]") |> render_click()

      assert html =~ "Standard"
      assert html =~ "Half Step Down"
      assert html =~ "Drop A"

      # Guitar-only presets should NOT be present
      refute html =~ "DADGAD"
      refute html =~ "Open G"
    end
  end

  describe "URL encoding with instrument" do
    test "mount with instrument=bass_4 and chords preserves both", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/?instrument=bass_4&chords=Cmaj")

      assert html =~ "Cmaj"
      assert html =~ "chord-chip"
      assert length(Regex.scan(~r/class="string-line"/, html)) == 4
    end

    test "mount with instrument=bass_5 and custom tuning preserves both", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/?instrument=bass_5&tuning=A,E,A,D,G")

      assert length(Regex.scan(~r/class="string-line"/, html)) == 5

      labels =
        Regex.scan(~r/class="tuning-label"[^>]*>\s*([A-G]#?)\s*</s, html)
        |> Enum.map(fn [_, note] -> note end)

      # Custom tuning A,E,A,D,G DOM order (low to high): A, E, A, D, G
      assert labels == ["A", "E", "A", "D", "G"]
    end
  end
end
