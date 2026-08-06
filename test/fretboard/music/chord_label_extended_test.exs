defmodule Fretboard.Music.ChordLabelExtendedTest do
  use ExUnit.Case, async: true

  alias Fretboard.Music.Chord

  describe "label/1 for new qualities" do
    test "maj6 label is 6" do
      assert Chord.label(:maj6) == "6"
    end

    test "min6 label is m6" do
      assert Chord.label(:min6) == "m6"
    end

    test "dominant 9 label is 9" do
      assert Chord.label(:"9") == "9"
    end

    test "min9 label is m9" do
      assert Chord.label(:min9) == "m9"
    end

    test "7b9 label is 7b9" do
      assert Chord.label(:"7b9") == "7b9"
    end

    test "7sus4 label is 7sus" do
      assert Chord.label(:"7sus4") == "7sus"
    end

    test "add9 label is add9" do
      assert Chord.label(:add9) == "add9"
    end

    test "m_add9 label is madd9" do
      assert Chord.label(:m_add9) == "madd9"
    end

    test "maj6_9 label is 6/9" do
      assert Chord.label(:maj6_9) == "6/9"
    end

    test "min6_9 label is m6/9" do
      assert Chord.label(:min6_9) == "m6/9"
    end

    test "maj9 label is maj9" do
      assert Chord.label(:maj9) == "maj9"
    end

    test "7#9 label is 7#9" do
      assert Chord.label(:"7#9") == "7#9"
    end

    test "9#5 label is 9#5" do
      assert Chord.label(:"9#5") == "9#5"
    end

    test "9b5 label is 9b5" do
      assert Chord.label(:"9b5") == "9b5"
    end

    test "7b5 label is 7b5" do
      assert Chord.label(:"7b5") == "7b5"
    end

    test "dim_maj7 label is dimMaj7" do
      assert Chord.label(:dim_maj7) == "dimMaj7"
    end

    test "maj7#11 label is maj7#11" do
      assert Chord.label(:"maj7#11") == "maj7#11"
    end

    test "7#11 label is 7#11" do
      assert Chord.label(:"7#11") == "7#11"
    end

    test "7b13 label is 7b13" do
      assert Chord.label(:"7b13") == "7b13"
    end

    test "7b9b13 label is 7b9b13" do
      assert Chord.label(:"7b9b13") == "7b9b13"
    end

    test "11 label is 11" do
      assert Chord.label(:"11") == "11"
    end

    test "maj11 label is maj11" do
      assert Chord.label(:maj11) == "maj11"
    end

    test "min11 label is m11" do
      assert Chord.label(:min11) == "m11"
    end

    test "m11b5 label is m11b5" do
      assert Chord.label(:m11b5) == "m11b5"
    end

    test "13 label is 13" do
      assert Chord.label(:"13") == "13"
    end

    test "maj13 label is maj13" do
      assert Chord.label(:maj13) == "maj13"
    end

    test "min13 label is m13" do
      assert Chord.label(:min13) == "m13"
    end

    test "13b9 label is 13b9" do
      assert Chord.label(:"13b9") == "13b9"
    end

    test "sus9 label is sus9" do
      assert Chord.label(:sus9) == "sus9"
    end

    test "susb9 label is susb9" do
      assert Chord.label(:susb9) == "susb9"
    end

    test "sus13 label is sus13" do
      assert Chord.label(:sus13) == "sus13"
    end

    test "min7b13 label is m7b13" do
      assert Chord.label(:min7b13) == "m7b13"
    end

    test "dim7b13 label is dim7b13" do
      assert Chord.label(:dim7b13) == "dim7b13"
    end
  end

  describe "chord_label/2 for new qualities" do
    test "formats C9" do
      assert Chord.chord_label("C", :"9") == "C9"
    end

    test "formats Gm9" do
      assert Chord.chord_label("G", :min9) == "Gm9"
    end

    test "formats C6" do
      assert Chord.chord_label("C", :maj6) == "C6"
    end

    test "formats Cm6" do
      assert Chord.chord_label("C", :min6) == "Cm6"
    end

    test "formats C7sus" do
      assert Chord.chord_label("C", :"7sus4") == "C7sus"
    end

    test "formats C7b9" do
      assert Chord.chord_label("C", :"7b9") == "C7b9"
    end

    test "formats C6/9" do
      assert Chord.chord_label("C", :maj6_9) == "C6/9"
    end

    test "formats CdimMaj7" do
      assert Chord.chord_label("C", :dim_maj7) == "CdimMaj7"
    end

    test "formats Cmaj7#11" do
      assert Chord.chord_label("C", :"maj7#11") == "Cmaj7#11"
    end

    test "formats C11" do
      assert Chord.chord_label("C", :"11") == "C11"
    end

    test "formats C13" do
      assert Chord.chord_label("C", :"13") == "C13"
    end

    test "formats Cdim7b13" do
      assert Chord.chord_label("C", :dim7b13) == "Cdim7b13"
    end
  end
end
