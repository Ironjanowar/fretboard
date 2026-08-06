defmodule Fretboard.Music.ChordIdentifyIncompleteTest do
  use ExUnit.Case, async: true

  alias Fretboard.Music.Chord

  describe "identify/1 incomplete matching" do
    test "E-G#-D-F# identifies E9 as first incomplete result" do
      [first | _] = Chord.identify(["E", "G#", "D", "F#"])

      assert first.root == "E"
      assert first.quality == :"9"
      assert first.exact == false
      assert first.incomplete == true
    end

    test "E9 incomplete result has missing_intervals listing Perfect 5th" do
      [first | _] = Chord.identify(["E", "G#", "D", "F#"])

      assert first.incomplete == true
      assert first.missing_intervals == ["Perfect 5th"]
    end

    test "C-E-G returns C major as exact first, not incomplete" do
      [first | _] = Chord.identify(["C", "E", "G"])

      assert first.root == "C"
      assert first.quality == :major
      assert first.exact == true
      assert first.incomplete == false
    end

    test "C-E-G incomplete matches come after exact" do
      results = Chord.identify(["C", "E", "G"])
      [first | rest] = results

      # C major is exact, comes first
      assert first.exact == true

      # All remaining results should be incomplete (no partials for 3-note input
      # since partial requires formula_size < input_size, i.e. formula of 2 notes)
      for r <- rest do
        assert r.exact == false
        assert r.incomplete == true
      end
    end

    test "exact before incomplete before partial ordering" do
      # C-E-G-B = Cmaj7 exact, Cmaj9 incomplete, C major partial
      results = Chord.identify(["C", "E", "G", "B"])

      exact_results = Enum.filter(results, & &1.exact)
      incomplete_results = Enum.filter(results, &(!&1.exact and &1.incomplete))
      partial_results = Enum.filter(results, &(!&1.exact and !&1.incomplete))

      # There is at least one exact
      refute exact_results == []
      # There is at least one incomplete (Cmaj9 missing 9th)
      refute incomplete_results == []
      # There is at least one partial (C major)
      refute partial_results == []

      # Verify ordering: all exact indices < all incomplete indices < all partial indices
      exact_indices = Enum.map(exact_results, fn r -> Enum.find_index(results, &(&1 == r)) end)

      incomplete_indices =
        Enum.map(incomplete_results, fn r -> Enum.find_index(results, &(&1 == r)) end)

      partial_indices =
        Enum.map(partial_results, fn r -> Enum.find_index(results, &(&1 == r)) end)

      assert Enum.max(exact_indices) < Enum.min(incomplete_indices)
      assert Enum.max(incomplete_indices) < Enum.min(partial_indices)
    end

    test "Cmaj7 is exact first for C-E-G-B" do
      [first | _] = Chord.identify(["C", "E", "G", "B"])

      assert first.root == "C"
      assert first.quality == :maj7
      assert first.exact == true
      assert first.incomplete == false
    end

    test "Cmaj9 appears as incomplete for C-E-G-B" do
      results = Chord.identify(["C", "E", "G", "B"])

      maj9 = Enum.find(results, fn r -> r.root == "C" and r.quality == :maj9 end)

      assert maj9 != nil
      assert maj9.exact == false
      assert maj9.incomplete == true
      # Cmaj9 = [0,2,4,7,11], input = {0,4,7,11}, missing interval 2
      assert maj9.missing_intervals == ["Major 9th"]
    end

    test "C major appears as partial for C-E-G-B" do
      results = Chord.identify(["C", "E", "G", "B"])

      major = Enum.find(results, fn r -> r.root == "C" and r.quality == :major end)

      assert major != nil
      assert major.exact == false
      assert major.incomplete == false
    end

    test "two notes returns empty list" do
      assert Chord.identify(["C", "E"]) == []
    end

    test "incomplete limited to at most 2 missing notes" do
      # C-E-G: C major is exact. Cmaj7 (missing 1), Cmaj9 (missing 2) are incomplete.
      # Cmaj13 = [0,2,4,5,7,9,11] has 4 missing notes — should NOT appear.
      results = Chord.identify(["C", "E", "G"])

      maj13 = Enum.find(results, fn r -> r.root == "C" and r.quality == :maj13 end)
      assert maj13 == nil, "Cmaj13 should not appear (more than 2 missing notes)"
    end

    test "Cmaj11 does not appear for C-E-G (3 missing notes)" do
      # Cmaj11 = [0,2,4,5,7,11], input {0,4,7}, missing {2,5,11} = 3 missing
      results = Chord.identify(["C", "E", "G"])

      maj11 = Enum.find(results, fn r -> r.root == "C" and r.quality == :maj11 end)
      assert maj11 == nil, "Cmaj11 should not appear (3 missing notes exceeds limit)"
    end

    test "C-E-A# identifies as C7 incomplete (missing Perfect 5th)" do
      # C-E-A# = {0,4,10}. C7 = [0,4,7,10], missing 7 (Perfect 5th), 1 missing
      results = Chord.identify(["C", "E", "A#"])

      c7 = Enum.find(results, fn r -> r.root == "C" and r.quality == :"7" end)

      assert c7 != nil
      assert c7.exact == false
      assert c7.incomplete == true
      assert c7.missing_intervals == ["Perfect 5th"]
    end

    test "incomplete result includes all identify/1 fields" do
      [first | _] = Chord.identify(["E", "G#", "D", "F#"])

      assert Map.has_key?(first, :root)
      assert Map.has_key?(first, :quality)
      assert Map.has_key?(first, :exact)
      assert Map.has_key?(first, :incomplete)
      assert Map.has_key?(first, :notes)
      assert Map.has_key?(first, :intervals)
      assert Map.has_key?(first, :missing_intervals)
    end

    test "exact results have empty missing_intervals" do
      [first | _] = Chord.identify(["C", "E", "G"])

      assert first.exact == true
      assert first.missing_intervals == []
    end

    test "partial results have empty missing_intervals" do
      results = Chord.identify(["C", "E", "G", "B"])

      partial = Enum.find(results, fn r -> !r.exact and !r.incomplete end)

      assert partial != nil
      assert partial.missing_intervals == []
    end
  end
end
