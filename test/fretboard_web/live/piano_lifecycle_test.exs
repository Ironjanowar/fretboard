defmodule FretboardWeb.PianoLifecycleTest do
  use FretboardWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  @piano_analyzer "/?instrument=piano&tab=analyzer"

  describe "URL-backed piano lifecycle" do
    test "switching analyzer to visualizer and back retains exact selected pitches", %{conn: conn} do
      {:ok, view, _html} = live(conn, @piano_analyzer <> "&keys=49,60,72")

      view |> element("[phx-click=toggle_tab][phx-value-tab=visualizer]") |> render_click()
      assert patch_query(view)["keys"] == "49,60,72"
      assert has_element?(view, "#piano-keyboard")
      refute has_element?(view, "#piano-analyzer")

      view |> element("[phx-click=toggle_tab][phx-value-tab=analyzer]") |> render_click()
      assert patch_query(view)["keys"] == "49,60,72"

      for pitch <- [49, 60, 72] do
        assert has_element?(view, "#piano-analyzer [data-pitch='#{pitch}'][aria-pressed='true']")
      end
    end

    test "a shared URL restores instrument tab keys analysis chords and highlight", %{conn: conn} do
      path =
        @piano_analyzer <>
          "&keys=67,60,64,60,bad&chords=Cmaj,Amin&highlight=Amin"

      {:ok, view, _html} = live(conn, path)

      assert has_element?(view, "#instrument-select option[value=piano][selected]")
      assert has_element?(view, "[phx-value-tab=analyzer].tab-toggle-btn--active")
      assert has_element?(view, ".analysis-card-title", "Cmaj")
      assert has_element?(view, ".chord-chip--highlighted", "Amin")

      view |> element("#piano-analyzer [data-pitch='72']") |> render_click()
      canonical_path = assert_patch(view)

      assert URI.decode_query(URI.parse(canonical_path).query) == %{
               "instrument" => "piano",
               "tab" => "analyzer",
               "keys" => "60,64,67,72",
               "chords" => "Cmaj,Amin",
               "highlight" => "Amin"
             }

      {:ok, restored, _html} = live(build_conn(), canonical_path)
      assert has_element?(restored, "#piano-analyzer [data-pitch='72'][aria-pressed='true']")
      assert has_element?(restored, ".analysis-card-title", "Cmaj")
      assert has_element?(restored, ".chord-chip--highlighted", "Amin")
    end

    test "URL navigation recomputes selection and analysis without stale assigns", %{conn: conn} do
      {:ok, view, _html} = live(conn, @piano_analyzer <> "&keys=60")
      assert has_element?(view, ".analyzer-single-note", "Note: C")

      render_patch(view, @piano_analyzer <> "&keys=60,64,67")
      assert has_element?(view, ".analysis-card-title", "Cmaj")

      render_patch(view, @piano_analyzer <> "&keys=60")
      assert has_element?(view, ".analyzer-single-note", "Note: C")
      refute has_element?(view, ".analysis-card")
    end
  end

  describe "instrument boundaries" do
    test "piano to each fretted instrument clears keys and preserves chords", %{conn: conn} do
      for instrument <- ~w(guitar bass_4 bass_5 ukelele) do
        {:ok, view, _html} =
          live(conn, @piano_analyzer <> "&keys=60,64,67&chords=Cmaj&highlight=Cmaj")

        view |> form("#instrument-form", %{instrument: instrument}) |> render_change()
        query = patch_query(view)

        assert query["instrument"] == if(instrument == "guitar", do: nil, else: instrument)
        assert query["tab"] == "analyzer"
        assert query["chords"] == "Cmaj"
        refute Map.has_key?(query, "keys")
        refute Map.has_key?(query, "marked")
        refute has_element?(view, ".analysis-card")
        assert has_element?(view, ".analyzer-empty", "Click notes on the fretboard")
      end
    end

    test "fretted instruments to piano clear positions even while visualizer is active", %{
      conn: conn
    } do
      for instrument <- ~w(guitar bass_4 bass_5 ukelele) do
        prefix = if instrument == "guitar", do: "/?", else: "/?instrument=#{instrument}&"
        {:ok, view, _html} = live(conn, prefix <> "marked=0-3&chords=Cmaj")

        view |> form("#instrument-form", %{instrument: "piano"}) |> render_change()

        assert patch_query(view) == %{"instrument" => "piano", "chords" => "Cmaj"}
        refute has_element?(view, "#piano-keyboard .piano-key--selected")
      end
    end

    test "same-instrument change is a no-op and string-to-string behavior remains intact", %{
      conn: conn
    } do
      {:ok, piano, _html} = live(conn, @piano_analyzer <> "&keys=60")
      piano |> form("#instrument-form", %{instrument: "piano"}) |> render_change()
      refute_patch(piano)
      assert has_element?(piano, "#piano-analyzer [data-pitch='60'][aria-pressed='true']")

      {:ok, guitar, _html} = live(build_conn(), "/?tab=analyzer&marked=2-2,5-3")
      guitar |> form("#instrument-form", %{instrument: "ukelele"}) |> render_change()
      query = patch_query(guitar)
      assert query["instrument"] == "ukelele"
      assert query["marked"] == "2-2"
      assert query["tab"] == "analyzer"
    end
  end

  describe "state isolation" do
    test "clearing chords retains piano analyzer keys while clearing highlight", %{conn: conn} do
      {:ok, view, _html} =
        live(conn, @piano_analyzer <> "&keys=60,64,67&chords=Cmaj,Amin&highlight=Amin")

      view |> element("[phx-click=toggle_tab][phx-value-tab=visualizer]") |> render_click()
      assert_patch(view)
      view |> element("button[phx-click=clear_all_chords]") |> render_click()

      assert patch_query(view) == %{
               "instrument" => "piano",
               "keys" => "60,64,67"
             }

      view |> element("[phx-click=toggle_tab][phx-value-tab=analyzer]") |> render_click()
      assert_patch(view)
      assert has_element?(view, ".analysis-card-title", "Cmaj")
      refute has_element?(view, ".chord-chip")
    end

    test "visualizer remains static and chord-based when the URL also carries keys", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?instrument=piano&keys=61&chords=Cmaj")

      assert has_element?(view, "#piano-keyboard[role=img]")
      refute has_element?(view, "#piano-analyzer")
      refute has_element?(view, "#piano-keyboard [phx-click=toggle_piano_key]")
      refute has_element?(view, "#piano-keyboard [aria-pressed]")
      refute has_element?(view, "#piano-keyboard [data-pitch='61'] .piano-key-marker")
      assert has_element?(view, "#piano-keyboard [data-pitch='60'] .piano-key-marker")
    end

    test "tuning events stay harmless and an open modal cannot cross into piano", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?tab=analyzer&marked=0-3")
      view |> element("button[phx-click=open_tuning_modal]") |> render_click()
      assert has_element?(view, "#tuning-modal")

      view |> form("#instrument-form", %{instrument: "piano"}) |> render_change()
      assert_patch(view)
      refute has_element?(view, "#tuning-modal")

      render_click(view, "open_tuning_modal")
      render_click(view, "select_preset", %{"preset" => "Standard"})
      render_click(view, "change_string", %{"string" => "0", "note" => "E"})
      render_click(view, "apply_tuning", %{})

      refute_patch(view)
      assert has_element?(view, "#piano-analyzer")
      refute has_element?(view, "button[phx-click=open_tuning_modal]")
    end
  end

  defp patch_query(view) do
    view |> assert_patch() |> URI.parse() |> Map.get(:query) |> decode_query()
  end

  defp decode_query(nil), do: %{}
  defp decode_query(query), do: URI.decode_query(query)

  defp refute_patch(view) do
    assert_raise ArgumentError, ~r/but got none/, fn -> assert_patch(view, 0) end
  end
end
