defmodule FretboardWeb.PianoStagingTest do
  # Interim phase-2 staging contract: the instrument selector now EXPOSES
  # Piano. Phase 1 asserted only fretted instruments were offered; the
  # visualizer slice flips that contract - Piano must be selectable in
  # display order directly after ukelele.
  use FretboardWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  @expected_instruments ~w(guitar bass_4 bass_5 ukelele piano)

  test "phase-two selectors offer Piano after ukelele in both tabs", %{conn: conn} do
    for path <- ["/", "/?tab=analyzer"] do
      {:ok, view, _html} = live(conn, path)

      assert has_element?(view, "#instrument-select option[value=piano]", "Piano")

      for {value, index} <- Enum.with_index(@expected_instruments, 1) do
        assert has_element?(view, "#instrument-select option:nth-child(#{index})[value=#{value}]")
      end

      # Piano is the last option; nothing is offered beyond it.
      refute has_element?(view, "#instrument-select option:nth-child(6)")
    end
  end
end
