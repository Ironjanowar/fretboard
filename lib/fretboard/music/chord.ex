defmodule Fretboard.Music.Chord do
  @moduledoc """
  Chord formulas and note calculation.

  Defines chord qualities as semitone interval formulas and computes
  the notes that belong to a chord given a root and quality.
  """

  alias Fretboard.Music.Note

  @formulas %{
    # Triads
    major: [0, 4, 7],
    minor: [0, 3, 7],
    dim: [0, 3, 6],
    aug: [0, 4, 8],
    sus2: [0, 2, 7],
    sus4: [0, 5, 7],
    # Sevenths
    "7": [0, 4, 7, 10],
    maj7: [0, 4, 7, 11],
    min7: [0, 3, 7, 10],
    dim7: [0, 3, 6, 9],
    m7b5: [0, 3, 6, 10],
    min_maj7: [0, 3, 7, 11],
    aug_maj7: [0, 4, 8, 11],
    aug7: [0, 4, 8, 10],
    # Sixths
    maj6: [0, 4, 7, 9],
    min6: [0, 3, 7, 9],
    # Added tones
    add9: [0, 2, 4, 7],
    m_add9: [0, 2, 3, 7],
    maj6_9: [0, 2, 4, 7, 9],
    min6_9: [0, 2, 3, 7, 9],
    # Ninths
    "9": [0, 2, 4, 7, 10],
    maj9: [0, 2, 4, 7, 11],
    min9: [0, 2, 3, 7, 10],
    "7b9": [0, 1, 4, 7, 10],
    "7#9": [0, 3, 4, 7, 10],
    "9#5": [0, 2, 4, 8, 10],
    "9b5": [0, 2, 4, 6, 10],
    "7b5": [0, 4, 6, 10],
    # 7th alterations
    "7sus4": [0, 5, 7, 10],
    dim_maj7: [0, 3, 6, 11],
    "maj7#11": [0, 4, 6, 7, 11],
    "7#11": [0, 4, 6, 7, 10],
    "7b13": [0, 4, 7, 8, 10],
    "7b9b13": [0, 1, 4, 7, 8, 10],
    # 11ths
    "11": [0, 2, 4, 5, 7, 10],
    maj11: [0, 2, 4, 5, 7, 11],
    min11: [0, 2, 3, 5, 7, 10],
    m11b5: [0, 2, 3, 5, 6, 10],
    # 13ths
    "13": [0, 2, 4, 5, 7, 9, 10],
    maj13: [0, 2, 4, 5, 7, 9, 11],
    min13: [0, 2, 3, 5, 7, 9, 10],
    "13b9": [0, 1, 4, 5, 7, 9, 10],
    # Suspended extended
    sus9: [0, 2, 5, 7, 10],
    susb9: [0, 1, 5, 7, 10],
    sus13: [0, 5, 7, 9, 10],
    # Minor/dim variations
    min7b13: [0, 3, 7, 8, 10],
    dim7b13: [0, 3, 6, 8, 9]
  }

  @interval_names %{
    0 => "Root",
    1 => "Minor 2nd",
    2 => "Major 2nd",
    3 => "Minor 3rd",
    4 => "Major 3rd",
    5 => "Perfect 4th",
    6 => "Tritone",
    7 => "Perfect 5th",
    8 => "Augmented 5th",
    9 => "Major 6th",
    10 => "Minor 7th",
    11 => "Major 7th"
  }

  # Compound interval names used for extensions (9ths, 11ths, 13ths).
  # These replace the simple chromatic names when the interval functions
  # as a chord extension rather than a basic chord tone.
  @flat_ninth "Flat 9th"
  @major_ninth "Major 9th"
  @sharp_ninth "Sharp 9th"
  @perfect_eleventh "Perfect 11th"
  @augmented_eleventh "Augmented 11th"
  @minor_thirteenth "Minor 13th"
  @major_thirteenth "Major 13th"

  @labels %{
    major: "maj",
    minor: "min",
    dim: "dim",
    aug: "aug",
    sus2: "sus2",
    sus4: "sus4",
    "7": "7",
    maj7: "maj7",
    min7: "min7",
    dim7: "dim7",
    m7b5: "m7b5",
    min_maj7: "mMaj7",
    aug_maj7: "augMaj7",
    aug7: "aug7",
    maj6: "6",
    min6: "m6",
    add9: "add9",
    m_add9: "madd9",
    maj6_9: "6/9",
    min6_9: "m6/9",
    "9": "9",
    maj9: "maj9",
    min9: "m9",
    "7b9": "7b9",
    "7#9": "7#9",
    "9#5": "9#5",
    "9b5": "9b5",
    "7b5": "7b5",
    "7sus4": "7sus",
    dim_maj7: "dimMaj7",
    "maj7#11": "maj7#11",
    "7#11": "7#11",
    "7b13": "7b13",
    "7b9b13": "7b9b13",
    "11": "11",
    maj11: "maj11",
    min11: "m11",
    m11b5: "m11b5",
    "13": "13",
    maj13: "maj13",
    min13: "m13",
    "13b9": "13b9",
    sus9: "sus9",
    susb9: "susb9",
    sus13: "sus13",
    min7b13: "m7b13",
    dim7b13: "dim7b13"
  }

  @doc """
  Returns the list of available chord qualities.
  """
  @spec available_qualities() :: [atom()]
  def available_qualities, do: Map.keys(@formulas) |> Enum.sort()

  @doc """
  Returns the interval formula for a chord quality.
  """
  @spec formula(atom()) :: [non_neg_integer()]
  def formula(quality), do: Map.fetch!(@formulas, quality)

  @doc """
  Returns the list of note names for a chord given a root and quality.
  """
  @spec notes(String.t(), atom()) :: [String.t()]
  def notes(root, quality) do
    formula(quality)
    |> Enum.map(&Note.note_at(root, &1))
  end

  @doc """
  Returns the short display label for a chord quality.
  """
  @spec label(atom()) :: String.t()
  def label(quality), do: Map.fetch!(@labels, quality)

  @doc """
  Returns a formatted chord label combining root and quality.

  ## Examples

      iex> Fretboard.Music.Chord.chord_label("C", :major)
      "Cmaj"

      iex> Fretboard.Music.Chord.chord_label("G", :"7")
      "G7"
  """
  @spec chord_label(String.t(), atom()) :: String.t()
  def chord_label(root, quality), do: "#{root}#{label(quality)}"

  # Chord-member priority for sorting interval labels: root first, then
  # 3rds, 5ths, 7ths, 9ths, 11ths, 13ths. Each semitone maps to a sort
  # rank so labels appear in conventional chord-member order regardless
  # of the formula's internal ordering.
  # Note: semitone 3 is ambiguous (Minor 3rd or Sharp 9th) and semitone 6
  # is ambiguous (Tritone or Augmented 11th). We rank by the simpler
  # interpretation (3rd and 5th respectively) since the sort only affects
  # display order, not the label itself.
  @chord_member_rank %{
    0 => 0,
    3 => 1,
    4 => 1,
    6 => 2,
    7 => 2,
    8 => 2,
    10 => 3,
    11 => 3,
    1 => 0,
    2 => 4,
    5 => 5,
    9 => 6
  }

  @doc """
  Returns the interval labels for a chord quality, sorted in conventional
  chord-member order (root, 3rd, 5th, 7th, 9th, 11th, 13th).

  Intervals are named contextually: when an interval functions as a chord
  extension (9th, 11th, 13th) it gets a compound name; when it's a basic
  chord tone it keeps the simple chromatic name. The rules are:

    * Intervals 0, 4, 7, 10, 11 always use simple names.
    * 2 → "Major 9th" when a 7th (10 or 11) is present, else "Major 2nd".
    * 5 → "Perfect 11th" when a 7th is present, else "Perfect 4th".
    * 9 → "Major 13th" when a 7th is present, else "Major 6th".
    * 1 → "Flat 9th" when a 7th is present, else "Minor 2nd".
    * 3 → "Sharp 9th" when a 7th is present AND 4 is in the formula,
      else "Minor 3rd".
    * 6 → "Augmented 11th" when 7 is in the formula, else "Tritone".
    * 8 → "Minor 13th" when 6 or 7 is in the formula, else "Augmented 5th".

  When the chord contains a 7th, labels are sorted into chord-member order
  (root, 3rd, 5th, 7th, 9th, 11th, 13th). Without a 7th, labels remain in
  formula order — the extension hasn't "earned" compound placement yet.
  """
  @spec interval_labels(atom()) :: [String.t()]
  def interval_labels(quality) do
    formula = formula(quality)
    labeled = Enum.map(formula, &{&1, contextual_interval_label(&1, formula)})

    if has_seventh?(formula) do
      labeled
      |> Enum.sort_by(fn {interval, _label} ->
        {@chord_member_rank[interval], interval}
      end)
      |> Enum.map(&elem(&1, 1))
    else
      Enum.map(labeled, &elem(&1, 1))
    end
  end

  defp contextual_interval_label(interval, formula) do
    interval_label_for(interval, formula)
  end

  # Intervals that always keep their simple chromatic name.
  defp interval_label_for(interval, _formula) when interval in [0, 4, 7, 10, 11] do
    Map.fetch!(@interval_names, interval)
  end

  # Extension intervals get compound names when a 7th is present.
  defp interval_label_for(2, formula),
    do: if(has_seventh?(formula), do: @major_ninth, else: Map.fetch!(@interval_names, 2))

  defp interval_label_for(5, formula),
    do: if(has_seventh?(formula), do: @perfect_eleventh, else: Map.fetch!(@interval_names, 5))

  defp interval_label_for(9, formula),
    do: if(has_seventh?(formula), do: @major_thirteenth, else: Map.fetch!(@interval_names, 9))

  defp interval_label_for(1, formula),
    do: if(has_seventh?(formula), do: @flat_ninth, else: Map.fetch!(@interval_names, 1))

  # Sharp 9th only when a 7th is present AND the major 3rd (4) is in the
  # formula — otherwise it's a minor 3rd.
  defp interval_label_for(3, formula) do
    if has_seventh?(formula) and 4 in formula,
      do: @sharp_ninth,
      else: Map.fetch!(@interval_names, 3)
  end

  defp interval_label_for(6, formula),
    do: if(7 in formula, do: @augmented_eleventh, else: Map.fetch!(@interval_names, 6))

  defp interval_label_for(8, formula) do
    if 6 in formula or 7 in formula,
      do: @minor_thirteenth,
      else: Map.fetch!(@interval_names, 8)
  end

  # Fallback for any interval not covered above.
  defp interval_label_for(interval, _formula),
    do: Map.fetch!(@interval_names, interval)

  @spec has_seventh?([non_neg_integer()]) :: boolean()
  defp has_seventh?(formula), do: 10 in formula or 11 in formula

  @doc """
  Returns notes with their interval labels for a chord.
  """
  @spec notes_with_intervals(String.t(), atom()) :: [{String.t(), String.t()}]
  def notes_with_intervals(root, quality) do
    Enum.zip(notes(root, quality), interval_labels(quality))
  end

  @doc """
  Returns chord qualities organized in groups for UI display.

  Returns a list of `{group_name, qualities}` tuples, sorted by
  ascending complexity: triads, sixths, added tones, sevenths,
  ninths, elevenths, thirteenths, and suspended extended chords.
  """
  @spec grouped_qualities() :: [{String.t(), [atom()]}]
  def grouped_qualities do
    [
      {"Triads", [:major, :minor, :dim, :aug, :sus2, :sus4]},
      {"Sixths", [:maj6, :min6, :maj6_9, :min6_9]},
      {"Added tones", [:add9, :m_add9]},
      {"Sevenths",
       [
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
       ]},
      {"Ninths",
       [
         :"9",
         :maj9,
         :min9,
         :"7b9",
         :"7#9",
         :"9#5",
         :"9b5",
         :"7b5"
       ]},
      {"Elevenths",
       [
         :"11",
         :maj11,
         :min11,
         :m11b5,
         :"maj7#11",
         :"7#11"
       ]},
      {"Thirteenths", [:"13", :maj13, :min13, :"13b9"]},
      {"Suspended (extended)",
       [
         :sus9,
         :susb9,
         :sus13,
         :"7b13",
         :"7b9b13",
         :min7b13,
         :dim7b13
       ]}
    ]
  end

  @doc """
  Identifies possible chord interpretations for a collection of notes.

  Returns a list of result maps, each containing `:root`, `:quality`,
  `:exact`, `:incomplete`, `:notes`, `:intervals`, and `:missing_intervals`.

  Three match types are recognized:

    * **Exact** — the input pitch-class set equals a chord formula's
      interval set (`coverage == input_size` and `formula_size == input_size`).
    * **Incomplete** — the input is a subset of the chord formula
      (`coverage == input_size` and `formula_size > input_size`) with
      at most 2 missing notes.
    * **Partial** — the chord formula is a strict subset of the input
      (`formula_size < input_size`, `coverage >= 3`).

  Results are ordered: exact first (root pitch ascending), then incomplete
  (missing count ascending, root ascending, formula length ascending),
  then partial (coverage descending, root ascending, formula length ascending).

  Returns `[]` for fewer than 3 unique pitch classes.
  """
  @spec identify([String.t()]) :: [map()]
  def identify(notes) do
    unique_notes = Enum.uniq_by(notes, &Note.note_index/1)

    case unique_notes do
      notes when length(notes) < 3 -> []
      _ -> identify_matches(unique_notes)
    end
  end

  defp identify_matches(unique_notes) do
    input_indices = Enum.map(unique_notes, &Note.note_index/1)
    input_size = length(input_indices)
    roots = Note.chromatic_scale()
    formulas = Map.to_list(@formulas)

    for root <- roots,
        root_index = Note.note_index(root),
        interval_set = intervals_from_root(input_indices, root_index),
        {quality, formula} <- formulas,
        match_result = try_match(root, quality, root_index, formula, interval_set, input_size),
        match_result != nil do
      match_result
    end
    |> Enum.sort_by(&match_sort_key/1)
    |> Enum.map(&strip_sort_keys/1)
  end

  defp intervals_from_root(input_indices, root_index) do
    Enum.map(input_indices, fn i -> rem(i - root_index + 12, 12) end)
    |> MapSet.new()
  end

  defp try_match(root, quality, root_index, formula, interval_set, input_size) do
    formula_set = MapSet.new(formula)
    formula_size = MapSet.size(formula_set)
    coverage = MapSet.size(MapSet.intersection(formula_set, interval_set))

    case classify_match(coverage, input_size, formula_size) do
      nil ->
        nil

      match_type ->
        build_match_result(
          root,
          quality,
          root_index,
          formula,
          formula_set,
          interval_set,
          match_type
        )
    end
  end

  defp strip_sort_keys(result) do
    Map.drop(result, [
      :_coverage,
      :_formula_len,
      :_root_index,
      :_missing_count,
      :_missing_priority,
      :_match_type
    ])
  end

  defp classify_match(coverage, input_size, formula_size) do
    cond do
      coverage == input_size and formula_size == input_size ->
        :exact

      coverage == input_size and formula_size > input_size and formula_size - input_size <= 2 ->
        :incomplete

      coverage >= 3 and formula_size < input_size ->
        :partial

      true ->
        nil
    end
  end

  defp build_match_result(
         root,
         quality,
         root_index,
         formula,
         formula_set,
         interval_set,
         match_type
       ) do
    exact = match_type == :exact
    incomplete = match_type == :incomplete

    missing_intervals =
      if incomplete do
        formula
        |> Enum.reject(&MapSet.member?(interval_set, &1))
        |> Enum.map(&contextual_interval_label(&1, formula))
      else
        []
      end

    missing_semitones =
      if incomplete do
        formula |> Enum.reject(&MapSet.member?(interval_set, &1))
      else
        []
      end

    %{
      root: root,
      quality: quality,
      exact: exact,
      incomplete: incomplete,
      notes: notes(root, quality),
      intervals: interval_labels(quality),
      missing_intervals: missing_intervals,
      _coverage: MapSet.size(MapSet.intersection(formula_set, interval_set)),
      _formula_len: length(formula),
      _root_index: root_index,
      _missing_count: length(missing_intervals),
      _missing_priority: missing_priority(missing_semitones),
      _match_type: match_type
    }
  end

  # Priority ranking of missing intervals for sorting incomplete matches.
  # Lower = more acceptable to omit (comes first). Omitting the 5th is
  # extremely common in guitar voicings; omitting the 3rd or 7th is less
  # desirable.
  @missing_interval_priority %{
    7 => 0,
    5 => 1,
    2 => 2,
    9 => 2,
    4 => 3,
    3 => 3,
    10 => 4,
    11 => 4,
    1 => 5,
    6 => 5,
    8 => 6
  }

  defp missing_priority(intervals) do
    intervals
    |> Enum.map(fn i -> @missing_interval_priority[i] || 9 end)
    |> Enum.sum()
  end

  defp match_sort_key(m) do
    case m._match_type do
      :exact ->
        {0, 0, 0, m._root_index, 0}

      :incomplete ->
        {1, m._missing_count, m._missing_priority, m._root_index, m._formula_len}

      :partial ->
        {2, 0, -m._coverage, m._root_index, m._formula_len}
    end
  end

  @doc """
  Identifies possible chord interpretations for a collection of notes
  given a bass note, annotating each result with its inversion and a
  slash-chord label.

  Returns a list of result maps with the same fields as `identify/1`
  (`:root`, `:quality`, `:exact`, `:incomplete`, `:notes`, `:intervals`,
  `:missing_intervals`) plus `:bass`, `:inversion`, and `:slash_label`.

  `inversion` is `0` for root position, `1`–`6` for first through sixth
  inversion (3rd, 5th, 7th, 9th, 11th, or 13th in the bass), or `nil`
  when the bass does not fall on a chord tone that maps to an inversion.

  Returns `[]` when `identify/1` returns `[]` for the given notes.
  """
  @spec identify([String.t()], String.t()) :: [map()]
  def identify(notes, bass_note) do
    bass_index = Note.note_index(bass_note)

    identify(notes)
    |> Enum.map(fn result ->
      root_index = Note.note_index(result.root)
      bass_interval = rem(bass_index - root_index + 12, 12)
      formula = formula(result.quality)

      inversion =
        if bass_interval in formula do
          inversion_for_interval(bass_interval)
        else
          nil
        end

      slash_label =
        if inversion == 0 or is_nil(inversion) do
          chord_label(result.root, result.quality)
        else
          "#{chord_label(result.root, result.quality)}/#{bass_note}"
        end

      result
      |> Map.put(:bass, bass_note)
      |> Map.put(:inversion, inversion)
      |> Map.put(:slash_label, slash_label)
    end)
  end

  defp inversion_for_interval(bass_interval) do
    cond do
      bass_interval == 0 -> 0
      bass_interval in [3, 4] -> 1
      bass_interval in [7, 8] -> 2
      bass_interval in [10, 11] -> 3
      bass_interval == 2 -> 4
      bass_interval == 5 -> 5
      bass_interval == 9 -> 6
      true -> nil
    end
  end
end
