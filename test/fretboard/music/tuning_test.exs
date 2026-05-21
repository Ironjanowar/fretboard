defmodule Fretboard.Music.TuningTest do
  use ExUnit.Case, async: true

  alias Fretboard.Music.Tuning

  describe "standard/0" do
    test "returns standard guitar tuning low to high" do
      assert Tuning.standard() == ["E", "A", "D", "G", "B", "E"]
    end
  end

  describe "note_for_string/2" do
    test "returns E for string 0 in standard tuning" do
      assert Tuning.note_for_string(Tuning.standard(), 0) == "E"
    end

    test "returns A for string 1 in standard tuning" do
      assert Tuning.note_for_string(Tuning.standard(), 1) == "A"
    end

    test "returns E for string 5 in standard tuning" do
      assert Tuning.note_for_string(Tuning.standard(), 5) == "E"
    end

    test "works with custom tuning" do
      drop_d = ["D", "A", "D", "G", "B", "E"]
      assert Tuning.note_for_string(drop_d, 0) == "D"
    end
  end
end
