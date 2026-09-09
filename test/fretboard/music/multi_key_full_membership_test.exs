defmodule Fretboard.Music.MultiKeyFullMembershipTest do
  @moduledoc """
  Regression tests for full membership in Scale.suggest_multi_keys/1.

  Each multi-key group's `chords` list must include EVERY user chord whose
  note set fits that group's key — not only the chords the greedy set cover
  happened to assign exclusively to that group. The greedy selection itself
  (which keys are chosen, group order, max 3 groups) and the unmatched-chords
  computation are unchanged by this expectation.
  """

  use ExUnit.Case, async: true

  alias Fretboard.Music.Scale

  defp chord(root, quality), do: %{root: root, quality: quality}

  defp find_group(results, tonic, scale_type) do
    Enum.find(results, fn g ->
      g.key != nil and g.key.tonic == tonic and g.key.scale_type == scale_type
    end)
  end

  defp key_sequence(results) do
    results
    |> Enum.filter(&(&1.key != nil))
    |> Enum.map(&{&1.key.tonic, &1.key.scale_type})
  end

  describe "suggest_multi_keys/1 full membership" do
    test "Dmin, Gmaj, Emaj, Fmaj → C Major lists Dmin, Gmaj, Fmaj and A Harmonic Minor lists Dmin, Emaj, Fmaj" do
      results =
        Scale.suggest_multi_keys([
          chord("D", :minor),
          chord("G", :major),
          chord("E", :major),
          chord("F", :major)
        ])

      # No unmatched group: every chord fits at least one of the selected keys.
      assert Enum.filter(results, &(&1.key == nil)) == []

      # Same group order as the greedy selection: C Major first, A Harmonic Minor second.
      assert key_sequence(results) == [{"C", :major}, {"A", :harmonic_minor}]

      # C Major group: all three chords whose notes fit C major.
      c_group = find_group(results, "C", :major)

      assert c_group.chords == [
               chord("D", :minor),
               chord("G", :major),
               chord("F", :major)
             ]

      # A Harmonic Minor group: Dmin and Fmaj fit it too (A B C D E F G#),
      # so they must be listed alongside Emaj, not only in the C Major group.
      a_group = find_group(results, "A", :harmonic_minor)

      assert a_group.chords == [
               chord("D", :minor),
               chord("E", :major),
               chord("F", :major)
             ]
    end

    test "full membership keeps the unmatched group (Fmaj, Cmaj, Gmin, G#maj, Dmaj, Bmaj)" do
      results =
        Scale.suggest_multi_keys([
          chord("F", :major),
          chord("C", :major),
          chord("G", :minor),
          chord("G#", :major),
          chord("D", :major),
          chord("B", :major)
        ])

      # Group selection and order are unchanged by full membership.
      assert key_sequence(results) == [
               {"F", :major},
               {"G", :melodic_minor},
               {"D#", :major}
             ]

      # G melodic minor also contains the notes of Cmaj and Gmin, so the
      # second group lists all of them, not only the exclusively-assigned Dmaj.
      second_group = Enum.at(Enum.filter(results, &(&1.key != nil)), 1)

      assert second_group.chords == [
               chord("C", :major),
               chord("G", :minor),
               chord("D", :major)
             ]

      # The unmatched group still exists, is last, and contains only Bmaj.
      [unmatched] = Enum.filter(results, &(&1.key == nil))
      assert List.last(results) == unmatched
      assert unmatched.chords == [chord("B", :major)]

      # A chord listed as unmatched never appears in a real group's chords.
      for group <- results, group.key != nil do
        refute chord("B", :major) in group.chords
      end
    end
  end
end
