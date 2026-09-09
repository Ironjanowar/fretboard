defmodule FretboardWeb.PitchTuningTest do
  use FretboardWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "preset pitches survive applying and sharing the URL" do
    test "Low G is selectable without renaming Standard and remains the open-string bass after reload",
         %{conn: conn} do
      {:ok, view, _} = live(conn, "/?instrument=ukelele&tab=analyzer&marked=0-0,1-0,2-0,3-0")
      assert_bass(view, "C")
      open_tuning(view)
      assert has_element?(view, "#tuning-modal option[value='Standard']")
      select_preset(view, "Low G")
      path = apply_tuning(view)
      assert_bass(view, "G")

      {:ok, reloaded, _} = live(conn, path)
      assert_bass(reloaded, "G")
      open_tuning(reloaded)
      assert has_element?(reloaded, "#tuning-modal option[value='Low G'][selected]")
    end

    test "Baritone uses D3 G3 B3 E4 rather than nearest standard pitches", %{conn: conn} do
      {:ok, view, _} = live(conn, "/?instrument=ukelele&tab=analyzer&marked=0-0,1-0,2-0")
      open_tuning(view)
      select_preset(view, "Baritone")
      path = apply_tuning(view)
      assert_bass(view, "D")
      refute has_element?(view, ".analysis-card-bass", "Bass: G")

      {:ok, reloaded, _} = live(conn, path)
      assert_bass(reloaded, "D")
      refute has_element?(reloaded, ".analysis-card-bass", "Bass: G")
    end
  end

  test "Drop D keeps its fixed reference through custom edits, reload and reopening", %{
    conn: conn
  } do
    {:ok, view, _} = live(conn, "/?tab=analyzer&marked=0-12,1-0")
    open_tuning(view)
    select_preset(view, "Drop D")

    # Against the fixed D2 reference (38), G# resolves to 32, not 44.
    # Passing through E must not replace the preset reference with E2 (40).
    change_string(view, 0, "E")
    change_string(view, 0, "G#")
    path = apply_tuning(view)
    assert_drop_d_interval(view)

    {:ok, reloaded, _} = live(conn, path)
    assert_drop_d_interval(reloaded)
    open_tuning(reloaded)
    change_string(reloaded, 0, "E")
    change_string(reloaded, 0, "G#")
    final_path = apply_tuning(reloaded)
    assert_drop_d_interval(reloaded)

    {:ok, final, _} = live(conn, final_path)
    assert_drop_d_interval(final)
  end

  test "tab patches and adding a chord retain Low G pitches and its editing reference", %{
    conn: conn
  } do
    {:ok, view, _} = live(conn, "/?instrument=ukelele&tab=analyzer&marked=0-0,1-0,2-0,3-0")
    open_tuning(view)
    select_preset(view, "Low G")
    apply_tuning(view)

    view |> element("[phx-click=toggle_tab][phx-value-tab=visualizer]") |> render_click()
    visualizer_path = assert_patch(view)
    assert query(visualizer_path)["marked"] == "0-0,1-0,2-0,3-0"

    view |> form("#chord-form", %{chord: %{root: "C", quality: "major"}}) |> render_submit()
    chord_path = assert_patch(view)
    assert query(chord_path)["chords"] =~ "Cmaj"

    view |> element("[phx-click=toggle_tab][phx-value-tab=analyzer]") |> render_click()
    path = assert_patch(view)
    assert query(path)["tab"] == "analyzer"
    assert_bass(view, "G")
    {:ok, reloaded, _} = live(conn, path)
    assert_bass(reloaded, "G")

    # Distinguish the retained G3 reference from Standard's G4 reference:
    # A#3-C4 is a Major 2nd; C4-A#4 would be a Minor 7th.
    reloaded |> element("[phx-click=clear_notes]") |> render_click()
    assert_patch(reloaded)
    mark(reloaded, 0, 0)
    mark(reloaded, 1, 0)
    open_tuning(reloaded)
    change_string(reloaded, 0, "A#")
    final_path = apply_tuning(reloaded)
    assert has_element?(reloaded, ".analyzer-interval", "Interval: A#-C (Major 2nd)")
    {:ok, final, _} = live(conn, final_path)
    assert has_element?(final, ".analyzer-interval", "Interval: A#-C (Major 2nd)")
  end

  describe "legacy note-only links" do
    test "explicit G C E A retains the compatible standard high-G reference", %{conn: conn} do
      {:ok, view, _} =
        live(conn, "/?instrument=ukelele&tuning=G,C,E,A&tab=analyzer&marked=0-0,1-0,2-0,3-0")

      assert_bass(view, "C")
      refute has_element?(view, ".analysis-card-bass", "Bass: G")
    end

    test "custom note-only guitar tuning resolves against Standard", %{conn: conn} do
      path =
        "/?" <>
          URI.encode_query(%{
            "tuning" => "G#,A,D,G,B,E",
            "tab" => "analyzer",
            "marked" => "0-12,1-0"
          })

      {:ok, view, _} = live(conn, path)
      assert has_element?(view, ".analyzer-interval", "Interval: A-G# (Major 7th)")
    end
  end

  describe "three selected pitches with octave doubling" do
    test "C3 G3 C4 retains the Perfect 5th interval", %{conn: conn} do
      {:ok, view, _} = live(conn, "/?tab=analyzer&marked=1-3,3-0,4-1")
      assert has_element?(view, ".analyzer-interval", "Interval: C-G (Perfect 5th)")
      refute render(view) =~ "No chord found"
    end

    test "C3 C4 C5 reports Octave rather than no chord found", %{conn: conn} do
      {:ok, view, _} = live(conn, "/?tab=analyzer&marked=1-3,4-1,5-8")
      assert has_element?(view, ".analyzer-interval", "Interval: C-C (Octave)")
      refute render(view) =~ "No chord found"
      refute has_element?(view, ".analyzer-single-note")
    end
  end

  defp open_tuning(view) do
    view |> element("[phx-click=open_tuning_modal]") |> render_click()
  end

  defp select_preset(view, name) do
    assert has_element?(view, "#tuning-modal option[value='#{name}']"),
           "expected selectable tuning preset #{inspect(name)}"

    view
    |> form("#tuning-modal form[phx-change=select_preset]", %{preset: name})
    |> render_change()
  end

  defp change_string(view, index, note) do
    view |> form("#string-form-#{index}", %{note: note}) |> render_change()
    assert has_element?(view, "#string-select-#{index} option[value='#{note}'][selected]")
  end

  defp apply_tuning(view) do
    view |> element("#tuning-modal [phx-click=apply_tuning]") |> render_click()
    refute has_element?(view, "#tuning-modal")
    path = assert_patch(view)
    assert is_map(query(path))
    path
  end

  defp query(path), do: path |> URI.parse() |> Map.fetch!(:query) |> URI.decode_query()

  defp assert_bass(view, note) do
    assert has_element?(view, ".analysis-card-bass", "Bass: #{note}"),
           "expected Bass: #{note}; rendered bass labels: #{Regex.scan(~r/Bass:\s*[A-G]#?/, String.replace(render(view), ~r/<[^>]*>/, " ")) |> inspect()}"
  end

  defp assert_drop_d_interval(view) do
    assert has_element?(view, ".analyzer-interval", "Interval: G#-A (Minor 2nd)"),
           "expected G#44 below A45 using fixed Drop D reference; rendered interval: #{view |> element(".analyzer-interval") |> render()}"

    refute has_element?(view, ".analyzer-interval", "Major 7th")
  end

  defp mark(view, string, fret) do
    view
    |> element("[phx-click=toggle_note][phx-value-string='#{string}'][phx-value-fret='#{fret}']")
    |> render_click()

    assert_patch(view)
  end
end
