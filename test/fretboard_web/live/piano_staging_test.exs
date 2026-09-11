defmodule FretboardWeb.PianoStagingTest do
  use FretboardWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "phase-one selectors offer only fretted instruments in both tabs", %{conn: conn} do
    for path <- ["/", "/?tab=analyzer"] do
      {:ok, view, _html} = live(conn, path)

      refute has_element?(view, "#instrument-select option[value=piano]")

      for {value, index} <- Enum.with_index(~w(guitar bass_4 bass_5 ukelele), 1) do
        assert has_element?(view, "#instrument-select option:nth-child(#{index})[value=#{value}]")
      end

      refute has_element?(view, "#instrument-select option:nth-child(5)")
    end
  end
end
