defmodule Fretboard.Music.ScaleTest do
  use ExUnit.Case, async: true

  alias Fretboard.Music.Scale
  alias Fretboard.Music.Chord
  alias Fretboard.Music.Note

  describe "available_scale_types/0" do
    test "returns all 15 scale types" do
      types = Scale.available_scale_types()
      assert length(types) == 15
      assert :major in types
      assert :minor in types
      assert :harmonic_minor in types
      assert :melodic_minor in types
      assert :pentatonic_major in types
      assert :pentatonic_minor in types
      assert :blues in types
      assert :dorian in types
      assert :phrygian in types
      assert :lydian in types
      assert :mixolydian in types
      assert :locrian in types
      assert :phrygian_dominant in types
      assert :whole_tone in types
      assert :chromatic in types
    end

    test "returns a deterministic order" do
      assert Scale.available_scale_types() == Scale.available_scale_types()
      assert hd(Scale.available_scale_types()) == :major
    end
  end

  describe "grouped_scale_types/0" do
    test "returns groups with correct structure" do
      groups = Scale.grouped_scale_types()
      assert is_list(groups)

      group_names = Enum.map(groups, &elem(&1, 0))
      assert "Standard" in group_names
      assert "Minor Variants" in group_names
      assert "Pentatonic" in group_names
      assert "Blues" in group_names
      assert "Modes" in group_names
      assert "Exotic" in group_names
      assert "Other" in group_names
    end

    test "Standard group contains major and minor" do
      {_, types} = Enum.find(Scale.grouped_scale_types(), fn {g, _} -> g == "Standard" end)
      assert types == [:major, :minor]
    end

    test "all scale types appear in exactly one group" do
      all_from_groups =
        Scale.grouped_scale_types()
        |> Enum.flat_map(&elem(&1, 1))

      assert Enum.sort(all_from_groups) == Enum.sort(Scale.available_scale_types())
      assert length(all_from_groups) == length(Scale.available_scale_types())
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

    test "A harmonic minor" do
      assert Scale.scale_notes("A", :harmonic_minor) == ["A", "B", "C", "D", "E", "F", "G#"]
    end

    test "C pentatonic major has 5 notes" do
      notes = Scale.scale_notes("C", :pentatonic_major)
      assert length(notes) == 5
      assert notes == ["C", "D", "E", "G", "A"]
    end

    test "A pentatonic minor has 5 notes" do
      notes = Scale.scale_notes("A", :pentatonic_minor)
      assert length(notes) == 5
      assert notes == ["A", "C", "D", "E", "G"]
    end

    test "C blues has 6 notes" do
      notes = Scale.scale_notes("C", :blues)
      assert length(notes) == 6
    end

    test "C chromatic has 12 notes" do
      notes = Scale.scale_notes("C", :chromatic)
      assert length(notes) == 12
    end

    test "C whole tone has 6 notes" do
      notes = Scale.scale_notes("C", :whole_tone)
      assert length(notes) == 6
      assert notes == ["C", "D", "E", "F#", "G#", "A#"]
    end
  end

  describe "infer_quality/2" do
    test "major triad when major 3rd and perfect 5th present" do
      # C in C major scale
      scale = MapSet.new([0, 2, 4, 5, 7, 9, 11])
      assert Scale.infer_quality(0, scale) == :major
    end

    test "minor triad when minor 3rd and perfect 5th present" do
      # D in C major scale
      scale = MapSet.new([0, 2, 4, 5, 7, 9, 11])
      assert Scale.infer_quality(2, scale) == :minor
    end

    test "diminished when minor 3rd and diminished 5th present" do
      # B in C major scale
      scale = MapSet.new([0, 2, 4, 5, 7, 9, 11])
      assert Scale.infer_quality(11, scale) == :dim
    end

    test "augmented when major 3rd and augmented 5th present" do
      # C in C whole tone scale
      scale = MapSet.new([0, 2, 4, 6, 8, 10])
      assert Scale.infer_quality(0, scale) == :aug
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

    test "A harmonic minor diatonic chords" do
      chords = Scale.diatonic_chords("A", :harmonic_minor)
      assert length(chords) == 7

      qualities = Enum.map(chords, & &1.quality)
      assert qualities == [:minor, :dim, :aug, :minor, :major, :major, :dim]
    end

    test "C pentatonic major diatonic chords" do
      chords = Scale.diatonic_chords("C", :pentatonic_major)
      assert length(chords) == 5
    end

    test "A pentatonic minor diatonic chords" do
      chords = Scale.diatonic_chords("A", :pentatonic_minor)
      assert length(chords) == 5
    end

    test "C blues diatonic chords" do
      chords = Scale.diatonic_chords("C", :blues)
      assert length(chords) == 6
    end

    test "C whole tone — all augmented" do
      chords = Scale.diatonic_chords("C", :whole_tone)
      assert length(chords) == 6
      assert Enum.all?(chords, fn c -> c.quality == :aug end)
    end
  end

  describe "infer_7th_quality/2" do
    test "C major degree 1 (root=0) → maj7" do
      scale = MapSet.new([0, 2, 4, 5, 7, 9, 11])
      assert Scale.infer_7th_quality(0, scale) == :maj7
    end

    test "C major degree 5 (root=7) → dominant 7" do
      scale = MapSet.new([0, 2, 4, 5, 7, 9, 11])
      assert Scale.infer_7th_quality(7, scale) == :"7"
    end

    test "C major degree 7 (root=11) → m7b5" do
      scale = MapSet.new([0, 2, 4, 5, 7, 9, 11])
      assert Scale.infer_7th_quality(11, scale) == :m7b5
    end

    test "C major degree 2 (root=2) → min7" do
      scale = MapSet.new([0, 2, 4, 5, 7, 9, 11])
      assert Scale.infer_7th_quality(2, scale) == :min7
    end

    test "A harmonic minor degree 1 (root=0) → min_maj7" do
      scale = MapSet.new([0, 2, 3, 5, 7, 8, 11])
      assert Scale.infer_7th_quality(0, scale) == :min_maj7
    end

    test "A harmonic minor degree 3 (root=3) → aug_maj7" do
      scale = MapSet.new([0, 2, 3, 5, 7, 8, 11])
      assert Scale.infer_7th_quality(3, scale) == :aug_maj7
    end

    test "C whole tone degree 1 (root=0) → aug7" do
      scale = MapSet.new([0, 2, 4, 6, 8, 10])
      assert Scale.infer_7th_quality(0, scale) == :aug7
    end

    test "falls back to triad when no 7th interval available (C pentatonic major degree 1)" do
      scale = MapSet.new([0, 2, 4, 7, 9])
      assert Scale.infer_7th_quality(0, scale) == :major
    end
  end

  describe "diatonic_chords/3" do
    test "C major :seventh → 7 chords with 7th qualities" do
      chords = Scale.diatonic_chords("C", :major, :seventh)
      assert length(chords) == 7

      assert Enum.at(chords, 0) == %{root: "C", quality: :maj7}
      assert Enum.at(chords, 1) == %{root: "D", quality: :min7}
      assert Enum.at(chords, 2) == %{root: "E", quality: :min7}
      assert Enum.at(chords, 3) == %{root: "F", quality: :maj7}
      assert Enum.at(chords, 4) == %{root: "G", quality: :"7"}
      assert Enum.at(chords, 5) == %{root: "A", quality: :min7}
      assert Enum.at(chords, 6) == %{root: "B", quality: :m7b5}
    end

    test "A minor :seventh → 7 chords" do
      chords = Scale.diatonic_chords("A", :minor, :seventh)
      assert length(chords) == 7

      assert Enum.at(chords, 0) == %{root: "A", quality: :min7}
      assert Enum.at(chords, 1) == %{root: "B", quality: :m7b5}
      assert Enum.at(chords, 2) == %{root: "C", quality: :maj7}
      assert Enum.at(chords, 3) == %{root: "D", quality: :min7}
      assert Enum.at(chords, 4) == %{root: "E", quality: :min7}
      assert Enum.at(chords, 5) == %{root: "F", quality: :maj7}
      assert Enum.at(chords, 6) == %{root: "G", quality: :"7"}
    end

    test "A harmonic_minor :seventh → 7 chords" do
      chords = Scale.diatonic_chords("A", :harmonic_minor, :seventh)
      assert length(chords) == 7

      assert Enum.at(chords, 0) == %{root: "A", quality: :min_maj7}
      assert Enum.at(chords, 1) == %{root: "B", quality: :dim7}
      assert Enum.at(chords, 2) == %{root: "C", quality: :aug_maj7}
      assert Enum.at(chords, 3) == %{root: "D", quality: :min7}
      assert Enum.at(chords, 4) == %{root: "E", quality: :"7"}
      assert Enum.at(chords, 5) == %{root: "F", quality: :maj7}
      assert Enum.at(chords, 6) == %{root: "G#", quality: :dim7}
    end

    test "C major :triad → same as default diatonic_chords/2" do
      seventh = Scale.diatonic_chords("C", :major, :triad)
      default = Scale.diatonic_chords("C", :major)
      assert seventh == default
    end

    test "C major default (no mode arg) → backward compatible, triads only" do
      chords = Scale.diatonic_chords("C", :major)
      assert length(chords) == 7
      assert Enum.at(chords, 0) == %{root: "C", quality: :major}
      assert Enum.at(chords, 4) == %{root: "G", quality: :major}
      assert Enum.at(chords, 6) == %{root: "B", quality: :dim}
    end

    test "C pentatonic_major :seventh → 5 chords, falls back to triads" do
      chords = Scale.diatonic_chords("C", :pentatonic_major, :seventh)
      assert length(chords) == 5
    end
  end

  describe "scale_label/1" do
    test "returns Major for major" do
      assert Scale.scale_label(:major) == "Major"
    end

    test "returns Minor for minor" do
      assert Scale.scale_label(:minor) == "Minor"
    end

    test "returns labels for all scale types" do
      for st <- Scale.available_scale_types() do
        label = Scale.scale_label(st)
        assert is_binary(label)
        assert label != ""
      end
    end
  end

  describe "suggest_keys/1" do
    # Helper: build a chord map from root + quality.
    defp chord(root, quality), do: %{root: root, quality: quality}

    # Helper: find a result by tonic + scale_type.
    defp find_result(results, tonic, scale_type) do
      Enum.find(results, &(&1.tonic == tonic and &1.scale_type == scale_type))
    end

    test "C-F-G major triads → top results have score 3/3 and C major is present" do
      results = Scale.suggest_keys([chord("C", :major), chord("F", :major), chord("G", :major)])

      # Top results should all be perfect 3/3.
      top = Enum.take(results, 5)
      assert Enum.all?(top, &(&1.score == 3 and &1.total == 3))

      # C major key must be among the perfect-score results.
      c_major = find_result(results, "C", :major)
      assert c_major != nil
      assert c_major.score == 3
      assert c_major.total == 3

      # The diatonic_chords for C major should match the known sequence.
      dc = c_major.diatonic_chords
      assert Enum.find(dc, &(&1.root == "C" and &1.quality == :major)) != nil
      assert Enum.find(dc, &(&1.root == "F" and &1.quality == :major)) != nil
      assert Enum.find(dc, &(&1.root == "G" and &1.quality == :major)) != nil
    end

    test "C major + A minor + F major + G major → C major and A minor both 4/4" do
      results =
        Scale.suggest_keys([
          chord("C", :major),
          chord("A", :minor),
          chord("F", :major),
          chord("G", :major)
        ])

      c_major = find_result(results, "C", :major)
      a_minor = find_result(results, "A", :minor)

      assert c_major != nil
      assert c_major.score == 4
      assert c_major.total == 4

      assert a_minor != nil
      assert a_minor.score == 4
      assert a_minor.total == 4

      # Top results should be 4/4.
      top = Enum.take(results, 3)
      assert Enum.all?(top, &(&1.score == 4 and &1.total == 4))
    end

    test "C maj7 + D min7 + G dominant 7 → C major with score 3/3 via 7th→triad matching" do
      results =
        Scale.suggest_keys([
          chord("C", :maj7),
          chord("D", :min7),
          chord("G", :"7")
        ])

      c_major = find_result(results, "C", :major)
      assert c_major != nil
      assert c_major.score == 3
      assert c_major.total == 3
    end

    test "C major + C# major → very few or no results (length <= 5)" do
      results = Scale.suggest_keys([chord("C", :major), chord("C#", :major)])
      assert length(results) <= 5
    end

    test "empty list → all 168 candidates with score 0" do
      results = Scale.suggest_keys([])

      assert length(results) == 168
      assert Enum.all?(results, &(&1.score == 0 and &1.total == 0))
    end

    test "single chord (C major) → many results, all with score 1" do
      results = Scale.suggest_keys([chord("C", :major)])

      # All returned results must contain C major's notes (C, E, G).
      assert length(results) > 0
      assert Enum.all?(results, &(&1.score == 1 and &1.total == 1))
    end

    test "each result has correct structure with required keys" do
      results = Scale.suggest_keys([chord("C", :major), chord("G", :major)])

      assert length(results) > 0

      for r <- results do
        assert Map.has_key?(r, :tonic)
        assert Map.has_key?(r, :scale_type)
        assert Map.has_key?(r, :score)
        assert Map.has_key?(r, :total)
        assert Map.has_key?(r, :diatonic_chords)

        assert is_binary(r.tonic)
        assert is_atom(r.scale_type)
        assert is_integer(r.score)
        assert is_integer(r.total)
        assert is_list(r.diatonic_chords)

        # tonic must be one of the 12 chromatic notes.
        assert r.tonic in Note.chromatic_scale()

        # scale_type must not be :chromatic (excluded from candidates).
        assert r.scale_type != :chromatic

        # diatonic_chords entries must each have :root and :quality.
        for dc <- r.diatonic_chords do
          assert Map.has_key?(dc, :root)
          assert Map.has_key?(dc, :quality)
          assert is_binary(dc.root)
          assert is_atom(dc.quality)
        end
      end
    end

    test "results are sorted by score descending (first score >= last score)" do
      results = Scale.suggest_keys([chord("C", :major), chord("F", :major), chord("G", :major)])

      scores = Enum.map(results, & &1.score)
      assert hd(scores) >= List.last(scores)

      # Full list must be non-increasing.
      assert scores == Enum.sort(scores, :desc)
    end
  end
end
