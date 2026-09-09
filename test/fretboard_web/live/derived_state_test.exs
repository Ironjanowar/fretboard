defmodule FretboardWeb.DerivedStateTest do
  use FretboardWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Fretboard.Music
  alias FretboardWeb.{FretboardLive, Modals}

  # Call counters measure real domain work, not timings or copied assign values.
  # Synchronous tests keep these VM-wide counters isolated from other tests.
  setup do
    functions = [
      fretboard_data: 2,
      analyzer_state: 2,
      suggest_keys: 1,
      tuning_notes: 1,
      detect_preset: 2
    ]

    Code.ensure_loaded!(Music)

    for {name, arity} <- functions do
      :erlang.trace_pattern({Music, name, arity}, true, [:call_count])
    end

    on_exit(fn ->
      for {name, arity} <- functions do
        :erlang.trace_pattern({Music, name, arity}, false, [:call_count])
      end
    end)

    :ok
  end

  test "handle_params alone initializes and invalidates derived data by its inputs" do
    params = %{
      "instrument" => "ukelele",
      "chords" => "Cmaj,Amin",
      "tab" => "analyzer",
      "marked" => "0-0,1-0"
    }

    socket = %Phoenix.LiveView.Socket{assigns: %{__changed__: %{}}}
    {:ok, socket} = FretboardLive.mount(params, %{}, socket)
    assert calls(:fretboard_data, 2) == 0
    assert calls(:analyzer_state, 2) == 0

    {:noreply, socket} = FretboardLive.handle_params(params, "/", socket)
    assert calls(:fretboard_data, 2) == 1
    assert calls(:analyzer_state, 2) == 1
    assert socket.assigns.analysis == {:interval, "C", "G", "Perfect 5th"}

    {:noreply, socket} =
      FretboardLive.handle_params(Map.put(params, "highlight", "Amin"), "/", socket)

    assert socket.assigns.highlighted_chord == 1
    assert calls(:fretboard_data, 2) == 1
    assert calls(:analyzer_state, 2) == 1

    params = Map.put(params, "pitches", "55,60,64,69")
    {:noreply, socket} = FretboardLive.handle_params(params, "/", socket)
    assert socket.assigns.analysis == {:interval, "G", "C", "Perfect 4th"}
    assert calls(:fretboard_data, 2) == 1
    assert calls(:analyzer_state, 2) == 2

    params = Map.put(params, "marked", "0-0,1-2")
    {:noreply, socket} = FretboardLive.handle_params(params, "/", socket)
    assert socket.assigns.analysis == {:interval, "G", "D", "Perfect 5th"}
    assert calls(:fretboard_data, 2) == 1
    assert calls(:analyzer_state, 2) == 3

    {:noreply, socket} =
      FretboardLive.handle_params(Map.put(params, "chords", "Dmaj"), "/", socket)

    assert socket.assigns.active_chords == [%{root: "D", quality: :major}]
    assert calls(:fretboard_data, 2) == 2
    assert calls(:analyzer_state, 2) == 3
  end

  test "hidden tuning modal does not derive names or preset" do
    assigns = %{
      show: false,
      instrument: :ukelele,
      string_count: 4,
      modal_tuning_state: Music.preset_tuning(:ukelele, "Low G")
    }

    refute render_component(&Modals.tuning_modal/1, assigns) =~ "tuning-modal"
    assert calls(:tuning_notes, 1) == 0
    assert calls(:detect_preset, 2) == 0

    assert render_component(&Modals.tuning_modal/1, %{assigns | show: true}) =~ "Low G"
    assert calls(:tuning_notes, 1) == 1
    assert calls(:detect_preset, 2) == 1
  end

  test "initial async suggestions survive unrelated patches and tabs and refresh on chords", %{
    conn: conn
  } do
    {:ok, view, _} = live(conn, "/?chords=Cmaj,Amin")
    assert render_async(view) =~ "View key"
    assert calls(:suggest_keys, 1) == 1

    render_click(view, "highlight_chord", %{"index" => "0"})
    render_click(view, "toggle_tab", %{"tab" => "analyzer"})
    render_click(view, "toggle_note", %{"string" => "0", "fret" => "0"})
    assert render_async(view) =~ "analyzer-results"
    render_click(view, "toggle_tab", %{"tab" => "visualizer"})
    assert render_async(view) =~ "View key"
    assert calls(:suggest_keys, 1) == 1

    render_click(view, "add_chord", %{"chord" => %{"root" => "G", "quality" => "major"}})
    assert render_async(view) =~ "View key"
    assert calls(:suggest_keys, 1) == 2
    render_click(view, "clear_all_chords")
    refute render_async(view) =~ "key-suggestions-wrapper"
  end

  test "initial URL analysis and async results reach the UI across immediate tab patches", %{
    conn: conn
  } do
    {:ok, view, html} =
      live(conn, "/?instrument=ukelele&tab=analyzer&marked=0-0,1-0&chords=Cmaj,Amin")

    assert html =~ "Perfect 5th"

    # Do not await the initial task before navigating: its result must still
    # arrive whether it completes before or after these unrelated patches.
    render_click(view, "toggle_tab", %{"tab" => "visualizer"})
    assert render_async(view) =~ "View key"
    assert calls(:suggest_keys, 1) == 1
    render_click(view, "toggle_tab", %{"tab" => "analyzer"})
    assert render(view) =~ "Perfect 5th"
  end

  test "default connected load resolves empty async suggestions", %{conn: conn} do
    {:ok, view, html} = live(conn, "/")
    assert html =~ "fretboard"
    refute render_async(view) =~ "key-suggestions-wrapper"
    assert calls(:suggest_keys, 1) == 0
  end

  defp calls(name, arity) do
    {:call_count, count} = :erlang.trace_info({Music, name, arity}, :call_count)
    count
  end
end
