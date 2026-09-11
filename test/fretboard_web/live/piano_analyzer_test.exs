defmodule FretboardWeb.PianoAnalyzerTest do
  use FretboardWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  @analyzer "/?instrument=piano&tab=analyzer"
  @first_pitch 48
  @last_pitch 83

  describe "URL-rendered analysis" do
    test "an empty selection renders the interactive keyboard and piano instruction", %{
      conn: conn
    } do
      {:ok, view, _html} = live(conn, @analyzer)

      assert has_element?(view, "#piano-analyzer[role=group][aria-label]")
      refute has_element?(view, "#piano-analyzer-pending")
      assert has_element?(view, ".analyzer-empty", "Click keys on the piano to identify a chord")
      refute has_element?(view, "button[phx-click=clear_notes]")
      refute has_element?(view, "#analyzer-fretboard")
    end

    test "one selected pitch renders its key and single-note result", %{conn: conn} do
      {:ok, view, _html} = live(conn, @analyzer <> "&keys=61")

      assert_selected(view, 61, "C#4")
      assert has_element?(view, ".analyzer-single-note", "Note: C#")
    end

    test "two pitch classes render the existing interval result", %{conn: conn} do
      {:ok, view, _html} = live(conn, @analyzer <> "&keys=60,64")

      assert has_element?(view, ".analyzer-interval", "Interval: C-E (Major 3rd)")
    end

    test "the same pitch class in distinct octaves renders an octave", %{conn: conn} do
      {:ok, view, _html} = live(conn, @analyzer <> "&keys=60,72")

      assert_selected(view, 60, "C4")
      assert_selected(view, 72, "C5")
      assert has_element?(view, ".analyzer-interval", "Interval: C-C (Octave)")
    end

    test "a root-position triad renders the shared chord card", %{conn: conn} do
      {:ok, view, _html} = live(conn, @analyzer <> "&keys=60,64,67")

      assert has_element?(view, "[id^=analyzer-results-] .analysis-card-title", "Cmaj")
      assert has_element?(view, ".analysis-card-badge", "exact")
      assert has_element?(view, ".analysis-card-bass", "Bass: C")
      assert has_element?(view, ".analysis-card-inversion", "Root position")
    end

    test "the lowest selected pitch determines chord inversion", %{conn: conn} do
      {:ok, view, _html} = live(conn, @analyzer <> "&keys=64,67,72")

      assert has_element?(view, ".analysis-card-title", "Cmaj/E")
      assert has_element?(view, ".analysis-card-bass", "Bass: E")
      assert has_element?(view, ".analysis-card-inversion", "1st inversion")
    end
  end

  describe "absolute-pitch interaction" do
    test "clicking a white key toggles that exact pitch on", %{conn: conn} do
      {:ok, view, _html} = live(conn, @analyzer)

      view |> element(key_selector(60)) |> render_click()

      assert patch_query(view) == %{
               "instrument" => "piano",
               "tab" => "analyzer",
               "keys" => "60"
             }

      assert_selected(view, 60, "C4")
      assert has_element?(view, ".analyzer-single-note", "Note: C")
    end

    test "clicking a selected key deselects only that pitch", %{conn: conn} do
      {:ok, view, _html} = live(conn, @analyzer <> "&keys=60,64")

      view |> element(key_selector(60)) |> render_click()

      assert patch_query(view) == %{
               "instrument" => "piano",
               "tab" => "analyzer",
               "keys" => "64"
             }

      assert_unselected(view, 60, "C4")
      assert_selected(view, 64, "E4")
    end

    test "black, white, and duplicate pitch classes across octaves toggle independently", %{
      conn: conn
    } do
      {:ok, view, _html} = live(conn, @analyzer)

      view |> element(key_selector(60)) |> render_click()
      assert patch_query(view)["keys"] == "60"
      view |> element(key_selector(61)) |> render_click()
      assert_patch(view)
      view |> element(key_selector(72)) |> render_click()

      assert patch_query(view)["keys"] == "60,61,72"
      assert_selected(view, 60, "C4")
      assert_selected(view, 61, "C#4")
      assert_selected(view, 72, "C5")
    end

    test "clear notes removes every selected piano key", %{conn: conn} do
      {:ok, view, _html} = live(conn, @analyzer <> "&keys=49,60,72")

      view |> element("button[phx-click=clear_notes]", "Clear notes") |> render_click()

      assert patch_query(view) == %{"instrument" => "piano", "tab" => "analyzer"}
      refute has_element?(view, ".piano-key--selected")
      refute has_element?(view, "button[phx-click=clear_notes]")
      assert has_element?(view, ".analyzer-empty", "Click keys on the piano to identify a chord")
    end

    test "selection changes preserve chords and highlight", %{conn: conn} do
      path = @analyzer <> "&chords=Cmaj,Amin&highlight=Amin"
      {:ok, view, _html} = live(conn, path)

      view |> element(key_selector(61)) |> render_click()

      assert patch_query(view) == %{
               "instrument" => "piano",
               "tab" => "analyzer",
               "keys" => "61",
               "chords" => "Cmaj,Amin",
               "highlight" => "Amin"
             }
    end
  end

  describe "event validation" do
    test "malformed, non-string, missing, and out-of-range pitches are ignored", %{conn: conn} do
      invalid_payloads = [
        %{},
        %{"pitch" => nil},
        %{"pitch" => ""},
        %{"pitch" => "60junk"},
        %{"pitch" => "60.0"},
        %{"pitch" => "47"},
        %{"pitch" => "84"},
        %{"pitch" => []},
        %{"pitch" => ["60"]},
        %{"pitch" => %{}},
        %{"pitch" => 60}
      ]

      for payload <- invalid_payloads do
        {:ok, view, _html} = live(conn, @analyzer <> "&keys=64")
        render_click(view, "toggle_piano_key", payload)

        refute_patch(view)
        assert_selected(view, 64, "E4")
        assert_unselected(view, 60, "C4")
      end
    end

    test "piano key events are ignored outside the piano analyzer", %{conn: conn} do
      for path <- ["/?tab=analyzer&marked=0-3", "/?instrument=piano&keys=60&chords=Cmaj"] do
        {:ok, view, _html} = live(conn, path)
        render_click(view, "toggle_piano_key", %{"pitch" => "64"})

        refute_patch(view)
      end
    end

    test "fretted note events are ignored on piano without changing key selection", %{conn: conn} do
      {:ok, view, _html} = live(conn, @analyzer <> "&keys=60")
      render_click(view, "toggle_note", %{"string" => "0", "fret" => "3"})

      refute_patch(view)
      assert_selected(view, 60, "C4")
    end
  end

  describe "accessible keyboard contract" do
    test "all C3-B5 keys are named focusable buttons and only selections are marked", %{
      conn: conn
    } do
      {:ok, view, _html} = live(conn, @analyzer <> "&keys=48,61,83")
      html = analyzer_html(view)

      assert length(Regex.scan(~r/data-pitch="(?:[4-7][0-9]|8[0-3])"/, html)) == 36
      assert length(Regex.scan(~r/role="button"/, html)) == 36
      assert length(Regex.scan(~r/tabindex="0"/, html)) == 36
      assert length(Regex.scan(~r/aria-label="[A-G](?:#)?[3-5]"/, html)) == 36
      assert length(Regex.scan(~r/aria-pressed="(?:true|false)"/, html)) == 36

      assert_selected(view, @first_pitch, "C3")
      assert_selected(view, 61, "C#4")
      assert_selected(view, @last_pitch, "B5")
      refute has_element?(view, "#piano-analyzer[role=img]")
      assert count_class(html, "piano-key--selected") == 3
      assert count_class(html, "piano-key-marker") == 3
      assert count_class(html, "piano-note-label") == 3
      refute has_element?(view, "#{key_selector(60)} .piano-note-label")
    end

    test "Enter and Space activate once while unsupported keys do not mutate", %{conn: conn} do
      for key <- ["Enter", " "] do
        {:ok, view, _html} = live(conn, @analyzer)
        view |> element(key_selector(60)) |> render_keydown(%{"key" => key})
        assert patch_query(view)["keys"] == "60"
        assert_selected(view, 60, "C4")
      end

      {:ok, view, _html} = live(conn, @analyzer <> "&keys=60")
      view |> element(key_selector(60)) |> render_keydown(%{"key" => "ArrowRight"})
      refute_patch(view)
      assert_selected(view, 60, "C4")
    end
  end

  defp assert_selected(view, pitch, label) do
    assert has_element?(
             view,
             "#piano-analyzer [data-pitch='#{pitch}'].piano-key--selected" <>
               "[role=button][tabindex='0'][aria-label='#{label}'][aria-pressed='true']"
           )
  end

  defp assert_unselected(view, pitch, label) do
    assert has_element?(
             view,
             "#piano-analyzer [data-pitch='#{pitch}']:not(.piano-key--selected)" <>
               "[role=button][tabindex='0'][aria-label='#{label}'][aria-pressed='false']"
           )
  end

  defp key_selector(pitch), do: "#piano-analyzer [data-pitch='#{pitch}']"

  defp analyzer_html(view) do
    assert has_element?(view, "#piano-analyzer")
    view |> element("#piano-analyzer") |> render()
  end

  defp patch_query(view) do
    view |> assert_patch() |> URI.parse() |> Map.get(:query) |> decode_query()
  end

  defp decode_query(nil), do: %{}
  defp decode_query(query), do: URI.decode_query(query)

  defp refute_patch(view) do
    assert_raise ArgumentError, ~r/but got none/, fn -> assert_patch(view, 0) end
  end

  defp count_class(html, class_name) do
    html
    |> then(&Regex.scan(~r/class="([^"]*)"/, &1, capture: :all_but_first))
    |> Enum.count(fn [classes] -> class_name in String.split(classes) end)
  end
end
