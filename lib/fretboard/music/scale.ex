defmodule Fretboard.Music.Scale do
  @moduledoc """
  Scale formulas and diatonic chord calculation.

  Defines scale types as semitone interval formulas and computes
  the notes and diatonic chords for a given tonic and scale type.
  """

  alias Fretboard.Music.Chord
  alias Fretboard.Music.Note

  @scale_types [
    :major,
    :minor,
    :harmonic_minor,
    :melodic_minor,
    :pentatonic_major,
    :pentatonic_minor,
    :blues,
    :dorian,
    :phrygian,
    :lydian,
    :mixolydian,
    :locrian,
    :phrygian_dominant,
    :whole_tone,
    :chromatic
  ]

  @scale_formulas %{
    major: [0, 2, 4, 5, 7, 9, 11],
    minor: [0, 2, 3, 5, 7, 8, 10],
    harmonic_minor: [0, 2, 3, 5, 7, 8, 11],
    melodic_minor: [0, 2, 3, 5, 7, 9, 11],
    pentatonic_major: [0, 2, 4, 7, 9],
    pentatonic_minor: [0, 3, 5, 7, 10],
    blues: [0, 3, 5, 6, 7, 10],
    dorian: [0, 2, 3, 5, 7, 9, 10],
    phrygian: [0, 1, 3, 5, 7, 8, 10],
    lydian: [0, 2, 4, 6, 7, 9, 11],
    mixolydian: [0, 2, 4, 5, 7, 9, 10],
    locrian: [0, 1, 3, 5, 6, 8, 10],
    phrygian_dominant: [0, 1, 4, 5, 7, 8, 10],
    whole_tone: [0, 2, 4, 6, 8, 10],
    chromatic: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
  }

  @labels %{
    major: "Major",
    minor: "Minor",
    harmonic_minor: "Harmonic Minor",
    melodic_minor: "Melodic Minor",
    pentatonic_major: "Major Pentatonic",
    pentatonic_minor: "Minor Pentatonic",
    blues: "Blues",
    dorian: "Dorian",
    phrygian: "Phrygian",
    lydian: "Lydian",
    mixolydian: "Mixolydian",
    locrian: "Locrian",
    phrygian_dominant: "Phrygian Dominant",
    whole_tone: "Whole Tone",
    chromatic: "Chromatic"
  }

  @grouped_scale_types [
    {"Standard", [:major, :minor]},
    {"Minor Variants", [:harmonic_minor, :melodic_minor]},
    {"Pentatonic", [:pentatonic_major, :pentatonic_minor]},
    {"Blues", [:blues]},
    {"Modes", [:dorian, :phrygian, :lydian, :mixolydian, :locrian]},
    {"Exotic", [:phrygian_dominant, :whole_tone]},
    {"Other", [:chromatic]}
  ]

  @doc """
  Returns the list of available scale types.
  """
  @spec available_scale_types() :: [atom()]
  def available_scale_types, do: @scale_types

  @doc """
  Returns scale types organized in groups for UI display.
  """
  @spec grouped_scale_types() :: [{String.t(), [atom()]}]
  def grouped_scale_types, do: @grouped_scale_types

  @doc """
  Returns the notes of a scale given a tonic and scale type.

  ## Examples

      iex> Fretboard.Music.Scale.scale_notes("C", :major)
      ["C", "D", "E", "F", "G", "A", "B"]
  """
  @spec scale_notes(String.t(), atom()) :: [String.t()]
  def scale_notes(tonic, scale_type) do
    Map.fetch!(@scale_formulas, scale_type)
    |> Enum.map(&Note.note_at(tonic, &1))
  end

  @doc """
  Returns the diatonic chords for a key as maps with `:root` and `:quality`.

  ## Examples

      iex> Fretboard.Music.Scale.diatonic_chords("C", :major)
      [%{root: "C", quality: :major}, %{root: "D", quality: :minor}, %{root: "E", quality: :minor}, %{root: "F", quality: :major}, %{root: "G", quality: :major}, %{root: "A", quality: :minor}, %{root: "B", quality: :dim}]
  """
  @spec diatonic_chords(String.t(), atom(), :triad | :seventh) :: [
          %{root: String.t(), quality: atom()}
        ]
  def diatonic_chords(tonic, scale_type, mode \\ :triad) do
    formula = Map.fetch!(@scale_formulas, scale_type)
    notes = Enum.map(formula, &Note.note_at(tonic, &1))
    semitone_set = MapSet.new(formula)
    infer_fn = quality_infer_fn(mode)

    Enum.zip(notes, formula)
    |> Enum.map(fn {note, root_semitone} ->
      quality = infer_fn.(root_semitone, semitone_set)
      %{root: note, quality: quality}
    end)
  end

  defp quality_infer_fn(:seventh), do: &infer_7th_quality/2
  defp quality_infer_fn(:triad), do: &infer_quality/2

  @doc """
  Infers the chord quality for a scale degree by analyzing
  which intervals from that root exist within the scale.

  ## Examples

      iex> Fretboard.Music.Scale.infer_quality(0, MapSet.new([0, 2, 4, 5, 7, 9, 11]))
      :major
  """
  @spec infer_quality(integer(), MapSet.t()) :: atom()
  def infer_quality(root_semitone, scale_semitones) do
    intervals =
      scale_semitones
      |> Enum.map(fn s -> rem(s - root_semitone + 12, 12) end)
      |> MapSet.new()

    classify_intervals(intervals)
  end

  @doc """
  Infers the 7th-chord quality for a scale degree by analyzing
  which intervals from that root exist within the scale.

  Tries 7th-chord rules in priority order (dim7, m7b5, min7,
  dominant 7, maj7, min_maj7, aug_maj7, aug7). Falls back to
  the existing triad classifier when no 7th interval is present.

  ## Examples

      iex> Fretboard.Music.Scale.infer_7th_quality(0, MapSet.new([0, 2, 4, 5, 7, 9, 11]))
      :maj7
  """
  @spec infer_7th_quality(integer(), MapSet.t()) :: atom()
  def infer_7th_quality(root_semitone, scale_semitones) do
    intervals =
      scale_semitones
      |> Enum.map(fn s -> rem(s - root_semitone + 12, 12) end)
      |> MapSet.new()

    classify_7th(intervals)
  end

  # 7th-chord rules in priority order.
  # Each rule is {required, excluded, quality}.
  # dim7 and m7b5 exclude the perfect 5th (7): when the scale contains
  # both a diminished and perfect 5th above the root, prefer the non-
  # diminished interpretation (min7 / dominant 7).
  @seventh_rules [
    {[3, 6, 9], [7], :dim7},
    {[3, 6, 10], [7], :m7b5},
    {[3, 7, 10], [], :min7},
    {[4, 7, 10], [], :"7"},
    {[4, 7, 11], [], :maj7},
    {[3, 7, 11], [], :min_maj7},
    {[4, 8, 11], [], :aug_maj7},
    {[4, 8, 10], [], :aug7}
  ]

  defp classify_7th(intervals) do
    case Enum.find(@seventh_rules, fn {required, excluded, _} ->
           Enum.all?(required, &MapSet.member?(intervals, &1)) and
             not Enum.any?(excluded, &MapSet.member?(intervals, &1))
         end) do
      {_, _, quality} -> quality
      nil -> classify_intervals(intervals)
    end
  end

  # Interval pattern matching for chord quality inference.
  # Priority: major > minor > dim > aug > sus2 > sus4 > partial 3rd > fallback
  @quality_rules [
    {[4, 7], :major},
    {[3, 7], :minor},
    {[3, 6], :dim},
    {[4, 8], :aug},
    {[2, 7], :sus2},
    {[5, 7], :sus4}
  ]

  defp classify_intervals(intervals) do
    case Enum.find(@quality_rules, fn {required, _} ->
           Enum.all?(required, &MapSet.member?(intervals, &1))
         end) do
      {_, quality} -> quality
      nil -> classify_partial(intervals)
    end
  end

  defp classify_partial(intervals) do
    cond do
      MapSet.member?(intervals, 4) -> :major
      MapSet.member?(intervals, 3) -> :minor
      true -> :major
    end
  end

  @doc """
  Returns the display label for a scale type.

  ## Examples

      iex> Fretboard.Music.Scale.scale_label(:major)
      "Major"
  """
  @spec scale_label(atom()) :: String.t()
  def scale_label(scale_type), do: Map.fetch!(@labels, scale_type)

  # Mapping from chord qualities to their triad base quality,
  # used by `suggest_keys/1` to compare input chords against
  # the diatonic triad chords of a candidate key. Each quality is
  # mapped by its 3rd/5th base (major/minor/dim/aug).
  @quality_to_triad %{
    # Triads map to themselves
    major: :major,
    minor: :minor,
    dim: :dim,
    aug: :aug,
    sus2: :sus2,
    sus4: :sus4,
    # Sevenths
    maj7: :major,
    "7": :major,
    min7: :minor,
    dim7: :dim,
    m7b5: :dim,
    min_maj7: :minor,
    aug_maj7: :aug,
    aug7: :aug,
    "7sus4": :sus4,
    dim_maj7: :dim,
    # Sixths
    maj6: :major,
    min6: :minor,
    maj6_9: :major,
    min6_9: :minor,
    # Added tones
    add9: :major,
    m_add9: :minor,
    # Ninths
    "9": :major,
    maj9: :major,
    min9: :minor,
    "7b9": :major,
    "7#9": :major,
    "9#5": :aug,
    "9b5": :dim,
    "7b5": :dim,
    # 7th alterations
    "maj7#11": :major,
    "7#11": :major,
    "7b13": :major,
    "7b9b13": :major,
    # 11ths
    "11": :major,
    maj11: :major,
    min11: :minor,
    m11b5: :dim,
    # 13ths
    "13": :major,
    maj13: :major,
    min13: :minor,
    "13b9": :major,
    # Suspended extended
    sus9: :sus2,
    susb9: :sus2,
    sus13: :sus4,
    # Minor/dim variations
    min7b13: :minor,
    dim7b13: :dim
  }

  @triad_qualities_list [:major, :minor, :dim, :aug, :sus2, :sus4]

  @doc """
  Suggests candidate keys (tonic + scale type) that contain all the notes
  of every chord in `chords`, scored by how many chords match the key's
  diatonic triads.

  Each chord is a map with `:root` (e.g. `"C"`) and `:quality` (e.g.
  `:major`, `:min7`). 7th-chord qualities are mapped to their triad base
  via `@quality_to_triad` before comparison against the diatonic triads.

  Returns a list of maps sorted by score descending, then tonic ascending,
  then scale_type ascending. Each map has:

    * `:tonic`           — the tonic note name (e.g. `"C"`)
    * `:scale_type`      — the scale type atom (e.g. `:major`)
    * `:score`           — number of chords that match a diatonic triad
    * `:total`           — number of input chords
    * `:diatonic_chords` — the diatonic triads of the candidate key

  ## Examples

      iex> hd(Fretboard.Music.Scale.suggest_keys([%{root: "C", quality: :major}])).score
      1
  """
  @spec suggest_keys([%{root: String.t(), quality: atom()}]) :: [map()]
  def suggest_keys(chords) do
    candidate_types = List.delete(@scale_types, :chromatic)
    tonics = Note.chromatic_scale()

    # Precompute each chord's note set once.
    chord_note_sets =
      Enum.map(chords, fn %{root: root, quality: quality} ->
        MapSet.new(Chord.notes(root, quality))
      end)

    for tonic <- tonics,
        scale_type <- candidate_types,
        valid_candidate?(tonic, scale_type, chord_note_sets) do
      build_result(tonic, scale_type, chords)
    end
    |> Enum.sort_by(fn r -> {-r.score, r.tonic, Atom.to_string(r.scale_type)} end)
  end

  defp valid_candidate?(tonic, scale_type, chord_note_sets) do
    scale_set = MapSet.new(scale_notes(tonic, scale_type))
    Enum.all?(chord_note_sets, &MapSet.subset?(&1, scale_set))
  end

  defp build_result(tonic, scale_type, chords) do
    dc = diatonic_chords(tonic, scale_type, :triad)
    dc_map = Map.new(dc, fn %{root: root, quality: quality} -> {root, quality} end)

    score =
      Enum.count(chords, fn %{root: root, quality: quality} ->
        expected = triad_base_quality(quality)
        Map.get(dc_map, root) == expected
      end)

    %{
      tonic: tonic,
      scale_type: scale_type,
      score: score,
      total: length(chords),
      diatonic_chords: dc
    }
  end

  defp triad_base_quality(quality) when quality in @triad_qualities_list do
    quality
  end

  defp triad_base_quality(quality) do
    Map.fetch!(@quality_to_triad, quality)
  end

  # Flat → sharp equivalents for normalizing note names that use flats
  # (the chromatic scale in Note.ex uses sharps only).
  @flat_to_sharp %{
    "Db" => "C#",
    "Eb" => "D#",
    "Fb" => "E",
    "Gb" => "F#",
    "Ab" => "G#",
    "Bb" => "A#",
    "Cb" => "B"
  }

  # Scale priority order for tiebreaking during greedy set cover.
  # Lower index = higher priority. Matches the flattening of
  # @grouped_scale_types (excluding :chromatic).
  @scale_priority_map @grouped_scale_types
                      |> Enum.flat_map(&elem(&1, 1))
                      |> Enum.with_index()
                      |> Map.new()

  @doc """
  Suggests multiple keys that together cover the given chords using a
  greedy set-cover algorithm (max 3 groups).

  Each chord is a map with `:root` and `:quality`. Returns a list of
  groups, each of the form:

      %{
        key: %{tonic, scale_type, score, total, diatonic_chords} | nil,
        chords: [%{root, quality}, ...]
      }

  Groups with real keys are ordered by coverage (chord count) descending.
  If any chords remain unmatched, a final group with `key: nil` is appended.

  ## Examples

      iex> Fretboard.Music.Scale.suggest_multi_keys([])
      []
  """
  @spec suggest_multi_keys([%{root: String.t(), quality: atom()}]) :: [map()]
  def suggest_multi_keys(chords) do
    if length(chords) < 3 do
      []
    else
      multi_keys_run(chords)
    end
  end

  defp multi_keys_run(chords) do
    norm_chords = Enum.map(chords, &normalize_chord/1)
    selected = select_candidates(norm_chords)
    format_multi_key_result(selected, norm_chords)
  end

  defp select_candidates(chords) do
    candidates = build_candidates(chords)
    greedy_select(candidates, chords, [], MapSet.new(), 3)
  end

  defp format_multi_key_result(selected, chords) do
    # Rule: if every selected group has exactly 1 chord, no chord shares a
    # key with any other → return [].
    if all_groups_are_singletons?(selected) do
      []
    else
      build_groups(selected, chords)
    end
  end

  defp all_groups_are_singletons?(selected) do
    Enum.all?(selected, fn {_key, covered} -> length(covered) == 1 end)
  end

  defp normalize_chord(%{root: root, quality: quality}) do
    %{root: normalize_note(root), quality: quality}
  end

  defp normalize_note(note) do
    Map.get(@flat_to_sharp, note, note)
  end

  # Build all 168 candidate keys (12 tonics × 14 scale types, excluding
  # :chromatic). For each candidate, precompute which input chord indices
  # it strictly covers (chord notes ⊆ scale notes) and its diatonic score.
  defp build_candidates(chords) do
    candidate_types = List.delete(@scale_types, :chromatic)
    tonics = Note.chromatic_scale()
    chord_note_sets = chord_note_sets(chords)

    for tonic <- tonics,
        scale_type <- candidate_types do
      scale_set = MapSet.new(scale_notes(tonic, scale_type))
      dc = diatonic_chords(tonic, scale_type, :triad)
      dc_map = Map.new(dc, fn %{root: r, quality: q} -> {r, q} end)

      build_candidate(tonic, scale_type, scale_set, chord_note_sets, chords, dc, dc_map)
    end
  end

  defp chord_note_sets(chords) do
    Enum.map(chords, fn %{root: root, quality: quality} ->
      MapSet.new(Chord.notes(root, quality))
    end)
  end

  defp build_candidate(tonic, scale_type, scale_set, chord_note_sets, chords, dc, dc_map) do
    covered_indices = compute_covered_indices(chord_note_sets, scale_set)
    diatonic_score = compute_diatonic_score(covered_indices, chords, dc_map)

    %{
      tonic: tonic,
      scale_type: scale_type,
      covered: covered_indices,
      diatonic_score: diatonic_score,
      diatonic_chords: dc
    }
  end

  defp compute_covered_indices(chord_note_sets, scale_set) do
    chord_note_sets
    |> Enum.with_index()
    |> Enum.filter(fn {note_set, _i} -> MapSet.subset?(note_set, scale_set) end)
    |> Enum.map(fn {_note_set, i} -> i end)
    |> MapSet.new()
  end

  defp compute_diatonic_score(covered_indices, chords, dc_map) do
    covered_indices
    |> Enum.filter(fn i ->
      %{root: root, quality: quality} = Enum.at(chords, i)
      expected = triad_base_quality(quality)
      Map.get(dc_map, root) == expected
    end)
    |> length()
  end

  # Greedy iteration: at each step pick the candidate that covers the most
  # *uncovered* chords. Tiebreak: higher diatonic score, then lower scale
  # priority index (higher priority). Stop after `max_groups`, when no
  # uncovered chords remain, or no candidate covers any remaining chord.
  defp greedy_select(_candidates, _chords, selected, _covered, 0) do
    selected
  end

  defp greedy_select(candidates, chords, selected, covered, max_groups)
       when max_groups > 0 do
    if remaining_empty?(covered, chords) do
      selected
    else
      select_next(candidates, chords, selected, covered, max_groups)
    end
  end

  defp remaining_empty?(covered, chords) do
    remaining_indices(covered, chords) |> MapSet.size() == 0
  end

  defp remaining_indices(covered, chords) do
    all_indices = MapSet.new(0..(length(chords) - 1)//1)
    MapSet.difference(all_indices, covered)
  end

  defp select_next(candidates, chords, selected, covered, max_groups) do
    remaining = remaining_indices(covered, chords)

    case find_best_candidate(candidates, remaining) do
      nil ->
        selected

      best ->
        add_selected(best, candidates, chords, selected, covered, max_groups, remaining)
    end
  end

  defp find_best_candidate(candidates, remaining) do
    candidates
    |> Enum.filter(fn c ->
      MapSet.size(MapSet.intersection(c.covered, remaining)) > 0
    end)
    |> Enum.max_by(
      fn c ->
        coverage = MapSet.size(MapSet.intersection(c.covered, remaining))

        {coverage, c.diatonic_score, -Map.get(@scale_priority_map, c.scale_type)}
      end,
      fn -> nil end
    )
  end

  defp add_selected(best, candidates, chords, selected, covered, max_groups, remaining) do
    newly_covered = MapSet.intersection(best.covered, remaining)
    new_covered = MapSet.union(covered, newly_covered)

    # Preserve the original chord indices directly — newly_covered is already
    # a MapSet of indices. Storing indices (not chord values) avoids re-buscar
    # with find_index, which fails on duplicate chords.
    covered_indices =
      newly_covered
      |> Enum.sort()

    greedy_select(
      candidates,
      chords,
      [{best, covered_indices} | selected],
      new_covered,
      max_groups - 1
    )
  end

  # Convert the list of {candidate, covered_indices} tuples (built in
  # reverse order during greedy selection) into the final return shape.
  defp build_groups(selected, chords) do
    groups = format_selected_groups(selected, chords, length(chords))
    unmatched = unmatched_chords(selected, chords)
    append_unmatched_group(groups, unmatched)
  end

  defp format_selected_groups(selected, chords, total) do
    selected
    |> Enum.reverse()
    |> Enum.map(fn {cand, _covered_indices} ->
      %{
        key: %{
          tonic: cand.tonic,
          scale_type: cand.scale_type,
          score: cand.diatonic_score,
          total: total,
          diatonic_chords: cand.diatonic_chords
        },
        # Full membership: list EVERY chord whose notes fit this key (the
        # candidate's full `covered` set), not only the chords the greedy
        # cover assigned exclusively to this group. The exclusive indices
        # kept in the tuples still drive the singleton rule and the
        # unmatched computation, whose output is unchanged.
        chords:
          cand.covered
          |> Enum.sort()
          |> Enum.map(&Enum.at(chords, &1))
      }
    end)
    # Order groups by coverage (chord count) descending.
    |> Enum.sort_by(&(-length(&1.chords)))
  end

  defp unmatched_chords(selected, chords) do
    # Indices are preserved directly in selected — no repeat lookup needed.
    covered_indices =
      selected
      |> Enum.flat_map(fn {_cand, indices} -> indices end)
      |> MapSet.new()

    chords
    |> Enum.with_index()
    |> Enum.filter(fn {_chord, i} -> not MapSet.member?(covered_indices, i) end)
    |> Enum.map(fn {chord, _i} -> chord end)
  end

  defp append_unmatched_group(groups, []), do: groups

  defp append_unmatched_group(groups, unmatched) do
    groups ++ [%{key: nil, chords: unmatched}]
  end
end
