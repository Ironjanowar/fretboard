defmodule FretboardWeb.DuplicateChordsLiveTest do
  use FretboardWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  @first_chord_color "#4FC3F7"
  @second_chord_color "#FF8A65"

  describe "duplicate chords loaded from the URL" do
    test "preserves every occurrence while identity remains root plus quality", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?chords=C6,Amin7,C6")

      assert has_element?(view, chord_chip(0), "C6")
      assert has_element?(view, chord_chip(1), "Amin7")
      assert has_element?(view, chord_chip(2), "C6")
      assert chord_chip_count(view) == 3
    end

    test "assigns colors by unique chord in first-appearance order", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?chords=Cmaj,Cmaj,Amin")

      assert has_element?(view, colored_chord_chip(0, @first_chord_color))
      assert has_element?(view, colored_chord_chip(1, @first_chord_color))
      assert has_element?(view, colored_chord_chip(2, @second_chord_color))
    end

    test "renders duplicate chord notes with their shared chord color rather than overlap gray",
         %{
           conn: conn
         } do
      {:ok, view, _html} = live(conn, "/?chords=Cmaj,Cmaj")

      assert has_element?(view, ~s(.note-circle[fill="#{@first_chord_color}"]))
      refute has_element?(view, ~s(.note-circle[fill="#9E9E9E"]))
    end

    test "restores a highlighted duplicate group from the URL", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?chords=Cmaj,Cmaj,Amin&highlight=Cmaj")

      assert has_element?(view, highlighted_chord_chip(0), "Cmaj")
      assert has_element?(view, highlighted_chord_chip(1), "Cmaj")
      refute has_element?(view, highlighted_chord_chip(2))
      assert highlighted_chord_chip_count(view) == 2
    end
  end

  describe "duplicate chord highlighting" do
    test "clicking any copy highlights every exact copy but not a chord with the same pitches", %{
      conn: conn
    } do
      {:ok, view, _html} = live(conn, "/?chords=C6,Amin7,C6")

      view |> element(chord_chip(2)) |> render_click()

      assert has_element?(view, highlighted_chord_chip(0), "C6")
      refute has_element?(view, highlighted_chord_chip(1))
      assert has_element?(view, highlighted_chord_chip(2), "C6")
      assert highlighted_chord_chip_count(view) == 2
    end

    test "clicking either copy of the highlighted chord again clears the whole group", %{
      conn: conn
    } do
      {:ok, view, _html} = live(conn, "/?chords=Cmaj,Cmaj,Amin")

      view |> element(chord_chip(1)) |> render_click()
      view |> element(chord_chip(0)) |> render_click()

      assert highlighted_chord_chip_count(view) == 0
    end
  end

  describe "removing highlighted duplicate chords" do
    test "keeps the chord highlighted when another exact copy remains", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?chords=Cmaj,Cmaj,Amin")

      view |> element(chord_chip(0)) |> render_click()
      view |> element(remove_chord_button(0)) |> render_click()

      assert chord_chip_count(view) == 2
      assert has_element?(view, highlighted_chord_chip(0), "Cmaj")
      refute has_element?(view, highlighted_chord_chip(1), "Amin")
    end

    test "clears the highlight when the last copy is removed", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?chords=Cmaj&highlight=Cmaj")

      view |> element(remove_chord_button(0)) |> render_click()

      assert chord_chip_count(view) == 0
      assert highlighted_chord_chip_count(view) == 0
    end
  end

  describe "manual chord form" do
    test "still prevents adding an exact duplicate", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      add_chord(view, "C", "maj6")
      add_chord(view, "C", "maj6")

      assert chord_chip_count(view) == 1
      assert has_element?(view, chord_chip(0), "C6")
    end

    test "allows chords with the same pitches when root or quality differs", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      add_chord(view, "C", "maj6")
      add_chord(view, "A", "min7")

      assert chord_chip_count(view) == 2
      assert has_element?(view, chord_chip(0), "C6")
      assert has_element?(view, chord_chip(1), "Amin7")
    end
  end

  defp add_chord(view, root, quality) do
    view
    |> form("#chord-form", %{chord: %{root: root, quality: quality}})
    |> render_submit()
  end

  defp chord_chip(index),
    do: ~s(.chord-chip[phx-click="highlight_chord"][phx-value-index="#{index}"])

  defp colored_chord_chip(index, color),
    do: chord_chip(index) <> ~s([style="background-color: #{color}"])

  defp highlighted_chord_chip(index),
    do: chord_chip(index) <> ".chord-chip--highlighted"

  defp remove_chord_button(index),
    do: ~s(.chord-chip-remove[phx-click="remove_chord"][phx-value-index="#{index}"])

  defp chord_chip_count(view), do: view |> render() |> count_class("chord-chip")

  defp highlighted_chord_chip_count(view),
    do: view |> render() |> count_class("chord-chip--highlighted")

  defp count_class(html, class_name) do
    html
    |> then(&Regex.scan(~r/class="([^"]*)"/, &1, capture: :all_but_first))
    |> Enum.count(fn [classes] -> class_name in String.split(classes) end)
  end
end
