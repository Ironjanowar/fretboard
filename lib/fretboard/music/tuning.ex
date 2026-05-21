defmodule Fretboard.Music.Tuning do
  @moduledoc """
  Guitar tuning definitions.

  Provides standard tuning, tuning presets, and utilities for looking up
  the open note of a given string.
  """

  @presets [
    {"Standard", ["E", "A", "D", "G", "B", "E"]},
    {"Drop D", ["D", "A", "D", "G", "B", "E"]},
    {"DADGAD", ["D", "A", "D", "G", "A", "D"]},
    {"Open G", ["D", "G", "D", "G", "B", "D"]},
    {"Open D", ["D", "A", "D", "F#", "A", "D"]},
    {"Open E", ["E", "B", "E", "G#", "B", "E"]},
    {"Half Step Down", ["D#", "G#", "C#", "F#", "A#", "D#"]},
    {"Full Step Down", ["D", "G", "C", "F", "A", "D"]},
    {"Drop C", ["C", "G", "C", "F", "A", "D"]}
  ]

  @doc """
  Returns standard guitar tuning (low to high, strings 0-5).
  """
  @spec standard() :: [String.t()]
  def standard, do: ["E", "A", "D", "G", "B", "E"]

  @doc """
  Returns a list of named tuning presets.

  Each preset is a tuple of `{name, notes}` where notes is a list of 6 strings
  representing the tuning from low to high.
  """
  @spec presets() :: [{String.t(), [String.t()]}]
  def presets, do: @presets

  @doc """
  Returns just the names of all tuning presets.
  """
  @spec preset_names() :: [String.t()]
  def preset_names, do: Enum.map(@presets, &elem(&1, 0))

  @doc """
  Returns the open note for a given string index in a tuning.
  """
  @spec note_for_string([String.t()], non_neg_integer()) :: String.t()
  def note_for_string(tuning, string_index) do
    Enum.at(tuning, string_index)
  end
end
