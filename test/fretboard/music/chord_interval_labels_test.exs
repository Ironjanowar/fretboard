defmodule Fretboard.Music.ChordIntervalLabelsTest do
  use ExUnit.Case, async: true

  alias Fretboard.Music.Chord

  describe "interval_labels/1 without 7th (simple names)" do
    test "major triad uses simple names" do
      assert Chord.interval_labels(:major) == ["Root", "Major 3rd", "Perfect 5th"]
    end

    test "minor triad uses simple names" do
      assert Chord.interval_labels(:minor) == ["Root", "Minor 3rd", "Perfect 5th"]
    end

    test "sus2 uses Major 2nd (no 7th)" do
      assert Chord.interval_labels(:sus2) == ["Root", "Major 2nd", "Perfect 5th"]
    end

    test "add9 uses Major 2nd (no 7th, 2 stays simple)" do
      assert Chord.interval_labels(:add9) == ["Root", "Major 2nd", "Major 3rd", "Perfect 5th"]
    end

    test "m_add9 uses Major 2nd (no 7th, simple)" do
      assert Chord.interval_labels(:m_add9) == ["Root", "Major 2nd", "Minor 3rd", "Perfect 5th"]
    end

    test "maj6_9 uses Major 2nd and Major 6th (no 7th, simple)" do
      assert Chord.interval_labels(:maj6_9) == [
               "Root",
               "Major 2nd",
               "Major 3rd",
               "Perfect 5th",
               "Major 6th"
             ]
    end

    test "min6_9 uses Major 2nd and Major 6th (no 7th, simple)" do
      assert Chord.interval_labels(:min6_9) == [
               "Root",
               "Major 2nd",
               "Minor 3rd",
               "Perfect 5th",
               "Major 6th"
             ]
    end

    test "maj6 uses simple names" do
      assert Chord.interval_labels(:maj6) == ["Root", "Major 3rd", "Perfect 5th", "Major 6th"]
    end

    test "min6 uses simple names" do
      assert Chord.interval_labels(:min6) == ["Root", "Minor 3rd", "Perfect 5th", "Major 6th"]
    end
  end

  describe "interval_labels/1 with 7th but no extensions" do
    test "dominant 7 has 7th but nothing after" do
      assert Chord.interval_labels(:"7") == [
               "Root",
               "Major 3rd",
               "Perfect 5th",
               "Minor 7th"
             ]
    end

    test "maj7 has 7th but nothing after" do
      assert Chord.interval_labels(:maj7) == [
               "Root",
               "Major 3rd",
               "Perfect 5th",
               "Major 7th"
             ]
    end

    test "min7 has 7th but nothing after" do
      assert Chord.interval_labels(:min7) == [
               "Root",
               "Minor 3rd",
               "Perfect 5th",
               "Minor 7th"
             ]
    end
  end

  describe "interval_labels/1 with 7th and 9th extensions" do
    test "dominant 9 uses Major 9th (2 after 7th)" do
      assert Chord.interval_labels(:"9") == [
               "Root",
               "Major 3rd",
               "Perfect 5th",
               "Minor 7th",
               "Major 9th"
             ]
    end

    test "maj9 uses Major 9th" do
      assert Chord.interval_labels(:maj9) == [
               "Root",
               "Major 3rd",
               "Perfect 5th",
               "Major 7th",
               "Major 9th"
             ]
    end

    test "min9 uses Major 9th" do
      assert Chord.interval_labels(:min9) == [
               "Root",
               "Minor 3rd",
               "Perfect 5th",
               "Minor 7th",
               "Major 9th"
             ]
    end

    test "7b9 uses Flat 9th (9th extension sorted after 7th)" do
      assert Chord.interval_labels(:"7b9") == [
               "Root",
               "Major 3rd",
               "Perfect 5th",
               "Minor 7th",
               "Flat 9th"
             ]
    end

    test "7#9 uses Sharp 9th (3 with 4 present)" do
      assert Chord.interval_labels(:"7#9") == [
               "Root",
               "Sharp 9th",
               "Major 3rd",
               "Perfect 5th",
               "Minor 7th"
             ]
    end
  end

  describe "interval_labels/1 with 11th extensions" do
    test "dominant 11 uses Perfect 11th" do
      assert Chord.interval_labels(:"11") == [
               "Root",
               "Major 3rd",
               "Perfect 5th",
               "Minor 7th",
               "Major 9th",
               "Perfect 11th"
             ]
    end

    test "maj11 uses Perfect 11th" do
      assert Chord.interval_labels(:maj11) == [
               "Root",
               "Major 3rd",
               "Perfect 5th",
               "Major 7th",
               "Major 9th",
               "Perfect 11th"
             ]
    end

    test "7#11 uses Augmented 11th (6 with 7th)" do
      assert Chord.interval_labels(:"7#11") == [
               "Root",
               "Major 3rd",
               "Augmented 11th",
               "Perfect 5th",
               "Minor 7th"
             ]
    end

    test "maj7#11 uses Augmented 11th" do
      assert Chord.interval_labels(:"maj7#11") == [
               "Root",
               "Major 3rd",
               "Augmented 11th",
               "Perfect 5th",
               "Major 7th"
             ]
    end
  end

  describe "interval_labels/1 with 13th extensions" do
    test "dominant 13 uses Major 13th" do
      assert Chord.interval_labels(:"13") == [
               "Root",
               "Major 3rd",
               "Perfect 5th",
               "Minor 7th",
               "Major 9th",
               "Perfect 11th",
               "Major 13th"
             ]
    end

    test "maj13 uses Major 13th" do
      assert Chord.interval_labels(:maj13) == [
               "Root",
               "Major 3rd",
               "Perfect 5th",
               "Major 7th",
               "Major 9th",
               "Perfect 11th",
               "Major 13th"
             ]
    end

    test "min13 uses Major 13th" do
      assert Chord.interval_labels(:min13) == [
               "Root",
               "Minor 3rd",
               "Perfect 5th",
               "Minor 7th",
               "Major 9th",
               "Perfect 11th",
               "Major 13th"
             ]
    end

    test "7b13 uses Minor 13th (8 with 7th, sorted as 13th extension)" do
      assert Chord.interval_labels(:"7b13") == [
               "Root",
               "Major 3rd",
               "Perfect 5th",
               "Minor 7th",
               "Minor 13th"
             ]
    end

    test "13b9 uses Flat 9th and Major 13th" do
      assert Chord.interval_labels(:"13b9") == [
               "Root",
               "Major 3rd",
               "Perfect 5th",
               "Minor 7th",
               "Flat 9th",
               "Perfect 11th",
               "Major 13th"
             ]
    end
  end

  describe "interval_labels/1 for suspended extended" do
    test "sus9 uses Major 9th and Perfect 11th" do
      assert Chord.interval_labels(:sus9) == [
               "Root",
               "Perfect 5th",
               "Minor 7th",
               "Major 9th",
               "Perfect 11th"
             ]
    end

    test "susb9 uses Flat 9th and Perfect 11th" do
      assert Chord.interval_labels(:susb9) == [
               "Root",
               "Perfect 5th",
               "Minor 7th",
               "Flat 9th",
               "Perfect 11th"
             ]
    end

    test "sus13 uses Major 13th" do
      assert Chord.interval_labels(:sus13) == [
               "Root",
               "Perfect 5th",
               "Minor 7th",
               "Perfect 11th",
               "Major 13th"
             ]
    end
  end

  describe "interval_labels/1 for minor/dim variations" do
    test "min7b13 uses Minor 13th" do
      assert Chord.interval_labels(:min7b13) == [
               "Root",
               "Minor 3rd",
               "Perfect 5th",
               "Minor 7th",
               "Minor 13th"
             ]
    end

    test "dim7b13 uses Minor 13th" do
      assert Chord.interval_labels(:dim7b13) == [
               "Root",
               "Minor 3rd",
               "Tritone",
               "Minor 13th",
               "Major 6th"
             ]
    end
  end
end
