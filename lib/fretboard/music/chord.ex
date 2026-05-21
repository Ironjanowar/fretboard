defmodule Fretboard.Music.Chord do
  @moduledoc """
  Chord formulas and note calculation.

  Defines chord qualities as semitone interval formulas and computes
  the notes that belong to a chord given a root and quality.
  """

  alias Fretboard.Music.Note

  @formulas %{major: [0, 4, 7], minor: [0, 3, 7]}

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
end
