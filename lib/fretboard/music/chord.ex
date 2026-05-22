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
    m7b5: [0, 3, 6, 10]
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
    m7b5: "m7b5"
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
      {"Sevenths", [:"7", :maj7, :min7, :dim7, :m7b5]}
    ]
  end
end
