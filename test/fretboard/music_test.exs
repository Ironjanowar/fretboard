defmodule Fretboard.MusicTest do
  use ExUnit.Case, async: true

  alias Fretboard.Music
  alias Fretboard.Music.Scale

  describe "standard_tuning/0" do
    test "returns standard guitar tuning" do
      assert Music.standard_tuning() == ["E", "A", "D", "G", "B", "E"]
    end
  end

  describe "available_qualities/0" do
    test "delegates to Chord and returns all 47 qualities" do
      qualities = Music.available_qualities()
      assert length(qualities) == 47
      assert :major in qualities
      assert :"7" in qualities
    end
  end

  describe "grouped_qualities/0" do
    test "returns triads and sevenths groups" do
      groups = Music.grouped_qualities()
      assert {"Triads", triads} = List.keyfind(groups, "Triads", 0)
      assert :major in triads

      assert {"Sevenths", sevenths} = List.keyfind(groups, "Sevenths", 0)
      assert :"7" in sevenths
    end
  end

  describe "chord_label/2" do
    test "formats root and quality into short label" do
      assert Music.chord_label("C", :major) == "Cmaj"
      assert Music.chord_label("A", :minor) == "Amin"
      assert Music.chord_label("G", :"7") == "G7"
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
      first_string = Enum.at(data, 0)
      fret_0 = Enum.at(first_string, 0)
      assert "Cmaj" in fret_0.chords
    end

    test "notes not in any chord have empty chords list" do
      active = [%{root: "C", quality: :major}]
      data = Music.fretboard_data(Music.standard_tuning(), active)
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
      first_string = Enum.at(data, 0)
      fret_0 = Enum.at(first_string, 0)
      assert "Cmaj" in fret_0.chords
      assert "Amin" in fret_0.chords
    end

    test "works with seventh chords" do
      active = [%{root: "C", quality: :"7"}]
      data = Music.fretboard_data(Music.standard_tuning(), active)
      first_string = Enum.at(data, 0)
      fret_0 = Enum.at(first_string, 0)
      # E is in C7 (C, E, G, A#)
      assert "C7" in fret_0.chords
    end

    test "works with diminished chords" do
      active = [%{root: "A", quality: :dim}]
      data = Music.fretboard_data(Music.standard_tuning(), active)
      # String 3 (G), fret 1 = G# → not in Adim (A, C, D#)
      string_3 = Enum.at(data, 3)
      fret_1 = Enum.at(string_3, 1)
      assert fret_1.chords == []
    end
  end

  describe "notes_with_intervals/2" do
    test "delegates to Chord.notes_with_intervals/2" do
      assert Music.notes_with_intervals("C", :major) == [
               {"C", "Root"},
               {"E", "Major 3rd"},
               {"G", "Perfect 5th"}
             ]
    end
  end

  describe "diatonic_chords/2" do
    test "delegates to Scale and returns 7 chords" do
      chords = Music.diatonic_chords("C", :major)
      assert length(chords) == 7
      assert Enum.at(chords, 0) == %{root: "C", quality: :major}
    end
  end

  describe "available_scale_types/0" do
    test "delegates to Scale" do
      types = Music.available_scale_types()
      assert :major in types
      assert :minor in types
    end
  end

  describe "scale_label/1" do
    test "delegates to Scale" do
      assert Music.scale_label(:major) == "Major"
      assert Music.scale_label(:minor) == "Minor"
    end
  end

  describe "instruments/0" do
    test "returns 4 instrument tuples" do
      instruments = Music.instruments()
      assert length(instruments) == 4
    end

    test "includes guitar tuple" do
      assert {:guitar, "Guitar"} in Music.instruments()
    end

    test "includes bass_4 tuple" do
      assert {:bass_4, "Bass (4-string)"} in Music.instruments()
    end

    test "includes bass_5 tuple" do
      assert {:bass_5, "Bass (5-string)"} in Music.instruments()
    end

    test "includes ukelele tuple" do
      assert {:ukelele, "Ukulele"} in Music.instruments()
    end
  end

  describe "instrument/1" do
    test "returns guitar map with correct keys" do
      guitar = Music.instrument(:guitar)
      assert guitar.name == "Guitar"
      assert guitar.strings == 6
      assert guitar.standard_tuning == ["E", "A", "D", "G", "B", "E"]
      assert guitar.frets == 24
      assert is_list(guitar.presets)
      assert length(guitar.presets) == 9
    end

    test "returns bass_4 map with correct keys" do
      bass_4 = Music.instrument(:bass_4)
      assert bass_4.name == "Bass (4-string)"
      assert bass_4.strings == 4
      assert bass_4.standard_tuning == ["E", "A", "D", "G"]
      assert bass_4.frets == 24
      assert is_list(bass_4.presets)
      assert length(bass_4.presets) == 3
    end

    test "returns bass_5 map with correct keys" do
      bass_5 = Music.instrument(:bass_5)
      assert bass_5.name == "Bass (5-string)"
      assert bass_5.strings == 5
      assert bass_5.standard_tuning == ["B", "E", "A", "D", "G"]
      assert bass_5.frets == 24
      assert is_list(bass_5.presets)
      assert length(bass_5.presets) == 3
    end

    test "returns ukelele map with correct keys" do
      ukelele = Music.instrument(:ukelele)
      assert ukelele.name == "Ukulele"
      assert ukelele.strings == 4
      assert ukelele.standard_tuning == ["G", "C", "E", "A"]
      assert ukelele.frets == 24
      assert is_list(ukelele.presets)
      assert length(ukelele.presets) == 5
    end
  end

  describe "instrument_strings/1" do
    test "returns 6 for guitar" do
      assert Music.instrument_strings(:guitar) == 6
    end

    test "returns 4 for bass_4" do
      assert Music.instrument_strings(:bass_4) == 4
    end

    test "returns 4 for ukelele" do
      assert Music.instrument_strings(:ukelele) == 4
    end
  end

  describe "instrument_standard_tuning/1" do
    test "returns E A D G for bass_4" do
      assert Music.instrument_standard_tuning(:bass_4) == ["E", "A", "D", "G"]
    end

    test "returns B E A D G for bass_5" do
      assert Music.instrument_standard_tuning(:bass_5) == ["B", "E", "A", "D", "G"]
    end

    test "returns G C E A for ukelele" do
      assert Music.instrument_standard_tuning(:ukelele) == ["G", "C", "E", "A"]
    end
  end

  describe "instrument_tuning_presets/1" do
    test "returns 9 guitar presets, same as tuning_presets/0" do
      presets = Music.instrument_tuning_presets(:guitar)
      assert length(presets) == 9
      assert presets == Music.tuning_presets()
    end

    test "returns 3 bass_4 presets" do
      presets = Music.instrument_tuning_presets(:bass_4)
      assert length(presets) == 3
    end

    test "returns 5 ukelele presets" do
      presets = Music.instrument_tuning_presets(:ukelele)
      assert length(presets) == 5
    end
  end

  describe "instrument_preset_names/1" do
    test "returns guitar preset names, same as tuning_preset_names/0" do
      names = Music.instrument_preset_names(:guitar)
      assert names == Music.tuning_preset_names()
    end

    test "returns bass_4 preset names" do
      assert Music.instrument_preset_names(:bass_4) == ["Standard", "Drop D", "Half Step Down"]
    end

    test "returns ukelele preset names" do
      assert Music.instrument_preset_names(:ukelele) == [
               "Standard",
               "Low G",
               "D tuning",
               "Baritone",
               "Half Step Down"
             ]
    end
  end

  describe "backward compatibility — tuning_presets/0" do
    test "still returns the 9 guitar presets" do
      presets = Music.tuning_presets()
      assert length(presets) == 9
      assert presets == Music.instrument_tuning_presets(:guitar)
    end
  end

  describe "backward compatibility — tuning_preset_names/0" do
    test "still returns the 9 guitar preset names" do
      names = Music.tuning_preset_names()
      assert length(names) == 9
      assert names == Music.instrument_preset_names(:guitar)
    end
  end

  describe "available_progressions/0" do
    test "delegates to Progression and returns non-empty list" do
      progressions = Music.available_progressions()
      assert is_list(progressions)
      assert progressions != []
      assert :pop_i_v_vi_iv in progressions
    end
  end

  describe "grouped_progressions/0" do
    test "delegates to Progression and returns grouped categories" do
      groups = Music.grouped_progressions()
      assert is_list(groups)
      names = Enum.map(groups, &elem(&1, 0))
      assert "Famous / Classic" in names
      assert "Jazz / Sophisticated" in names
    end
  end

  describe "progression/1" do
    test "returns progression map for valid id" do
      prog = Music.progression(:pop_i_v_vi_iv)
      assert prog.id == :pop_i_v_vi_iv
      assert prog.name =~ "I-V-vi-IV"
    end

    test "returns nil for invalid id" do
      assert Music.progression(:nonexistent) == nil
    end
  end

  describe "progression_label/1" do
    test "returns display name" do
      label = Music.progression_label(:pop_i_v_vi_iv)
      assert is_binary(label)
      assert label =~ "I-V-vi-IV"
    end
  end

  describe "progression_chords/2" do
    test "delegates to Progression and resolves chords" do
      chords = Music.progression_chords("C", :pop_i_v_vi_iv)

      assert [
               %{root: "C", quality: :major},
               %{root: "G", quality: :major},
               %{root: "A", quality: :minor},
               %{root: "F", quality: :major}
             ] =
               chords
    end

    test "works with minor key progression" do
      chords = Music.progression_chords("A", :andalusian_cadence)
      assert [%{root: "A", quality: :minor} | _] = chords
    end
  end

  describe "suggest_keys/1" do
    test "delegates to Scale.suggest_keys/1" do
      chords = [
        %{root: "C", quality: :major},
        %{root: "F", quality: :major},
        %{root: "G", quality: :major}
      ]

      assert Music.suggest_keys(chords) == Scale.suggest_keys(chords)
    end
  end

  describe "suggest_multi_keys/1" do
    test "delegates to Scale.suggest_multi_keys/1" do
      chords = [
        %{root: "C", quality: :major},
        %{root: "F", quality: :major},
        %{root: "G", quality: :major},
        %{root: "D", quality: :major},
        %{root: "A", quality: :major}
      ]

      assert Music.suggest_multi_keys(chords) == Scale.suggest_multi_keys(chords)
    end
  end

  describe "filter_marked_notes/2" do
    test "filter_marked_notes returns empty map for empty input" do
      assert Music.filter_marked_notes(%{}, 6) == %{}
    end

    test "filter_marked_notes returns the same map when all strings are within string_count" do
      marked = %{0 => 3, 1 => 5, 2 => 7, 3 => 9, 4 => 12, 5 => 24}

      assert Music.filter_marked_notes(marked, 6) == marked
    end

    test "filter_marked_notes filters out entries with string index >= string_count" do
      marked = %{0 => 3, 4 => 12, 5 => 24}

      # string_count of 4 keeps only strings 0-3
      assert Music.filter_marked_notes(marked, 4) == %{0 => 3}
    end

    test "filter_marked_notes keeps entries with string index 0 (boundary)" do
      marked = %{0 => 3}

      assert Music.filter_marked_notes(marked, 4) == %{0 => 3}
    end

    test "filter_marked_notes filters out entries with string index == string_count (boundary)" do
      # string index 4 equals string_count 4, so it should be excluded
      marked = %{3 => 9, 4 => 12}

      assert Music.filter_marked_notes(marked, 4) == %{3 => 9}
    end

    test "filter_marked_notes works with mixed valid and invalid entries" do
      # Guitar has 6 strings (indices 0-5); bass_4 has 4 strings (indices 0-3)
      marked = %{0 => 3, 3 => 9, 4 => 12, 5 => 24}

      assert Music.filter_marked_notes(marked, 4) == %{0 => 3, 3 => 9}
    end
  end
end
