defmodule Fretboard.Music.ChordExtendedFormulasTest do
  use ExUnit.Case, async: true

  alias Fretboard.Music.Chord

  describe "6ths" do
    test "C maj6 produces C-E-G-A" do
      assert Chord.notes("C", :maj6) == ["C", "E", "G", "A"]
    end

    test "C min6 produces C-D#-G-A" do
      assert Chord.notes("C", :min6) == ["C", "D#", "G", "A"]
    end

    test "maj6 formula" do
      assert Chord.formula(:maj6) == [0, 4, 7, 9]
    end

    test "min6 formula" do
      assert Chord.formula(:min6) == [0, 3, 7, 9]
    end
  end

  describe "added tones" do
    test "C add9 produces C-D-E-G" do
      assert Chord.notes("C", :add9) == ["C", "D", "E", "G"]
    end

    test "C m_add9 produces C-D-D#-G" do
      assert Chord.notes("C", :m_add9) == ["C", "D", "D#", "G"]
    end

    test "C maj6_9 produces C-D-E-G-A" do
      assert Chord.notes("C", :maj6_9) == ["C", "D", "E", "G", "A"]
    end

    test "C min6_9 produces C-D-D#-G-A" do
      assert Chord.notes("C", :min6_9) == ["C", "D", "D#", "G", "A"]
    end

    test "add9 formula" do
      assert Chord.formula(:add9) == [0, 2, 4, 7]
    end

    test "m_add9 formula" do
      assert Chord.formula(:m_add9) == [0, 2, 3, 7]
    end

    test "maj6_9 formula" do
      assert Chord.formula(:maj6_9) == [0, 2, 4, 7, 9]
    end

    test "min6_9 formula" do
      assert Chord.formula(:min6_9) == [0, 2, 3, 7, 9]
    end
  end

  describe "9ths" do
    test "C9 produces C-D-E-G-A#" do
      assert Chord.notes("C", :"9") == ["C", "D", "E", "G", "A#"]
    end

    test "C maj9 produces C-D-E-G-B" do
      assert Chord.notes("C", :maj9) == ["C", "D", "E", "G", "B"]
    end

    test "C min9 produces C-D-D#-G-A#" do
      assert Chord.notes("C", :min9) == ["C", "D", "D#", "G", "A#"]
    end

    test "C 7b9 produces C-C#-E-G-A#" do
      assert Chord.notes("C", :"7b9") == ["C", "C#", "E", "G", "A#"]
    end

    test "C 7#9 produces C-D#-E-G-A#" do
      assert Chord.notes("C", :"7#9") == ["C", "D#", "E", "G", "A#"]
    end

    test "C 9#5 produces C-D-E-G#-A#" do
      assert Chord.notes("C", :"9#5") == ["C", "D", "E", "G#", "A#"]
    end

    test "C 9b5 produces C-D-E-F#-A#" do
      assert Chord.notes("C", :"9b5") == ["C", "D", "E", "F#", "A#"]
    end

    test "C 7b5 produces C-E-F#-A#" do
      assert Chord.notes("C", :"7b5") == ["C", "E", "F#", "A#"]
    end

    test "9 formula" do
      assert Chord.formula(:"9") == [0, 2, 4, 7, 10]
    end

    test "maj9 formula" do
      assert Chord.formula(:maj9) == [0, 2, 4, 7, 11]
    end

    test "min9 formula" do
      assert Chord.formula(:min9) == [0, 2, 3, 7, 10]
    end

    test "7b9 formula" do
      assert Chord.formula(:"7b9") == [0, 1, 4, 7, 10]
    end

    test "7#9 formula" do
      assert Chord.formula(:"7#9") == [0, 3, 4, 7, 10]
    end

    test "9#5 formula" do
      assert Chord.formula(:"9#5") == [0, 2, 4, 8, 10]
    end

    test "9b5 formula" do
      assert Chord.formula(:"9b5") == [0, 2, 4, 6, 10]
    end

    test "7b5 formula" do
      assert Chord.formula(:"7b5") == [0, 4, 6, 10]
    end
  end

  describe "7th alterations" do
    test "C 7sus4 produces C-F-G-A#" do
      assert Chord.notes("C", :"7sus4") == ["C", "F", "G", "A#"]
    end

    test "C dim_maj7 produces C-D#-F#-B" do
      assert Chord.notes("C", :dim_maj7) == ["C", "D#", "F#", "B"]
    end

    test "C maj7#11 produces C-E-F#-G-B" do
      assert Chord.notes("C", :"maj7#11") == ["C", "E", "F#", "G", "B"]
    end

    test "C 7#11 produces C-E-F#-G-A#" do
      assert Chord.notes("C", :"7#11") == ["C", "E", "F#", "G", "A#"]
    end

    test "C 7b13 produces C-E-G-G#-A#" do
      assert Chord.notes("C", :"7b13") == ["C", "E", "G", "G#", "A#"]
    end

    test "C 7b9b13 produces C-C#-E-G-G#-A#" do
      assert Chord.notes("C", :"7b9b13") == ["C", "C#", "E", "G", "G#", "A#"]
    end

    test "7sus4 formula" do
      assert Chord.formula(:"7sus4") == [0, 5, 7, 10]
    end

    test "dim_maj7 formula" do
      assert Chord.formula(:dim_maj7) == [0, 3, 6, 11]
    end

    test "maj7#11 formula" do
      assert Chord.formula(:"maj7#11") == [0, 4, 6, 7, 11]
    end

    test "7#11 formula" do
      assert Chord.formula(:"7#11") == [0, 4, 6, 7, 10]
    end

    test "7b13 formula" do
      assert Chord.formula(:"7b13") == [0, 4, 7, 8, 10]
    end

    test "7b9b13 formula" do
      assert Chord.formula(:"7b9b13") == [0, 1, 4, 7, 8, 10]
    end
  end

  describe "11ths" do
    test "C11 produces C-D-E-F-G-A#" do
      assert Chord.notes("C", :"11") == ["C", "D", "E", "F", "G", "A#"]
    end

    test "C maj11 produces C-D-E-F-G-B" do
      assert Chord.notes("C", :maj11) == ["C", "D", "E", "F", "G", "B"]
    end

    test "C min11 produces C-D-D#-F-G-A#" do
      assert Chord.notes("C", :min11) == ["C", "D", "D#", "F", "G", "A#"]
    end

    test "C m11b5 produces C-D-D#-F-F#-A#" do
      assert Chord.notes("C", :m11b5) == ["C", "D", "D#", "F", "F#", "A#"]
    end

    test "11 formula" do
      assert Chord.formula(:"11") == [0, 2, 4, 5, 7, 10]
    end

    test "maj11 formula" do
      assert Chord.formula(:maj11) == [0, 2, 4, 5, 7, 11]
    end

    test "min11 formula" do
      assert Chord.formula(:min11) == [0, 2, 3, 5, 7, 10]
    end

    test "m11b5 formula" do
      assert Chord.formula(:m11b5) == [0, 2, 3, 5, 6, 10]
    end
  end

  describe "13ths" do
    test "C13 produces C-D-E-F-G-A-A#" do
      assert Chord.notes("C", :"13") == ["C", "D", "E", "F", "G", "A", "A#"]
    end

    test "C maj13 produces C-D-E-F-G-A-B" do
      assert Chord.notes("C", :maj13) == ["C", "D", "E", "F", "G", "A", "B"]
    end

    test "C min13 produces C-D-D#-F-G-A-A#" do
      assert Chord.notes("C", :min13) == ["C", "D", "D#", "F", "G", "A", "A#"]
    end

    test "C 13b9 produces C-C#-E-F-G-A-A#" do
      assert Chord.notes("C", :"13b9") == ["C", "C#", "E", "F", "G", "A", "A#"]
    end

    test "13 formula" do
      assert Chord.formula(:"13") == [0, 2, 4, 5, 7, 9, 10]
    end

    test "maj13 formula" do
      assert Chord.formula(:maj13) == [0, 2, 4, 5, 7, 9, 11]
    end

    test "min13 formula" do
      assert Chord.formula(:min13) == [0, 2, 3, 5, 7, 9, 10]
    end

    test "13b9 formula" do
      assert Chord.formula(:"13b9") == [0, 1, 4, 5, 7, 9, 10]
    end
  end

  describe "suspended extended" do
    test "C sus9 produces C-D-F-G-A#" do
      assert Chord.notes("C", :sus9) == ["C", "D", "F", "G", "A#"]
    end

    test "C susb9 produces C-C#-F-G-A#" do
      assert Chord.notes("C", :susb9) == ["C", "C#", "F", "G", "A#"]
    end

    test "C sus13 produces C-F-G-A-A#" do
      assert Chord.notes("C", :sus13) == ["C", "F", "G", "A", "A#"]
    end

    test "sus9 formula" do
      assert Chord.formula(:sus9) == [0, 2, 5, 7, 10]
    end

    test "susb9 formula" do
      assert Chord.formula(:susb9) == [0, 1, 5, 7, 10]
    end

    test "sus13 formula" do
      assert Chord.formula(:sus13) == [0, 5, 7, 9, 10]
    end
  end

  describe "minor/dim variations" do
    test "C min7b13 produces C-D#-G-G#-A#" do
      assert Chord.notes("C", :min7b13) == ["C", "D#", "G", "G#", "A#"]
    end

    test "C dim7b13 produces C-D#-F#-G#-A" do
      assert Chord.notes("C", :dim7b13) == ["C", "D#", "F#", "G#", "A"]
    end

    test "min7b13 formula" do
      assert Chord.formula(:min7b13) == [0, 3, 7, 8, 10]
    end

    test "dim7b13 formula" do
      assert Chord.formula(:dim7b13) == [0, 3, 6, 8, 9]
    end
  end

  describe "available_qualities/0" do
    test "returns 47 qualities" do
      qualities = Chord.available_qualities()
      assert length(qualities) == 47
    end

    test "includes all new qualities" do
      qualities = Chord.available_qualities()

      for q <- [
            :maj6,
            :min6,
            :add9,
            :m_add9,
            :maj6_9,
            :min6_9,
            :"9",
            :maj9,
            :min9,
            :"7b9",
            :"7#9",
            :"9#5",
            :"9b5",
            :"7b5",
            :"7sus4",
            :dim_maj7,
            :"maj7#11",
            :"7#11",
            :"7b13",
            :"7b9b13",
            :"11",
            :maj11,
            :min11,
            :m11b5,
            :"13",
            :maj13,
            :min13,
            :"13b9",
            :sus9,
            :susb9,
            :sus13,
            :min7b13,
            :dim7b13
          ] do
        assert q in qualities, "Expected #{inspect(q)} to be in available_qualities"
      end
    end
  end

  describe "grouped_qualities/0" do
    test "returns 8 groups" do
      groups = Chord.grouped_qualities()
      assert length(groups) == 8
    end

    test "Triads group" do
      groups = Chord.grouped_qualities()
      {"Triads", triads} = Enum.find(groups, fn {name, _} -> name == "Triads" end)
      assert triads == [:major, :minor, :dim, :aug, :sus2, :sus4]
    end

    test "Sixths group" do
      groups = Chord.grouped_qualities()
      {"Sixths", sixths} = Enum.find(groups, fn {name, _} -> name == "Sixths" end)
      assert sixths == [:maj6, :min6, :maj6_9, :min6_9]
    end

    test "Added tones group" do
      groups = Chord.grouped_qualities()
      {"Added tones", added} = Enum.find(groups, fn {name, _} -> name == "Added tones" end)
      assert added == [:add9, :m_add9]
    end

    test "Sevenths group" do
      groups = Chord.grouped_qualities()
      {"Sevenths", sevenths} = Enum.find(groups, fn {name, _} -> name == "Sevenths" end)

      assert sevenths == [
               :"7",
               :maj7,
               :min7,
               :dim7,
               :m7b5,
               :min_maj7,
               :aug_maj7,
               :aug7,
               :"7sus4",
               :dim_maj7
             ]
    end

    test "Ninths group" do
      groups = Chord.grouped_qualities()
      {"Ninths", ninths} = Enum.find(groups, fn {name, _} -> name == "Ninths" end)

      assert ninths == [
               :"9",
               :maj9,
               :min9,
               :"7b9",
               :"7#9",
               :"9#5",
               :"9b5",
               :"7b5"
             ]
    end

    test "Elevenths group" do
      groups = Chord.grouped_qualities()
      {"Elevenths", elevenths} = Enum.find(groups, fn {name, _} -> name == "Elevenths" end)

      assert elevenths == [
               :"11",
               :maj11,
               :min11,
               :m11b5,
               :"maj7#11",
               :"7#11"
             ]
    end

    test "Thirteenths group" do
      groups = Chord.grouped_qualities()
      {"Thirteenths", thirteenths} = Enum.find(groups, fn {name, _} -> name == "Thirteenths" end)

      assert thirteenths == [
               :"13",
               :maj13,
               :min13,
               :"13b9"
             ]
    end

    test "Suspended (extended) group" do
      groups = Chord.grouped_qualities()

      {"Suspended (extended)", suspended} =
        Enum.find(groups, fn {name, _} -> name == "Suspended (extended)" end)

      assert suspended == [
               :sus9,
               :susb9,
               :sus13,
               :"7b13",
               :"7b9b13",
               :min7b13,
               :dim7b13
             ]
    end
  end
end
