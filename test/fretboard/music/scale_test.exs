defmodule Fretboard.Music.ScaleTest do
  use ExUnit.Case, async: true

  alias Fretboard.Music.Scale

  describe "available_scale_types/0" do
    test "returns major and minor" do
      types = Scale.available_scale_types()
      assert :major in types
      assert :minor in types
      assert length(types) == 2
    end
  end

  describe "scale_notes/2" do
    test "C major returns all natural notes" do
      assert Scale.scale_notes("C", :major) == ["C", "D", "E", "F", "G", "A", "B"]
    end

    test "A minor returns all natural notes starting from A" do
      assert Scale.scale_notes("A", :minor) == ["A", "B", "C", "D", "E", "F", "G"]
    end

    test "G major includes F#" do
      assert Scale.scale_notes("G", :major) == ["G", "A", "B", "C", "D", "E", "F#"]
    end

    test "E major has four sharps" do
      assert Scale.scale_notes("E", :major) == ["E", "F#", "G#", "A", "B", "C#", "D#"]
    end

    test "D minor" do
      assert Scale.scale_notes("D", :minor) == ["D", "E", "F", "G", "A", "A#", "C"]
    end
  end

  describe "diatonic_chords/2" do
    test "C major diatonic chords have correct roots and qualities" do
      chords = Scale.diatonic_chords("C", :major)
      assert length(chords) == 7

      assert Enum.at(chords, 0) == %{root: "C", quality: :major}
      assert Enum.at(chords, 1) == %{root: "D", quality: :minor}
      assert Enum.at(chords, 2) == %{root: "E", quality: :minor}
      assert Enum.at(chords, 3) == %{root: "F", quality: :major}
      assert Enum.at(chords, 4) == %{root: "G", quality: :major}
      assert Enum.at(chords, 5) == %{root: "A", quality: :minor}
      assert Enum.at(chords, 6) == %{root: "B", quality: :dim}
    end

    test "A minor diatonic chords" do
      chords = Scale.diatonic_chords("A", :minor)
      assert length(chords) == 7

      assert Enum.at(chords, 0) == %{root: "A", quality: :minor}
      assert Enum.at(chords, 1) == %{root: "B", quality: :dim}
      assert Enum.at(chords, 2) == %{root: "C", quality: :major}
      assert Enum.at(chords, 3) == %{root: "D", quality: :minor}
      assert Enum.at(chords, 4) == %{root: "E", quality: :minor}
      assert Enum.at(chords, 5) == %{root: "F", quality: :major}
      assert Enum.at(chords, 6) == %{root: "G", quality: :major}
    end

    test "E major diatonic chords with sharps" do
      chords = Scale.diatonic_chords("E", :major)

      assert Enum.at(chords, 0) == %{root: "E", quality: :major}
      assert Enum.at(chords, 1) == %{root: "F#", quality: :minor}
      assert Enum.at(chords, 6) == %{root: "D#", quality: :dim}
    end
  end

  describe "scale_label/1" do
    test "returns Major for major" do
      assert Scale.scale_label(:major) == "Major"
    end

    test "returns Minor for minor" do
      assert Scale.scale_label(:minor) == "Minor"
    end
  end
end
