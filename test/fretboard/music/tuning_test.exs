defmodule Fretboard.Music.TuningTest do
  use ExUnit.Case, async: true

  alias Fretboard.Music.Tuning

  describe "standard/0" do
    test "returns standard guitar tuning low to high" do
      assert Tuning.standard() == ["E", "A", "D", "G", "B", "E"]
    end
  end

  describe "presets/0" do
    test "returns a list of named tuning presets" do
      presets = Tuning.presets()
      assert is_list(presets)
      assert length(presets) == 9

      {name, notes} = List.first(presets)
      assert name == "Standard"
      assert notes == ["E", "A", "D", "G", "B", "E"]
    end

    test "each preset has a name and 6 notes" do
      for {name, notes} <- Tuning.presets() do
        assert is_binary(name)
        assert length(notes) == 6
        assert Enum.all?(notes, &is_binary/1)
      end
    end

    test "includes Drop D preset" do
      presets = Tuning.presets()
      assert {"Drop D", ["D", "A", "D", "G", "B", "E"]} in presets
    end

    test "includes Open G preset" do
      presets = Tuning.presets()
      assert {"Open G", ["D", "G", "D", "G", "B", "D"]} in presets
    end
  end

  describe "preset_names/0" do
    test "returns just the preset names" do
      names = Tuning.preset_names()
      assert is_list(names)
      assert "Standard" in names
      assert "Drop D" in names
      assert length(names) == 9
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
