defmodule Fretboard.Music.Scale do
  @moduledoc """
  Scale formulas and diatonic chord calculation.

  Defines scale types as semitone interval formulas and computes
  the notes and diatonic chords for a given tonic and scale type.
  """

  alias Fretboard.Music.Note

  @scale_formulas %{
    major: [0, 2, 4, 5, 7, 9, 11],
    minor: [0, 2, 3, 5, 7, 8, 10]
  }

  @diatonic_qualities %{
    major: [:major, :minor, :minor, :major, :major, :minor, :dim],
    minor: [:minor, :dim, :major, :minor, :minor, :major, :major]
  }

  @labels %{
    major: "Major",
    minor: "Minor"
  }

  @doc """
  Returns the list of available scale types.
  """
  @spec available_scale_types() :: [atom()]
  def available_scale_types, do: Map.keys(@scale_formulas) |> Enum.sort()

  @doc """
  Returns the 7 note names of a scale given a tonic and scale type.

  ## Examples

      iex> Fretboard.Music.Scale.scale_notes("C", :major)
      ["C", "D", "E", "F", "G", "A", "B"]
  """
  @spec scale_notes(String.t(), atom()) :: [String.t()]
  def scale_notes(tonic, scale_type) do
    Map.fetch!(@scale_formulas, scale_type)
    |> Enum.map(&Note.note_at(tonic, &1))
  end

  @doc """
  Returns the 7 diatonic chords for a key as maps with `:root` and `:quality`.

  ## Examples

      iex> Fretboard.Music.Scale.diatonic_chords("C", :major)
      [%{root: "C", quality: :major}, %{root: "D", quality: :minor}, %{root: "E", quality: :minor}, %{root: "F", quality: :major}, %{root: "G", quality: :major}, %{root: "A", quality: :minor}, %{root: "B", quality: :dim}]
  """
  @spec diatonic_chords(String.t(), atom()) :: [%{root: String.t(), quality: atom()}]
  def diatonic_chords(tonic, scale_type) do
    notes = scale_notes(tonic, scale_type)
    qualities = Map.fetch!(@diatonic_qualities, scale_type)

    Enum.zip(notes, qualities)
    |> Enum.map(fn {note, quality} -> %{root: note, quality: quality} end)
  end

  @doc """
  Returns the display label for a scale type.

  ## Examples

      iex> Fretboard.Music.Scale.scale_label(:major)
      "Major"
  """
  @spec scale_label(atom()) :: String.t()
  def scale_label(scale_type), do: Map.fetch!(@labels, scale_type)
end
