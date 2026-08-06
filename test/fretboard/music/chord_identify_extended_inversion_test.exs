defmodule Fretboard.Music.ChordIdentifyExtendedInversionTest do
  use ExUnit.Case, async: true

  alias Fretboard.Music.Chord

  describe "identify/2 4th inversion (9th in bass)" do
    test "C9 with D bass is 4th inversion" do
      # C9 = C-D-E-G-A#, D is the 9th (interval 2 from root)
      [first | _] = Chord.identify(["C", "D", "E", "G", "A#"], "D")

      assert first.root == "C"
      assert first.quality == :"9"
      assert first.exact == true
      assert first.bass == "D"
      assert first.inversion == 4
      assert first.slash_label == "C9/D"
    end
  end

  describe "identify/2 5th inversion (11th in bass)" do
    test "C11 with F bass is 5th inversion" do
      # C11 = C-D-E-F-G-A#, F is the 11th (interval 5 from root)
      [first | _] = Chord.identify(["C", "D", "E", "F", "G", "A#"], "F")

      assert first.root == "C"
      assert first.quality == :"11"
      assert first.exact == true
      assert first.bass == "F"
      assert first.inversion == 5
      assert first.slash_label == "C11/F"
    end
  end

  describe "identify/2 6th inversion (13th in bass)" do
    test "C13 with A bass is 6th inversion" do
      # C13 = C-D-E-F-G-A-A#, A is the 13th (interval 9 from root)
      [first | _] = Chord.identify(["C", "D", "E", "F", "G", "A", "A#"], "A")

      assert first.root == "C"
      assert first.quality == :"13"
      assert first.exact == true
      assert first.bass == "A"
      assert first.inversion == 6
      assert first.slash_label == "C13/A"
    end
  end
end
