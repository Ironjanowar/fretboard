defmodule Fretboard.Music.PianoAnalysisTest do
  use ExUnit.Case, async: true

  alias Fretboard.Music

  describe "analyze_pitches/1" do
    test "empty selection has no analysis" do
      assert Music.analyze_pitches([]) == {:empty}
    end

    test "one absolute pitch is a single note" do
      assert Music.analyze_pitches([61]) == {:single, "C#"}
    end

    test "repeated identical pitches remain a single note" do
      assert Music.analyze_pitches([60, 60, 60]) == {:single, "C"}
    end

    test "distinct heights of one pitch class remain an octave" do
      assert Music.analyze_pitches([72, 60]) == {:interval, "C", "C", "Octave"}
      assert Music.analyze_pitches([84, 60, 72, 60]) == {:interval, "C", "C", "Octave"}
    end

    test "two pitch classes use their lowest heights regardless of input order" do
      assert Music.analyze_pitches([76, 72, 64, 60]) ==
               {:interval, "C", "E", "Major 3rd"}
    end

    test "compound intervals retain the existing simple interval label" do
      assert Music.analyze_pitches([76, 60]) == {:interval, "C", "E", "Major 3rd"}
    end

    test "an exact chord retains its root-position interpretation" do
      assert {:chords, ["C", "E", "G"], "C", [first | _]} =
               Music.analyze_pitches([60, 64, 67])

      assert %{root: "C", quality: :major, exact: true, bass: "C", inversion: 0} = first
      assert first.slash_label == "Cmaj"
    end

    test "the lowest absolute pitch determines an unsorted chord's inversion" do
      assert {:chords, ["E", "G", "C"], "E", [first | _]} =
               Music.analyze_pitches([72, 67, 64])

      assert %{root: "C", quality: :major, exact: true, bass: "E", inversion: 1} = first
      assert first.slash_label == "Cmaj/E"
    end

    test "reordering and doubling chord pitches preserves the full analysis" do
      assert Music.analyze_pitches([79, 72, 64, 67, 64, 76]) ==
               Music.analyze_pitches([64, 67, 72])
    end
  end

  describe "analyzer_state/2 compatibility" do
    test "fretted selections produce the same full analysis as their sounding pitches" do
      cases = [
        {%{}, [67, 60, 64, 69], []},
        {%{0 => 1}, [59], [60]},
        {%{0 => 0, 1 => 5}, [60, 55], [60, 60]},
        {%{0 => 0, 1 => 0}, [72, 60], [72, 60]},
        {%{1 => 3, 2 => 2}, [40, 45, 50, 55, 59, 64], [48, 52]},
        {%{0 => 24, 2 => 5, 4 => 0}, [40, 45, 50, 55, 59, 64], [64, 55, 59]},
        {%{0 => 0, 1 => 0, 2 => 0, 3 => 0}, [67, 60, 64, 69], [67, 60, 64, 69]}
      ]

      for {marked, string_pitches, sounding_pitches} <- cases do
        assert Music.analyzer_state(marked, string_pitches) ==
                 Music.analyze_pitches(sounding_pitches)
      end
    end
  end
end
