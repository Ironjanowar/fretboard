defmodule Fretboard.Music.ChordTest do
  use ExUnit.Case, async: true

  alias Fretboard.Music.Chord

  describe "available_qualities/0" do
    test "returns all chord qualities" do
      qualities = Chord.available_qualities()

      assert :major in qualities
      assert :minor in qualities
      assert :dim in qualities
      assert :aug in qualities
      assert :sus2 in qualities
      assert :sus4 in qualities
      assert :"7" in qualities
      assert :maj7 in qualities
      assert :min7 in qualities
      assert :dim7 in qualities
      assert :m7b5 in qualities
      assert length(qualities) == 11
    end
  end

  describe "formula/1" do
    test "returns major formula" do
      assert Chord.formula(:major) == [0, 4, 7]
    end

    test "returns minor formula" do
      assert Chord.formula(:minor) == [0, 3, 7]
    end

    test "returns dim formula" do
      assert Chord.formula(:dim) == [0, 3, 6]
    end

    test "returns aug formula" do
      assert Chord.formula(:aug) == [0, 4, 8]
    end

    test "returns sus2 formula" do
      assert Chord.formula(:sus2) == [0, 2, 7]
    end

    test "returns sus4 formula" do
      assert Chord.formula(:sus4) == [0, 5, 7]
    end

    test "returns dominant 7 formula" do
      assert Chord.formula(:"7") == [0, 4, 7, 10]
    end

    test "returns maj7 formula" do
      assert Chord.formula(:maj7) == [0, 4, 7, 11]
    end

    test "returns min7 formula" do
      assert Chord.formula(:min7) == [0, 3, 7, 10]
    end

    test "returns dim7 formula" do
      assert Chord.formula(:dim7) == [0, 3, 6, 9]
    end

    test "returns m7b5 formula" do
      assert Chord.formula(:m7b5) == [0, 3, 6, 10]
    end
  end

  describe "notes/2" do
    test "returns C major notes" do
      assert Chord.notes("C", :major) == ["C", "E", "G"]
    end

    test "returns A minor notes" do
      assert Chord.notes("A", :minor) == ["A", "C", "E"]
    end

    test "returns G major notes" do
      assert Chord.notes("G", :major) == ["G", "B", "D"]
    end

    test "wraps around for notes near end of scale" do
      assert Chord.notes("B", :major) == ["B", "D#", "F#"]
    end

    test "returns C dim notes" do
      assert Chord.notes("C", :dim) == ["C", "D#", "F#"]
    end

    test "returns C aug notes" do
      assert Chord.notes("C", :aug) == ["C", "E", "G#"]
    end

    test "returns D sus2 notes" do
      assert Chord.notes("D", :sus2) == ["D", "E", "A"]
    end

    test "returns A sus4 notes" do
      assert Chord.notes("A", :sus4) == ["A", "D", "E"]
    end

    test "returns C7 notes" do
      assert Chord.notes("C", :"7") == ["C", "E", "G", "A#"]
    end

    test "returns C maj7 notes" do
      assert Chord.notes("C", :maj7) == ["C", "E", "G", "B"]
    end

    test "returns A min7 notes" do
      assert Chord.notes("A", :min7) == ["A", "C", "E", "G"]
    end

    test "returns C dim7 notes" do
      assert Chord.notes("C", :dim7) == ["C", "D#", "F#", "A"]
    end

    test "returns B m7b5 notes" do
      assert Chord.notes("B", :m7b5) == ["B", "D", "F", "A"]
    end
  end

  describe "label/1" do
    test "returns short label for major" do
      assert Chord.label(:major) == "maj"
    end

    test "returns short label for minor" do
      assert Chord.label(:minor) == "min"
    end

    test "returns short label for dim" do
      assert Chord.label(:dim) == "dim"
    end

    test "returns short label for aug" do
      assert Chord.label(:aug) == "aug"
    end

    test "returns short label for sus2" do
      assert Chord.label(:sus2) == "sus2"
    end

    test "returns short label for sus4" do
      assert Chord.label(:sus4) == "sus4"
    end

    test "returns short label for dominant 7" do
      assert Chord.label(:"7") == "7"
    end

    test "returns short label for maj7" do
      assert Chord.label(:maj7) == "maj7"
    end

    test "returns short label for min7" do
      assert Chord.label(:min7) == "min7"
    end

    test "returns short label for dim7" do
      assert Chord.label(:dim7) == "dim7"
    end

    test "returns short label for m7b5" do
      assert Chord.label(:m7b5) == "m7b5"
    end
  end

  describe "chord_label/2" do
    test "formats C major as Cmaj" do
      assert Chord.chord_label("C", :major) == "Cmaj"
    end

    test "formats A minor as Amin" do
      assert Chord.chord_label("A", :minor) == "Amin"
    end

    test "formats G dominant 7 as G7" do
      assert Chord.chord_label("G", :"7") == "G7"
    end

    test "formats C dim7 as Cdim7" do
      assert Chord.chord_label("C", :dim7) == "Cdim7"
    end

    test "formats F# sus2 as F#sus2" do
      assert Chord.chord_label("F#", :sus2) == "F#sus2"
    end
  end

  describe "grouped_qualities/0" do
    test "returns triads and sevenths groups" do
      groups = Chord.grouped_qualities()

      assert [{"Triads", triads}, {"Sevenths", sevenths}] = groups
      assert triads == [:major, :minor, :dim, :aug, :sus2, :sus4]
      assert sevenths == [:"7", :maj7, :min7, :dim7, :m7b5]
    end
  end
end
