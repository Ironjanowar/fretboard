defmodule Fretboard.Music do
  @moduledoc """
  Public API facade for all music domain logic.

  This is the only module that `FretboardWeb` should call.
  It delegates to `Note`, `Chord`, and `Tuning` internally.
  """

  alias Fretboard.Music.{Chord, Note, Tuning}

  @doc """
  Returns standard guitar tuning.
  """
  @spec standard_tuning() :: [String.t()]
  def standard_tuning, do: Tuning.standard()

  @doc """
  Returns available chord qualities.
  """
  @spec available_qualities() :: [atom()]
  def available_qualities, do: Chord.available_qualities()

  @doc """
  Returns the notes for a chord given root and quality.
  """
  @spec chord_notes(String.t(), atom()) :: [String.t()]
  def chord_notes(root, quality), do: Chord.notes(root, quality)

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

  defp build_chord_lookup(active_chords) do
    Enum.reduce(active_chords, %{}, fn %{root: root, quality: quality}, acc ->
      label = "#{root} #{quality}"
      notes = Chord.notes(root, quality)

      Enum.reduce(notes, acc, fn note, inner_acc ->
        Map.update(inner_acc, note, [label], &(&1 ++ [label]))
      end)
    end)
  end
end
