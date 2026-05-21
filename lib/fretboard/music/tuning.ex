defmodule Fretboard.Music.Tuning do
  @moduledoc """
  Guitar tuning definitions.

  Provides standard tuning and utilities for looking up
  the open note of a given string.
  """

  @doc """
  Returns standard guitar tuning (low to high, strings 0-5).
  """
  @spec standard() :: [String.t()]
  def standard, do: ["E", "A", "D", "G", "B", "E"]

  @doc """
  Returns the open note for a given string index in a tuning.
  """
  @spec note_for_string([String.t()], non_neg_integer()) :: String.t()
  def note_for_string(tuning, string_index) do
    Enum.at(tuning, string_index)
  end
end
