defmodule Fretboard.Music.ProgressionTest do
  use ExUnit.Case, async: true

  alias Fretboard.Music.Progression

  describe "available_progressions/0" do
    test "returns a non-empty list of atoms" do
      ids = Progression.available_progressions()

      assert is_list(ids)
      refute ids == []
      assert Enum.all?(ids, &is_atom/1)
    end

    test "includes well-known progressions" do
      ids = Progression.available_progressions()

      assert :pop_i_v_vi_iv in ids
      assert :jazz_ii_v_i in ids
      assert :andalusian_cadence in ids
    end

    test "returns a deterministic order" do
      assert Progression.available_progressions() == Progression.available_progressions()
    end
  end

  describe "grouped_progressions/0" do
    test "returns a list of {category, progressions} tuples" do
      groups = Progression.grouped_progressions()

      assert is_list(groups)

      for {category, progressions} <- groups do
        assert is_binary(category)
        assert is_list(progressions)
      end
    end

    test "contains all four categories" do
      group_names = Progression.grouped_progressions() |> Enum.map(&elem(&1, 0))

      assert "Famous / Classic" in group_names
      assert "Curious / Interesting" in group_names
      assert "Exotic / World" in group_names
      assert "Jazz / Sophisticated" in group_names
    end

    test "every progression appears in exactly one group" do
      all_from_groups =
        Progression.grouped_progressions()
        |> Enum.flat_map(fn {_, progs} -> progs end)

      all_progressions = Progression.all()

      assert length(all_from_groups) == length(all_progressions)
      assert Enum.sort(all_from_groups) == Enum.sort(all_progressions)
    end
  end

  describe "progression/1" do
    test "returns a map with correct keys for a known id" do
      prog = Progression.progression(:pop_i_v_vi_iv)

      assert is_map(prog)
      assert prog.id == :pop_i_v_vi_iv
      assert Map.has_key?(prog, :name)
      assert Map.has_key?(prog, :degrees)
      assert Map.has_key?(prog, :scale_type)
      assert Map.has_key?(prog, :category)
    end

    test "returns nil for an unknown id" do
      assert Progression.progression(:nonexistent_progression) == nil
    end

    test "degrees are well-formed maps" do
      prog = Progression.progression(:jazz_ii_v_i)

      for degree <- prog.degrees do
        assert Map.has_key?(degree, :degree)
        assert Map.has_key?(degree, :accidental)
        assert Map.has_key?(degree, :quality)
        assert is_integer(degree.degree)
        assert is_integer(degree.accidental)
      end
    end
  end

  describe "progression_label/1" do
    test "returns the display name for a known id" do
      assert Progression.progression_label(:pop_i_v_vi_iv) == "Pop: I-V-vi-IV"
    end

    test "returns the display name for an andalusian cadence" do
      assert Progression.progression_label(:andalusian_cadence) ==
               "Flamenco: Andalusian Cadence (i-bVII-bVI-V)"
    end

    test "returns nil for an unknown id" do
      assert Progression.progression_label(:nonexistent_progression) == nil
    end
  end

  describe "progression_chords/2" do
    test "diatonic-only progression in C major resolves to correct chords" do
      chords = Progression.progression_chords("C", :pop_i_v_vi_iv)

      assert chords == [
               %{root: "C", quality: :major},
               %{root: "G", quality: :major},
               %{root: "A", quality: :minor},
               %{root: "F", quality: :major}
             ]
    end

    test "minor-key diatonic progression in A minor resolves to correct chords" do
      chords = Progression.progression_chords("A", :andalusian_cadence)

      assert chords == [
               %{root: "A", quality: :minor},
               %{root: "G", quality: :major},
               %{root: "F", quality: :major},
               %{root: "E", quality: :major}
             ]
    end

    test "explicit qualities are respected for jazz ii-V-I in C" do
      chords = Progression.progression_chords("C", :jazz_ii_v_i)

      assert chords == [
               %{root: "D", quality: :min7},
               %{root: "G", quality: :"7"},
               %{root: "C", quality: :maj7}
             ]
    end

    test "altered degree in major key infers major quality for bVII" do
      # :rock_i_bvii_iv — I-bVII-IV in C major
      # degree 7 of C major is B; accidental -1 -> A#; inferred quality :major
      chords = Progression.progression_chords("C", :rock_i_bvii_iv)

      assert chords == [
               %{root: "C", quality: :major},
               %{root: "A#", quality: :major},
               %{root: "F", quality: :major}
             ]
    end

    test "minor pop progression i-bVI-bIII-bVII in A minor uses diatonic degrees" do
      # After fix: in A minor, degrees 6,3,7 are already bVI,bIII,bVII (accidental 0)
      chords = Progression.progression_chords("A", :minor_pop_i_bvi_biii_bvii)

      assert chords == [
               %{root: "A", quality: :minor},
               %{root: "F", quality: :major},
               %{root: "C", quality: :major},
               %{root: "G", quality: :major}
             ]
    end

    test "returns a list of chord maps with root and quality keys" do
      chords = Progression.progression_chords("C", :classic_i_iv_v)

      assert is_list(chords)

      for chord <- chords do
        assert Map.has_key?(chord, :root)
        assert Map.has_key?(chord, :quality)
        assert is_binary(chord.root)
        assert is_atom(chord.quality)
      end
    end

    test "respects the number of degrees in the progression" do
      # 12-bar blues has 12 degrees
      chords = Progression.progression_chords("A", :blues_12_bar)
      assert length(chords) == 12
    end

    test "flamenco phrygian dominant in E has major tonic and correct bII/bIII" do
      # Phrygian dominant tonic is MAJOR (not minor).
      # Degree 2 is already bII in the scale (accidental 0), degree 3 needs accidental -1
      # to flatten the major 3rd to bIII.
      chords = Progression.progression_chords("E", :flamenco_phrygian_dominant)

      assert chords == [
               %{root: "E", quality: :major},
               %{root: "F", quality: :major},
               %{root: "G", quality: :major},
               %{root: "F", quality: :major}
             ]
    end

    test "middle eastern hijaz in D has major tonic and correct bII/bIII" do
      chords = Progression.progression_chords("D", :middle_eastern_hijaz)

      assert chords == [
               %{root: "D", quality: :major},
               %{root: "D#", quality: :major},
               %{root: "F", quality: :major},
               %{root: "G", quality: :minor}
             ]
    end

    test "klezmer freygish in D has major tonic and correct bII/III/VII" do
      chords = Progression.progression_chords("D", :klezmer_freygish)

      assert chords == [
               %{root: "D", quality: :major},
               %{root: "D#", quality: :major},
               %{root: "F", quality: :major},
               %{root: "C", quality: :major}
             ]
    end
  end

  describe "accidental validity" do
    test "all progressions have accidentals in the valid range [-2, 2]" do
      for prog <- Progression.all() do
        for degree <- prog.degrees do
          assert degree.accidental in [-2, -1, 0, 1, 2],
                 "progression #{prog.id} degree #{degree.degree} has invalid accidental #{degree.accidental}"
        end
      end
    end

    test "minor-key progressions do not flatten already-flat degrees 3, 6, 7" do
      # In a minor key, degrees 3, 6, 7 are already "flat" relative to the
      # parallel major. They must not carry an extra accidental: -1.
      for prog <- Progression.all(), prog.scale_type == :minor do
        for degree <- prog.degrees, degree.degree in [3, 6, 7] do
          assert degree.accidental == 0,
                 "minor progression #{prog.id} flattens degree #{degree.degree} " <>
                   "(accidental #{degree.accidental}) but minor degrees 3/6/7 are already flat"
        end
      end
    end

    test "major-key progressions may flatten degrees 3, 6, 7 (modal interchange)" do
      # :rock_i_bvii_iv flattens degree 7 in major — this is correct (bVII)
      prog = Progression.progression(:rock_i_bvii_iv)
      degree_7 = Enum.find(prog.degrees, &(&1.degree == 7))
      assert degree_7.accidental == -1
    end

    test "phrygian_dominant progressions use correct accidentals for degrees 2 and 3" do
      # In phrygian dominant, degree 2 is already bII (1 semitone from root), so it
      # needs accidental: 0 (no extra flat). Degree 3 is a major 3rd (e.g. G# in E),
      # so to get the bIII chord it needs accidental: -1.
      phrygian_dom_progs =
        for prog <- Progression.all(), Map.get(prog, :scale_type) == :phrygian_dominant, do: prog

      assert length(phrygian_dom_progs) >= 3,
             "expected at least 3 phrygian_dominant progressions, " <>
               "got #{length(phrygian_dom_progs)}"

      for prog <- phrygian_dom_progs do
        degree_2 = Enum.find(prog.degrees, &(&1.degree == 2))
        degree_3 = Enum.find(prog.degrees, &(&1.degree == 3))

        assert degree_2.accidental == 0,
               "phrygian_dominant progression #{prog.id} degree 2 should have " <>
                 "accidental 0 (already bII in the scale), got #{degree_2.accidental}"

        assert degree_3.accidental == -1,
               "phrygian_dominant progression #{prog.id} degree 3 should have " <>
                 "accidental -1 (diatonic is major 3rd, flatten to get bIII), " <>
                 "got #{degree_3.accidental}"
      end
    end
  end
end
