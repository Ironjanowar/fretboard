defmodule FretboardWeb.EnglishInterfaceTest do
  use FretboardWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "document language and existing accessibility copy are English", %{conn: conn} do
    html = conn |> get("/") |> html_response(200)
    assert html =~ ~r/<html\s+lang="en"[\s>]/
    {:ok, view, _} = live(conn, "/")
    assert has_element?(view, ~s(button[aria-label="Toggle more controls"]), "More")
  end

  test "visualizer controls use English instrument labels with legacy URL values", %{conn: conn} do
    {:ok, view, _} = live(conn, "/?instrument=ukelele")
    assert has_element?(view, "#instrument-select option[value=ukelele][selected]", "Ukulele")
    assert has_element?(view, "button[phx-value-tab=visualizer]", "Visualizer")
    assert has_element?(view, "button[phx-value-tab=analyzer]", "Analyzer")
    assert has_element?(view, "#chord-form button", "Add")

    view |> element("button[phx-value-tab=analyzer]") |> render_click()
    path = assert_patch(view)
    assert URI.decode_query(URI.parse(path).query)["instrument"] == "ukelele"
    {:ok, reloaded, _} = live(build_conn(), path)
    assert has_element?(reloaded, "#instrument-select option[value=ukelele][selected]", "Ukulele")
  end

  test "compatible keys and expanded mode actions use English", %{conn: conn} do
    {:ok, view, _} = live(conn, "/?chords=Cmaj,Amin")
    render_async(view)
    assert has_element?(view, "#key-suggestions .section-label", "Compatible keys")
    assert has_element?(view, "#key-suggestions .key-card-arrow", "View key")
    assert has_element?(view, "button[phx-click=toggle_key_modes]", "additional modes")

    # Each modal group exposes the same global toggle event.
    render_click(view, "toggle_key_modes")
    assert has_element?(view, ".key-modes-expanded .key-card-arrow", "View key")
  end

  test "incompatible keys have an English explanation", %{conn: conn} do
    {:ok, view, _} = live(conn, "/?chords=Cmaj,F%23maj")
    render_async(view)
    assert has_element?(view, "#key-suggestions", "No compatible keys found for these chords.")
  end

  test "multi-key groups explain their results in English", %{conn: conn} do
    {:ok, view, _} = live(conn, "/?chords=Cmaj,Fmaj,Gmaj,F%23maj")

    render_async(view)
    assert has_element?(view, "#multi-key-suggestions")

    assert has_element?(
             view,
             "#multi-key-suggestions .section-label",
             ~r/No common key.*keys found/s
           )

    assert has_element?(view, ".multi-key-group-label", "Key 1")
    assert has_element?(view, ".multi-key-your-chords-label", "Your chords:")
  end

  test "analyzer instructions return in English after clearing notes", %{conn: conn} do
    {:ok, view, _} = live(conn, "/?tab=analyzer&marked=0-3")
    assert has_element?(view, ".analyzer-single-note", "Note: G")
    view |> element("button[phx-click=clear_notes]", "Clear notes") |> render_click()

    assert has_element?(
             view,
             ".analyzer-empty",
             "Click notes on the fretboard to identify a chord"
           )
  end

  test "analyzer interval prefix is English", %{conn: conn} do
    {:ok, view, _} = live(conn, "/?tab=analyzer&marked=0-0,1-0")
    assert has_element?(view, ".analyzer-interval", "Interval: E-A (Perfect 4th)")
  end

  test "unrecognized notes have an English explanation", %{conn: conn} do
    # Three adjacent pitch classes do not match a supported chord.
    {:ok, view, _} = live(conn, "/?tab=analyzer&marked=0-8,1-4,2-0")
    assert has_element?(view, ".analyzer-empty")
    refute has_element?(view, ".analysis-card")
    assert has_element?(view, ".analyzer-empty", "No chord found for these notes.")
  end

  test "tuning dialog keeps English labels when changing presets", %{conn: conn} do
    {:ok, view, _} = live(conn, "/")
    view |> element("button[phx-click=open_tuning_modal]") |> render_click()
    assert has_element?(view, "#tuning-modal h2", "Tuning")
    assert has_element?(view, "#tuning-modal label", "Preset")
    assert has_element?(view, "#tuning-modal label", "String 6")
    assert has_element?(view, "#tuning-modal option[value=Custom]", "Custom")

    view
    |> form("#tuning-modal form[phx-change=select_preset]", preset: "Drop D")
    |> render_change()

    assert has_element?(view, "#tuning-modal option[selected]", "Drop D")
    assert has_element?(view, "#tuning-modal button[phx-click=apply_tuning]", "Apply")

    view
    |> element("#tuning-modal button[phx-click=close_tuning_modal]", "Cancel")
    |> render_click()

    refute has_element?(view, "#tuning-modal")
  end

  test "key dialog uses English labels and preserves scale identifiers", %{conn: conn} do
    {:ok, view, _} = live(conn, "/")
    view |> element("button[phx-click=open_key_modal]") |> render_click()

    for label <- ["Tonic", "Scale", "Chords", "Diatonic Chords"] do
      assert has_element?(view, "#key-modal label", label)
    end

    assert has_element?(view, "#key-modal option[value=harmonic_minor]", "Harmonic Minor")

    view
    |> form("#key-form", key: %{tonic: "A", scale_type: "harmonic_minor", chord_mode: "triad"})
    |> render_change()

    assert has_element?(
             view,
             "#key-modal option[value=harmonic_minor][selected]",
             "Harmonic Minor"
           )

    assert has_element?(view, "#key-modal button[phx-click=close_key_modal]", "Cancel")
    view |> element("#key-modal button[phx-click=apply_key]", "Apply") |> render_click()
    refute has_element?(view, "#key-modal")
    assert has_element?(view, ".chord-chip-title", "Amin")
  end

  test "progression dialog uses English names and preserves progression identifiers", %{
    conn: conn
  } do
    {:ok, view, _} = live(conn, "/")
    view |> element("button[phx-click=open_progression_modal]") |> render_click()
    assert has_element?(view, "#progression-modal h2", "Chord Progressions")

    for label <- ["Progression", "Tonic", "Chords"] do
      assert has_element?(view, "#progression-modal label", label)
    end

    assert has_element?(
             view,
             "#progression-select option[value=andalusian_cadence]",
             "Flamenco: Andalusian Cadence"
           )

    view
    |> form("#progression-form", progression: %{id: "andalusian_cadence", tonic: "A"})
    |> render_change()

    assert has_element?(
             view,
             "#progression-select option[value=andalusian_cadence][selected]",
             "Flamenco: Andalusian Cadence"
           )

    assert has_element?(
             view,
             "#progression-modal button[phx-click=close_progression_modal]",
             "Cancel"
           )

    view
    |> element("#progression-modal button[phx-click=apply_progression]", "Apply")
    |> render_click()

    refute has_element?(view, "#progression-modal")
    assert has_element?(view, ".chord-chip-title", "Amin")
  end
end
