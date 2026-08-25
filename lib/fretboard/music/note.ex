defmodule Fretboard.Music.Note do
  @moduledoc """
  Handles chromatic note calculations.

  Provides functions to work with the 12-note chromatic scale,
  calculate notes at semitone intervals, and look up note indices.
  """

  @chromatic_scale ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

  # Flat note names are normalized to their enharmonic sharp equivalents
  # so that all lookups work against the sharp-only chromatic scale.
  @flat_to_sharp %{
    "Db" => "C#",
    "Eb" => "D#",
    "Fb" => "E",
    "Gb" => "F#",
    "Ab" => "G#",
    "Bb" => "A#",
    "Cb" => "B"
  }

  @doc """
  Returns the 12-note chromatic scale starting from C.
  """
  @spec chromatic_scale() :: [String.t()]
  def chromatic_scale, do: @chromatic_scale

  @doc """
  Returns the index (0-11) of a note in the chromatic scale.

  Flat note names (Db, Eb, Gb, Ab, Bb, Cb, Fb) are normalized to their
  enharmonic sharp equivalents before lookup.
  """
  @spec note_index(String.t()) :: non_neg_integer()
  def note_index(note) do
    normalized = Map.get(@flat_to_sharp, note, note)
    Enum.find_index(@chromatic_scale, &(&1 == normalized))
  end

  @doc """
  Returns the note name at a given number of semitones from a base note.

  Wraps around the chromatic scale (modulo 12).
  """
  @spec note_at(String.t(), non_neg_integer()) :: String.t()
  def note_at(base_note, semitones) do
    base = note_index(base_note)
    Enum.at(@chromatic_scale, rem(base + semitones, 12))
  end
end
