defmodule Fretboard.Music.Intervals do
  @moduledoc """
  Single source of truth for simple interval names.

  Maps semitone distances (0-11) to their simple interval names. The
  same distance means the same interval in every context; callers may
  layer contextual wording on top (e.g. chords call semitone 0 "Root").
  """

  @interval_names %{
    0 => "Perfect Unison",
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

  @doc """
  Returns the simple interval name for a semitone distance (0-11).

  ## Examples

      iex> Fretboard.Music.Intervals.name(4)
      "Major 3rd"

      iex> Fretboard.Music.Intervals.name(11)
      "Major 7th"
  """
  @spec name(non_neg_integer()) :: String.t()
  def name(semitones), do: Map.fetch!(@interval_names, semitones)
end
