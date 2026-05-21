defmodule Fretboard.Music.ChordTest do
  use ExUnit.Case, async: true

  alias Fretboard.Music.Chord

  describe "available_qualities/0" do
    test "returns major and minor" do
      assert Chord.available_qualities() == [:major, :minor]
    end
  end

  describe "formula/1" do
    test "returns major formula" do
      assert Chord.formula(:major) == [0, 4, 7]
    end

    test "returns minor formula" do
      assert Chord.formula(:minor) == [0, 3, 7]
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
  end
end
