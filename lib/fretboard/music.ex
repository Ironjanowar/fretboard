defmodule Fretboard.Music do
  @moduledoc """
  Public API facade for all music domain logic.

  This is the only module that `FretboardWeb` should call.
  It delegates to `Note`, `Chord`, `Instrument`, and `Scale` internally.
  """

  alias Fretboard.Music.{Chord, Instrument, Note, Progression, Scale, URLCodec}

  @doc """
  Returns standard guitar tuning.
  """
  @spec standard_tuning() :: [String.t()]
  def standard_tuning, do: Instrument.instrument_standard_tuning(:guitar)

  @doc """
  Returns a list of named tuning presets (guitar, for backward compatibility).
  """
  @spec tuning_presets() :: [{String.t(), [String.t()]}]
  def tuning_presets, do: instrument_tuning_presets(:guitar)

  @doc """
  Returns just the names of all tuning presets (guitar, for backward
  compatibility).
  """
  @spec tuning_preset_names() :: [String.t()]
  def tuning_preset_names, do: instrument_preset_names(:guitar)

  @doc """
  Returns a list of `{key, label}` tuples for all supported instruments.
  """
  @spec instruments() :: [{atom(), String.t()}]
  def instruments, do: Instrument.instruments()

  @doc """
  Returns the full instrument definition map for the given instrument key.
  """
  @spec instrument(atom()) :: map() | nil
  def instrument(key), do: Instrument.instrument(key)

  @doc """
  Returns the number of strings for the given instrument.
  """
  @spec instrument_strings(atom()) :: pos_integer()
  def instrument_strings(key), do: Instrument.instrument_strings(key)

  @doc """
  Returns the standard tuning for the given instrument.
  """
  @spec instrument_standard_tuning(atom()) :: [String.t()]
  def instrument_standard_tuning(key), do: Instrument.instrument_standard_tuning(key)

  @doc """
  Returns the list of tuning presets for the given instrument.
  """
  @spec instrument_tuning_presets(atom()) :: [{String.t(), [String.t()]}]
  def instrument_tuning_presets(key), do: Instrument.instrument_tuning_presets(key)

  @doc """
  Returns just the names of all tuning presets for the given instrument.
  """
  @spec instrument_preset_names(atom()) :: [String.t()]
  def instrument_preset_names(key), do: Instrument.instrument_preset_names(key)

  @doc """
  Returns available chord qualities.
  """
  @spec available_qualities() :: [atom()]
  def available_qualities, do: Chord.available_qualities()

  @doc """
  Returns chord qualities organized in groups for UI display.
  """
  @spec grouped_qualities() :: [{String.t(), [atom()]}]
  def grouped_qualities, do: Chord.grouped_qualities()

  @doc """
  Returns the short display label for a chord quality.
  """
  @spec chord_label(atom()) :: String.t()
  def chord_label(quality), do: Chord.label(quality)

  @doc """
  Returns a formatted chord label combining root and quality.
  """
  @spec chord_label(String.t(), atom()) :: String.t()
  def chord_label(root, quality), do: Chord.chord_label(root, quality)

  @doc """
  Returns the notes for a chord given root and quality.
  """
  @spec chord_notes(String.t(), atom()) :: [String.t()]
  def chord_notes(root, quality), do: Chord.notes(root, quality)

  @doc """
  Returns notes with their interval labels for a chord.
  """
  @spec notes_with_intervals(String.t(), atom()) :: [{String.t(), String.t()}]
  def notes_with_intervals(root, quality), do: Chord.notes_with_intervals(root, quality)

  @doc """
  Returns the diatonic chords for a key.

  Pass `:seventh` as the third argument to get 7th-chord qualities.
  """
  @spec diatonic_chords(String.t(), atom(), :triad | :seventh) :: [
          %{root: String.t(), quality: atom()}
        ]
  def diatonic_chords(tonic, scale_type, mode \\ :triad),
    do: Scale.diatonic_chords(tonic, scale_type, mode)

  @doc """
  Returns available scale types.
  """
  @spec available_scale_types() :: [atom()]
  def available_scale_types, do: Scale.available_scale_types()

  @doc """
  Returns scale types organized in groups for UI display.
  """
  @spec grouped_scale_types() :: [{String.t(), [atom()]}]
  def grouped_scale_types, do: Scale.grouped_scale_types()

  @doc """
  Returns the display label for a scale type.
  """
  @spec scale_label(atom()) :: String.t()
  def scale_label(scale_type), do: Scale.scale_label(scale_type)

  @doc """
  Returns the notes of a scale given a tonic and scale type.

  ## Examples

      iex> Fretboard.Music.scale_notes("C", :major)
      ["C", "D", "E", "F", "G", "A", "B"]
  """
  @spec scale_notes(String.t(), atom()) :: [String.t()]
  def scale_notes(tonic, scale_type), do: Scale.scale_notes(tonic, scale_type)

  @doc """
  Suggests candidate keys that contain all notes of the given chords.

  Each chord is a map with `:root` and `:quality`. Returns a list of
  `%{tonic, scale_type, score, total, diatonic_chords}` maps sorted by
  score descending, then tonic, then scale_type.
  """
  @spec suggest_keys([%{root: String.t(), quality: atom()}]) :: [map()]
  def suggest_keys(chords), do: Scale.suggest_keys(chords)

  @doc """
  Suggests multiple keys that together cover the given chords using a
  greedy set-cover algorithm (max 3 groups).

  Each chord is a map with `:root` and `:quality`. Returns a list of
  groups, each with a `:key` (map or `nil` for unmatched chords) and a
  `:chords` list. Groups with real keys are ordered by coverage
  descending; the unmatched group (`key: nil`), if present, is last.
  """
  @spec suggest_multi_keys([%{root: String.t(), quality: atom()}]) :: [map()]
  def suggest_multi_keys(chords), do: Scale.suggest_multi_keys(chords)

  @doc """
  Returns the list of available chord progression ids.
  """
  @spec available_progressions() :: [atom()]
  def available_progressions, do: Progression.available_progressions()

  @doc """
  Returns chord progressions organized in groups for UI display.
  """
  @spec grouped_progressions() :: [{String.t(), [map()]}]
  def grouped_progressions, do: Progression.grouped_progressions()

  @doc """
  Returns the progression map for the given id, or `nil` if not found.
  """
  @spec progression(atom()) :: map() | nil
  def progression(id), do: Progression.progression(id)

  @doc """
  Returns the display label for a chord progression id, or `nil` if not found.
  """
  @spec progression_label(atom()) :: String.t() | nil
  def progression_label(id), do: Progression.progression_label(id)

  @doc """
  Resolves a progression to a list of chord maps for the given tonic.

  Each chord is `%{root: String.t(), quality: atom()}`.
  """
  @spec progression_chords(String.t(), atom()) :: [%{root: String.t(), quality: atom()}]
  def progression_chords(tonic, progression_id),
    do: Progression.progression_chords(tonic, progression_id)

  @doc """
  Builds the full fretboard data structure.

  Returns a list of 6 lists (one per string), each with 25 maps (frets 0-24).
  Each map contains `:fret`, `:note`, and `:chords` (list of chord labels
  like "C major" that contain this note).
  """
  @spec fretboard_data([String.t()], [map()]) :: [[map()]]
  def fretboard_data(tuning, active_chords) do
    chord_lookup = build_chord_lookup(active_chords)

    Enum.map(tuning, fn open_note ->
      Enum.map(0..24, fn fret ->
        note = Note.note_at(open_note, fret)
        chords = Map.get(chord_lookup, note, [])
        %{fret: fret, note: note, chords: chords}
      end)
    end)
  end

  @doc """
  Encodes tuning and active chords into URL query params.
  """
  @spec encode_params([String.t()], [map()]) :: map()
  def encode_params(tuning, active_chords), do: URLCodec.encode_params(tuning, active_chords)

  @doc """
  Encodes tuning, active chords, and highlighted index into URL query params.
  """
  @spec encode_params([String.t()], [map()], non_neg_integer() | nil) :: map()
  def encode_params(tuning, active_chords, highlighted_index),
    do: URLCodec.encode_params(tuning, active_chords, highlighted_index)

  @doc """
  Encodes instrument, tuning, active chords, and highlighted index into URL query params.
  """
  @spec encode_params(atom(), [String.t()], [map()], non_neg_integer() | nil) :: map()
  def encode_params(instrument, tuning, active_chords, highlighted_index),
    do: URLCodec.encode_params(instrument, tuning, active_chords, highlighted_index)

  @doc """
  Decodes URL query params into `{instrument, tuning, active_chords, highlighted_index}`.
  """
  @spec decode_params(map()) :: {atom(), [String.t()], [map()], non_neg_integer() | nil}
  def decode_params(params), do: URLCodec.decode_params(params)

  defp build_chord_lookup(active_chords) do
    Enum.reduce(active_chords, %{}, fn %{root: root, quality: quality}, acc ->
      label = Chord.chord_label(root, quality)
      notes = Chord.notes(root, quality)

      Enum.reduce(notes, acc, fn note, inner_acc ->
        Map.update(inner_acc, note, [label], &(&1 ++ [label]))
      end)
    end)
  end
end
