defmodule Fretboard.Music.ChordIdentifyTest do
  use ExUnit.Case, async: true

  alias Fretboard.Music.Chord

  describe "identify/1" do
    test "C major triad returns C major as first result" do
      [first | _] = Chord.identify(["C", "E", "G"])

      assert first.root == "C"
      assert first.quality == :major
      assert first.exact == true
      assert first.notes == ["C", "E", "G"]
      assert first.intervals == ["Root", "Major 3rd", "Perfect 5th"]
    end

    test "A minor triad returns A minor as first result" do
      [first | _] = Chord.identify(["A", "C", "E"])

      assert first.root == "A"
      assert first.quality == :minor
      assert first.exact == true
      assert first.notes == ["A", "C", "E"]
      assert first.intervals == ["Root", "Minor 3rd", "Perfect 5th"]
    end

    test "C-E-G returns C major as the only exact interpretation" do
      results = Chord.identify(["C", "E", "G"])
      exact_results = Enum.filter(results, & &1.exact)

      # C-E-G is pitch-class set {0,4,7} — that is C major, NOT A minor
      # (A minor is {0,4,9} from A). A is not among the input notes, so
      # A minor cannot be an exact match for C-E-G.
      assert length(exact_results) == 1
      [only_exact] = exact_results
      assert only_exact.root == "C"
      assert only_exact.quality == :major

      refute Enum.any?(results, fn r ->
               r.root == "A" and r.quality == :minor and r.exact == true
             end)
    end

    test "G7 dominant seventh is first result" do
      [first | _] = Chord.identify(["G", "B", "D", "F"])

      assert first.root == "G"
      assert first.quality == :"7"
      assert first.exact == true
      assert first.notes == ["G", "B", "D", "F"]
      assert first.intervals == ["Root", "Major 3rd", "Perfect 5th", "Minor 7th"]
    end

    test "C maj7 is first result" do
      [first | _] = Chord.identify(["C", "E", "G", "B"])

      assert first.root == "C"
      assert first.quality == :maj7
      assert first.exact == true
      assert first.notes == ["C", "E", "G", "B"]
      assert first.intervals == ["Root", "Major 3rd", "Perfect 5th", "Major 7th"]
    end

    test "C dim is first result" do
      [first | _] = Chord.identify(["C", "D#", "F#"])

      assert first.root == "C"
      assert first.quality == :dim
      assert first.exact == true
      assert first.notes == ["C", "D#", "F#"]
      assert first.intervals == ["Root", "Minor 3rd", "Tritone"]
    end

    test "C aug is first result" do
      [first | _] = Chord.identify(["C", "E", "G#"])

      assert first.root == "C"
      assert first.quality == :aug
      assert first.exact == true
      assert first.notes == ["C", "E", "G#"]
      assert first.intervals == ["Root", "Major 3rd", "Augmented 5th"]
    end

    test "empty list returns empty list" do
      assert Chord.identify([]) == []
    end

    test "single note returns empty list (not enough notes for a chord)" do
      assert Chord.identify(["C"]) == []
    end

    test "two notes returns empty list (need at least 3)" do
      assert Chord.identify(["C", "G"]) == []
    end

    test "duplicate notes are deduplicated" do
      [first | _] = Chord.identify(["C", "C", "E", "G"])

      assert first.root == "C"
      assert first.quality == :major
      assert first.exact == true
      assert first.notes == ["C", "E", "G"]
    end

    test "notes in different order still identify correctly" do
      [first | _] = Chord.identify(["G", "E", "C"])

      assert first.root == "C"
      assert first.quality == :major
      assert first.exact == true
    end

    test "C-E-G-B returns C maj7 as exact first and C major as partial" do
      results = Chord.identify(["C", "E", "G", "B"])

      [maj7 | _] = results

      assert maj7.root == "C"
      assert maj7.quality == :maj7
      assert maj7.exact == true

      major = Enum.find(results, fn r -> r.root == "C" and r.quality == :major end)

      assert major != nil
      assert major.exact == false
    end

    test "exact matches sort before partial matches" do
      results = Chord.identify(["C", "E", "G", "B"])

      {exact_results, partial_results} = Enum.split_with(results, & &1.exact)

      # The first element of the overall results should belong to the exact group
      assert hd(results) in exact_results
      # All exact results come before all partial results in the ordering
      exact_indices = Enum.map(exact_results, fn r -> Enum.find_index(results, &(&1 == r)) end)

      partial_indices =
        Enum.map(partial_results, fn r -> Enum.find_index(results, &(&1 == r)) end)

      if partial_indices != [] do
        assert Enum.max(exact_indices) < Enum.min(partial_indices)
      end
    end

    test "C dim7 (C-D#-F#-A) is first result" do
      [first | _] = Chord.identify(["C", "D#", "F#", "A"])

      assert first.root == "C"
      assert first.quality == :dim7
      assert first.exact == true
      assert first.notes == ["C", "D#", "F#", "A"]
      assert first.intervals == ["Root", "Minor 3rd", "Tritone", "Major 6th"]
    end

    test "unidentifiable triad C-D-F# returns empty list (no exact match)" do
      results = Chord.identify(["C", "D", "F#"])
      # No exact match exists for C-D-F#, but incomplete matches may appear
      assert Enum.empty?(Enum.filter(results, & &1.exact))
    end
  end
end
