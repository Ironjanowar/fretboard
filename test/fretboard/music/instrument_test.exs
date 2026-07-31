defmodule Fretboard.Music.InstrumentTest do
  use ExUnit.Case, async: true

  alias Fretboard.Music.Instrument

  describe "instruments/0" do
    test "returns a list of 3 instrument tuples" do
      instruments = Instrument.instruments()

      assert is_list(instruments)
      assert length(instruments) == 3
    end

    test "includes guitar tuple" do
      assert {:guitar, "Guitar"} in Instrument.instruments()
    end

    test "includes bass_4 tuple" do
      assert {:bass_4, "Bass (4-string)"} in Instrument.instruments()
    end

    test "includes bass_5 tuple" do
      assert {:bass_5, "Bass (5-string)"} in Instrument.instruments()
    end
  end

  describe "instrument/1 — guitar" do
    test "returns a map" do
      assert is_map(Instrument.instrument(:guitar))
    end

    test "has name 'Guitar'" do
      assert Instrument.instrument(:guitar).name == "Guitar"
    end

    test "has 6 strings" do
      assert Instrument.instrument(:guitar).strings == 6
    end

    test "has standard tuning E A D G B E" do
      assert Instrument.instrument(:guitar).standard_tuning == ["E", "A", "D", "G", "B", "E"]
    end

    test "has 9 tuning presets" do
      guitar = Instrument.instrument(:guitar)
      assert is_list(guitar.presets)
      assert length(guitar.presets) == 9
    end

    test "has 24 frets" do
      assert Instrument.instrument(:guitar).frets == 24
    end
  end

  describe "instrument/1 — bass_4" do
    test "returns a map" do
      assert is_map(Instrument.instrument(:bass_4))
    end

    test "has name 'Bass (4-string)'" do
      assert Instrument.instrument(:bass_4).name == "Bass (4-string)"
    end

    test "has 4 strings" do
      assert Instrument.instrument(:bass_4).strings == 4
    end

    test "has standard tuning E A D G" do
      assert Instrument.instrument(:bass_4).standard_tuning == ["E", "A", "D", "G"]
    end

    test "has 3 tuning presets" do
      bass_4 = Instrument.instrument(:bass_4)
      assert is_list(bass_4.presets)
      assert length(bass_4.presets) == 3
    end

    test "has 24 frets" do
      assert Instrument.instrument(:bass_4).frets == 24
    end
  end

  describe "instrument/1 — bass_5" do
    test "returns a map" do
      assert is_map(Instrument.instrument(:bass_5))
    end

    test "has name 'Bass (5-string)'" do
      assert Instrument.instrument(:bass_5).name == "Bass (5-string)"
    end

    test "has 5 strings" do
      assert Instrument.instrument(:bass_5).strings == 5
    end

    test "has standard tuning B E A D G" do
      assert Instrument.instrument(:bass_5).standard_tuning == ["B", "E", "A", "D", "G"]
    end

    test "has 3 tuning presets" do
      bass_5 = Instrument.instrument(:bass_5)
      assert is_list(bass_5.presets)
      assert length(bass_5.presets) == 3
    end

    test "has 24 frets" do
      assert Instrument.instrument(:bass_5).frets == 24
    end
  end

  describe "instrument/1 — invalid instrument" do
    test "returns nil for unknown instrument" do
      assert is_nil(Instrument.instrument(:unknown))
    end
  end

  describe "instrument_strings/1" do
    test "returns 6 for guitar" do
      assert Instrument.instrument_strings(:guitar) == 6
    end

    test "returns 4 for bass_4" do
      assert Instrument.instrument_strings(:bass_4) == 4
    end

    test "returns 5 for bass_5" do
      assert Instrument.instrument_strings(:bass_5) == 5
    end
  end

  describe "instrument_standard_tuning/1" do
    test "returns E A D G B E for guitar" do
      assert Instrument.instrument_standard_tuning(:guitar) == ["E", "A", "D", "G", "B", "E"]
    end

    test "returns E A D G for bass_4" do
      assert Instrument.instrument_standard_tuning(:bass_4) == ["E", "A", "D", "G"]
    end

    test "returns B E A D G for bass_5" do
      assert Instrument.instrument_standard_tuning(:bass_5) == ["B", "E", "A", "D", "G"]
    end
  end

  describe "instrument_tuning_presets/1" do
    test "returns 9 guitar presets" do
      presets = Instrument.instrument_tuning_presets(:guitar)
      assert length(presets) == 9
    end

    test "returns 3 bass_4 presets" do
      presets = Instrument.instrument_tuning_presets(:bass_4)
      assert length(presets) == 3
    end

    test "returns 3 bass_5 presets" do
      presets = Instrument.instrument_tuning_presets(:bass_5)
      assert length(presets) == 3
    end
  end

  describe "instrument_preset_names/1" do
    test "returns names for bass_4" do
      assert Instrument.instrument_preset_names(:bass_4) == [
               "Standard",
               "Drop D",
               "Half Step Down"
             ]
    end

    test "returns names for bass_5" do
      assert Instrument.instrument_preset_names(:bass_5) == [
               "Standard",
               "Half Step Down",
               "Drop A"
             ]
    end
  end

  describe "preset structure — all instruments" do
    test "guitar presets each have a name and 6 notes" do
      for {name, notes} <- Instrument.instrument_tuning_presets(:guitar) do
        assert is_binary(name)
        assert length(notes) == 6
        assert Enum.all?(notes, &is_binary/1)
      end
    end

    test "bass_4 presets each have a name and 4 notes" do
      for {name, notes} <- Instrument.instrument_tuning_presets(:bass_4) do
        assert is_binary(name)
        assert length(notes) == 4
        assert Enum.all?(notes, &is_binary/1)
      end
    end

    test "bass_5 presets each have a name and 5 notes" do
      for {name, notes} <- Instrument.instrument_tuning_presets(:bass_5) do
        assert is_binary(name)
        assert length(notes) == 5
        assert Enum.all?(notes, &is_binary/1)
      end
    end
  end

  describe "bass_4 preset values" do
    test "Standard is E A D G" do
      presets = Instrument.instrument_tuning_presets(:bass_4)
      assert {"Standard", ["E", "A", "D", "G"]} in presets
    end

    test "Drop D is D A D G" do
      presets = Instrument.instrument_tuning_presets(:bass_4)
      assert {"Drop D", ["D", "A", "D", "G"]} in presets
    end

    test "Half Step Down is D# G# C# F#" do
      presets = Instrument.instrument_tuning_presets(:bass_4)
      assert {"Half Step Down", ["D#", "G#", "C#", "F#"]} in presets
    end
  end

  describe "bass_5 preset values" do
    test "Standard is B E A D G" do
      presets = Instrument.instrument_tuning_presets(:bass_5)
      assert {"Standard", ["B", "E", "A", "D", "G"]} in presets
    end

    test "Half Step Down is A# D# G# C# F#" do
      presets = Instrument.instrument_tuning_presets(:bass_5)
      assert {"Half Step Down", ["A#", "D#", "G#", "C#", "F#"]} in presets
    end

    test "Drop A is A E A D G" do
      presets = Instrument.instrument_tuning_presets(:bass_5)
      assert {"Drop A", ["A", "E", "A", "D", "G"]} in presets
    end
  end
end
