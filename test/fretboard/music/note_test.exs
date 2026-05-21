defmodule Fretboard.Music.NoteTest do
  use ExUnit.Case, async: true

  alias Fretboard.Music.Note

  describe "chromatic_scale/0" do
    test "returns 12 notes starting from C" do
      assert Note.chromatic_scale() == [
               "C",
               "C#",
               "D",
               "D#",
               "E",
               "F",
               "F#",
               "G",
               "G#",
               "A",
               "A#",
               "B"
             ]
    end
  end

  describe "note_index/1" do
    test "returns 0 for C" do
      assert Note.note_index("C") == 0
    end

    test "returns 4 for E" do
      assert Note.note_index("E") == 4
    end

    test "returns 11 for B" do
      assert Note.note_index("B") == 11
    end
  end

  describe "note_at/2" do
    test "returns the same note at 0 semitones" do
      assert Note.note_at("E", 0) == "E"
    end

    test "returns F for E + 1 semitone" do
      assert Note.note_at("E", 1) == "F"
    end

    test "wraps around after 12 semitones" do
      assert Note.note_at("E", 12) == "E"
    end

    test "returns correct note for arbitrary semitones" do
      assert Note.note_at("C", 7) == "G"
    end

    test "handles large semitone values" do
      assert Note.note_at("A", 25) == "A#"
    end
  end
end
