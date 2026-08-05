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
    aug7: [0, 4, 8, 10]
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
    aug7: "aug7"
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

  @doc """
  Returns the interval labels for a chord quality.
  """
  @spec interval_labels(atom()) :: [String.t()]
  def interval_labels(quality) do
    formula(quality)
    |> Enum.map(&Map.fetch!(@interval_names, &1))
  end

  @doc """
  Returns notes with their interval labels for a chord.
  """
  @spec notes_with_intervals(String.t(), atom()) :: [{String.t(), String.t()}]
  def notes_with_intervals(root, quality) do
    Enum.zip(notes(root, quality), interval_labels(quality))
  end

  @doc """
  Returns chord qualities organized in groups for UI display.

  Returns a list of `{group_name, qualities}` tuples.
  """
  @spec grouped_qualities() :: [{String.t(), [atom()]}]
  def grouped_qualities do
    [
      {"Triads", [:major, :minor, :dim, :aug, :sus2, :sus4]},
      {"Sevenths", [:"7", :maj7, :min7, :dim7, :m7b5, :min_maj7, :aug_maj7, :aug7]}
    ]
  end

  @doc """
  Identifies possible chord interpretations for a collection of notes.

  Returns a list of result maps, each containing `:root`, `:quality`,
  `:exact`, `:notes`, and `:intervals`. Exact matches (where the input
  pitch-class set equals a chord formula's interval set) are returned
  first, sorted by root pitch ascending. Partial matches (where at
  least 3 intervals overlap a formula) follow, sorted by coverage
  descending, then root pitch ascending, then formula length ascending
  (simpler chords first).

  Returns `[]` for fewer than 3 unique pitch classes.
  """
  @spec identify([String.t()]) :: [map()]
  def identify(notes) do
    unique_notes = Enum.uniq_by(notes, &Note.note_index/1)

    if length(unique_notes) < 3 do
      []
    else
      input_indices = Enum.map(unique_notes, &Note.note_index/1)
      input_size = length(input_indices)
      roots = Note.chromatic_scale()
      formulas = Map.to_list(@formulas)

      matches =
        for root <- roots,
            root_index = Note.note_index(root),
            intervals = Enum.map(input_indices, fn i -> rem(i - root_index + 12, 12) end),
            interval_set = MapSet.new(intervals),
            {quality, formula} <- formulas,
            formula_set = MapSet.new(formula),
            formula_size = MapSet.size(formula_set),
            intersection = MapSet.intersection(formula_set, interval_set),
            coverage = MapSet.size(intersection),
            # Keep exact matches (set equality) and partial matches where
            # the chord formula is a strict subset of the input (input has
            # extra notes beyond the chord, coverage >= 3). A 3-note input
            # matching 3 of 4 notes of a 7th chord is NOT a partial — the
            # input is a subset of the chord, not a superset containing it.
            (coverage == input_size and formula_size == input_size) or
              (coverage >= 3 and formula_size < input_size) do
          exact = coverage == input_size and formula_size == input_size

          %{
            root: root,
            quality: quality,
            exact: exact,
            notes: notes(root, quality),
            intervals: interval_labels(quality),
            _coverage: coverage,
            _formula_len: length(formula),
            _root_index: root_index
          }
        end

      matches
      |> Enum.sort_by(fn m ->
        if m.exact do
          {0, m._root_index}
        else
          {1, -m._coverage, m._root_index, m._formula_len}
        end
      end)
      |> Enum.map(&Map.drop(&1, [:_coverage, :_formula_len, :_root_index]))
    end
  end

  @doc """
  Identifies possible chord interpretations for a collection of notes
  given a bass note, annotating each result with its inversion and a
  slash-chord label.

  Returns a list of result maps with the same fields as `identify/1`
  (`:root`, `:quality`, `:exact`, `:notes`, `:intervals`) plus `:bass`,
  `:inversion`, and `:slash_label`.

  `inversion` is `0` for root position, `1`/`2`/`3` for first/second/third
  inversion (3rd, 5th, or 7th in the bass), or `nil` when the bass does
  not fall on a chord tone that maps to one of those inversions.

  Returns `[]` when `identify/1` returns `[]` for the given notes.
  """
  @spec identify([String.t()], String.t()) :: [map()]
  def identify(notes, bass_note) do
    bass_index = Note.note_index(bass_note)

    identify(notes)
    |> Enum.map(fn result ->
      root_index = Note.note_index(result.root)
      bass_interval = rem(bass_index - root_index + 12, 12)

      inversion =
        cond do
          bass_interval == 0 -> 0
          bass_interval in [3, 4] -> 1
          bass_interval in [7, 8] -> 2
          bass_interval in [10, 11] -> 3
          true -> nil
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
end
