defmodule Fretboard.Music.AnalyzerStateFollowupTest do
  use ExUnit.Case, async: true

  alias Fretboard.Music

  describe "analyzer_state/2 sounding pitch classification" do
    test "no marked positions is empty regardless of available strings" do
      assert Music.analyzer_state(%{}, []) == {:empty}
      assert Music.analyzer_state(%{}, [67, 60, 64, 69]) == {:empty}
    end

    test "one sounding pitch is a single note" do
      assert Music.analyzer_state(%{0 => 1}, [59]) == {:single, "C"}
    end

    test "multiple strings at the exact same sounding height are a unison" do
      assert Music.analyzer_state(%{0 => 0, 1 => 5, 2 => 12}, [60, 55, 48]) ==
               {:single, "C"}
    end

    test "one pitch class at distinct heights is an octave even across multiple octaves" do
      assert Music.analyzer_state(%{0 => 0, 1 => 0}, [72, 60]) ==
               {:interval, "C", "C", "Octave"}

      assert Music.analyzer_state(%{0 => 0, 1 => 0, 2 => 0}, [84, 60, 72]) ==
               {:interval, "C", "C", "Octave"}
    end

    test "two duplicated classes use each class's lowest sounding height, not string order" do
      assert Music.analyzer_state(%{0 => 0, 1 => 0, 2 => 0, 3 => 0}, [76, 72, 64, 60]) ==
               {:interval, "C", "E", "Major 3rd"}
    end

    test "two duplicated classes reduce a compound distance to its simple interval" do
      assert Music.analyzer_state(%{0 => 0, 1 => 0, 2 => 0, 3 => 0}, [88, 72, 76, 60]) ==
               {:interval, "C", "E", "Major 3rd"}
    end
  end
end
