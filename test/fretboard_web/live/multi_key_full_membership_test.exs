defmodule FretboardWeb.MultiKeyFullMembershipLiveTest do
  @moduledoc """
  LiveView regression tests for full membership in the multi-key section.

  Every key card's "Your chords:" area must list every user chord whose
  notes fit that key — a chord that fits several suggested keys appears in
  each of those keys' cards, not only in the first one selected.
  """

  use FretboardWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "multi-key section full membership" do
    test "Dmin and Fmaj chips render in both key cards' Your chords areas", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?chords=Dmin,Gmaj,Emaj,Fmaj")
      render_async(view)

      assert has_element?(view, "#multi-key-suggestions")

      html = render(view)
      normalized = String.replace(html, ~r/\s+/, " ")

      # The two suggested keys are C Major and A Harmonic Minor.
      assert String.contains?(normalized, "Major C")
      assert String.contains?(normalized, "Harmonic Minor A")

      groups = your_chords_groups(html)

      # Two tonal key cards, in suggestion order, each with a "Your chords:" area.
      assert Enum.map(groups, &elem(&1, 0)) == ["Key 1", "Key 2"]

      [{"Key 1", first_chips}, {"Key 2", second_chips}] = groups

      # Full membership: Dmin and Fmaj fit both suggested keys, so BOTH key
      # cards list them — not just the first group the greedy cover assigned
      # them to.
      assert first_chips == ["Dmin", "Gmaj", "Fmaj"]
      assert second_chips == ["Dmin", "Emaj", "Fmaj"]
    end
  end

  # Extracts each tonal key card's group label ("Key N") and the chip labels
  # in its "Your chords:" area, in render order. The unmatched-chords block
  # (class "multi-key-unmatched") uses different classes and is skipped.
  defp your_chords_groups(html) do
    html
    |> String.split(~r/class="multi-key-group"/)
    # Drop the page content before the first key card.
    |> Enum.drop(1)
    |> Enum.map(&group_summary/1)
  end

  defp group_summary(chunk) do
    with [_, label] <- Regex.run(~r/class="multi-key-group-label">\s*([^<]*?)\s*</, chunk),
         [_, area] <- Regex.run(~r/class="multi-key-your-chords"[^>]*>(.*?)<\/div>/s, chunk) do
      chips =
        Regex.scan(~r/class="key-card-chip"[^>]*>\s*([^<]*?)\s*<\/span>/, area)
        |> Enum.map(fn [_, chip] -> chip end)

      {label, chips}
    else
      _ ->
        flunk(
          "could not parse multi-key group markup from chunk: #{inspect(String.slice(chunk, 0, 300))}"
        )
    end
  end
end
