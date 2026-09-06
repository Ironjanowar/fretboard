defmodule Fretboard.Music do
  @moduledoc """
  Public API facade for all music domain logic.

  This is the only module that `FretboardWeb` should call.
  It delegates to `Note`, `Chord`, `Instrument`, `Scale`, `Pitch`, and
  `Analyzer` internally.
  """

  alias Fretboard.Music.{Analyzer, Chord, Instrument, Note, Pitch, Progression, Scale, URLCodec}

  @typedoc """
  A tuning state: the exact MIDI pitches of every open string plus the
  preset name (`"Standard"`, `"Low G"`, ...) the state is anchored to.
  """
  @type tuning_state() :: %{pitches: [integer], reference: String.t()}

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

  @doc """
  Decodes the `tab` query param into `:visualizer` or `:analyzer`.

  Defaults to `:visualizer` when the param is missing or invalid.
  """
  @spec decode_tab(String.t() | nil) :: :visualizer | :analyzer
  def decode_tab(value), do: URLCodec.decode_tab(value)

  @doc """
  Decodes the `marked` query param into a map of `string_index => fret`.

  Returns an empty map when the param is missing or invalid.
  """
  @spec decode_marked(String.t() | nil) :: %{non_neg_integer() => non_neg_integer()}
  def decode_marked(value), do: URLCodec.decode_marked_map(value)

  @doc """
  Encodes a `marked` map into the comma-separated URL format.

  Returns `nil` for an empty map.
  """
  @spec encode_marked(%{non_neg_integer() => non_neg_integer()}) :: String.t() | nil
  def encode_marked(map), do: URLCodec.encode_marked_map(map)

  @doc """
  Filters marked notes to keep only entries whose string index is valid
  for the given string count.

  A string index is valid when it is strictly less than `string_count`
  (string indices are zero-based, so a 4-string instrument accepts 0-3).
  """
  @spec filter_marked_notes(%{non_neg_integer() => non_neg_integer()}, pos_integer()) ::
          %{non_neg_integer() => non_neg_integer()}
  def filter_marked_notes(marked_notes, string_count) do
    Map.filter(marked_notes, fn {string, _fret} -> string < string_count end)
  end

  @doc """
  Computes the note name for a given open-string note and fret.

  Delegates to `Note.note_at/2`.
  """
  @spec note_at(String.t(), non_neg_integer()) :: String.t()
  def note_at(open_note, fret), do: Note.note_at(open_note, fret)

  @doc """
  Returns the chromatic index (0-11) of a note name.
  """
  @spec note_index(String.t()) :: non_neg_integer()
  def note_index(note), do: Note.note_index(note)

  @doc """
  Identifies possible chord interpretations for a collection of notes,
  given a bass note, annotating each result with its inversion and a
  slash-chord label.

  Returns a list of result maps with `:root`, `:quality`, `:exact`,
  `:notes`, `:intervals`, `:bass`, `:inversion`, and `:slash_label`.

  Returns `[]` when fewer than 3 unique pitch classes are present.
  """
  @spec analyze_notes([String.t()], String.t()) :: [map()]
  def analyze_notes(notes, bass_note), do: Chord.identify(notes, bass_note)

  @doc """
  Identifies possible chord interpretations for a collection of notes
  without a bass note.

  Returns `[]` when fewer than 3 unique pitch classes are present.
  """
  @spec analyze_notes([String.t()]) :: [map()]
  def analyze_notes(notes), do: Chord.identify(notes)

  @doc "Returns chromatic display names without octave notation."
  def chromatic_scale, do: Note.chromatic_scale()

  @doc "Returns named absolute-pitch presets."
  def instrument_pitch_presets(instrument), do: Instrument.instrument_pitch_presets(instrument)

  @doc "Builds a tuning state from a known preset, or returns nil."
  @spec preset_tuning(atom(), String.t()) :: tuning_state() | nil
  def preset_tuning(instrument, name) do
    case Instrument.preset_pitches(instrument, name) do
      nil -> nil
      pitches -> %{pitches: pitches, reference: name}
    end
  end

  @doc "Derives display names from a tuning state's exact pitches."
  def tuning_notes(%{pitches: pitches}), do: Enum.map(pitches, &Pitch.note_name/1)

  @doc "Edits one string nearest to the unchanged starting preset reference."
  @spec change_tuning_note(atom(), tuning_state(), non_neg_integer(), String.t()) ::
          tuning_state()
  def change_tuning_note(instrument, state, index, note) do
    references = Instrument.preset_pitches(instrument, state.reference)
    [pitch] = Pitch.string_pitches([Enum.at(references, index)], [note])
    %{state | pitches: List.replace_at(state.pitches, index, pitch)}
  end

  @doc "Encodes exact tuning state, chords and highlight for a shareable URL."
  @spec encode_pitch_params(atom(), tuning_state(), [map()], non_neg_integer() | nil) :: map()
  defdelegate encode_pitch_params(instrument, state, chords, highlight), to: URLCodec

  @doc "Decodes exact tuning state with safe legacy note-only compatibility."
  @spec decode_pitch_params(map()) ::
          {atom(), tuning_state(), [map()], non_neg_integer() | nil}
  defdelegate decode_pitch_params(params), to: URLCodec

  @doc """
  Computes the analysis state from the marked positions (string index
  to fret) and the open-string pitches of the current tuning.

  Returns one of:
    - `{:empty}` — no notes marked
    - `{:single, note}` — one unique sounding pitch
    - `{:interval, note_low, note_high, label}` — two pitch classes ordered
      by their lowest heights, or one class at distinct heights (Octave)
    - `{:chords, notes, bass, interpretations}` — three or more pitch classes;
      `bass` is the note name of the lowest sounding pitch
  """
  @spec analyzer_state(%{non_neg_integer() => non_neg_integer()}, [integer()]) ::
          {:empty}
          | {:single, String.t()}
          | {:interval, String.t(), String.t(), String.t()}
          | {:chords, [String.t()], String.t(), [map()]}
  def analyzer_state(marked_notes, string_pitches),
    do: Analyzer.analyzer_state(marked_notes, string_pitches)

  @doc """
  Detects which named pitch preset matches a tuning, or "Custom".

  The comparison is by exact pitches, never by derived note names.
  """
  @spec detect_preset(atom(), [integer()]) :: String.t()
  def detect_preset(instrument, pitches) do
    case Enum.find(Instrument.instrument_pitch_presets(instrument), fn {_name, preset} ->
           preset == pitches
         end) do
      {name, _pitches} -> name
      nil -> "Custom"
    end
  end

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
