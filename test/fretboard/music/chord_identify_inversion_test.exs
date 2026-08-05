defmodule Fretboard.Music.ChordIdentifyInversionTest do
  use ExUnit.Case, async: true

  alias Fretboard.Music.Chord

  describe "identify/2 root position" do
    test "C major triad with C bass is root position (inversion 0)" do
      [first | _] = Chord.identify(["C", "E", "G"], "C")

      assert first.root == "C"
      assert first.quality == :major
      assert first.exact == true
      assert first.bass == "C"
      assert first.inversion == 0
      assert first.slash_label == "Cmaj"
    end

    test "A minor triad with A bass is root position" do
      [first | _] = Chord.identify(["A", "C", "E"], "A")

      assert first.root == "A"
      assert first.quality == :minor
      assert first.bass == "A"
      assert first.inversion == 0
      assert first.slash_label == "Amin"
    end

    test "G7 with G bass is root position" do
      [first | _] = Chord.identify(["G", "B", "D", "F"], "G")

      assert first.root == "G"
      assert first.quality == :"7"
      assert first.inversion == 0
      assert first.slash_label == "G7"
    end
  end

  describe "identify/2 first inversion (3rd in bass)" do
    test "C major triad with E bass is first inversion" do
      [first | _] = Chord.identify(["C", "E", "G"], "E")

      assert first.root == "C"
      assert first.quality == :major
      assert first.bass == "E"
      assert first.inversion == 1
      assert first.slash_label == "Cmaj/E"
    end

    test "A minor triad with C bass is first inversion" do
      [first | _] = Chord.identify(["A", "C", "E"], "C")

      assert first.root == "A"
      assert first.bass == "C"
      assert first.inversion == 1
      assert first.slash_label == "Amin/C"
    end
  end

  describe "identify/2 second inversion (5th in bass)" do
    test "C major triad with G bass is second inversion" do
      [first | _] = Chord.identify(["C", "E", "G"], "G")

      assert first.root == "C"
      assert first.bass == "G"
      assert first.inversion == 2
      assert first.slash_label == "Cmaj/G"
    end

    test "A minor triad with E bass is second inversion" do
      [first | _] = Chord.identify(["A", "C", "E"], "E")

      assert first.root == "A"
      assert first.bass == "E"
      assert first.inversion == 2
      assert first.slash_label == "Amin/E"
    end
  end

  describe "identify/2 third inversion (7th in bass)" do
    test "G7 with F bass is third inversion" do
      [first | _] = Chord.identify(["G", "B", "D", "F"], "F")

      assert first.root == "G"
      assert first.quality == :"7"
      assert first.bass == "F"
      assert first.inversion == 3
      assert first.slash_label == "G7/F"
    end

    test "C maj7 with B bass is third inversion" do
      [first | _] = Chord.identify(["C", "E", "G", "B"], "B")

      assert first.root == "C"
      assert first.quality == :maj7
      assert first.bass == "B"
      assert first.inversion == 3
      assert first.slash_label == "Cmaj7/B"
    end
  end

  describe "identify/2 preserves identify/1 fields and ordering" do
    test "results include all identify/1 fields plus bass, inversion, slash_label" do
      [first | _] = Chord.identify(["C", "E", "G"], "C")

      assert Map.has_key?(first, :root)
      assert Map.has_key?(first, :quality)
      assert Map.has_key?(first, :exact)
      assert Map.has_key?(first, :notes)
      assert Map.has_key?(first, :intervals)
      assert Map.has_key?(first, :bass)
      assert Map.has_key?(first, :inversion)
      assert Map.has_key?(first, :slash_label)
    end

    test "results are returned in the same order as identify/1" do
      notes = ["C", "E", "G", "B"]
      bass = "C"

      base_results = Chord.identify(notes)
      enhanced_results = Chord.identify(notes, bass)

      assert length(base_results) == length(enhanced_results)

      base_pairs = Enum.map(base_results, &{&1.root, &1.quality})
      enhanced_pairs = Enum.map(enhanced_results, &{&1.root, &1.quality})

      assert base_pairs == enhanced_pairs
    end

    test "empty input returns empty list" do
      assert Chord.identify([], "C") == []
    end

    test "too few notes returns empty list" do
      assert Chord.identify(["C", "G"], "C") == []
    end
  end

  describe "identify/2 bass not on a chord tone" do
    test "bass that is not a chord tone yields nil inversion and plain label" do
      # C major is C-E-G. D is not a chord tone.
      [first | _] = Chord.identify(["C", "E", "G"], "D")

      assert first.root == "C"
      assert first.bass == "D"
      assert first.inversion == nil
      assert first.slash_label == "Cmaj"
    end
  end
end
