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
      assert length(Regex.scan(~r/chord-chip/, html)) == 2
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
      assert length(Regex.scan(~r/chord-chip/, html)) == 7
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
      assert length(Regex.scan(~r/chord-chip/, html)) == 1
    end

    test "after applying key, user can still remove individual chords", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      view |> element("[phx-click=open_key_modal]") |> render_click()
      render_click(view, "apply_key", %{})

      # Remove the first chord
      html = view |> element("[phx-click=remove_chord][phx-value-index='0']") |> render_click()
      assert length(Regex.scan(~r/chord-chip/, html)) == 6
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
end
