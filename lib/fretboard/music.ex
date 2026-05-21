defmodule Fretboard.Music do
  @moduledoc """
  Public API facade for all music domain logic.

  This is the only module that `FretboardWeb` should call.
  It delegates to `Note`, `Chord`, and `Tuning` internally.
  """

  alias Fretboard.Music.{Chord, Note, Scale, Tuning, URLCodec}

  @doc """
  Returns standard guitar tuning.
  """
  @spec standard_tuning() :: [String.t()]
  def standard_tuning, do: Tuning.standard()

  @doc """
  Returns a list of named tuning presets.
  """
  @spec tuning_presets() :: [{String.t(), [String.t()]}]
  def tuning_presets, do: Tuning.presets()

  @doc """
  Returns just the names of all tuning presets.
  """
  @spec tuning_preset_names() :: [String.t()]
  def tuning_preset_names, do: Tuning.preset_names()

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
  Returns the diatonic chords for a key.
  """
  @spec diatonic_chords(String.t(), atom()) :: [%{root: String.t(), quality: atom()}]
  def diatonic_chords(tonic, scale_type), do: Scale.diatonic_chords(tonic, scale_type)

  @doc """
  Returns available scale types.
  """
  @spec available_scale_types() :: [atom()]
  def available_scale_types, do: Scale.available_scale_types()

  @doc """
  Returns the display label for a scale type.
  """
  @spec scale_label(atom()) :: String.t()
  def scale_label(scale_type), do: Scale.scale_label(scale_type)

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
  Decodes URL query params into `{tuning, active_chords}`.
  """
  @spec decode_params(map()) :: {[String.t()], [map()]}
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
