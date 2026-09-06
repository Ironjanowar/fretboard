defmodule FretboardWeb.PitchTuningLifecycleTest do
  use FretboardWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  @low_g "/?instrument=ukelele&pitches=55,60,64,69&reference=Low+G&chords=Cmaj,Amin&marked=0-0,1-0"

  test "all patch-producing chord and analyzer events retain exact tuning", %{conn: conn} do
    events = [
      {"add_chord", %{"chord" => %{"root" => "G", "quality" => "major"}}},
      {"remove_chord", %{"index" => "0"}},
      {"highlight_chord", %{"index" => "0"}},
      {"clear_all_chords", %{}},
      {"apply_key", %{}},
      {"apply_progression", %{}},
      {"apply_suggested_key", %{"tonic" => "C", "scale_type" => "major"}},
      {"toggle_tab", %{"tab" => "analyzer"}},
      {"toggle_note", %{"string" => "2", "fret" => "1"}},
      {"clear_notes", %{}}
    ]

    for {event, params} <- events do
      {:ok, view, _} = live(conn, @low_g)
      render_click(view, event, params)
      path = assert_patch(view)
      query = path |> URI.parse() |> Map.fetch!(:query) |> URI.decode_query()
      assert query["pitches"] == "55,60,64,69", event
      assert query["reference"] == "Low G", event
      {:ok, restored, _} = live(conn, path)
      render_click(restored, "open_tuning_modal")
      assert has_element?(restored, "option[value='Low G'][selected]"), event
    end
  end

  test "cancel discards both a preset selection and custom draft edits", %{conn: conn} do
    {:ok, view, _} = live(conn, @low_g)
    render_click(view, "open_tuning_modal")
    render_change(view, "select_preset", %{"preset" => "Baritone"})
    render_change(view, "change_string", %{"string" => "0", "note" => "E"})
    render_click(view, "close_tuning_modal")
    render_click(view, "open_tuning_modal")
    assert has_element?(view, "option[value='Low G'][selected]")
    assert has_element?(view, "#string-select-0 option[value='G'][selected]")
    render_click(view, "apply_tuning")

    assert assert_patch(view)
           |> URI.parse()
           |> Map.fetch!(:query)
           |> URI.decode_query()
           |> Map.fetch!("pitches") == "55,60,64,69"
  end

  test "switching instrument resets exact tuning and reference to its Standard", %{conn: conn} do
    {:ok, view, _} = live(conn, @low_g)
    render_change(view, "change_instrument", %{"instrument" => "bass_4"})
    query = assert_patch(view) |> URI.parse() |> Map.fetch!(:query) |> URI.decode_query()
    assert query["instrument"] == "bass_4"
    refute Map.has_key?(query, "pitches")
    refute Map.has_key?(query, "reference")
    refute Map.has_key?(query, "tuning")
    render_click(view, "open_tuning_modal")
    assert has_element?(view, "option[value='Standard'][selected]")
    assert has_element?(view, "#string-select-0 option[value='E'][selected]")
  end

  test "handle_params restores Standard and Low G distinctly despite identical note names", %{
    conn: conn
  } do
    {:ok, view, _} = live(conn, @low_g)
    render_patch(view, "/?instrument=ukelele")
    render_click(view, "open_tuning_modal")
    assert has_element?(view, "option[value='Standard'][selected]")
    render_patch(view, @low_g)
    assert has_element?(view, "option[value='Low G'][selected]")
  end
end
