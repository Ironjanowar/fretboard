defmodule Fretboard.MusicTest do
  use ExUnit.Case, async: true

  alias Fretboard.Music

  describe "standard_tuning/0" do
    test "delegates to Tuning" do
      assert Music.standard_tuning() == ["E", "A", "D", "G", "B", "E"]
    end
  end

  describe "available_qualities/0" do
    test "delegates to Chord" do
      assert Music.available_qualities() == [:major, :minor]
    end
  end

  describe "chord_notes/2" do
    test "delegates to Chord" do
      assert Music.chord_notes("C", :major) == ["C", "E", "G"]
    end
  end

  describe "fretboard_data/2" do
    test "returns 6 strings" do
      data = Music.fretboard_data(Music.standard_tuning(), [])
      assert length(data) == 6
    end

    test "each string has 25 frets (0-24)" do
      data = Music.fretboard_data(Music.standard_tuning(), [])

      for string <- data do
        assert length(string) == 25
      end
    end

    test "fret 0 of string 0 is E with no chords when no active chords" do
      data = Music.fretboard_data(Music.standard_tuning(), [])
      first_string = Enum.at(data, 0)
      fret_0 = Enum.at(first_string, 0)
      assert fret_0 == %{fret: 0, note: "E", chords: []}
    end

    test "fret 1 of string 0 is F" do
      data = Music.fretboard_data(Music.standard_tuning(), [])
      first_string = Enum.at(data, 0)
      fret_1 = Enum.at(first_string, 1)
      assert fret_1.note == "F"
    end

    test "highlights notes belonging to active chords" do
      active = [%{root: "C", quality: :major}]
      data = Music.fretboard_data(Music.standard_tuning(), active)
      # String 0 (E), fret 0 = E → E is in C major
      first_string = Enum.at(data, 0)
      fret_0 = Enum.at(first_string, 0)
      assert "C major" in fret_0.chords
    end

    test "notes not in any chord have empty chords list" do
      active = [%{root: "C", quality: :major}]
      data = Music.fretboard_data(Music.standard_tuning(), active)
      # String 0 (E), fret 1 = F → F is NOT in C major
      first_string = Enum.at(data, 0)
      fret_1 = Enum.at(first_string, 1)
      assert fret_1.chords == []
    end

    test "multiple active chords produce overlap" do
      active = [
        %{root: "C", quality: :major},
        %{root: "A", quality: :minor}
      ]

      data = Music.fretboard_data(Music.standard_tuning(), active)
      # String 0 (E), fret 0 = E → E is in both C major and A minor
      first_string = Enum.at(data, 0)
      fret_0 = Enum.at(first_string, 0)
      assert "C major" in fret_0.chords
      assert "A minor" in fret_0.chords
    end
  end
end
